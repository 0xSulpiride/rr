// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {WhitelistDiscountNFT} from "../src/WhitelistDiscountNFT.sol";

contract WhitelistDiscountNFTTest is Test {
    address owner = address(0x4200);
    address user1 = address(0x1337);
    address user2 = address(0x1338);
    WhitelistDiscountNFT nft;

    event DiscountUsed(address indexed sender, uint256 index);
    event DiscountRateUpdated(uint96 rate);
    event RoyaltyRateUpdated(uint96 rate);

    function setUp() public {
        bytes memory initializerData = abi
            .encodeWithSelector(
                WhitelistDiscountNFT.initialize.selector,
                owner,
                "Test WL NFT",
                "WLNFT",
                bytes32(0x048c6e7746f948a03fd1686e8194e2f62d096380ba12b113b55a734ed9228095),
                250, // 2.5%
                1000,
                0.1 ether,
                250
            );
        vm.startPrank(owner);
        address proxy = Upgrades.deployUUPSProxy("WhitelistDiscountNFT.sol", initializerData);
        nft = WhitelistDiscountNFT(proxy);
        vm.stopPrank();
    }

    function test_discountedMint() public {
        vm.deal(user1, 10 ether);

        vm.startPrank(user1);

        bytes32[] memory proof = new bytes32[](3);
        proof[0] = 0xe10e1f7fdb0fc794cb1210eef684e1be1081e9fb24ac530b4e0e3bef8b7205d3;
        proof[1] = 0x1fdf5401990e2cac67ac4a5f20ffb1f408ec0fb41734d0679ef9196ee9aaf536;
        proof[2] = 0xe3a7e3a8cb1580e699b2aeea7feece39e5275d134a6501003672dab6f9e77d7c;

        vm.expectEmit();
        emit DiscountUsed(user1, 0);

        uint256 discountPrice = 0.0975 ether; // 0.1 ether * (1 - 0.025);

        nft.mintAtDiscount{value: discountPrice}(proof, 0);
        assertEq(nft.balanceOf(user1), 1);

        vm.stopPrank();
    }

    function test_replayAttack() public {
        vm.deal(user1, 10 ether);

        vm.startPrank(user1);

        bytes32[] memory proof = new bytes32[](3);
        proof[0] = 0xe10e1f7fdb0fc794cb1210eef684e1be1081e9fb24ac530b4e0e3bef8b7205d3;
        proof[1] = 0x1fdf5401990e2cac67ac4a5f20ffb1f408ec0fb41734d0679ef9196ee9aaf536;
        proof[2] = 0xe3a7e3a8cb1580e699b2aeea7feece39e5275d134a6501003672dab6f9e77d7c;
        nft.mintAtDiscount{value: 0.0975 ether}(proof, 0);

        assertEq(nft.balanceOf(user1), 1);

        vm.expectRevert("Already claimed");
        nft.mintAtDiscount{value: 0.0975 ether}(proof, 0);
        vm.stopPrank();
    }

    function test_mint() public {
        vm.deal(user1, 10 ether);

        vm.startPrank(user1);

        nft.mint{value: 0.1 ether}();
        assertEq(nft.balanceOf(user1), 1);

        vm.expectRevert("Value < Price");
        nft.mint{value: 0.0975 ether}();

        vm.stopPrank();
    }
}
