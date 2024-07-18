// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./IMyToken.sol";

contract TokenBank {
    IMyToken token;
    mapping(address => uint256) public balances;

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    constructor(address tokenAddr) {
        token = IMyToken(tokenAddr);
    }

    function deposit(uint256 amount) public {
        require(amount > 0, "The deposit amount must be greater than 0");
        require(amount <= token.balanceOf(msg.sender), "The deposit amount cannot be higher than the token balance.");
        (bool success) = token.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert("Failed to deposit");
        }
        balances[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] > 0, "Token not deposited");
        require(amount <= balances[msg.sender], "The withdrawal amount cannot be higher than the token balance.");
        balances[msg.sender] -= amount;
        (bool success) = token.transfer(msg.sender, amount);
        if (!success) {
            revert("Failed to withdraw");
        }
        emit Withdraw(msg.sender, amount);
    }

    function permitDeposit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        token.permit(owner, spender, value, deadline, v, r, s);
        require(value > 0, "The deposit amount must be greater than 0");
        require(value <= token.balanceOf(owner), "The deposit amount cannot be higher than the token balance.");
        (bool success) = token.transferFrom(owner, address(this), value);
        if (!success) {
            revert("Failed to deposit");
        }
        balances[owner] += value;
        emit Deposit(owner, value);
    }
}