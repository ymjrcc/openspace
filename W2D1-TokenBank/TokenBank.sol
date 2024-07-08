// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./ERC20.sol";

contract TokenBank {
    BaseERC20 token;
    mapping(address => uint256) public balances;

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    constructor(address tokenAddr) {
        token = BaseERC20(tokenAddr);
    }

    function deposit(uint256 amount) public {
        require(amount > 0, unicode"存入数量必须大于 0");
        require(amount <= token.balanceOf(msg.sender), unicode"存入数量不能高于 token 余额");
        (bool success) = token.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert(unicode"存入失败");
        }
        balances[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] > 0, unicode"没有存入 token");
        require(amount <= balances[msg.sender], unicode"取出数量不能高于 token 余额");
        balances[msg.sender] -= amount;
        (bool success) = token.transfer(msg.sender, amount);
        if (!success) {
            revert(unicode"取出失败");
        }
        emit Withdraw(msg.sender, amount);
    }
}
