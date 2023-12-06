### Why does the price0CumulativeLast and price1CumulativeLast never decrement?

Because they must be equal to the sum of all historical prices since the creation of a pair

### How do you write a contract that uses the oracle?

Suppose we want to use a 30 minute TWAP. The contract must store 2 cumulative prices that are fetched with a difference of 30 minutes.

```sol
uint256 twap1 = pair.price0Cumulative();
// after 30 minutes
uint256 twap2 = pair.price0Cumulative();;
```

Then we get the average price of the asset for 30 minutes

```
uint256 avgPrice = (twap2 - twap1) / (30*60)
```

### Why are price0CumulativeLast and price1CumulativeLast stored separately? Why not just calculate `price1CumulativeLast = 1/price0CumulativeLast?

Although a price of the asset X in terms of the asset Y and the price of Y in terms of X in the moment are invertible, the sum of the historical prices are not, since:

```
1/(a+b) != 1/a + 1/b
```