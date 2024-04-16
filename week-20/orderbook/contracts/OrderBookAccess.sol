// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract OrderBookAccess is AccessControl {
    /// @notice can execute orders
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    /// @notice initial admin
    constructor(address _admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(EXECUTOR_ROLE, _admin);
    }

    /// @notice add new executor
    function addExecutor(address _executor) external onlyRole(EXECUTOR_ROLE) {
        _grantRole(EXECUTOR_ROLE, _executor);
    }

    /// @notice remove executor
    function removeExecutor(
        address _executor
    ) external onlyRole(EXECUTOR_ROLE) {
        _revokeRole(EXECUTOR_ROLE, _executor);
    }
}
