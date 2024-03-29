## EIP-1167 - Minimal Proxy contract

Simplest and cheapest proxy contract

#### Features

- it's just 45 bytes of code, makes deployment very cheap

#### Downsides

- can't be upgraded - the implementation contract can't have immutable values
- can't initialize the implementation contract, but we can build a separate contract factory that deploys a proxy and immediately initializes it

## EIP-3448 - MetaProxy contract

The second simplest and cheapest proxy contract that allows having immutable values. Immutable values are hardcoded in the proxy's bytecode and forwarded to the implementation contract's calldata with each `delegatecall`.

## EIP-1967 - Standard Proxy Storage Slots

One solution to proxy storage collision. All values in the proxy contract are stored in a pseudo-random slot that is large and random enough not to minimize the probability of storage collision with the implementation contract.

## Transparent proxy (TPP)

Upgradable proxy contract.
The proxy contracts above had these downsides:
- the proxy contract should store the implementation contract address in itself
- the proxy should restrict the access to the upgrading function, thus it must store the admin address as well
- the upgrading function may have a function name collision with the implementation contract

Transparent proxy pattern addresses these issues this way:
- the implementation contract address and the owner address are stored in a pseudo-random slot
- the owner of the proxy can not call any other function other than the upgrading function and all calls from other senders are allways delegatecalled
```solidity
function _fallback() internal virtual override {
    if (msg.sender == _proxyAdmin()) {
        if (msg.sig != ITransparentUpgradeableProxy.upgradeToAndCall.selector) {
            revert ProxyDeniedAdminAccess();
        } else {
            _dispatchUpgradeToAndCall();
        }
    } else {
        super._fallback();
    }
}
```

## EIP-1822 - Universal Upgradeable Proxy Standard (UUPS)

Addresses the issue of function selector clash by moving all the logic for upgrading the proxy to the implementation contract, so basically the implementation contract must be aware of the proxy contract

## Beacon Proxy

Is a contract used by the proxy contract exclusively to store the address of the implementation contract.

This pattern can be helpful when we have many proxy contracts that need to be upgraded at once - all of them should point to a single beacon contract.
