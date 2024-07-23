// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./IRNT.sol";
import "forge-std/Test.sol";

contract IDO {
    
    // 设定预售价格，募集ETH目标，超募上限，预售时长
    uint256 constant public PRICE = 0.001 ether;
    uint256 constant public TARGET = 100 ether;
    uint256 constant public CAP = 200 ether;
    uint256 constant public DURATION = 7 days;

    uint256 public totalETH;

    mapping(address => uint256) public balances;

    uint256 public startTime;
    IRNT public token;
    address public admin;

    constructor(address tokenAddr) {
        startTime = block.timestamp;
        token = IRNT(tokenAddr);
        admin = msg.sender;
    }

    function presale() payable onlyActive public {
        require(msg.value >= PRICE, "Insufficient funds");
        balances[msg.sender] += msg.value;
        totalETH += msg.value;
        emit Presale(msg.sender, msg.value);
    }

    function claim() onlySuccess public {
        // 计算 token 总量
        uint256 tokenAmountTotal = TARGET * 1 ether / PRICE;
        // 计算 1 ETH 对应多少 token
        uint256 tokenAmountPerETH = tokenAmountTotal / totalETH;
        // 计算用户能分配到多少 token
        uint256 amount = balances[msg.sender] * tokenAmountPerETH;

        balances[msg.sender] = 0;
        token.transfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }

    function withdraw() onlySuccess public {
        uint256 balance = address(this).balance;
        require(balance > 0, "The balance is zero");
        (bool success, ) = admin.call{value: balance}("");
        require(success, "Withdraw failed");
        emit Withdraw(balance);
    }

    function refund() onlyFailed public {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "You are not founder");
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Refund failed");
        emit Refund(msg.sender, balance);
    }

    function transferOwner(address newAdmin) onlyAdmin public {
        require(newAdmin != address(0), "Invalid address");
        require(newAdmin != admin, "Same address");
        admin = newAdmin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyActive() {
        require(block.timestamp >= startTime, "Presale has not started");
        require(block.timestamp < startTime + DURATION, "Presale has ended");
        require(totalETH + msg.value <= CAP, "Cap exceeded");
        _;
    }

    modifier onlySuccess() {
        require(totalETH >= TARGET, "Target not reached");
        require(block.timestamp >= startTime + DURATION, "Presale has not ended");
        _;
    }

    modifier onlyFailed() {
        require(totalETH < TARGET, "Target reached");
        require(block.timestamp >= startTime + DURATION, "Presale has not ended");
        _;
    }

    event Presale(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event Withdraw(uint256 amount);
    event Refund(address indexed user, uint256 amount);
}