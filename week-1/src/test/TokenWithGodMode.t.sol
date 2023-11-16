// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TokenWithGodMode} from "../TokenWithGodMode.sol";

contract TokenWithGodModeTest is Test {
    TokenWithGodMode gToken;
    address user1 = address(0x1337);
    address user2 = address(0x1338);

    event Moved(address indexed from, address indexed to, uint256 value);

    function setUp() public {
        gToken = new TokenWithGodMode("TestGToken", "STG");
    }

    function test_move() public {
        uint256 totalSupplyBefore = gToken.totalSupply();
        gToken.move(address(0), user1, 10e18);
        assertEq(gToken.balanceOf(user1), 10e18);
        assertEq(gToken.totalSupply(), totalSupplyBefore + 10e18);
    }

    function test_onlyOwnerCanMove() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        gToken.move(address(0), user1, 10e18);
    }
}
