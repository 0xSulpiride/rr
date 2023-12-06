// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";
import {RareswapFactory} from "../RareswapFactory.sol";
import {RareswapPair} from "../RareswapPair.sol";

contract RareswapPairTest is Test {
    address user1 = address(0x1337);
    address user2 = address(0x1338);
    RareswapFactory factory;
    RareswapPair pair;
    ERC20Mock token0;
    ERC20Mock token1;
    address token0Addr;
    address token1Addr;

    function setUp() public {
        factory = new RareswapFactory();
        token0 = new ERC20Mock();
        token1 = new ERC20Mock();
        factory.createPair(address(token0), address(token1));
        pair = RareswapPair(factory.getPair(address(token0), address(token1)));

        token0.mint(address(this), 1000 ether);
        token1.mint(address(this), 1000 ether);
        token0.approve(address(pair), type(uint256).max);
        token1.approve(address(pair), type(uint256).max);
    }

    function test_firstMinter() public {
        // should mint 1 LP token, not 1001
        pair.mint(1001, 1001, 1);
        assertEq(pair.balanceOf(address(this)), 1);

        // should mint 1001 LP tokens
        pair.mint(1001, 1001, 1);
        assertEq(pair.balanceOf(address(this)), 1002);
    }
}