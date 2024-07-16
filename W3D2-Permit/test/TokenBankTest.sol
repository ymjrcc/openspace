// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {TokenBank} from "../src/TokenBank.sol";

contract TokenBankTest is Test {
    MyToken public myToken;
    TokenBank public tokenBank;

    address public Bob = vm.addr(uint256(keccak256(abi.encodePacked("Bob"))));

    function setUp() public {
        myToken = new MyToken(address(this));
        tokenBank = new TokenBank(address(myToken));
        myToken.mint(Bob, 1e20);
    }

    function testPermitDeposit() public {

        address owner = Bob;
        address spender = address(tokenBank);
        uint256 value = 1e18;
        uint256 nonce = myToken.nonces(owner);
        uint256 deadline = block.timestamp + 1 hours;

        // 构建 EIP-712 结构体
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner, spender, value, nonce, deadline
            )
        );

        // 计算 digest，包括 EIP-712 域分隔符和结构体哈希
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                myToken.DOMAIN_SEPARATOR(),
                structHash
            )
        );

        // 使用 Foundry 的 vm 模块签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(keccak256(abi.encodePacked("Bob"))), digest);

        // 调用 permitDeposit
        vm.prank(owner);
        tokenBank.permitDeposit(owner, spender, value, deadline, v, r, s);

        // 验证 allowance 是否更新
        assertEq(tokenBank.balances(owner), value);
    }
}
