// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SanctionedERC20
/// @notice ERC20 that allows an admin to ban specified addresses from sending and receiving tokens
contract SanctionedERC20 is ERC20, Ownable {
    mapping(address => bool) public banned;

    /// @dev emitted when new address is banned
    event Banned(address indexed who);
    /// @dev emitted when the address is unbanned
    event Unbanned(address indexed who);

    /// @notice Address is banned
    error AddressIsBanned(address who);

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
     * @dev Throws if the given address is banned
     */
    modifier notBanned(address who) {
        if (banned[who]) {
            revert AddressIsBanned(who);
        }
        _;
    }

    /**
     * @notice Bans a new address. Can only be used by the admin
     * @dev emit a Banned event
     * @param who address to ban
     */
    function ban(address who) external onlyOwner {
        banned[who] = true;
        emit Banned(who);
    }

    /**
     * @notice Unbans the address. Can only be used by the admin
     * @dev emit an Unbanned event
     * @param who address to ban
     */
    function unban(address who) external onlyOwner {
        banned[who] = false;
        emit Unbanned(who);
    }

    /**
     * @dev Checks if the sender or the recipient are banned
     * @inheritdoc ERC20
     */
    function transfer(address to, uint256 value) public override notBanned(to) notBanned(msg.sender) returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * @dev Checks if the sender or the recipient are banned
     * @inheritdoc ERC20
     */
    function transferFrom(address from, address to, uint256 value)
        public
        override
        notBanned(to)
        notBanned(from)
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }
}
