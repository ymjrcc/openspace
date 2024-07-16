// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "./IMyToken.sol";

contract NFTMarket is EIP712{
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

    constructor(address _erc20) EIP712("NFTMarket", "1") {
        token = IMyToken(_erc20);
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

    function permitBuy(address _nftAddr, uint256 _tokenId, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) public {
        require(block.timestamp <= _deadline, "time expired");
        bytes32 structHash = keccak256(abi.encodePacked(msg.sender, _tokenId, _deadline));
        bytes32 digest = keccak256(abi.encodePacked(structHash));
        address signer = ecrecover(digest, _v, _r, _s);
        require(signer == nftList[_nftAddr][_tokenId].owner, "Not the correct signer");
        buyNFT(_nftAddr, _tokenId);

    }
}