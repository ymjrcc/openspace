// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract Bank is AutomationCompatibleInterface {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        uint256 balance = balances[msg.sender];
        require(balance > 0 && amount <= balance, "Not enough balance");
        balances[msg.sender] -= amount;
        (bool success, ) = owner.call{value: amount}("");
        if (!success) {
            revert("failed!");
        }
        emit Withdraw(msg.sender, amount);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        if(address(this).balance > 0.01 ether) {
            upkeepNeeded = true;
        }
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if(address(this).balance > 0.01 ether) {
            (bool success,) = payable(owner).call{value: address(this).balance / 2}("");
            require(success, "transfer failed");
        }
    }

    event Deposit(address owner, uint256 amount);
    event Withdraw(address owner, uint256 amount);
}