// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./IRNT.sol";
import "./esRNT.sol";

contract StakePool {
    
    IRNT public immutable token;
    esRNT public immutable esToken;

    struct StakeInfo {
        uint256 stakedAmount;
        uint256 lastUpdateTime;
        uint256 unClaimed;
    }

    mapping(address => StakeInfo) public stakeInfos;

    constructor(address tokenAddr, address esTokenAddr) {
        require(tokenAddr != address(0) && esTokenAddr != address(0), "Invalid token addresses");
        token = IRNT(tokenAddr);
        esToken = esRNT(esTokenAddr);
        token.approve(esTokenAddr, type(uint256).max);
    }

    function _updateReward(address account) internal {
        StakeInfo storage info = stakeInfos[account];
        // 如果是第一次 stake，需要初始化 lastUpdateTime
        if (info.lastUpdateTime == 0) {
            info.lastUpdateTime = block.timestamp;
            return;
        }
        uint256 duration = block.timestamp - info.lastUpdateTime;
        info.unClaimed += duration * info.stakedAmount / (60 * 60 * 24);
        info.lastUpdateTime = block.timestamp;
    }

    function stake(uint256 amount) public {
        require(amount > 0, "Stake amount must be greater than 0");
        // 需要提前手动 approve 给 StakePool 合约

        if (stakeInfos[msg.sender].lastUpdateTime == 0) {
            stakeInfos[msg.sender].lastUpdateTime = block.timestamp;
        }

        _updateReward(msg.sender);
        stakeInfos[msg.sender].stakedAmount += amount;
        token.transferFrom(msg.sender, address(this), amount);
        emit Stake(msg.sender, amount);
    }

    function stake(uint256 amount, bytes memory signature) public {
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(signature, (uint8, bytes32, bytes32));
        token.permit(msg.sender, address(this), amount, 1 hours, v, r, s);
        stake(amount);
    }

    function unstake(uint256 amount) public {
        StakeInfo storage info = stakeInfos[msg.sender];
        require(amount > 0, "Unstake amount must be greater than 0");
        require(info.stakedAmount >= amount, "Insufficient staked amount");
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");

        _updateReward(msg.sender);
        info.stakedAmount -= amount;

        token.transfer(msg.sender, amount);
        emit Unstake(msg.sender, amount);
    }

    function claim() public {
        _updateReward(msg.sender);
        StakeInfo storage info = stakeInfos[msg.sender];
        uint256 unClaimed = info.unClaimed;
        require(unClaimed > 0, "No rewards to claim");

        info.unClaimed = 0;
        esToken.mint(msg.sender, unClaimed);
        emit Claim(msg.sender, unClaimed);
    }

    // 查看待领取奖励
    function pendingRewards(address account) public view returns (uint256) {
        StakeInfo memory info = stakeInfos[account];
        uint256 duration = block.timestamp - info.lastUpdateTime;
        return info.unClaimed + duration * info.stakedAmount / (60 * 60 * 24);
    }

    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event Claim(address indexed from, uint256 amount);
}