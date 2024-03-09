// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenVestingRS
 * @dev Gas-optimized TokenVesting.sol
 */
contract TokenVestingRS is Ownable {
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);
    event TokenVestingRevoked(address token);

    /// @notice beneficiary is the zero address
    error ZeroAddress();
    /// @notice cliff is longer than duration
    error CliffIsLongerThanDuration();
    /// @notice duration is 0
    error DurationIsZero();
    /// @notice final time is before current time
    error FinalTimePassed();
    /// @notice no tokens are due
    error NoTokenAreDue();
    /// @notice cannot revoke
    error CannotRevoke();
    /// @notice token already revoked
    error AlreadyRevoked();

    address immutable public beneficiary;
    uint64 immutable public cliff;
    uint64 immutable public start;
    uint64 immutable public duration;
    bool immutable public revocable;

    mapping(address => uint256) public released;
    mapping(address => bool) public revoked;

    constructor(
        address _beneficiary,
        uint64 _start,
        uint64 _cliffDuration,
        uint64 _duration,
        bool _revocable
    ) Ownable(msg.sender) payable {
        if (_beneficiary == address(0)) revert ZeroAddress();
        if (_cliffDuration > _duration) revert CliffIsLongerThanDuration();
        if (_duration == 0) revert DurationIsZero();
        if (block.timestamp > uint256(_start) + _duration) revert FinalTimePassed();

        beneficiary = _beneficiary;
        revocable = _revocable;
        duration = _duration;
        cliff = _start + _cliffDuration;
        start = _start;
    }

    /** Write */
    function release(IERC20 token) external {
        uint256 unreleased = _releasableAmount(token);
        if (unreleased == 0) revert NoTokenAreDue();

        released[address(token)] = released[address(token)] + unreleased;

        token.safeTransfer(beneficiary, unreleased);

        emit TokensReleased(address(token), unreleased);
    }

    function revoke(IERC20 token) external payable onlyOwner {
        if (!revocable) revert CannotRevoke();
        if (revoked[address(token)]) revert AlreadyRevoked();

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = _releasableAmount(token);
        uint256 refund = balance - unreleased;

        revoked[address(token)] = true;

        token.safeTransfer(owner(), refund);

        emit TokenVestingRevoked(address(token));
    }

    function emergencyRevoke(IERC20 token) external payable onlyOwner {
        if (!revocable) revert CannotRevoke();
        if (revoked[address(token)]) revert AlreadyRevoked();

        uint256 balance = token.balanceOf(address(this));

        revoked[address(token)] = true;

        token.safeTransfer(owner(), balance);

        emit TokenVestingRevoked(address(token));
    }

    /** Private functions */
    function _releasableAmount(IERC20 token) private view returns (uint256 amount) {
        amount = _vestedAmount(token) - released[address(token)];
    }

    function _vestedAmount(IERC20 token) private view returns (uint256) {
        unchecked {
            uint256 currentBalance = token.balanceOf(address(this));
            uint256 totalBalance = currentBalance + released[address(token)];

            if (block.timestamp < cliff) {
                return 0;
            }
            if (block.timestamp >= start + duration || revoked[address(token)]) {
                return totalBalance;
            }
            return totalBalance * (block.timestamp - start) / duration;   
        }
    }
}
