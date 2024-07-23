// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./IRNT.sol";

contract StakePool {
    
    IRNT public token;
    constructor(address tokenAddr) {
        token = IRNT(tokenAddr);
    }

    function stage(uint256 amount) public {
        // 需要提前手动 approve 给 StakePool 合约
        token.transferFrom(msg.sender, address(this), amount);
    }

    function stake(uint256 amount, bytes memory signature) public {
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(signature, (uint8, bytes32, bytes32));
        token.permit(msg.sender, address(this), amount, 1 hours, v, r, s);
        token.transferFrom(msg.sender, address(this), amount);
    }

    function unstake() public {
        
    }

    function claim() public {
        
    }
}