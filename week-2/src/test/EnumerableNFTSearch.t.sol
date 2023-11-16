// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {EnumerableNFTSearch} from "../eco-2/EnumerableNFTSearch.sol";
import {EnumerableNFT} from "../eco-2/EnumerableNFT.sol";

contract EnumerableNFTSearchTest is Test {
    EnumerableNFTSearch search;
    EnumerableNFT nft;
    address[10] users = [
        address(0x1),
        address(0x2),
        address(0x3),
        address(0x4),
        address(0x5),
        address(0x6),
        address(0x7),
        address(0x8),
        address(0x9),
        address(0x10)
    ];

    function setUp() public {
        nft = new EnumerableNFT("Test eNFT", "eNFT", 100);
        search = new EnumerableNFTSearch(address(nft));
    }

    function test_getPrimeNFTCountWith10NFTS() public {
        for (uint256 i = 0; i < 10; ++i) {
            vm.startPrank(users[i]);
            for (uint256 j = 0; j < 10; ++j) {
                nft.mint();
            }
            assertEq(nft.balanceOf(users[i]), 10);
            vm.stopPrank();
        }
        assertEq(search.getPrimeNFTCount(users[0]), 5); // [1],[2],[3],4,[5],6,[7],8,9,10
        assertEq(search.getPrimeNFTCount(users[1]), 4); // [11],12,[13],14,15,16,[17],18,[19],20
        assertEq(search.getPrimeNFTCount(users[2]), 2); // 21,22,[23],24,25,26,27,28,[29],30
        assertEq(search.getPrimeNFTCount(users[3]), 2); // [31],32,33,34,35,36,[37],38,39,40
        assertEq(search.getPrimeNFTCount(users[4]), 3); // [41],42,[43],44,45,46,[47],48,49,50
    }

    function test_getPrimeNFTCountWith20NFTS() public {
        for (uint256 i = 0; i < 5; ++i) {
            vm.startPrank(users[i]);
            for (uint256 j = 0; j < 20; ++j) {
                nft.mint();
            }
            assertEq(nft.balanceOf(users[i]), 20);
            vm.stopPrank();
        }
        assertEq(search.getPrimeNFTCount(users[0]), 9); // 1-20
        assertEq(search.getPrimeNFTCount(users[1]), 4); // 21-40
        assertEq(search.getPrimeNFTCount(users[2]), 5); // 41-60
        assertEq(search.getPrimeNFTCount(users[3]), 5); // 61-80
        assertEq(search.getPrimeNFTCount(users[4]), 3); // 81-100
    }
}
