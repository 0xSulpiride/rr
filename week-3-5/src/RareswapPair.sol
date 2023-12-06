// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {IERC3156FlashLender} from "@openzeppelin/interfaces/IERC3156FlashLender.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/interfaces/IERC3156FlashBorrower.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IRareswapFactory} from "./interfaces/IRareswapFactory.sol";
import {UQ112x112} from "./libraries/UQ112x112.sol";
import {RareswapERC20} from "./RareswapERC20.sol";

/// @title Rareswap Pair
/// @notice Pool of 2 ERC20 tokens
/// @notice swap fee = 30 bps
/// @notice protocol fee = 5 bps
contract RareswapPair is IERC3156FlashLender, RareswapERC20 {
    using UQ112x112 for uint224;
    using SafeTransferLib for address;

    /// @dev Invalid amount of tokens was sent
    error InvalidAmount();
    /// @dev Balance of tokens are more than max(uint112), call skim()
    error ReserveOverflow();
    /// @dev Insufficient liquidity minted
    error ZeroLiquidityMinted();
    /// @dev Thrown if LP minted is less than a slippage
    error InsufficientLiquidityMinted(uint256 lpMinted);
    /// @dev Thrown if token amount after swap or burn is less than a slippage
    error InsufficientTokenAmount(uint256 token0Amount, uint256 token1Amount);
    /// @dev block.timestamp is greater than deadline
    error Deadline();
    /// @dev The loan token is not valid.
    error ERC3156UnsupportedToken(address token);
    /// @dev The requested loan exceeds the max loan value for `token`.
    error ERC3156ExceededMaxLoan(uint256 maxLoan);
    /// @dev The receiver of a flashloan is not a valid {onFlashLoan} implementer.
    error ERC3156InvalidReceiver(address receiver);

    /// @notice emitted on each _update()
    event Sync(uint112 _reserve0, uint112 _reserve1);
    /// @notice minted lp amount of lp tokens for amount0 of token0, amount1 of token1
    event Mint(uint256 _amount0, uint256 _amount1, uint256 _lp);
    /// @notice new swap event
    event Swap(uint256 _amount0In, uint256 _amount1In, uint256 _amount0Out, uint256 _amount1Out);
    /// @notice burn lp amount of lp tokens and given amount0 of token0 and amount1 of token1
    event Burn(uint256 _amount0, uint256 _amount1, uint256 _lp);

    /// @notice return value of ERC3156FlashBorrower.onFlashLoan
    bytes32 private constant ERC3156_RETURN_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");
    /// @notice total supply can't go lower than this
    /// @dev MINIMUM_LIQUIDITY_SQRT will be burned on the first deposit
    /// @dev defense from inflation attack on the first mint()
    uint256 private constant MINIMUM_LIQUIDITY = 1000;
    /// @notice address of the factory contract
    address private immutable factory;
    /// @notice accounted balance of token0
    uint112 private reserve0;
    /// @notice accounted balance of token1
    uint112 private reserve1;
    /// @notice timestamp of the last time reserves were updated
    uint32 private lastUpdateTime;
    /// @notice first token of the pair
    address public immutable token0;
    /// @notice second token of the pair
    address public immutable token1;
    /// @notice cumulative price of token0
    uint256 public price0Cumulative;
    /// @notice cumulative price of token1
    uint256 public price1Cumulative;
    /// @notice last x*y, needed to calculate the protocol fee
    uint256 public kLast;

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
        factory = msg.sender;
    }

    /// @notice emergency update of reserves & twap
    function sync() external {
        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)), reserve0, reserve1);
    }

    /// @notice if there's excess amount of tokens in the contracts balances, send them to the msg.sender
    function skim() external {
        // gas savings
        uint256 excess0 = IERC20(token0).balanceOf(address(this)) - reserve0;
        uint256 excess1 = IERC20(token1).balanceOf(address(this)) - reserve1;
        if (excess0 > 0) token0.safeTransfer(msg.sender, excess0);
        if (excess1 > 0) token1.safeTransfer(msg.sender, excess1);
    }

    /// @notice mints at least `minLpAmount` of LP tokens for tokenAmount of token0 and token1Amount of token2
    /// @notice the very first supplier's LP token amount if reduced by 1000. this is to protect everyone against inflation attacks
    function mint(uint256 _token0Amount, uint256 _token1Amount, uint256 _minLpAmount) external {
        // gas savings
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        if (_token0Amount > 0) {
            token0.safeTransferFrom(msg.sender, address(this), _token0Amount);
        }
        if (_token1Amount > 0) {
            token1.safeTransferFrom(msg.sender, address(this), _token1Amount);
        }
        // check how much tokens we actually received
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        if (amount0 == 0 && amount1 == 0) revert InvalidAmount();

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 liquidity = 0;
        if (totalSupply() == 0) {
            liquidity = FixedPointMathLib.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = FixedPointMathLib.min(amount0 * totalSupply() / _reserve0, amount1 * totalSupply() / _reserve1);
        }
        if (liquidity == 0) revert ZeroLiquidityMinted();
        if (liquidity < _minLpAmount) revert InsufficientLiquidityMinted(liquidity);
        _mint(msg.sender, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0) * reserve1;
        emit Mint(amount0, amount1, liquidity);
    }

    /// @notice burn `lpAmount` of lp tokens from sender's balance and transfer the amount of token0 and token1
    /// @notice that is equal to the proportion of lpAmount in the pool
    function burn(uint256 _lpAmount, uint256 _amount0Min, uint256 _amount1Min) external {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint256 amount0 = _lpAmount * _reserve0 / totalSupply();
        uint256 amount1 = _lpAmount * _reserve1 / totalSupply();
        if (_amount0Min > amount0 || _amount1Min > amount1) revert InsufficientTokenAmount(amount0, amount1);
        bool feeOn = _mintFee(_reserve0, _reserve1);
        _burn(msg.sender, _lpAmount);
        token0.safeTransferFrom(address(this), msg.sender, amount0);
        token1.safeTransferFrom(address(this), msg.sender, amount1);
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0) * reserve1;
        emit Burn(amount0, amount1, _lpAmount);
    }

    /// @notice put `_amount0In` amount of token0 and `_amount1In` amount of token1 and get
    /// @notice `_amount0Out` and `_amount1Out` of tokens in exchange
    /// @notice `_deadline` is a timestamp
    function swap(uint256 _amount0In, uint256 _amount1In, uint256 _amount0Out, uint256 _amount1Out, uint32 _deadline)
        external
    {
        if (_deadline > block.timestamp) revert Deadline();
        // gas savings
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        if (_amount0Out > 0) token0.safeTransfer(msg.sender, _amount0Out);
        if (_amount1Out > 0) token1.safeTransfer(msg.sender, _amount1Out);

        // To handle tokens with fees we need to check how much really was put in the contract
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = _amount0In;
        uint256 amount1 = _amount1In;
        if (amount0 > 0) {
            token0.safeTransferFrom(msg.sender, address(this), amount0);
            amount0 = IERC20(token0).balanceOf(address(this)) - balance0;
        }
        if (amount0 > 0) {
            token1.safeTransferFrom(msg.sender, address(this), amount1);
            amount1 = IERC20(token1).balanceOf(address(this)) - balance1;
        }

        // balanceAdjusted is a new balance of a pool minus fees (30 bps)
        // here we're substracting 30 bps from the inputted amounts
        // balanceAdjusted = balance + amount - (amount/10000 * 30) = (balance * 1000 + amount * 997) / 1000
        uint256 balance0Adjusted = balance0 * 1000 + amount0 * 997;
        uint256 balance1Adjusted = balance1 * 1000 + amount1 * 997;
        if (balance0Adjusted * balance1Adjusted <= uint256(_reserve0) * uint256(_reserve1) * 1000 ** 2) {
            revert InvalidAmount();
        }
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(amount0, amount1, _amount0Out, _amount1Out);
    }

    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool)
    {
        uint256 maxLoan = maxFlashLoan(token);
        if (amount > maxLoan) {
            revert ERC3156ExceededMaxLoan(maxLoan);
        }
        uint256 fee = flashFee(token, amount);
        token.safeTransfer(address(receiver), amount);
        if (receiver.onFlashLoan(msg.sender, token, amount, fee, data) != ERC3156_RETURN_VALUE) {
            revert ERC3156InvalidReceiver(address(receiver));
        }
        token.safeTransferFrom(address(receiver), address(this), amount + fee);
        return true;
    }

    /// @notice see {IERC3156FlashLender-maxFlashLoan}
    function maxFlashLoan(address token) public view returns (uint256) {
        if (token != address(token0) && token != address(token1)) {
            return 0;
        }
        return IERC20(token).balanceOf(address(this));
    }

    /// @notice see {IERC3156FlashLender-flashFee}
    function flashFee(address token, uint256 amount) public view returns (uint256) {
        if (token != address(token0) && token != address(token1)) revert ERC3156UnsupportedToken(token);
        return amount * 3 / 1000; // 30 bps
    }

    /// @notice returns reserves and last updated time
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _lastUpdateTime) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _lastUpdateTime = lastUpdateTime;
    }

    /// @notice update reserves & check that reserves are less than max(uint112) & update twap
    function _update(uint256 _balance0, uint256 _balance1, uint112 _reserve0, uint112 _reserve1) internal {
        if (_balance0 > type(uint112).max || _balance0 > type(uint112).max) revert ReserveOverflow();
        uint32 timestamp = uint32(block.timestamp % 2 ** 32);
        unchecked {
            uint32 timeElapsed = timestamp - lastUpdateTime;
            if (timeElapsed > 0 && _reserve0 > 0 && _reserve0 > 0) {
                price0Cumulative += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
                price1Cumulative += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
            }
        }
        reserve0 = uint112(_balance0);
        reserve1 = uint112(_balance1);
        lastUpdateTime = timestamp;
        emit Sync(reserve0, reserve0);
    }

    /// @notice updates kLast if protocol fee is actived
    /// @notice mints 1/6 of swap fees to the protocol as a fee
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IRareswapFactory(factory).getFeeReceiver();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = FixedPointMathLib.sqrt(uint256(_reserve0) * (_reserve1));
                uint256 rootKLast = FixedPointMathLib.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply() * (uint256(rootK) - rootKLast);
                    uint256 denominator = rootK * 5 + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }
}
