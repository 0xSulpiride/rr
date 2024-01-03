pragma solidity ^0.8.0;

import "../../src/exercise3.sol";

contract TestToken is MintableToken {
    address echidna = msg.sender;

    constructor() MintableToken(10000) {}

    function echidna_test_balance() public view returns (bool) {
        return balances[echidna] < 10000;
    }
}
