// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "openzeppelin-contracts/token/ERC721/utils/ERC721Holder.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";
import {TokenWithGodMode} from "./TokenWithGodMode.sol";

/// @title NFT Staking
/// @notice Contract mints 10 ERC20 tokens every 24 hours. Reward pot is fixed and shared amongst NFT stakers.
/// @notice The more nfts you stake, the more proportion of the pot you get
/// @dev math for calculating rewards is from synthetix
/// @dev https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol
contract NFTStaking is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ERC721Holder
{
    /// @notice emitted on reward paid
    event RewardPaid(address indexed rewardee, uint256 amount);
    /// @notice emitted on withdrawing nft
    event Withdrawn(address indexed withdrawer, uint256 tokenId);
    /// @notice emitted on staked nft
    event Staked(address indexed user, uint256 tokenId);

    struct StakeInfo {
        /// @notice amount of tokens staked
        uint256 balance;
        /// @notice tokenId => bool, staked token ids
        mapping(uint256 => bool) tokens;
        /// @notice rewards per token
        uint256 rewardPerTokenPaid;
        /// @notice rewards earned
        uint256 rewards;
    }

    /// @notice reward token
    TokenWithGodMode public rewardToken;
    /// @notice nft to stake
    IERC721 private nft;
    /// @notice stakers info
    mapping(address => StakeInfo) private stakeInfo;
    /// @notice total amount of tokens staked
    uint256 private totalStaked;
    /// @notice reward per token
    uint256 private rewardPerTokenStored;
    /// @notice last time when rewards were updated
    uint256 private lastUpdateTime;
    /// @notice 10 ERC20 tokens per 24 hours
    uint256 private constant rewardRate = 10e18 / uint256(24 hours);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @param _nft address of the nft contract to stake
    function initialize(address _owner, address _nft) external initializer {
        __Ownable_init(_owner);
        nft = IERC721(_nft);
        rewardToken = new TokenWithGodMode("Reward Token", "RTKN");
    }

    /// @notice returns the number of staked nfts
    function balanceOf(address account) external view returns (uint256) {
        return stakeInfo[account].balance;
    }

    /// @notice withdraw staked nft
    function withdrawNFT(uint256 tokenId) external {
        _updateReward(msg.sender);
        StakeInfo storage staker = stakeInfo[msg.sender];
        require(staker.tokens[tokenId], "Token not staked");
        totalStaked--;
        staker.balance--;
        staker.tokens[tokenId] = false;
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        emit Withdrawn(msg.sender, tokenId);
    }

    /// @notice withdraw rewards
    /// @dev emits RewardPaid event
    function getReward() external {
        _updateReward(msg.sender);
        StakeInfo storage staker = stakeInfo[msg.sender];
        uint256 reward = staker.rewards;
        if (reward > 0) {
            staker.rewards = 0;
            // mint reward tokens
            rewardToken.move(address(0x0), msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /**
     * @dev stakes nft with token id `_tokenId` on behalf of `_operator` and emits Staked event
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data)
        public
        override
        returns (bytes4)
    {
        require(msg.sender == address(nft), "Invalid NFT");
        StakeInfo storage staker = stakeInfo[_operator];
        _updateReward(_operator);
        staker.tokens[_tokenId] = true;
        staker.balance++;
        totalStaked++;
        emit Staked(_operator, _tokenId);
        return this.onERC721Received.selector;
    }

    /// @return amount of ERC20 tokens staker can earn for staking 1 NFT
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + ((block.timestamp - lastUpdateTime) * rewardRate * 1e18 / totalStaked);
    }

    /// @param _account address of a staker
    /// @return rewards earned up to now
    function earned(address _account) public view returns (uint256) {
        StakeInfo storage staker = stakeInfo[_account];
        return staker.balance * (rewardPerToken() - staker.rewardPerTokenPaid) / 1e18 + staker.rewards;
    }

    /// @notice updates reward info of `account`
    function _updateReward(address _account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (_account != address(0)) {
            StakeInfo storage staker = stakeInfo[_account];
            staker.rewards = earned(_account);
            staker.rewardPerTokenPaid = rewardPerTokenStored;
        }
    }

    /// @dev authorize upgradeToAndCall() operation, only owner can use that
    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}
}
