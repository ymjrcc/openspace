// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import { TokenFactory } from "../src/TokenFactory.sol";
import { Upgrades, Options } from "openzeppelin-foundry-upgrades/Upgrades.sol";


contract TokenFactoryScript is Script {

    address internal deployer;

    function setUp() public virtual {
      uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
      deployer = vm.addr(deployerPrivateKey);
    }

    function run() public broadcaster {

        Options memory opts;
        opts.unsafeSkipAllChecks = true;

        address proxy = Upgrades.deployTransparentProxy(
            "TokenFactory.sol",
            deployer,
            abi.encodeCall(TokenFactory.initialize, ()),
            opts
        );

        address implementation = Upgrades.getImplementationAddress(proxy);
        address admin = Upgrades.getAdminAddress(proxy);

        console.log("TokenFactory proxy address: %s", proxy);
        console.log("TokenFactory imple address: %s", implementation);
        console.log("TokenFactory admin address: %s", admin);
    }

    modifier broadcaster() {
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }
}