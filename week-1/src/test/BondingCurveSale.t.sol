// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BondingCurveSale} from "../BondingCurveSale.sol";
import {TokenWithGodMode} from "../TokenWithGodMode.sol";

contract BondingCurveSaleTest is Test {
    TokenWithGodMode token;
    BondingCurveSale saleContract;
    address user1 = address(0x1337);
    address user2 = address(0x1338);

    function setUp() public {
        token = new TokenWithGodMode("Test", "TST");
        saleContract = new BondingCurveSale(address(token));
        token.approve(address(saleContract), type(uint256).max);
        saleContract.start(10_000e18);
    }

    function test_math() public {
        assertEq(
            10 ** 18 / 2,
            saleContract.tokenToEth(1e18)
        );
        assertEq(
            10 ** 18 / 2,
            saleContract.tokenToEth(saleContract.ethToToken(10 ** 18 / 2))
        );
    }

    function test_buy() public {
        uint256 tokens = saleContract.ethToToken(1 ether);
        payable(user1).transfer(1 ether);

        vm.startPrank(user1);
        saleContract.buy{value: 1 ether}(tokens);
        assertEq(token.balanceOf(user1), tokens);
        vm.stopPrank();
    }

    function test_arbitrage() public {
        uint256 tokens1 = saleContract.ethToToken(1 ether);
        payable(user1).transfer(1 ether);
        payable(user2).transfer(1 ether);

        uint256 balanceBefore = user1.balance;
        vm.startPrank(user1);
        saleContract.buy{value: 1 ether}(tokens1);
        assertEq(token.balanceOf(user1), tokens1);
        vm.stopPrank();

        uint256 tokens2 = saleContract.ethToToken(1 ether);
        assert(tokens2 < tokens1);
        vm.startPrank(user2);
        saleContract.buy{value: 1 ether}(tokens2);
        assertEq(token.balanceOf(user2), tokens2);
        vm.stopPrank();

        vm.startPrank(user1);
        token.approve(address(saleContract), tokens1);
        saleContract.sell(tokens1, address(saleContract).balance);
        vm.stopPrank();
        assert(user1.balance > balanceBefore);
    }
}
