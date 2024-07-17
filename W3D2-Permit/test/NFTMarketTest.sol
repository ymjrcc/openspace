// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {NFTMarket} from "../src/NFTMarket.sol";

contract NFTMarketTest is Test {
    MyToken public myToken;
    MyNFT public myNFT;
    NFTMarket public nftMarket;

    uint256 private adminPrivateKey = uint256(keccak256(abi.encodePacked("admin")));
    uint256 private buyerPrivateKey = uint256(keccak256(abi.encodePacked("buyer")));
    uint256 private sellerPrivateKey = uint256(keccak256(abi.encodePacked("seller")));
    uint256 private somebodyPrivateKey = uint256(keccak256(abi.encodePacked("somebodyPrivateKey")));


    address public admin = vm.addr(adminPrivateKey);
    address public buyer = vm.addr(buyerPrivateKey);
    address public seller = vm.addr(sellerPrivateKey);
    address public somebody = vm.addr(somebodyPrivateKey);

    function setUp() public {

        vm.startPrank(admin);
        myToken = new MyToken(admin);
        myNFT = new MyNFT();
        nftMarket = new NFTMarket(address(myToken));
        myToken.mint(buyer, 1e20);
        myToken.mint(somebody, 1e20);
        myNFT.safeMint(seller, "ipfs://123");
        vm.stopPrank();
    }

    function testPermitBuyNFT() public {
        uint256 tokenId = 0;
        uint256 price = 100;
        vm.startPrank(seller);
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, price);
        vm.stopPrank();

        uint256 deadline = block.timestamp + 1 hours;
        bytes32 domainSeparator = nftMarket.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(
            nftMarket.WHITELIST_TYPEHASH(),
            buyer,
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19\x01",
            domainSeparator,
            structHash
        ));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminPrivateKey, hash);

        assertEq(myNFT.ownerOf(tokenId), address(nftMarket));
        console.log("Before permitBuy, NFT's owner: ", myNFT.ownerOf(tokenId));
        
        vm.startPrank(buyer);
        myToken.approve(address(nftMarket), price);
        nftMarket.permitBuy(address(myNFT), tokenId, deadline, v, r, s);
        vm.stopPrank();

        assertEq(myNFT.ownerOf(tokenId), buyer);
        console.log("After permitBuy, NFT's owner: ", myNFT.ownerOf(tokenId));
    }

    function testPermitBuyFailsWithInvalidSignature() public {
        uint256 tokenId = 0;
        uint256 price = 100;
        vm.startPrank(seller);
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, price);
        vm.stopPrank();

        uint256 deadline = block.timestamp + 1 hours;
        bytes32 domainSeparator = nftMarket.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(
            nftMarket.WHITELIST_TYPEHASH(),
            buyer,
            deadline
        ));
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19\x01",
            domainSeparator,
            structHash
        ));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminPrivateKey, hash);
        
        vm.startPrank(somebody);
        myToken.approve(address(nftMarket), price);
        vm.expectRevert("Invalid signature");
        nftMarket.permitBuy(address(myNFT), tokenId, deadline, v, r, s);
        vm.stopPrank();
    }
}