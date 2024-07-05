// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./BigBank.sol";

contract Ownable {

    address public owner;
    BigBank bigBank;

    constructor(address payable _bigBankAddr) {
        bigBank = BigBank(_bigBankAddr);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    function withdraw() public onlyOwner{
      bigBank.withdraw();
    }
    receive() external payable {}
}