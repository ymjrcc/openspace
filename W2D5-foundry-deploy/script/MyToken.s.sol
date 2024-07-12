// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenScript is Script {
    MyToken public myToken;

    function setUp() public {}

    function run() public {

        vm.startBroadcast();

        myToken = new MyToken("My Token", "MTK");

        vm.stopBroadcast();
    }
}
