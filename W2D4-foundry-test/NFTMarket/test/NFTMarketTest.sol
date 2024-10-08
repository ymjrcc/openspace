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

    NFTMarketHandler public handler;

    address nftOwner = address(0x123);
    address nftBuyer = address(0x456);
    address notNftOwner = address(0x789);

    function setUp() public {
        yimingToken = new YimingToken();
        yimingNFT = new YimingNFT();
        nftMarket = new NFTMarket(address(yimingToken));

        handler = new NFTMarketHandler(nftMarket, yimingNFT, yimingToken, address(this));
        targetContract(address(handler));
    }

    // 辅助函数：铸造并批准 NFT
    function mintAndApproveNFT(address to, uint256 tokenId) internal {
        yimingNFT.safeMint(to, "ipfs://123");
        vm.prank(to);
        yimingNFT.approve(address(nftMarket), tokenId);
    }

    // 测试上架 NFT 成功和上架事件
    function testListSuccess() public {
        mintAndApproveNFT(nftOwner, 0);
        vm.startPrank(nftOwner);
        vm.expectEmit(true, true, true, true);
        emit List(nftOwner, address(yimingNFT), 0, 100);
        nftMarket.list(address(yimingNFT), 0, 100);
        vm.stopPrank();
    }

    // 测试上架 NFT 失败：不是 NFT 拥有者
    function testListFailure_NotOwner() public {
        mintAndApproveNFT(nftOwner, 0);
        vm.startPrank(notNftOwner);
        vm.expectRevert(unicode"不是 NFT 拥有者");
        nftMarket.list(address(yimingNFT), 0, 100);
        vm.stopPrank();
    }

    // 测试上架 NFT 失败：没有授权
    function testListFailure_NoApproval() public {
        yimingNFT.safeMint(nftOwner, "ipfs://123");
        vm.startPrank(nftOwner);
        vm.expectRevert(unicode"没有授权");
        nftMarket.list(address(yimingNFT), 0, 100);
        vm.stopPrank();
    }

    // 测试上架 NFT 失败：价格要大于 0
    function testListFailure_PriceZero() public {
        mintAndApproveNFT(nftOwner, 0);
        vm.startPrank(nftOwner);
        vm.expectRevert(unicode"价格要大于 0");
        nftMarket.list(address(yimingNFT), 0, 0);
        vm.stopPrank();
    }

    // 辅助函数：设置购买前的条件
    function setUpBuyConditions(uint256 price) internal {
        mintAndApproveNFT(nftOwner, 0);
        vm.prank(nftOwner);
        nftMarket.list(address(yimingNFT), 0, price);
    }

    // 测试购买 NFT 成功和购买事件
    function testBuyNFTSuccess() public {
        setUpBuyConditions(100);
        yimingToken.mint(nftBuyer, 1000);
        vm.startPrank(nftBuyer);
        yimingToken.approve(address(nftMarket), 100);
        vm.expectEmit(true, true, true, true);
        emit BuyNFT(nftBuyer, address(yimingNFT), 0, 100);
        nftMarket.buyNFT(address(yimingNFT), 0);
        vm.stopPrank();
    }

    // 测试购买 NFT 失败：自己购买自己的 NFT
    function testBuyNFTFailure_BuySelf() public {
        setUpBuyConditions(100);
        yimingToken.mint(nftOwner, 1000);
        vm.startPrank(nftOwner);
        yimingToken.approve(address(nftMarket), 100);
        vm.expectRevert(unicode"不能购买自己的 NFT");
        nftMarket.buyNFT(address(yimingNFT), 0);
        vm.stopPrank();
    }

    // 测试购买 NFT 失败：NFT 被重复购买
    function testBuyNFTFailure_BuyRepeat() public {
        setUpBuyConditions(100);
        yimingToken.mint(nftBuyer, 1000);
        vm.startPrank(nftBuyer);
        yimingToken.approve(address(nftMarket), 200);
        nftMarket.buyNFT(address(yimingNFT), 0);
        vm.expectRevert(unicode"nft不在合约中");
        nftMarket.buyNFT(address(yimingNFT), 0);
        vm.stopPrank();
    }

    // 测试购买 NFT 失败：支付 token 过少
    function testBuyNFTFailure_TokenToLess() public {
        setUpBuyConditions(100);
        yimingToken.mint(nftBuyer, 50);
        vm.startPrank(nftBuyer);
        yimingToken.approve(address(nftMarket), 100);
        vm.expectRevert(unicode"钱不够");
        nftMarket.buyNFT(address(yimingNFT), 0);
        vm.stopPrank();
    }

    // 模糊测试：测试随机使⽤ 0.01-10000 Token价格上架NFT，并随机使⽤任意Address购买 NFT
    function testFuzzListAndBuy(address buyer, uint256 price) public {
        vm.assume(price > 0 && price <= 10000);
        vm.assume(buyer != address(0) && buyer != nftOwner);
        setUpBuyConditions(price);
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

contract NFTMarketHandler is Test {
    NFTMarket public nftMarket;
    YimingNFT public yimingNFT;
    YimingToken public yimingToken;

    address nftOwner = address(0x123);
    address testContractAddr;
    constructor(NFTMarket nftMarket_, YimingNFT yimingNFT_, YimingToken yimingToken_, address testContract_){
        nftMarket = nftMarket_;
        yimingNFT = yimingNFT_;
        yimingToken = yimingToken_;
        testContractAddr = testContract_;
    }

    // 辅助函数：铸造并批准 NFT
    function mintAndApproveNFT(address to, uint256 tokenId) internal {
        vm.startPrank(testContractAddr);
        yimingNFT.safeMint(to, "ipfs://123");
        vm.stopPrank();

        vm.startPrank(to);
        yimingNFT.approve(address(nftMarket), tokenId);
        vm.stopPrank();
    }

    function testFuzzListAndBuy(address buyer, uint256 price) public {
        vm.assume(price > 0 && price <= 10000);
        vm.assume(buyer != address(0) && buyer != nftOwner && buyer != address(nftMarket));

        mintAndApproveNFT(nftOwner, 0);
        vm.startPrank(nftOwner);
        nftMarket.list(address(yimingNFT), 0, price);
        vm.stopPrank();

        deal(address(yimingToken), buyer, 10000);
        vm.startPrank(buyer);
        yimingToken.approve(address(nftMarket), 10000);
        nftMarket.buyNFT(address(yimingNFT), 0);
        vm.stopPrank();
    }
}
