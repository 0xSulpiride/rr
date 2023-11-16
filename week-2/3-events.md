### How can OpenSea quickly determine which NFTs an address owns if most NFTs don’t use ERC721 enumerable. Explain how you would accomplish this if you were creating an NFT marketplace

If NFT is ERC721-compliant, then all mint and transfer operations will emit an event. In that case, all I need to do is to listen for those events and track the ownership of each tokenId.

If I would do it in NodeJS, I could create a in-memory mapping (or a persistent storage Redis):
```js
const token_id_to_owner = {}; // mapping(tokenId => address)
```

Then I would look through past `Transfer` events and would listen to future `Transfer` events.

On each `Transfer` event
```sol
event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
```
I would update the mapping
```js
token_id_to_owner[_tokenId] = _to;
```


If the contract is not ERC721, then there can not be a general solution to this and the solution will depend on the implementation of the contract.