// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library Errors {
    error AddressZero();
    error SameTokens();
    error OrdersDontMatch();
    error OrderOutdated();
    error InvalidSignature();
}
