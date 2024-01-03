pragma solidity ^0.4.21;

import "../../src/token-whale.sol";

contract TokenWhaleChallengeTest is TokenWhaleChallenge {
    address echidna = msg.sender;

    function TokenWhaleChallengeTest() TokenWhaleChallenge(msg.sender) public {}

    function echidna_is_complete() public returns (bool) {
        return !isComplete();
    }
}
