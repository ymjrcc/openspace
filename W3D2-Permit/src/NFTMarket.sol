// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "./IMyToken.sol";
import {Test, console} from "forge-std/Test.sol";


contract NFTMarket is EIP712{
    using ECDSA for bytes32;
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
    IMyToken token;
    address public admin;

    bytes32 public constant WHITELIST_TYPEHASH = keccak256("Whitelist(address user,uint256 deadline)");

    constructor(address _erc20) EIP712("NFTMarket", "1") {
        token = IMyToken(_erc20);
        admin = msg.sender;
    }

    receive() external payable {}
    fallback() external payable {}

    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public {
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.getApproved(_tokenId) == address(this), "Not approved");
        require(_price > 0, "The price must be greater than 0");
        Order storage _order = nftList[_nftAddr][_tokenId];
        _order.owner = msg.sender;
        _order.price = _price;
        _nft.transferFrom(msg.sender, address(this), _tokenId);
        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }

    function buyNFT(address _nftAddr, uint256 _tokenId) public {
        Order storage _order = nftList[_nftAddr][_tokenId];
        address _owner = _order.owner;
        uint256 _price = _order.price;
        require(_price > 0, "The price must be greater than 0");
        require(token.balanceOf(msg.sender) >= _price, "No enough balance");
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "NFT is not on sell");
        delete nftList[_nftAddr][_tokenId];
        _nft.transferFrom(address(this), msg.sender, _tokenId);
        token.transferFrom(msg.sender, _owner, _price);
        emit BuyNFT(msg.sender, _nftAddr, _tokenId, _price);
    }

    function permitBuy(
        address _nftAddr,
        uint256 _tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp <= deadline, "Signature expired");

        bytes32 structHash = keccak256(abi.encode(WHITELIST_TYPEHASH, msg.sender, deadline));
        // bytes32 hash = _hashTypedDataV4(structHash);
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR(),
            structHash
        ));
        address signer = hash.recover(v, r, s);
        // address signer = ecrecover(hash, v, r, s);

        require(signer == admin, "Invalid signature");

        buyNFT(_nftAddr, _tokenId);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _domainSeparatorV4();
    }
}