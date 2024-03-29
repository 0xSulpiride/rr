// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { Upgrades, Options } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { WhitelistDiscountNFT } from "./../src/WhitelistDiscountNFT.sol";

contract UpgradeV3NFT is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PK");
        address deployer = vm.addr(deployerPrivateKey);
        address proxy = vm.envAddress("NFT");

        vm.startBroadcast(deployerPrivateKey);
        Options memory opts;
        opts.referenceContract ="WhitelistDiscountNFTV2.sol";
        bytes memory initializerData = abi
            .encodeWithSelector(
                WhitelistDiscountNFT.initialize.selector,
                deployer,
                "Test WL NFT V3",
                "NFTv3",
                bytes32(0x048c6e7746f948a03fd1686e8194e2f62d096380ba12b113b55a734ed9228095),
                250, // 2.5%
                1000,
                10 gwei,
                250
            );
        Upgrades.upgradeProxy(
            proxy,
            "WhitelistDiscountNFTV3.sol",
            initializerData,
            opts
        );
        vm.stopBroadcast();
    }
}
