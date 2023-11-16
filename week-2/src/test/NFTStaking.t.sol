// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {NFTStaking} from "../eco-1/NFTStaking.sol";
import {WhitelistDiscountNFT} from "../eco-1/WhitelistDiscountNFT.sol";

contract NFTStakingTest is Test {
    address user1 = address(0x1337);
    address user2 = address(0x1338);
    NFTStaking staking;
    WhitelistDiscountNFT nft;

    function setUp() public {
        nft = new WhitelistDiscountNFT(
            "Test WL NFT",
            "WLNFT",
            bytes32(0x048c6e7746f948a03fd1686e8194e2f62d096380ba12b113b55a734ed9228095),
            250, // 2.5%
            1000,
            0.1 ether,
            250
        );
        staking = new NFTStaking(address(nft));
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function test_stake() public {
        assertEq(staking.balanceOf(user1), 0);
        vm.startPrank(user1);
        nft.mint{value: 0.1 ether}();

        assertEq(nft.balanceOf(user1), 1);

        nft.safeTransferFrom(user1, address(staking), 0);
        assertEq(nft.balanceOf(user1), 0);
        assertEq(nft.balanceOf(address(staking)), 1);
        assertEq(staking.balanceOf(user1), 1);
    }

    function test_differentNft() public {
        WhitelistDiscountNFT newNft = new WhitelistDiscountNFT(
            "Test WL NFT",
            "WLNFT",
            bytes32(0x048c6e7746f948a03fd1686e8194e2f62d096380ba12b113b55a734ed9228095),
            250, // 2.5%
            1000,
            0.1 ether,
            250
        );
        vm.startPrank(user1);
        newNft.mint{value: 0.1 ether}();
        vm.expectRevert("Invalid NFT");
        newNft.safeTransferFrom(user1, address(staking), 0);
    }

    function test_reward() public {
        vm.startPrank(user1);
        nft.mint{value: 0.1 ether}();
        nft.safeTransferFrom(user1, address(staking), 0);

        assertEq(staking.earned(user1), 0);

        vm.warp(block.timestamp + 12 hours);
        assertApproxEqAbs(staking.earned(user1), 5e18, 1e6);

        vm.warp(block.timestamp + 12 hours);
        assertApproxEqAbs(staking.earned(user1), 10e18, 1e6);

        // withdraw rewards
        IERC20 token = IERC20(staking.rewardToken());
        assertEq(token.balanceOf(user1), 0);
        staking.getReward();
        assertApproxEqAbs(token.balanceOf(user1), 10e18, 1e6);

        vm.warp(block.timestamp + 12 hours);
        assertApproxEqAbs(staking.earned(user1), 5e18, 1e6);

        // unstake nft and check that rewards are not coming after that
        staking.withdrawNFT(0);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.balanceOf(address(staking)), 0);

        vm.warp(block.timestamp + 12 hours);
        assertApproxEqAbs(staking.earned(user1), 5e18, 1e6);

        staking.getReward();
        assertApproxEqAbs(token.balanceOf(user1), 15e18, 1e6);
    }

    function test_multipleStakers() public {
        // mint and stake as user 1
        vm.startPrank(user1);
        nft.mint{value: 0.1 ether}();
        nft.safeTransferFrom(user1, address(staking), 0);
        assertEq(staking.earned(user1), 0);
        vm.warp(block.timestamp + 12 hours);
        assertApproxEqAbs(staking.earned(user1), 5e18, 1e6);
        vm.stopPrank();

        // after 12 hours mint nft and stake it as user 2
        vm.startPrank(user2);
        nft.mint{value: 0.1 ether}();
        nft.safeTransferFrom(user2, address(staking), 1);
        assertEq(staking.earned(user2), 0);
        vm.stopPrank();

        // after 12 more hours, user1 should have earned 7.5 tokens and user2 2.5 tokens
        vm.warp(block.timestamp + 12 hours);
        assertApproxEqAbs(staking.earned(user1), 75e17, 1e6);
        assertApproxEqAbs(staking.earned(user2), 25e17, 1e6);

        // withdraw user1's nft
        vm.prank(user1);
        staking.withdrawNFT(0);

        // in 12 hours after user1's withdrawal user2 should have earned 5 more tokens, instead of 2.5 tokens
        vm.warp(block.timestamp + 12 hours);
        assertApproxEqAbs(staking.earned(user2), 75e17, 1e6);
    }
}
