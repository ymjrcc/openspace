// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract RNT is ERC20, Ownable, ERC20Burnable, ERC20Permit {
    constructor()
        ERC20("RNT Token", "RNT")
        Ownable(msg.sender)
        ERC20Permit("RNT")
    {
        _mint(msg.sender, 1e10 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}