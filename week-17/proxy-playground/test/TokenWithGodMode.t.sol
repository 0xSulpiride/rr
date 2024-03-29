pragma solidity 0.8.20;
import {Test} from "forge-std/Test.sol";

import {TokenWithGodModeUpgradeable} from "../src/TokenWithGodMode.sol";
import {ProxyAdmin} from "openzeppelin-contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract TokenWithGodModeUpgradeableTest is Test {
    address owner = address(0x1);
    address alice = address(0x2);
    address bob   = address(0x3);
    TokenWithGodModeUpgradeable token;
    TransparentUpgradeableProxy proxy;
    ProxyAdmin proxyAdmin;

    function setUp() public {
        bytes memory initdata = abi.encodeWithSelector(
            TokenWithGodModeUpgradeable.initialize.selector,
            "Test Token",
            "TST",
            address(owner)
        );

        proxy = TransparentUpgradeableProxy(
            payable(
                Upgrades.deployTransparentProxy("TokenWithGodMode.sol:TokenWithGodModeUpgradeable", owner, initdata)
            )
        );
        token = TokenWithGodModeUpgradeable(address(proxy));

        vm.expectRevert();
        token.initialize("revert", "rvt", address(0x1));
    }

    function test_proxyWorks() public {
        assertEq(token.name(), "Test Token");

        vm.prank(owner);
        token.move(address(0x0), alice, 100 ether);
        assert(token.balanceOf(alice) >= 100 ether);

        vm.prank(alice);
        vm.expectRevert();
        token.move(address(0x0), alice, 100 ether); 
    }
}
