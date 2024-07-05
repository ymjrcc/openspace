// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Bank.sol";

contract BigBank is Bank{
  
    modifier minAmount {
        require(msg.value > 0.001 ether, unicode"存款金额应该大于 0.001 ether");
        _;
    }

    function deposit() public payable override minAmount{
        super.deposit();
    }

    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), unicode"新地址不能为 0");
        owner = newOwner;
    }
}