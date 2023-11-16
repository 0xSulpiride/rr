// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @notice ERC721Enumerable with limited supply
/// @notice token id starts with 1
contract EnumerableNFT is ERC721Enumerable {
    /// @notice max nft total supply
    uint256 private immutable maxSupply;

    constructor(string memory _name, string memory _symbol, uint256 _maxSupply) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
    }

    /// @notice mint new nft to `msg.sender`
    function mint() external {
        uint256 tokenId = firstTokenId() + totalSupply();
        require(tokenId <= maxSupply, "Max supply reached");
        _safeMint(msg.sender, tokenId);
    }

    /// @notice starting id of this nft collection
    function firstTokenId() public pure returns (uint256) {
        return 1;
    }
}
