// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Bank {
    address public owner;
    mapping(address => uint256) public balances;
    address[3] public top3;

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

    function deposit() public payable{
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        _updateTop3();
    }

    function _updateTop3() private {
        if (balances[msg.sender] > balances[top3[0]]) {
            top3[2] = top3[1];
            top3[1] = top3[0];
            top3[0] = msg.sender;
        } else if (balances[msg.sender] > balances[top3[1]]) {
            top3[2] = top3[1];
            top3[1] = msg.sender;
        } else if (balances[msg.sender] > balances[top3[2]]) {
            top3[2] = msg.sender;
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        if (!success) {
            revert("failed!");
        }
    }
}
