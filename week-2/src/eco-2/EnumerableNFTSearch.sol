// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @notice contract that searchs through IERC721Enumerable contract and shows
/// @notice how many NFTs are owned by that address which have tokenIDs that are prime numbers.
contract EnumerableNFTSearch {
    /// @notice nft collection
    IERC721Enumerable private immutable nft;

    constructor(address _nft) {
        nft = IERC721Enumerable(_nft);
    }

    /// @notice returns amount of nfts owned by `account` that have prime tokenId
    function getPrimeNFTCount(address account) external view returns (uint256) {
        uint256 primeNfts = 0;
        uint256 maxIndex = nft.balanceOf(account);
        unchecked {
            for (uint256 i = 0; i < maxIndex; ++i) {
                if (isPrime(nft.tokenOfOwnerByIndex(account, i))) {
                    primeNfts++;
                }
            }
        }
        return primeNfts;
    }

    /// @notice returns true is `num` is prime
    function isPrime(uint256 num) public pure returns (bool ans) {
        ans = true;
        assembly {
            let halfX := add(div(num, 2), 1)
            for { let i := 2 } lt(i, halfX) { i := add(i, 1) } {
                if iszero(mod(num, i)) {
                    ans := false
                    break
                }
            }
        }
        return ans;
    }
}
