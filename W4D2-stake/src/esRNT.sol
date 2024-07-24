// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "./IRNT.sol";
import "./StakePool.sol";

contract esRNT is ERC20, Ownable, ERC20Permit {

    IRNT public RNT;

    struct LockInfo {
        address user;
        uint256 amount;
        uint256 lockTime;
    }

    LockInfo[] public lockInfos;

    constructor(address rntAddr)
        ERC20("esRNT Token", "esRNT")
        Ownable(msg.sender)
        ERC20Permit("esRNT")
    {
        RNT = IRNT(rntAddr);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        RNT.transferFrom(msg.sender, address(this), amount);
        _mint(to, amount);
        lockInfos.push(LockInfo(to, amount, block.timestamp));
    }

    function burn(uint256 id) public {
        LockInfo memory lockInfo = lockInfos[id];
        require(lockInfo.user == msg.sender, "You are not the owner");
        uint256 time = block.timestamp - lockInfo.lockTime;
        if (time > 30 days) {
            time = 30 days;
        }
        uint256 unLockedAmount = lockInfo.amount * time / 30 days;
        RNT.transfer(lockInfo.user, unLockedAmount);
        RNT.transfer(address(0), lockInfo.amount - unLockedAmount);
        _burn(msg.sender, lockInfo.amount);
    }
}