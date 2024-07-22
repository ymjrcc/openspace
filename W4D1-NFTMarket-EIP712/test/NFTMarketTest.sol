// SPDX-License-Identifier: MIT
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
        myToken = new MyToken();
        myNFT = new MyNFT();
        nftMarket = new NFTMarket();
        nftMarket.setWhiteListSigner(admin);
        myToken.mint(buyer, 1e20);
        myToken.mint(somebody, 1e20);
        myNFT.safeMint(seller, "ipfs://123");
        vm.stopPrank();
    }

    function testList() public {
        // Setup
        address payToken = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // ETH
        uint256 price = 1 ether;
        uint256 deadline = block.timestamp + 1 days;

        // Approve market to transfer NFT
        vm.prank(seller);
        myNFT.approve(address(nftMarket), 0);

        // Prepare EIP712 signature
        bytes32 DOMAIN_SEPARATOR = nftMarket.DOMAIN_SEPARATOR();
        bytes32 LIST_TYPEHASH = keccak256("List(address nft,uint256 tokenId,address payToken,uint256 price,uint256 deadline)");
        
        bytes32 structHash = keccak256(abi.encode(
            LIST_TYPEHASH,
            address(myNFT),
            0,
            payToken,
            price,
            deadline
        ));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sellerPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Call list function
        vm.prank(seller);
        nftMarket.list(address(myNFT), 0, payToken, price, deadline, signature);

        _checkListData();
    }

    function _checkListData() private view {
        // Setup
        address payToken = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // ETH
        uint256 price = 1 ether;
        uint256 deadline = block.timestamp + 1 days;

        bytes32 orderId = nftMarket.listing(address(myNFT), 0);
        assertTrue(orderId != bytes32(0), "Listing should exist");
        (
            address _seller,
            address _nft,
            uint256 _tokenId,
            address _payToken,
            uint256 _price,
            uint256 _deadline
        ) = nftMarket.listingOrders(orderId);
        assertEq(_seller, seller, "Incorrect seller");
        assertEq(_nft, address(myNFT), "Incorrect NFT address");
        assertEq(_tokenId, 0, "Incorrect token ID");
        assertEq(_payToken, payToken, "Incorrect pay token");
        assertEq(_price, price, "Incorrect price");
        assertEq(_deadline, deadline, "Incorrect deadline");
    }
}