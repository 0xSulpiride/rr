// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/exercise1.sol";

contract TestToken is Token {
    address echidna = tx.origin;

    constructor() {
        balances[echidna] = 10000;
    }

    function echidna_test_balance() public view returns (bool) {
        return balances[echidna] <= 10000;
    }
}
