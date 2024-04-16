// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {WadRayMath} from "./libraries/WadRayMath.sol";
import {NonceManager} from "./NonceManager.sol";
import {OrderBookAccess} from "./OrderBookAccess.sol";
import {Errors} from "./OrderBookErrors.sol";

/** Gasless exchange of 2 ERC20 tokens */
contract OrderBook is NonceManager, OrderBookAccess, EIP712 {
    using SafeERC20 for IERC20;

    /// @notice emiited on order execution
    event Executed(
        Order sellOrder,
        Order buyOrder,
        uint256 amountA,
        uint256 amountB
    );

    /// @notice token A
    IERC20 private immutable TOKEN_A; // UZS
    /// @notice token B
    IERC20 private immutable TOKEN_B; // USD - 12600

    struct Order {
        /// @notice trader address
        address trader;
        /// @notice order deadline
        uint256 deadline;
        /// @notice (price of B in terms of A) * 1e18
        uint256 price;
        /// @notice if buying B, amount of tokens A selling
        /// @notice if selling B, amount of token B selling
        uint256 quantity;
        /// @notice true if buying B, false if selling B
        bool buy;
    }

    /// @notice EIP-712 hash of Order
    bytes32 private constant ORDER_TYPEHASH =
        keccak256(
            "Order(address trader,uint256 deadline,uint256 price,uint256 quantity,bool buy)"
        );

    /// @param token1 address of token A
    /// @param token2 address of token B
    /// @param admin initial admin
    constructor(
        address token1,
        address token2,
        address admin
    ) OrderBookAccess(admin) EIP712("Orderbook", "1") {
        if (token1 == address(0x0) || token2 == address(0x0)) {
            revert Errors.AddressZero();
        }
        if (token1 == token2) {
            revert Errors.SameTokens();
        }
        TOKEN_A = IERC20(token1);
        TOKEN_B = IERC20(token2);
    }

    /// @notice execute matched orders
    function execute(
        Order memory sellOrder,
        bytes memory sellSignature,
        Order memory buyOrder,
        bytes memory buySignature
    ) external onlyRole(EXECUTOR_ROLE) {
        // validate signatures and deadlines
        _validateSignature(sellOrder, sellSignature);
        _validateSignature(buyOrder, buySignature);

        if (sellOrder.buy || !buyOrder.buy) {
            revert Errors.OrdersDontMatch();
        }
        if (sellOrder.price > buyOrder.price) {
            revert Errors.OrdersDontMatch();
        }

        uint256 maxAmountA = WadRayMath.wadMul(
            sellOrder.price,
            sellOrder.quantity
        ); // max amount of token A sell order can buy
        uint256 maxAmountB = WadRayMath.wadDiv(
            buyOrder.quantity,
            buyOrder.price
        ); // max amount of token B buy order can buy
        uint256 amountA;
        uint256 amountB;

        if (
            maxAmountB <= sellOrder.quantity && maxAmountA <= buyOrder.quantity
        ) {
            amountA = maxAmountA;
            amountB = maxAmountB;
        } else if (
            maxAmountB <= sellOrder.quantity && maxAmountA > buyOrder.quantity
        ) {
            amountB = maxAmountB;
            amountA = WadRayMath.wadMul(buyOrder.price, amountB);
        } else if (
            maxAmountB > sellOrder.quantity && maxAmountA <= buyOrder.quantity
        ) {
            amountA = maxAmountA;
            amountB = WadRayMath.wadDiv(amountA, buyOrder.price);
        } else {
            amountB = sellOrder.quantity;
            amountA = buyOrder.quantity;
        }

        TOKEN_A.safeTransferFrom(buyOrder.trader, address(this), amountA);
        TOKEN_B.safeTransferFrom(sellOrder.trader, address(this), amountB);
        TOKEN_A.safeTransfer(sellOrder.trader, amountA);
        TOKEN_B.safeTransfer(buyOrder.trader, amountB);

        emit Executed(sellOrder, buyOrder, amountA, amountB);
    }

    function permitERC20(
        address token,
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC20Permit(token).permit(
            owner,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
    }

    function multicall(bytes[] calldata data) external onlyRole(EXECUTOR_ROLE) {
        for (uint256 i = 0; i < data.length; ) {
            (bool success, bytes memory retdata) = address(this).delegatecall(
                data[i]
            );
            if (!success) {
                assembly {
                    revert(retdata, mload(retdata))
                }
            }
            unchecked {
                i++;
            }
        }
    }

    function _validateSignature(
        Order memory order,
        bytes memory signature
    ) internal view {
        if (order.deadline < block.timestamp) {
            revert Errors.OrderOutdated();
        }
        bytes32 structHash = keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                order.trader,
                order.deadline,
                order.price,
                order.quantity,
                order.buy
            )
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        bool valid = SignatureChecker.isValidSignatureNow(
            order.trader,
            hash,
            signature
        );
        if (!valid) {
            revert Errors.InvalidSignature();
        }
    }
}
