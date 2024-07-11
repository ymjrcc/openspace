// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Test, console} from "forge-std/Test.sol";
import {NFTMarket} from "../src/NFTMarket.sol";
import {YimingToken} from "../src/ERC20.sol";
import {YimingNFT} from "../src/ERC721.sol";

contract NFTMarketTest is Test {

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

    NFTMarket public nftMarket;
    YimingToken public yimingToken;
    YimingNFT public yimingNFT;

    address nftOwner = address(0x123);
    address nftBuyer = address(0x456);
    address notNftOwner = address(0x789);

    function setUp() public {
        yimingToken = new YimingToken();
        yimingNFT = new YimingNFT();
        nftMarket = new NFTMarket(address(yimingToken));
    }

    // 测试上架 NFT 成功和上架事件
    function testListSuccess() public {
        yimingNFT.safeMint(nftOwner, "ipfs://123");
        vm.startPrank(nftOwner);
        yimingNFT.approve(address(nftMarket), 0);
        vm.expectEmit(true, true, true, true);
        emit List(nftOwner, address(yimingNFT), 0, 100);
        nftMarket.list(address(yimingNFT), 0, 100);
        vm.stopPrank();
    }

    // 测试上架 NFT 失败：不是 NFT 拥有者
    function testListFailure1() public {
        yimingNFT.safeMint(nftOwner, "ipfs://123");
        vm.prank(nftOwner);
        yimingNFT.approve(address(nftMarket), 0);
        vm.startPrank(notNftOwner);
        vm.expectRevert(unicode"不是 NFT 拥有者");
        nftMarket.list(address(yimingNFT), 0, 100);
        vm.stopPrank();
    }

    // 测试上架 NFT 失败：没有授权
    function testListFailure2() public {
        yimingNFT.safeMint(nftOwner, "ipfs://123");
        vm.startPrank(nftOwner);
        vm.expectRevert(unicode"没有授权");
        nftMarket.list(address(yimingNFT), 0, 100);
        vm.stopPrank();
    }

    // 测试上架 NFT 失败：价格要大于 0
    function testListFailure3() public {
        yimingNFT.safeMint(nftOwner, "ipfs://123");
        vm.startPrank(nftOwner);
        yimingNFT.approve(address(nftMarket), 0);
        vm.expectRevert(unicode"价格要大于 0");
        nftMarket.list(address(yimingNFT), 0, 0);
        vm.stopPrank();
    }

    // 测试购买 NFT 成功和购买事件
    function testBuyNFTSuccess() public {
        yimingNFT.safeMint(nftOwner, "ipfs://123");
        vm.startPrank(nftOwner);
        yimingNFT.approve(address(nftMarket), 0);
        nftMarket.list(address(yimingNFT), 0, 100);
        vm.stopPrank();
        yimingToken.mint(nftBuyer, 1000);
        vm.startPrank(nftBuyer);
        yimingToken.approve(address(nftMarket), 100);
        vm.expectEmit(true, true, true, true);
        emit BuyNFT(nftBuyer, address(yimingNFT), 0, 100);
        nftMarket.buyNFT(address(yimingNFT), 0);
        vm.stopPrank();
    }

    // 测试购买 NFT 失败：自己购买自己的 NFT
    function testBuyNFTFailure1() public {
        yimingToken.mint(nftOwner, 1000);
        yimingNFT.safeMint(nftOwner, "ipfs://123");
        vm.startPrank(nftOwner);
        yimingNFT.approve(address(nftMarket), 0);
        nftMarket.list(address(yimingNFT), 0, 100);
        yimingToken.approve(address(nftMarket), 100);
        vm.expectRevert(unicode"不能购买自己的 NFT");
        nftMarket.buyNFT(address(yimingNFT), 0);
        vm.stopPrank();
    }

    // 测试购买 NFT 失败：NFT 被重复购买
    function testBuyNFTFailure2() public {
        yimingNFT.safeMint(nftOwner, "ipfs://123");
        vm.startPrank(nftOwner);
        yimingNFT.approve(address(nftMarket), 0);
        nftMarket.list(address(yimingNFT), 0, 100);
        vm.stopPrank();
        yimingToken.mint(nftBuyer, 1000);
        vm.startPrank(nftBuyer);
        yimingToken.approve(address(nftMarket), 200);
        nftMarket.buyNFT(address(yimingNFT), 0);
        vm.expectRevert(unicode"nft不在合约中");
        nftMarket.buyNFT(address(yimingNFT), 0);
        vm.stopPrank();
    }

    // 测试购买 NFT 失败：支付 token 过少
    function testBuyNFTFailure3() public {
        yimingNFT.safeMint(nftOwner, "ipfs://123");
        vm.startPrank(nftOwner);
        yimingNFT.approve(address(nftMarket), 0);
        nftMarket.list(address(yimingNFT), 0, 100);
        vm.stopPrank();
        yimingToken.mint(nftBuyer, 50);
        vm.startPrank(nftBuyer);
        yimingToken.approve(address(nftMarket), 50);
        vm.expectRevert(unicode"钱不够");
        nftMarket.buyNFT(address(yimingNFT), 0);
        vm.stopPrank();
    }

    // 模糊测试
    function testFuzzListAndBuy(address buyer, uint256 price) public {
        vm.assume(price > 0 && price <= 10000);
        vm.assume(buyer != address(0) && buyer != nftOwner);
        yimingNFT.safeMint(nftOwner, "ipfs://123");
        vm.startPrank(nftOwner);
        yimingNFT.approve(address(nftMarket), 0);
        nftMarket.list(address(yimingNFT), 0, price);
        vm.stopPrank();
        yimingToken.mint(buyer, 10000);
        vm.startPrank(buyer);
        yimingToken.approve(address(nftMarket), 10000);
        nftMarket.buyNFT(address(yimingNFT), 0);
        vm.stopPrank();
    }

    // 不可变测试：测试⽆论如何买卖，NFTMarket合约中都不可能有 Token 持仓
    function invariantToken() public view {
        assertEq(yimingToken.balanceOf(address(nftMarket)), 0);
    }
}
