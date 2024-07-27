// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { NFTMarket } from "../src/NFTMarket.sol";

import { Upgrades, Options } from "openzeppelin-foundry-upgrades/Upgrades.sol";


contract NFTMarketScript is Script {

    address internal deployer;

    function setUp() public virtual {
      uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
      deployer = vm.addr(deployerPrivateKey);
    }

    function run() public broadcaster {

        Options memory opts;
        opts.unsafeSkipAllChecks = true;

        address proxy = Upgrades.deployTransparentProxy(
            "NFTMarket.sol",
            deployer,
            abi.encodeCall(NFTMarket.initialize, (100)),
            opts
        );

        address implementation = Upgrades.getImplementationAddress(proxy);
        address admin = Upgrades.getAdminAddress(proxy);

        console.log("NFTMarket proxy address: %s", proxy);
        console.log("NFTMarket imple address: %s", implementation);
        console.log("NFTMarket admin address: %s", admin);
    }

    modifier broadcaster() {
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }
}