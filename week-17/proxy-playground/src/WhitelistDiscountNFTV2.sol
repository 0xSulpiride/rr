// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721EnumerableUpgradeable} from "openzeppelin-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {ERC2981Upgradeable} from "openzeppelin-upgradeable/token/common/ERC2981Upgradeable.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-upgradeable/access/Ownable2StepUpgradeable.sol";
import {BitMaps} from "openzeppelin-contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title Discounted NFT
/// @notice Contract allows minting to addresses in a merkle tree at a discount
contract WhitelistDiscountNFTV2 is
    UUPSUpgradeable,
    Initializable,
    Ownable2StepUpgradeable,
    ERC2981Upgradeable,
    ERC721EnumerableUpgradeable
{
    using BitMaps for BitMaps.BitMap;

    /// @notice emitted on mint at discount
    event DiscountUsed(address indexed sender, uint256 index);
    /// @notice emitted on discount rate update
    event DiscountRateUpdated(uint96 rate);
    /// @notice emitted on royale rate update
    event RoyaltyRateUpdated(uint96 rate);

    /// @dev max discount rate = 100%
    uint256 private constant _MAX_BPS_ = 10000;

    /// @notice merkle root
    bytes32 private merkleRoot;
    /// @notice max total supply of nfts
    uint256 private maxSupply;
    /// @notice price of nfts in wei (without discount)
    uint256 private nftPrice;
    /// @notice discounts claimed, to protect against replay attacks
    BitMaps.BitMap private discountsClaimed;
    /// @notice discount rate in bps, 1% = 100, 0.01% = 1
    uint96 private discountRate;
    /// @notice royalty rate in bps, 2.5% = 250
    uint96 private royaltyRate;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        bytes32 _merkleRoot,
        uint96 _discountRate,
        uint256 _maxSupply,
        uint256 _nftPrice,
        uint96 _royaltyRate
    )
        external initializer
    {
        __Ownable_init(_owner);
        __ERC721_init(_name, _symbol);

        merkleRoot = _merkleRoot;
        maxSupply = _maxSupply;
        nftPrice = _nftPrice;

        updateDiscountRate(_discountRate);
        updateRoyaltyRate(_royaltyRate);
    }

    /// @notice transfer NFTs between accounts forcefully
    function move(address from, address to, uint256 id) external onlyOwner {
        _transfer(from, to, id);
    }

    /// @notice mint nft at a discount
    function mintAtDiscount(bytes32[] memory _proof, uint256 _index) external payable {
        require(msg.value >= getPrice(true), "Value < Price");
        _useDiscount(_proof, msg.sender, _index);
        _beforeMint(msg.sender, totalSupply());
        _mint(msg.sender, totalSupply());
    }

    /// @notice safe mint at a discount
    function safeMintAtDiscount(bytes32[] memory _proof, uint256 _index, bytes memory _data) external payable {
        require(msg.value >= getPrice(true), "Value < Price");
        _useDiscount(_proof, msg.sender, _index);
        _beforeMint(msg.sender, totalSupply());
        _safeMint(msg.sender, totalSupply(), _data);
    }

    /// @notice mint nft
    function mint() external payable {
        require(msg.value >= getPrice(false), "Value < Price");
        _beforeMint(msg.sender, totalSupply());
        _mint(msg.sender, totalSupply());
    }

    /// @notice mint nft
    function safeMint(bytes memory _data) external payable {
        require(msg.value >= getPrice(false), "Value < Price");
        _beforeMint(msg.sender, totalSupply());
        _safeMint(msg.sender, totalSupply(), _data);
    }

    /// @notice withdraw funds from sales
    function withdraw() external onlyOwner returns (bool success) {
        (success,) = msg.sender.call{value: address(this).balance}("");
    }

    /// @notice update discount rate
    /// @dev emits DiscountRateUpdated event
    function updateDiscountRate(uint96 _rate) public onlyOwner {
        require(_rate <= _MAX_BPS_, "Invalid discount rate");
        discountRate = _rate;
        emit DiscountRateUpdated(_rate);
    }

    /// @notice update royalty rate
    /// @dev emits RoyaltyRateUpdated event
    function updateRoyaltyRate(uint96 _rate) public onlyOwner {
        require(_rate <= _MAX_BPS_, "Invalid royalty rate");
        royaltyRate = _rate;
        emit RoyaltyRateUpdated(_rate);
    }

    /// @notice return nft price with or without discount
    function getPrice(bool _withDiscount) public view returns (uint256 price) {
        if (_withDiscount) {
            price = nftPrice * (_MAX_BPS_ - discountRate) / _MAX_BPS_;
        } else {
            price = nftPrice;
        }
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 _interfaceId) public view override(ERC2981Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /// @dev use discount for address `addr` at index `index`
    function _useDiscount(bytes32[] memory _proof, address _addr, uint256 _index) internal {
        require(!discountsClaimed.get(_index), "Already claimed");
        _verifyProof(_proof, _index, _addr);
        discountsClaimed.set(_index);
        emit DiscountUsed(_addr, _index);
    }

    /// @dev verify merkle proof, reverts if proof is invalid
    function _verifyProof(bytes32[] memory _proof, uint256 _index, address _addr) private view {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_addr, _index))));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof");
    }

    /// @dev check that tokenId doesnt go over maxSupply before minting nft
    function _beforeMint(address _to, uint256 _tokenId) internal {
        require(_tokenId < maxSupply, "Max supply reached");
        _setTokenRoyalty(_tokenId, _to, royaltyRate);
    }

    /// @dev authorize upgradeToAndCall() operation, only owner can use that
    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}
}
