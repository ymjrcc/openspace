// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NFTMarketWithRewards.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

// 模拟的 NFT 合约
contract MockNFT is ERC721 {
    uint256 private _tokenIdCounter;

    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(to, tokenId);
        return tokenId;
    }
}

contract NFTMarketWithRewardsTest is Test {
    NFTMarketWithRewards public market;
    MockNFT public mockNFT;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);
    address public david = address(0x4);

    function setUp() public {
        market = new NFTMarketWithRewards();
        mockNFT = new MockNFT();
        vm.deal(alice, 10000 ether);
        vm.deal(bob, 10000 ether);
        vm.deal(charlie, 10000 ether);
        vm.deal(david, 10000 ether);
    }

    // function testList() public {
    //     uint256 tokenId = mockNFT.mint(alice);
    //     vm.startPrank(alice);
    //     mockNFT.approve(address(market), tokenId);
    //     market.list(address(mockNFT), tokenId, 1 ether);
    //     vm.stopPrank();

    //     (address owner, uint256 price) = market.nftList(address(mockNFT), tokenId);
    //     assertEq(owner, alice);
    //     assertEq(price, 1 ether);
    // }

    // function testBuyNFT() public {
    //     uint256 tokenId = mockNFT.mint(alice);
    //     vm.startPrank(alice);
    //     mockNFT.approve(address(market), tokenId);
    //     market.list(address(mockNFT), tokenId, 1 ether);
    //     vm.stopPrank();

    //     vm.prank(bob);
    //     market.buyNFT{value: 1 ether}(address(mockNFT), tokenId);

    //     assertEq(mockNFT.ownerOf(tokenId), bob);
    //     assertEq(market.accumulatedFees(), 0.01 ether);
    // }

    // function testStake() public {
    //     vm.prank(alice);
    //     market.stake{value: 1 ether}();

    //     assertEq(market.userStakeAmount(alice), 1 ether);
    //     assertEq(market.totalStaked(), 1 ether);
    // }

    // function testUnstake() public {
    //     vm.startPrank(alice);
    //     market.stake{value: 1 ether}();
    //     uint256 balanceBefore = alice.balance;
    //     market.unstake(0.5 ether);
    //     vm.stopPrank();

    //     assertEq(market.userStakeAmount(alice), 0.5 ether);
    //     assertEq(market.totalStaked(), 0.5 ether);
    //     assertEq(alice.balance, balanceBefore + 0.5 ether);
    // }

    // function testClaimReward() public {
    //     // Alice stakes 1 ETH
    //     vm.prank(alice);
    //     market.stake{value: 1 ether}();

    //     // Generate some fees
    //     uint256 tokenId = mockNFT.mint(bob);
    //     vm.startPrank(bob);
    //     mockNFT.approve(address(market), tokenId);
    //     market.list(address(mockNFT), tokenId, 1 ether);
    //     vm.stopPrank();

    //     vm.prank(charlie);
    //     market.buyNFT{value: 1 ether}(address(mockNFT), tokenId);

    //     // Alice claims reward
    //     uint256 balanceBefore = alice.balance;
    //     vm.prank(alice);
    //     market.claimReward();

    //     assertEq(alice.balance - balanceBefore, 0.01 ether);
    //     assertEq(market.userRewardToClaim(alice), 0);
    // }

    // function testMultipleStakersRewards() public {
    //     // Alice and Bob stake 1 ETH each
    //     vm.prank(alice);
    //     market.stake{value: 1 ether}();
    //     vm.prank(bob);
    //     market.stake{value: 1 ether}();

    //     // Generate some fees
    //     uint256 tokenId = mockNFT.mint(charlie);
    //     vm.startPrank(charlie);
    //     mockNFT.approve(address(market), tokenId);
    //     market.list(address(mockNFT), tokenId, 2 ether);
    //     vm.stopPrank();

    //     vm.prank(david);
    //     market.buyNFT{value: 2 ether}(address(mockNFT), tokenId);

    //     // Alice and Bob claim rewards
    //     uint256 aliceBalanceBefore = alice.balance;
    //     uint256 bobBalanceBefore = bob.balance;

    //     vm.prank(alice);
    //     market.claimReward();
    //     vm.prank(bob);
    //     market.claimReward();

    //     assertGt(alice.balance, aliceBalanceBefore);
    //     assertGt(bob.balance, bobBalanceBefore);
    //     assertEq(market.userRewardToClaim(alice), 0);
    //     assertEq(market.userRewardToClaim(bob), 0);
    //     assertApproxEqAbs(alice.balance - aliceBalanceBefore, bob.balance - bobBalanceBefore, 1e9);
    // }

    function generateFees(uint256 amount) private {
        uint256 tokenId = mockNFT.mint(charlie);
        vm.startPrank(charlie);
        mockNFT.approve(address(market), tokenId);
        market.list(address(mockNFT), tokenId, amount * 100);
        vm.stopPrank();
        vm.prank(david);
        market.buyNFT{value: amount * 100}(address(mockNFT), tokenId);
    }

    function testMultipleStakersRewards2() public {
        // Alice stakes 5 ETH
        console.log("1. Alice stakes 5 ETH");
        vm.prank(alice);
        market.stake{value: 5 ether}();
        assertEq(market.totalStaked(), 5 ether);
        assertEq(market.accumulatedFees(), 0);
        assertEq(market.rewardPerETHStored(), 0);
        assertEq(market.userStakeAmount(alice),  5 ether);
        assertEq(market.userRewardToClaim(alice), 0);
        assertEq(market.userRewardPerETHPaid(alice), 0);

        // add fees
        console.log("2. Fee = 20 ETH");
        generateFees(20 ether);
        assertEq(market.totalStaked(), 5 ether);
        assertEq(market.accumulatedFees(), 20 ether);
        assertEq(market.rewardPerETHStored(), 4 ether);

        // bob stakes 5 ETH
        console.log("3. Bob stakes 5 ETH");
        vm.prank(bob);
        market.stake{value: 5 ether}();
        assertEq(market.totalStaked(), 10 ether);
        assertEq(market.accumulatedFees(), 20 ether);
        assertEq(market.rewardPerETHStored(), 2 ether); // 20 / 10
        assertEq(market.userStakeAmount(bob),  5 ether);
        assertEq(market.userRewardToClaim(bob), 0);
        assertEq(market.userRewardPerETHPaid(bob), 2 ether);

        // add more fees
        console.log("4. Fee = 20 + 10 = 30 ETH");
        generateFees(10 ether);
        assertEq(market.totalStaked(), 10 ether);
        assertEq(market.accumulatedFees(), 30 ether);
        assertEq(market.rewardPerETHStored(), 3 ether);

        // Bob claims reward
        console.log("5. Bob claims reward = 5 ETH");
        uint256 bobBalanceBefore = bob.balance;
        vm.prank(bob);
        market.claimReward();
        assertEq(market.userRewardToClaim(bob), 0);
        assertEq(bob.balance - bobBalanceBefore, 5 ether);

        // Alice claims reward
        console.log("6. Alice claims reward = 25 ETH");
        uint256 aliceBalanceBefore = alice.balance;
        vm.prank(alice);
        market.claimReward();
        assertEq(market.userRewardToClaim(alice), 0);
        assertEq(alice.balance - aliceBalanceBefore, 25 ether);
    }
}