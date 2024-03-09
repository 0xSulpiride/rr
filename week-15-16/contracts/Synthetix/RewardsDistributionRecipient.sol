// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract RewardsDistributionRecipient is Ownable2Step {
    address public rewardsDistribution;

    constructor(address _owner) Ownable(_owner) {}

    function notifyRewardAmount(uint256 reward) virtual external {
        revert("Not implemented");
    }

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
    }
}
