// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { Upgrades, Options } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { WhitelistDiscountNFT } from "../src/WhitelistDiscountNFT.sol";

contract UpgradeWhitelistDiscountNFT is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PK");
        address deployer = vm.addr(deployerPrivateKey);
        address proxy = vm.envAddress("NFT");

        vm.startBroadcast(deployerPrivateKey);
        Options memory opts;
        opts.referenceContract ="WhitelistDiscountNFT.sol";
        Upgrades.upgradeProxy(
            proxy,
            "WhitelistDiscountNFTV2.sol",
            "",
            opts
        );
        vm.stopBroadcast();
    }
}
