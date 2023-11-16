// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SanctionedERC20} from "../SanctionedERC20.sol";

contract SanctionedERC20Test is Test {
    SanctionedERC20 sToken;
    address user1 = address(0x1337);
    address user2 = address(0x1338);

    event Banned(address indexed who);
    event Unbanned(address indexed who);

    function setUp() public {
        sToken = new SanctionedERC20("TestSToken", "STS");
    }

    function test_transfer() public {
        sToken.transfer(user1, 10e18);

        // transferFrom
        vm.prank(user1);
        sToken.approve(user2, 10e18);

        vm.prank(user2);
        sToken.transferFrom(user1, user2, 1e18);
        assertEq(sToken.balanceOf(user2), 1e18);
        assertEq(sToken.balanceOf(user1), 9e18);

        // transfer
        vm.prank(user1);
        sToken.transfer(user2, 1e18);
        assertEq(sToken.balanceOf(user2), 2e18);
        assertEq(sToken.balanceOf(user1), 8e18);
    }

    function test_ban() public {
        sToken.transfer(user1, 10e18);
        sToken.transfer(user2, 10e18);

        vm.expectEmit();
        emit Banned(user1);

        sToken.ban(user1);
        assertEq(sToken.banned(user1), true);

        // Can't transfer from a banned user
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(SanctionedERC20.AddressIsBanned.selector, user1));
        sToken.transfer(user2, 1e18);
        vm.stopPrank();

        // Can't transfer to a banned user
        vm.expectRevert(abi.encodeWithSelector(SanctionedERC20.AddressIsBanned.selector, user1));
        sToken.transfer(user1, 1e18);

        // Can't transfer from a banned user or to a banned user
        vm.expectRevert(abi.encodeWithSelector(SanctionedERC20.AddressIsBanned.selector, user1));
        sToken.transferFrom(address(this), user1, 1e18);

        vm.prank(user2);
        sToken.approve(user1, 100e18);
        vm.expectRevert(abi.encodeWithSelector(SanctionedERC20.AddressIsBanned.selector, user1));
        sToken.transferFrom(user2, user1, 1e18);
    }

    function test_unban() public {
        sToken.transfer(user1, 10e18);
        sToken.ban(user1);

        vm.expectEmit();
        emit Unbanned(user1);

        sToken.unban(user1);

        assertEq(sToken.banned(user1), false);

        // Can transfer from an unbanned user
        vm.startPrank(user1);
        sToken.transfer(user2, 1e18);
        assertEq(sToken.balanceOf(user2), 1e18);
        vm.stopPrank();

        // Can transfer to an unbanned user
        sToken.transfer(user1, 10e18);
    }

    function test_onlyOwnerCanBan() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        sToken.ban(user1);
    }
}
