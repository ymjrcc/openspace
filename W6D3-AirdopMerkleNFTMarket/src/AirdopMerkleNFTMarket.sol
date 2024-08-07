// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/contracts/utils/Multicall.sol";
import "./IMyToken.sol";

contract AirdopMerkleNFTMarket is Multicall {

    struct Order {
        address owner;
        uint256 price;
    }

    // NFTAddress => tokenId => Order
    mapping(address => mapping(uint256 => Order)) public nftList;
    IMyToken token;
    bytes32 public immutable merkleRoot;

    constructor(address _token, bytes32 _merkleRoot) {
        token = IMyToken(_token);
        merkleRoot = _merkleRoot;
    }

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
        Order memory _order = nftList[_nftAddr][_tokenId];
        uint256 _price = _order.price;
        _buyNFT(_nftAddr, _tokenId, _price);
    }

    function verifyUserInWhitelist(address user, bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(merkleProof, merkleRoot, node);
    }

    function permitPrePay(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public  {
        token.permit(owner, spender, value, deadline, v, r, s);
    }

    function claimNFT(address _nftAddr, uint256 _tokenId, bytes32[] calldata merkleProof) public {
        require(verifyUserInWhitelist(msg.sender, merkleProof), "User not in whitelist");
        Order memory _order = nftList[_nftAddr][_tokenId];
        uint256 _price = _order.price / 2;
        _buyNFT(_nftAddr, _tokenId, _price);
    }

    function _buyNFT(address _nftAddr, uint256 _tokenId, uint256 _price) private {
        Order memory _order = nftList[_nftAddr][_tokenId];
        require(_order.price > 0, "The price must be greater than 0");
        require(token.balanceOf(msg.sender) >= _price, "No enough balance");
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "NFT is not on sell");
        delete nftList[_nftAddr][_tokenId];
        token.transferFrom(msg.sender, _order.owner, _price);
        _nft.transferFrom(address(this), msg.sender, _tokenId);
        emit BuyNFT(msg.sender, _nftAddr, _tokenId, _price);
    }

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
}