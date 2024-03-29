**Question 1**: The OZ upgrade tool for hardhat defends against 6 kinds of mistakes. What are they and why do they matter?

**Answer:**
    - storage collision
    - usage of constructor by the implementation contract
    - usage of selfdestruct or delegatecall by the implementation contract
    - missing the public upgradeTo function
    - external library linking
    - usage of immutable values by the implementation contract

---

**Question 2**: What is a beacon proxy used for?

**Answer:** Beacon proxy pattern can be used when we need to upgrade multiple proxies at once.

The proxy contract will store the address of the beacon contract instead of the implementation contract and the beacon contract will store the address of the implementation. That way if we have to upgrade multiple proxies simultaneously we can store the address of the beacon in them and then update the address of the implementation in the beacon contract.

---

**Question 3:** Why does the openzeppelin upgradeable tool insert something like uint256[50] private __gap; inside the contracts? To see it, create an upgradeable smart contract that has a parent contract and look in the parent.

**Answer:**

--- With these they were occupying slots in the storage for future changes. They don't do that anymore and switched to namespaces storage slots pattern

**Question 4:** What is the difference between initializing the proxy and initializing the implementation? Do you need to do both? When do they need to be done?

**Answer:** Initializer is a upgradable contract's constructor.

Because constructor run only once during the deployment of the implementation contract and in the context of that contract, we can't reuse them with proxies. To make up for that we can create a special initializer function that can be called only once.

We don't need to have the initializer function in the proxy contract itself

---

**Question 5:** What is the use for the reinitializer? Provide a minimal example of proper use in Solidity

**Answer:** To be able to intiialize the proxy contract multiple times with different parameters. Example in WhitelistDiscountNFTV3.sol



```solidity
function delegate(address impl) external returns (uint256) {
    (bool ok, bytes memory result) = impl.delegatecall(abi.encodeWithSignature("data()"));
    return abi.decode(result, (uint256));
}
```

Q1: When a contract calls another call via call, delegatecall, or staticcall, how is information passed between them? Where is this data stored?

A1: through calldata

Q2: If a proxy calls an implementation, and the implementation self-destructs in the function that gets called, what happens?

A2: Proxy will be destroyed

Q3: If a proxy calls an empty address or an implementation that was previously self-destructed, what happens?

A3: The proxy will try to call the implementation contract, but since the code is 0x nothing will happen but the delegatecall won't return `false` in the first argument, it will always be `true`

Q4: If a user calls a proxy makes a delegatecall to A, and A makes a regular call to B, from A's perspective, who is msg.sender? from B's perspective, who is msg.sender? From the proxy's perspective, who is msg.sender?

A4:
- A's msg.sender = a user
- B's msg.sender = a proxy
- Proxy's msg.sender = a user

Q5: If a proxy makes a delegatecall to A, and A does address(this).balance, whose balance is returned, the proxy's or A?

A5: proxy's

Q6: If a proxy makes a delegatecall to A, and A calls codesize, is codesize the size of the proxy or A?

A6: proxy's

Q7: If a delegatecall is made to a function that reverts, what does the delegatecall do?

A7: will return `false` in the first argument

Q8: Under what conditions does the Openzeppelin Proxy.sol overwrite the free memory pointer? Why is it safe to do this?

A8: It does so when copying the calldata into memory and then when copying returndata. It is safe to do so because that memory is not used for anything else other than that

Q9: If a delegatecall is made to a function that reads from an immutable variable, what will the value be?

A9: immutable variable is stored in the bytecode of the implementation contract, so the value from the implementation contract will be read, not from proxy's storage

Q10: If a delegatecall is made to a contract that makes a delegatecall to another contract, who is msg.sender in the proxy, the first contract, and the second contract?

A11: a user is the msg.sender in all 3 cases