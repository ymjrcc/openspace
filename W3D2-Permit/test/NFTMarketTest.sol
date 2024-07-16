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

    address public buyer = vm.addr(uint256(keccak256(abi.encodePacked("buyer"))));
    address public seller = vm.addr(uint256(keccak256(abi.encodePacked("seller"))));

    function setUp() public {

        myToken = new MyToken(address(this));
        myNFT = new MyNFT();
        nftMarket = new NFTMarket(address(myToken));

        myToken.mint(buyer, 1e20);

        myNFT.safeMint(seller, "ipfs://123");
    }

    function testPermitBuyNFT() public {
        uint256 tokenId = 0;
        uint256 price = 100;
        vm.startPrank(seller);
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, price);
        vm.stopPrank();

        uint256 deadline = block.timestamp + 1 hours;
        bytes32 structHash = keccak256(abi.encodePacked(buyer, tokenId, deadline));
        bytes32 digest = keccak256(abi.encodePacked(structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(keccak256(abi.encodePacked("seller"))), digest);

        assertEq(myNFT.ownerOf(tokenId), address(nftMarket));
        console.log("Before permitBuy, NFT's owner is NFTMarket: ", myNFT.ownerOf(tokenId) == address(nftMarket));
        
        vm.startPrank(buyer);
        myToken.approve(address(nftMarket), price);
        nftMarket.permitBuy(address(myNFT), tokenId, deadline, v, r, s);
        vm.stopPrank();

        assertEq(myNFT.ownerOf(tokenId), buyer);
        console.log("After permitBuy, NFT's owner is buyer: ", myNFT.ownerOf(tokenId) == buyer);
    }
}