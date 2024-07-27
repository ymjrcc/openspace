// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

contract NFTMarket is Initializable {
    uint256 private _value;

    function initialize(uint256 initialValue) public initializer {
        _value = initialValue;
    }

    function getValue() public view returns (uint256) {
        return _value;
    }

    function setValue(uint256 newValue) public {
        _value = newValue;
    }
}