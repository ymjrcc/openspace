// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/StakePool.sol";
import "../src/RNT.sol";
import "../src/esRNT.sol";

contract StakePoolTest is Test {
    StakePool public stakePool;
    RNT public rntToken;
    esRNT public esRNTToken;

    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        rntToken = new RNT();
        esRNTToken = new esRNT(address(rntToken));
        stakePool = new StakePool(address(rntToken), address(esRNTToken));

        esRNTToken.transferOwnership(address(stakePool));

        rntToken.mint(alice, 1000e18);
        rntToken.mint(bob, 1000e18);

        vm.startPrank(alice);
        rntToken.approve(address(stakePool), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        rntToken.approve(address(stakePool), type(uint256).max);
        vm.stopPrank();
    }

    function testStake() public {
        vm.startPrank(alice);
        stakePool.stake(100e18);
        vm.stopPrank();

        (uint256 stakedAmount, , ) = stakePool.stakeInfos(alice);
        assertEq(stakedAmount, 100e18);
    }

    function testUnstake() public {
        vm.startPrank(alice);
        stakePool.stake(100e18);
        vm.warp(block.timestamp + 1 days);
        stakePool.unstake(50e18);
        vm.stopPrank();

        (uint256 stakedAmount, , ) = stakePool.stakeInfos(alice);
        assertEq(stakedAmount, 50e18);
    }

    function testMultipleStakes() public {
        vm.startPrank(alice);
        stakePool.stake(50e18);
        vm.warp(block.timestamp + 1 days); // 50
        stakePool.stake(100e18);
        vm.warp(block.timestamp + 1 days); // 50 + 150
        stakePool.stake(100e18);
        vm.warp(block.timestamp + 1 days); // 50 + 150 + 250
        vm.stopPrank();

        (uint256 stakedAmount, ,) = stakePool.stakeInfos(alice);
        uint256 unClaimed = stakePool.pendingRewards(alice);
        assertEq(stakedAmount, 250e18);
        assertEq(unClaimed, 450e18);
    }

    function testClaim() public {
        vm.startPrank(alice);
        stakePool.stake(100e18);
        vm.warp(block.timestamp + 1 days);
        stakePool.claim();
        vm.stopPrank();

        assertEq(esRNTToken.balanceOf(alice), 100e18);
    }

    function testPendingRewards() public {
        vm.startPrank(alice);
        stakePool.stake(100e18);
        vm.warp(block.timestamp + 12 hours);
        uint256 pendingRewards = stakePool.pendingRewards(alice);
        vm.stopPrank();

        assertEq(pendingRewards, 50e18);
    }

    function testMultipleUsers() public {
        vm.startPrank(alice);
        stakePool.stake(100e18);
        vm.stopPrank();

        vm.startPrank(bob);
        stakePool.stake(200e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        assertEq(stakePool.pendingRewards(alice), 100e18);
        assertEq(stakePool.pendingRewards(bob), 200e18);
    }

    function testFuzzStake(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 1000e18);
        vm.startPrank(alice);
        stakePool.stake(amount);
        vm.stopPrank();

        (uint256 stakedAmount, , ) = stakePool.stakeInfos(alice);
        assertEq(stakedAmount, amount);
    }

    function testFuzzTimeOfRewards(uint256 amount, uint256 duration) public {
        vm.assume(amount > 0 && amount < 1000e18);
        vm.assume(duration > 1 hours && duration < 3650 days);
        vm.startPrank(alice);
        stakePool.stake(amount);
        vm.warp(block.timestamp + duration);
        uint256 pendingRewards = stakePool.pendingRewards(alice);
        vm.stopPrank();

        assertEq(pendingRewards, duration * amount / (60 * 60 * 24));
    }
}