// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title Bonding Curve Sale
/// @notice Sell ERC20 with increasing price
/// @notice linear bonding curve Y=X
contract BondingCurveSale {
    using SafeERC20 for IERC20;
    using Math for uint256;

    /// @notice emitted when sale starts
    event SaleStarted();
    /// @notice emitted on buy
    event Bought(address indexed who, uint256 tokens, uint256 value);
    /// @notice emitted on sell
    event Sold(address indexed who, uint256 tokens, uint256 value);

    /// @notice sale is started after the contract has been topped up
    bool private saleStarted;
    /// @notice token to sell
    IERC20 private token;
    /// @notice accounted amount of tokens
    uint256 private reserveToken;
    /// @notice account ether
    uint256 private reserveEther;
    /// @notice initial token liquidity
    uint256 private initialLiquidity;

    /**
     * @param _token token to sell
     */
    constructor(address _token) {
        token = IERC20(_token);
    }

    modifier whenStarted() {
        require(saleStarted, "not started");
        _;
    }

    /**
     * @notice start the sale
     * @param _liquidity how many of tokens to sell
     */
    function start(uint256 _liquidity) external {
        saleStarted = true;
        initialLiquidity = reserveToken = _liquidity;
        token.safeTransferFrom(msg.sender, address(this), initialLiquidity);
        require(token.balanceOf(address(this)) >= initialLiquidity, "Could not send tokens");
        emit SaleStarted();
    }

    /**
     * @notice buy `_minAmount` amount of tokens for msg.value
     * @param _minAmount minimum amount of tokens to buy (slippage)
     */
    function buy(uint256 _minAmount) external payable whenStarted {
        uint256 toSell = ethToToken(msg.value);
        require(toSell >= _minAmount, "out of slippage");
        toSell = Math.min(toSell, reserveToken);
        reserveEther += msg.value;
        reserveToken -= toSell;
        emit Bought(msg.sender, toSell, msg.value);
        token.safeTransfer(msg.sender, toSell);
    }

    /**
     * @notice sell _amount of tokens and receive at least _minReceive of ether
     * @param _amount amount of tokens to sell
     * @param _minReceive minimum amount of ether to receive (slippage)
     */
    function sell(uint256 _amount, uint256 _minReceive) external whenStarted {
        uint256 toSend = tokenToEth(_amount);
        require(toSend >= _minReceive, "out of slippage");
        toSend = Math.min(toSend, reserveEther);
        reserveEther -= toSend;
        reserveToken += _amount;
        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit Sold(msg.sender, _amount, toSend);
        (bool success,) = payable(msg.sender).call{value: toSend}("");
        require(success, "");
    }

    /**
     * @notice converts ether to tokens at current continous price
     * @param _value amount of ether
     * @return amount of tokens
     */
    function ethToToken(uint256 _value) public view returns (uint256) {
        uint256 prevPrice = Math.sqrt(2 * reserveEther * 1e18);
        uint256 newPrice = Math.sqrt(2 * (reserveEther + _value) * 1e18);
        return (newPrice - prevPrice);
    }

    /**
     * @notice converts tokens to ether at current continous price
     * @param _value amount of tokens
     * @return amount of ethers
     */
    function tokenToEth(uint256 _value) public view returns (uint256) {
        uint256 prevPrice = (initialLiquidity - reserveToken) ** 2;
        uint256 newPrice = ((initialLiquidity - reserveToken) + _value) ** 2;
        return (newPrice - prevPrice) / 2 / 1e18;
    }
}
