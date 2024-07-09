// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenBank {
    IERC20 token;
    mapping(address => uint256) public balances;

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    constructor(address tokenAddr) {
        
        token = IERC20(tokenAddr);
    }

    function tokensReceived(address from, uint256 amount) external returns (bool) {
        require(msg.sender == address(token), unicode"函数调用方不正确");
        require(amount > 0, unicode"存入数量必须大于 0");
        require(amount <= token.balanceOf(from), unicode"存入数量不能高于 token 余额");
        balances[from] += amount;
        emit Deposit(from, amount);
        return true;
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
