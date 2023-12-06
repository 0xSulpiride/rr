// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/mocks/token/ERC20Mock.sol";
import {RareswapFactory} from "../RareswapFactory.sol";
import {RareswapPair} from "../RareswapPair.sol";

contract RareswapFactoryTest is Test {
    address user1 = address(0x1337);
    address user2 = address(0x1338);
    RareswapFactory factory;
    ERC20Mock token0;
    ERC20Mock token1;

    function setUp() public {
        factory = new RareswapFactory();
        token0 = new ERC20Mock();
        token1 = new ERC20Mock();
    }

    function test_createPair() public {
        (address _token0, address _token1) = sortTokens(address(token0), address(token1));
        address deterministicAddress = getDeterministicAddress(_token0, _token1);
        factory.createPair(_token0, _token1);
        address factualAddress = factory.getPair(_token0, _token1);
        assertEq(deterministicAddress, factualAddress);
        assertEq(RareswapPair(factualAddress).token0(), _token0);
        assertEq(RareswapPair(factualAddress).token1(), _token1);
    }

    function test_createPairTwice() public {
        (address _token0, address _token1) = sortTokens(address(token0), address(token1));

        factory.createPair(_token0, _token1);
        vm.expectRevert();
        factory.createPair(_token0, _token1);
    }

    function getDeterministicAddress(address _token0, address _token1) public returns (address _addr) {
        bytes memory code =
            abi.encodePacked(type(RareswapPair).creationCode, uint256(uint160(_token0)), uint256(uint160(_token1)));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(factory), bytes32(0x0), keccak256(code)));
        _addr = address(uint160(uint256(hash)));
    }

    /// @dev sorts address of tokens in asc order
    function sortTokens(address _token0, address _token1) public pure returns (address, address) {
        return _token0 > _token1 ? (_token1, _token0) : (_token0, _token1);
    }
}
