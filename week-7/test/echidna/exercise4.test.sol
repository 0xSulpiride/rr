pragma solidity ^0.8.0;

import "../../src/exercise4.sol";

contract TestToken is Token {
    function transfer(address to, uint256 value) public override {
        uint256 rb_before = balances[to]; // recipient
        uint256 sb_before = balances[msg.sender]; // sender
        super.transfer(to, value);
        uint256 rb_after = balances[to];
        uint256 sb_after = balances[msg.sender];
        assert(rb_after >= rb_before);
        assert(sb_after <= sb_before);
    }
}
