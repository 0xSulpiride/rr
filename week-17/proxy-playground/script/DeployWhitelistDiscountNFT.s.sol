// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { WhitelistDiscountNFT } from "./../src/WhitelistDiscountNFT.sol";

contract DeployWhitelistDiscountNFT is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PK");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        bytes memory initializerData = abi
            .encodeWithSelector(
                WhitelistDiscountNFT.initialize.selector,
                deployer,
                "Test WL NFT",
                "WLNFT",
                bytes32(0x048c6e7746f948a03fd1686e8194e2f62d096380ba12b113b55a734ed9228095),
                250, // 2.5%
                1000,
                0.1 ether,
                250
            );
        Upgrades.deployUUPSProxy("WhitelistDiscountNFT.sol", initializerData);
        vm.stopBroadcast();
    }
}
