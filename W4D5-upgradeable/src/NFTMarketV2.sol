// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract NFTMarket is Initializable, EIP712("NFTMarket", "1") {
    event List(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );
    event BuyNFT(
        address indexed buyer,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );

    struct Order {
        address owner;
        uint256 price;
    }

    // NFTAddress => tokenId => Order
    mapping(address => mapping(uint256 => Order)) public nftList;
    IERC20 token;

    // EIP712相关常量
    bytes32 private constant LIST_TYPEHASH = keccak256("List(address nftAddr,uint256 tokenId,uint256 price)");

    function initialize(address _erc20) public initializer {
        token = IERC20(_erc20);
    }

    function _list(address _seller, address _nftAddr, uint256 _tokenId, uint256 _price) private {
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.getApproved(_tokenId) == address(this) || _nft.isApprovedForAll(_seller, address(this)), "Not approved");
        require(_price > 0, "The price must be greater than 0");
        Order storage _order = nftList[_nftAddr][_tokenId];
        _order.owner = _seller;
        _order.price = _price;
        _nft.transferFrom(_seller, address(this), _tokenId);
        emit List(_seller, _nftAddr, _tokenId, _price);
    }

    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public {
        _list(msg.sender, _nftAddr, _tokenId, _price);
    }

    // 新增：使用离线签名上架NFT
    function listWithSignature(
        address _nftAddr,
        uint256 _tokenId,
        uint256 _price,
        bytes calldata signature
    ) public {
        // 验证签名
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            LIST_TYPEHASH,
            _nftAddr,
            _tokenId,
            _price
        )));
        address signer = ECDSA.recover(digest, signature);
        require(IERC721(_nftAddr).ownerOf(_tokenId) == signer, "Signer is not the owner of the NFT");

        _list(signer, _nftAddr, _tokenId, _price);
    }

    function buyNFT(address _nftAddr, uint256 _tokenId) public {
        Order memory _order = nftList[_nftAddr][_tokenId];
        require(_order.price > 0, "The price must be greater than 0");
        require(token.balanceOf(msg.sender) >= _order.price, "No enough balance");
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "NFT is not on sell");
        delete nftList[_nftAddr][_tokenId];
        _nft.transferFrom(address(this), msg.sender, _tokenId);
        token.transferFrom(msg.sender, _order.owner, _order.price);
        emit BuyNFT(msg.sender, _nftAddr, _tokenId, _order.price);
    }
}