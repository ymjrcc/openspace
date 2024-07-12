// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenScript is Script {
    MyToken public myToken;

    function setUp() public {}

    function run() public {

        // string memory rpcUrl = vm.envString("SEPOLIA_RPC_URL");
        // uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // vm.startBroadcast(privateKey);

        vm.startBroadcast();

        myToken = new MyToken("My Token", "MTK");

        vm.stopBroadcast();
    }
}
