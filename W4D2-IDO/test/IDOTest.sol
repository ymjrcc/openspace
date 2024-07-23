// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/IDO.sol";
import "../src/RNT.sol";

contract IDOTest is Test {
    IDO public ido;
    RNT public token;
    address public admin;
    address public user1;
    address public user2;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        
        token = new RNT();
        ido = new IDO(address(token));
        
        // Transfer tokens to IDO contract
        token.transfer(address(ido), 1e28);
    }

    function testPresale() public {
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        ido.presale{value: 1 ether}();
        assertEq(ido.balances(user1), 1 ether);
        assertEq(ido.totalETH(), 1 ether);
        vm.stopPrank();
    }

    function testPresaleInsufficientFunds() public {
        vm.startPrank(user1);
        vm.deal(user1, 0.0009 ether);
        vm.expectRevert("Insufficient funds");
        ido.presale{value: 0.0009 ether}();
        vm.stopPrank();
    }

    function testPresaleCapExceeded() public {
        vm.startPrank(user1);
        vm.deal(user1, 201 ether);
        vm.expectRevert("Cap exceeded");
        ido.presale{value: 201 ether}();
        vm.stopPrank();
    }

    function testClaimSuccess() public {
        vm.startPrank(user1);
        vm.deal(user1, 100 ether);
        ido.presale{value: 100 ether}();
        vm.stopPrank();

        vm.warp(block.timestamp + 7 days + 1);

        vm.prank(user1);
        ido.claim();

        assertEq(token.balanceOf(user1), 100000 ether);
        assertEq(ido.balances(user1), 0);
    }

    function testClaimFail() public {
        vm.startPrank(user1);
        vm.deal(user1, 50 ether);
        ido.presale{value: 50 ether}();
        vm.stopPrank();

        vm.warp(block.timestamp + 7 days + 1);

        vm.expectRevert("Target not reached");
        vm.prank(user1);
        ido.claim();
    }

    function testWithdrawSuccess() public {
        vm.startPrank(user1);
        vm.deal(user1, 100 ether);
        ido.presale{value: 100 ether}();
        vm.stopPrank();

        vm.warp(block.timestamp + 7 days + 1);

        uint256 initialBalance = admin.balance;
        ido.withdraw();
        assertEq(admin.balance - initialBalance, 100 ether);
    }

    function testRefundSuccess() public {
        vm.startPrank(user1);
        vm.deal(user1, 50 ether);
        ido.presale{value: 50 ether}();
        vm.stopPrank();

        vm.warp(block.timestamp + 7 days + 1);

        uint256 initialBalance = user1.balance;
        vm.prank(user1);
        ido.refund();
        assertEq(user1.balance - initialBalance, 50 ether);
    }

    function testTransferOwner() public {
        ido.transferOwner(user1);
        assertEq(ido.admin(), user1);
    }

    function testTransferOwnerFail() public {
        vm.expectRevert("Not admin");
        vm.prank(user1);
        ido.transferOwner(user2);
    }

    // 必须有 receive 函数，否则无法向合约转账，withdraw 会报错
    receive() external payable {} 
}