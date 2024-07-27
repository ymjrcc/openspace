// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { NFTMarketV2 } from "../src/NFTMarketV2.sol";

import { Upgrades, Options } from "openzeppelin-foundry-upgrades/Upgrades.sol";


contract NFTMarketV2Script is Script {

    address internal deployer;

    function setUp() public virtual {
      uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
      deployer = vm.addr(deployerPrivateKey);
    }

    function run() public broadcaster {

        Options memory opts;
        opts.unsafeSkipAllChecks = true;
        opts.referenceContract = "NFTMarket.sol";

        address proxy = vm.envAddress("PROXY_ADDRESS");
        Upgrades.upgradeProxy(proxy, "NFTMarketV2.sol", "", opts);

        address implementation = Upgrades.getImplementationAddress(proxy);
        address admin = Upgrades.getAdminAddress(proxy);

        console.log("NFTMarketV2 proxy address: %s", proxy);
        console.log("NFTMarketV2 imple address: %s", implementation);
        console.log("NFTMarketV2 admin address: %s", admin);
    }

    modifier broadcaster() {
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }
}