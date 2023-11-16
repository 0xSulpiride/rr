// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Token With God Mode
/// @notice ERC20. A special address is able to transfer tokens between addresses at will.
contract TokenWithGodMode is ERC20, Ownable {
    /// @notice emitted when a `value` amount of tokens moved from `from` to `to`
    event Moved(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Deploy the token contract with a name and a symbol
     * @param name token name
     * @param symbol token symbol
     * @dev mint 10kk tokens to the owner
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, 10_000_000 * 1e18);
    }

    /**
     * @notice Moves a `value` amount of tokens from `from` to `to`
     * @dev emits `Moved` event
     */
    function move(address from, address to, uint256 value) external onlyOwner {
        emit Moved(from, to, value);
        _update(from, to, value);
    }
}
