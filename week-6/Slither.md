## Document true and false positives that you discovered with the tools

### Week 1

#### True Positives

- none

#### False Positives

- Reentrancy in BondingCurveSale.sell(uint256,uint256) (src/BondingCurveSale.sol#76-86)
- Reentrancy in BondingCurveSale.start(uint256) (src/BondingCurveSale.sol#49-55)

### Week 2

#### True Positives

- Reentrancy in Overmint1.mint() (src/ctfs/overmint1.sol#15-20):
- Attack1.constructor(address,address)._victim (src/ctfs/overmint1.attack.sol#11) lacks a zero-check on
- Attack1.constructor(address,address)._owner (src/ctfs/overmint1.attack.sol#11) lacks a zero-check on
- EnumerableNFTSearch.getPrimeNFTCount(address) (src/eco-2/EnumerableNFTSearch.sol#17-28) has external calls inside a loop: isPrime(nft.tokenOfOwnerByIndex(account,i)) (src/eco-2/EnumerableNFTSearch.sol#22)
- Attack1.owner (src/ctfs/overmint1.attack.sol#9) should be immutable
- Attack1.victim (src/ctfs/overmint1.attack.sol#8) should be immutable
- EnumerableNFTSearch.isPrime(uint256) (src/eco-2/EnumerableNFTSearch.sol#31-43) uses assembly

#### False Positives

- Reentrancy in NFTStaking.getReward() (src/eco-1/NFTStaking.sol#72-82)
- Reentrancy in NFTStaking.withdrawNFT(uint256) (src/eco-1/NFTStaking.sol#59-68)
- Reentrancy in NFTStaking.withdrawNFT(uint256) (src/eco-1/NFTStaking.sol#59-68)

