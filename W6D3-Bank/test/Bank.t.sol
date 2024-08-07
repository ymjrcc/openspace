// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address private constant GUARD = address(1);
    address public alice = address(2);
    address public bob = address(3);
    address public charlie = address(4);

    function setUp() public {
        bank = new Bank();
    }

    function testDeposit() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        bank.deposit{value: 1 ether}(GUARD, GUARD);
        assertEq(bank.balances(alice), 1 ether);
    }

    function testWithdraw() public {
        vm.deal(alice, 2 ether);
        vm.startPrank(alice);
        bank.deposit{value: 2 ether}(GUARD, GUARD);
        uint256 balanceBefore = alice.balance;
        bank.withdraw(1 ether, GUARD, GUARD);
        assertEq(alice.balance - balanceBefore, 1 ether);
        assertEq(bank.balances(alice), 1 ether);
        vm.stopPrank();
    }

    function testMultipleDeposits() public {
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);

        vm.prank(alice);
        bank.deposit{value: 2 ether}(GUARD, GUARD);
        vm.prank(bob);
        bank.deposit{value: 3 ether}(GUARD, GUARD);
        vm.prank(charlie);
        bank.deposit{value: 1 ether}(alice, alice);

        assertEq(bank.balances(alice), 2 ether);
        assertEq(bank.balances(bob), 3 ether);
        assertEq(bank.balances(charlie), 1 ether);
    }

    function testGetTopTenUsers() public {
        address[20] memory users;
        for(uint i = 0; i < 20; i++) {
            users[i] = address(uint160(i + 1));
            vm.deal(users[i], (i + 1) * 1 ether);
            vm.prank(users[i]);
            bank.deposit{value: (i + 1) * 1 ether}(GUARD, GUARD);
        }

        (address[10] memory topUsers, uint256[10] memory topBalances) = bank.getTopTenUsers();

        for(uint i = 0; i < 10; i++) {
            assertEq(topUsers[i], users[19 - i]);
            assertEq(topBalances[i], (20 - i) * 1 ether);
        }
    }

    function testWithdrawInsufficientFunds() public {
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);
        bank.deposit{value: 1 ether}(GUARD, GUARD);
        vm.expectRevert("Insufficient balance");
        bank.withdraw(2 ether, GUARD, GUARD);
        vm.stopPrank();
    }

    receive() external payable {}
}