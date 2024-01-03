// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/dex.sol";

contract DexTest {
    Dex dex;
    SwappableToken token0;
    SwappableToken token1;

    constructor() {
        dex = new Dex();
        token0 = new SwappableToken(address(dex), "token0", "tkn0", 110e18);
        token1 = new SwappableToken(address(dex), "token1", "tkn1", 110e18);
        token0.transfer(address(dex), 100e18);
        token1.transfer(address(dex), 100e18);
        dex.setTokens(address(token0), address(token1));
        dex.renounceOwnership();
    }

    function swap0_1(uint amount) public {
        amount = amount % token0.balanceOf(address(this));
        token0.approve(address(dex), amount);
        dex.swap(address(token0), address(token1), amount);
    }

    function swap1_0(uint amount) public {
        amount = amount % token1.balanceOf(address(this));
        token1.approve(address(dex), amount);
        dex.swap(address(token1), address(token0), amount);
    }

    function echidna_drain() public returns (bool) {
        return token0.balanceOf(address(dex)) > 10e18 || token1.balanceOf(address(dex)) > 10e18;
    }
}