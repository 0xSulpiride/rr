// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title Discounted NFT
/// @notice Contract allows minting to addresses in a merkle tree at a discount
contract WhitelistDiscountNFT is Ownable2Step, ERC2981, ERC721Enumerable {
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
    bytes32 private immutable merkleRoot;
    /// @notice max total supply of nfts
    uint256 private immutable maxSupply;
    /// @notice price of nfts in wei (without discount)
    uint256 private immutable nftPrice;
    /// @notice discounts claimed, to protect against replay attacks
    BitMaps.BitMap private discountsClaimed;
    /// @notice discount rate in bps, 1% = 100, 0.01% = 1
    uint96 private discountRate;
    /// @notice royalty rate in bps, 2.5% = 250
    uint96 private royaltyRate;

    constructor(
        string memory _name,
        string memory _symbol,
        bytes32 _merkleRoot,
        uint96 _discountRate,
        uint256 _maxSupply,
        uint256 _nftPrice,
        uint96 _royaltyRate
    ) Ownable(msg.sender) ERC721(_name, _symbol) {
        merkleRoot = _merkleRoot;
        maxSupply = _maxSupply;
        nftPrice = _nftPrice;

        updateDiscountRate(_discountRate);
        updateRoyaltyRate(_royaltyRate);
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
    function supportsInterface(bytes4 _interfaceId) public view override(ERC2981, ERC721Enumerable) returns (bool) {
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
}
