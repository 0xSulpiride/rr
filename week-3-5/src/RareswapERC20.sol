// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@solady/tokens/ERC20.sol";

/// @title Rareswap ERC20
/// @notice base contract for Rareswap Pair with ERC20 + ERC2612 implementation
abstract contract RareswapERC20 is ERC20 {
    function name() public view virtual override returns (string memory) {
        return "RareswapPair";
    }

    function symbol() public view virtual override returns (string memory) {
        return "RS-V2";
    }
}
