// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public wallet;
    address[] public owners;
    uint128 public constant CONFIRMATIONS_REQUIRED = 2;

    address public owner1 = address(1);
    address public owner2 = address(2);
    address public owner3 = address(3);
    address public not_owner = address(4);

    function setUp() public {
        owners = [owner1, owner2, owner3];
        wallet = new MultiSigWallet(owners, CONFIRMATIONS_REQUIRED);
    }

    function testConstructor() view public {
        assertEq(wallet.owners(0), owner1);
        assertEq(wallet.owners(1), owner2);
        assertEq(wallet.owners(2), owner3);
        assertEq(wallet.ownersCountForConfirmation(), CONFIRMATIONS_REQUIRED);
    }

    function testSubmitTransaction() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(0x123), 100, "");
        
        (bool executed, uint128 confirmations, address destination, uint256 value, bytes memory data) = wallet.transactions(0);
        
        assertEq(executed, false);
        assertEq(confirmations, 0);
        assertEq(destination, address(0x123));
        assertEq(value, 100);
        assertEq(data, "");
    }

    function testConfirmTransaction() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(0x123), 100, "");

        vm.prank(owner2);
        wallet.confirmTransaction(0);

        (,uint128 confirmations,,,) = wallet.transactions(0);
        assertEq(confirmations, 1);
        assertTrue(wallet.isConfirmed(0, owner2));
    }

    function testExecuteTransaction() public {
        address payable recipient = payable(address(0x123));
        uint256 amount = 100;

        // Fund the wallet
        vm.deal(address(wallet), amount);

        // Submit transaction
        vm.prank(owner1);
        wallet.submitTransaction(recipient, amount, "");

        // Confirm transaction
        vm.prank(owner2);
        wallet.confirmTransaction(0);
        vm.prank(owner3);
        wallet.confirmTransaction(0);

        // Execute transaction
        uint256 initialBalance = recipient.balance;
        wallet.executeTransaction(0);

        // Check recipient balance
        assertEq(recipient.balance, initialBalance + amount);

        // Check transaction status
        (bool executed,,,,) = wallet.transactions(0);
        assertTrue(executed);
    }

    function testRevertNonOwnerSubmit() public {
        vm.prank(not_owner);
        vm.expectRevert("Not owner");
        wallet.submitTransaction(address(0x123), 100, "");
    }

    function testRevertDoubleConfirmation() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(0x123), 100, "");

        vm.prank(owner2);
        wallet.confirmTransaction(0);

        vm.prank(owner2);
        vm.expectRevert("Transaction already confirmed");
        wallet.confirmTransaction(0);
    }

    function testRevertExecuteWithoutEnoughConfirmations() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(0x123), 100, "");

        vm.prank(owner2);
        wallet.confirmTransaction(0);

        vm.expectRevert("Not enough confirmations");
        wallet.executeTransaction(0);
    }

    receive() external payable {}
}