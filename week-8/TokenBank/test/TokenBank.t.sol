// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenBank.sol";

contract TankBankTest is Test {
    TokenBankChallenge public tokenBankChallenge;
    TokenBankAttacker public tokenBankAttacker;
    address player = address(1234);

    function setUp() public {}

    function testExploit() public {
        tokenBankChallenge = new TokenBankChallenge(player);
        tokenBankAttacker = new TokenBankAttacker(address(tokenBankChallenge));

        // Put your solution here
        SimpleERC223Token token = tokenBankChallenge.token();
        vm.startPrank(player);
        tokenBankChallenge.withdraw(500000 * 10 ** 18);
        token.transfer(address(tokenBankAttacker), 500000 * 10 ** 18);
        tokenBankAttacker.attack();
        vm.stopPrank();
        _checkSolved();
    }

    function _checkSolved() internal {
        SimpleERC223Token token = tokenBankChallenge.token();
        assertTrue(tokenBankChallenge.isComplete(), "Challenge Incomplete");
        assertTrue(token.balanceOf(player) == 1000000 * 10 ** 18);
    }
}
