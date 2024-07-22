// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {EIP712} from "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract  NFTMarket is Ownable(msg.sender), EIP712("OpenSpaceNFTMarket", "1") {
    address public constant ETH_FLAG = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint256 public constant feeBP = 30; //  30/10000 = 0.3%
    address public whiteListSigner;
    address public feeTo;
    // 挂单的所有订单簿
    mapping(bytes32 => SellOrder) public listingOrders;
    // 反向关联最后一个订单 nft => tokenId => orderId
    mapping(address => mapping (uint256 => bytes32)) private _lastIds;

    struct SellOrder {
        address seller;
        address nft;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
    }

    function listing(address nft, uint256 tokenId) external view returns (bytes32) {
      bytes32 id = _lastIds[nft][tokenId];
      return listingOrders[id].seller == address(0) ? bytes32(0x00) : id;
    }

    bytes32 private constant LIST_TYPEHASH = keccak256("List(address nft,uint256 tokenId,address payToken,uint256 price,uint256 deadline)");

    function _checkList(
        address nft, 
        uint256 tokenId, 
        address payToken, 
        uint256 price, 
        uint256 deadline, 
        bytes calldata signature
    ) private view {
        // check listSignature for seller
        bytes32 structHash = keccak256(abi.encode(
            LIST_TYPEHASH,
            nft,
            tokenId,
            payToken,
            price,
            deadline
        ));
        bytes32 listHash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(listHash, signature);
        require(signer == msg.sender, "NFTMarket: invalid signature");
    }

    function list(
        address nft, 
        uint256 tokenId, 
        address payToken, 
        uint256 price, 
        uint256 deadline, 
        bytes calldata signature
    ) external {
        require(deadline > block.timestamp, "NFTMarket: deadline is in the past");
        require(price > 0, "NFTMarket: price is zero");
        require(payToken == ETH_FLAG || IERC20(payToken).totalSupply() > 0, "NFTMarket: payToken is not valid");
        
        // safe check
        require(IERC721(nft).ownerOf(tokenId) == msg.sender, "NFTMarket: not owner");
        require(
            IERC721(nft).getApproved(tokenId) == address(this) 
                || IERC721(nft).isApprovedForAll(msg.sender, address(this)), 
            "NFTMarket: not approved"
        );

        // check listSignature for seller
        _checkList(nft, tokenId, payToken, price, deadline, signature);
    
        SellOrder memory order = SellOrder({
            seller: msg.sender,
            nft: nft,
            tokenId: tokenId,
            payToken: payToken,
            price: price,
            deadline: deadline
        });

        bytes32 orderId = keccak256(abi.encode(order));
        // safe check repeat list
        require(listingOrders[orderId].seller == address(0), "NFTMarket: order already list");
        listingOrders[orderId] = order;
        _lastIds[nft][tokenId] = orderId; // reset
        emit List(nft, tokenId, orderId, msg.sender, payToken, price, deadline);
    }

    function cancel(bytes32 orderId) external {
        address seller = listingOrders[orderId].seller;
        // safe check repeat list
        require(seller != address(0), "NFTMarket: order not listed");
        require(seller == msg.sender, "NFTMarket: only seller can cancel");
        delete listingOrders[orderId];
        emit Cancel(orderId);
    }

    function buy(bytes32 orderId) public payable {
        _buy(orderId, feeTo);
    }

    function buy(bytes32 orderId, bytes calldata signatureForWL) external payable {
        _checkWL(signatureForWL);
        // trade fee is zero
        _buy(orderId, address(0));
    }

    function _buy(bytes32 orderId, address feeReceiver) private {
        // 0. load order info to memory for check and read
        SellOrder memory order = listingOrders[orderId];

        // 1. check
        require(order.seller != address(0), "NFTMarket: order not listed");
        require(order.deadline > block.timestamp, "NFTMarket: order expired");

        // 2. remove order info before transfer
        delete listingOrders[orderId];
        // 3. transfer nft
        IERC721(order.nft).safeTransferFrom(order.seller, msg.sender, order.tokenId);

        // 4. transfer payToken
        // fee 0.3% or zero
        uint256 fee = feeReceiver == address(0) ? 0 : order.price * feeBP / 10000;
        // safe check
        if(order.payToken == ETH_FLAG) {
            require(msg.value == order.price, "NFTMarket: wrong msg.value");
        } else {
            require(msg.value == 0, "NFTMarket: wrong msg.value");
        }
        _transferOut(order.payToken, order.seller, order.price - fee);
        if(fee > 0) _transferOut(order.payToken, feeReceiver, fee);

        emit Sold(orderId, msg.sender, fee);
    }

    function _transferOut(address token, address to, uint256 amount) private {
        if(token == ETH_FLAG) { 
            // eth
            (bool success, ) = to.call{value: amount}("");
            require(success, "NFTMarket: transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(token), to, amount);
        }
    }

    bytes32 constant WL_TYPEHASH = keccak256("IsWhiteList(address user)");

    function _checkWL(bytes calldata signature) private view {
        // check whiteListSignature for buyer
        bytes32 wlHash = _hashTypedDataV4(keccak256(abi.encode(WL_TYPEHASH, msg.sender)));
        address signer = ECDSA.recover(wlHash, signature);
        require(signer == whiteListSigner, "NFTMarket: invalid signature");
    }

    // admin functions
    function setWhiteListSigner(address signer) external onlyOwner {
        require(signer != address(0), "NFTMarket: invalid signer");
        require(whiteListSigner != signer, "NFTMarket: whiteListSigner is the same");
        whiteListSigner = signer;

        emit SetWhiteListSigner(signer);
    }

    function setFeeTo(address to) external onlyOwner {
        require(feeTo != to, "NFTMarket: feeTo is the same");
        feeTo = to;

        emit SetFeeTo(to);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    event List(
      address indexed nft, 
      uint256 indexed tokenId, 
      bytes32 orderId, 
      address seller, 
      address payToken, 
      uint256 price, 
      uint256 deadline
    );
    event Cancel(bytes32 orderId);
    event Sold(bytes32 orderId, address buyer, uint256 fee);
    event SetFeeTo(address to);
    event SetWhiteListSigner(address signer);
}