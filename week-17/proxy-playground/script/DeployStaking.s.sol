// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { NFTStaking } from "../src/NFTStaking.sol";

contract DeployNFTStaking is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PK");
        address deployer = vm.addr(deployerPrivateKey);
        address nft = vm.envAddress("NFT");

        vm.startBroadcast(deployerPrivateKey);
        bytes memory stakingData = abi.encodeWithSelector(
            NFTStaking.initialize.selector,
            deployer,
            nft
        );
        Upgrades.deployUUPSProxy("NFTStaking.sol", stakingData);
        vm.stopBroadcast();
    }
}
