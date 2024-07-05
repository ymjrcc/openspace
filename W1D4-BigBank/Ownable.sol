// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./BigBank.sol";

contract Ownable {
    BigBank bigBank;
    constructor(address payable _bigBankAddr) {
        bigBank = BigBank(_bigBankAddr);
    }
    function withdraw() public {
      bigBank.withdraw();
    }
    receive() external payable {}
}