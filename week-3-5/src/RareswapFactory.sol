// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@solady/auth/Ownable.sol";
import {IRareswapFactory} from "./interfaces/IRareswapFactory.sol";
import {RareswapPair} from "./RareswapPair.sol";

/// @title Rareswap Factory
/// @notice Factory contract of Rareswap
contract RareswapFactory is Ownable, IRareswapFactory {
    /// @notice invalid pair of tokens
    error InvalidTokens();
    /// @notice pair already exists
    error PairExists();

    /// @notice emitted when new pair is created
    event PairCreated(address indexed _token0, address indexed _token1, address indexed _pair);
    /// @notice new protocol fee receiver set
    event FeeReceiverSet(address indexed _address);

    mapping(address => mapping(address => address)) private pairs;
    address private feeReceiver;

    constructor() {
        _setOwner(msg.sender);
    }

    /// @notice creates a new pair, throws error is the pair already exists
    /// @param _token0 address of the first token
    /// @param _token1 address of the second token
    /// @dev emits PairCreated event
    function createPair(address _token0, address _token1) external returns (address _pair) {
        if (_token0 == _token1) revert InvalidTokens();
        (_token0, _token1) = _sortTokens(_token0, _token1);
        if (pairs[_token0][_token1] != address(0)) revert PairExists();

        bytes memory deploymentData =
            abi.encodePacked(type(RareswapPair).creationCode, uint256(uint160(_token0)), uint256(uint160(_token1)));

        assembly {
            _pair :=
                create2(
                    0x0,
                    add(0x20, deploymentData),
                    mload(deploymentData),
                    0x0 // salt
                )
        }

        pairs[_token0][_token1] = _pair;
        emit PairCreated(_token0, _token1, _pair);
    }

    /// @notice returns pool address for given pair
    function getPair(address _token0, address _token1) external view returns (address _pair) {
        (_token0, _token1) = _sortTokens(_token0, _token1);
        return pairs[_token0][_token1];
    }

    /// @notice set new fee receiver or disable fee with address(0) input
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
        emit FeeReceiverSet(_feeReceiver);
    }

    function getFeeReceiver() external view returns (address) {
        return feeReceiver;
    }

    /// @notice sorts address of tokens in asc order
    function _sortTokens(address _token0, address _token1) internal pure returns (address, address) {
        return _token0 > _token1 ? (_token1, _token0) : (_token0, _token1);
    }
}
