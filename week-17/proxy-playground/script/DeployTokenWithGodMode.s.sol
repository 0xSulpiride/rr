// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {TokenWithGodModeUpgradeable} from "../src/TokenWithGodMode.sol";

contract DeployTokenWithGodMode is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PK");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        bytes memory initdata = abi.encodeWithSelector(
            TokenWithGodModeUpgradeable.initialize.selector,
            "Test Token",
            "TST",
            deployer
        );
        address proxy = Upgrades.deployTransparentProxy(
            "TokenWithGodMode.sol:TokenWithGodModeUpgradeable",
            deployer,
            initdata
        );
        vm.stopBroadcast();
    }
}
