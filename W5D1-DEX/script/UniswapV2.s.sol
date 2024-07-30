// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {UniswapV2Router02} from "../src/UniswapV2Router02.sol";
import "../src/WETH9.sol"; // 假设您有 WETH9 合约

contract DeployUniswapV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 部署 WETH9
        WETH9 weth = new WETH9();
        console.log("WETH9 deployed at:", address(weth));

        // 部署 UniswapV2Factory
        UniswapV2Factory factory = new UniswapV2Factory(deployerAddress);
        console.log("UniswapV2Factory deployed at:", address(factory));

        // 部署 UniswapV2Router02
        UniswapV2Router02 router = new UniswapV2Router02(address(factory), address(weth));
        console.log("UniswapV2Router02 deployed at:", address(router));

        // 输出一些有用的信息
        console.log("Deployer address:", deployerAddress);

        vm.stopBroadcast();
    }
}