// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRareswapFactory {
    /// @notice returns the address of the protocol fee receiver
    /// @dev can be address(0) if the fee is deactived
    function getFeeReceiver() external view returns (address);
}
