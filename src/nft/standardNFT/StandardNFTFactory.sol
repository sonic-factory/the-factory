// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@standardNFT/StandardNFT.sol";
import "@common/CollectorHelper.sol";

/**
 * @title Standard NFT Factory
 * @notice This is a factory for creating standard NFT contracts.
 * @dev Proxy implementation are Clones. Implementation is immutable and not upgradeable.
 */
contract StandardNFTFactory is 
    Pausable,
    ReentrancyGuard,
    FactoryErrors,
    FactoryEvents,
    CollectorHelper
{
    using SafeERC20 for IERC20;

    /// @notice Information of each NFT
    struct NFTInfo {
        address nftAddress;
        address creator;
        uint256 nftId;
    }

    /// @notice The address of the NFT implementation contract.
    address public immutable nftImplementation;
    /// @notice The fee to create a new NFT.
    uint256 public creationFee;
    /// @notice The number of NFTs created.
    uint256 internal nftCounter;

    /// @notice Mapping from NFT ID to NFT address.
    mapping(uint256 nftId => address nftAddress) internal IdToAddress;
    /// @notice Mapping from creator address to their NFT addresses.
    mapping(address creator => address[] nfts) internal creatorToNFT;
    /// @notice Mapping from NFT address to its registry information.
    mapping(address nft => NFTInfo info) internal nftInfo;

    /// @notice Constructor arguments for the NFT factory.
    /// @param _nftImplementation This is the address of the NFT to be cloned.
    /// @param _initialOwner The owner of the factory contract.
    /// @param _feeCollector The multi-sig or contract address where the fees are sent.
    /// @param _creationFee The amount to collect for every contract creation.
    constructor(
        address _nftImplementation,
        address _initialOwner,
        address _feeCollector,
        uint256 _creationFee
    ) CollectorHelper (_initialOwner, _feeCollector) {
        if(_nftImplementation == address(0)) revert ZeroAddress();

        nftImplementation = _nftImplementation;
        creationFee = _creationFee;

        _pause();
    }

    /// @notice This function allows the contract to receive ETH.
    receive() external payable {}

    /// @notice This function is called to create a new NFT contract.
    /// @param _name The name of the NFT.
    /// @param _symbol The symbol of the NFT.
    /// @param baseURI The base URI for the NFT metadata.
    function createNFT(
        string memory _name,
        string memory _symbol,
        string memory baseURI
    ) external payable whenNotPaused nonReentrant returns (address nft) {
        if(
            bytes(_name).length < 0 || 
            bytes(_symbol).length < 0 || 
            bytes(baseURI).length < 0
        ) revert InputCannotBeNull();
        if(msg.value < creationFee) revert InvalidFee();

        uint256 excessEth = msg.value - creationFee;

        if (excessEth > 0) {
            (bool success, ) = msg.sender.call{value: excessEth}("");
            require(success, "Failed to refund excess ETH");
        }

        nftCounter = nftCounter + 1;

        nft = payable(Clones.clone(nftImplementation));
        
        StandardNFT(nft).initialize(
            _name,
            _symbol,
            baseURI,
            msg.sender
        );

        IdToAddress[nftCounter] = nft;
        creatorToNFT[msg.sender].push(nft);

        nftInfo[nft] = NFTInfo({
            nftAddress: nft,
            creator: msg.sender,
            nftId: nftCounter
        });

        emit NFTCreated(nft, msg.sender, nftCounter);
    }

    /// @notice This function sets the creation fee.
    /// @param _creationFee The amount to set as the creation fee.
    function setCreationFee(uint256 _creationFee) external onlyOwner {       
        creationFee = _creationFee;
        emit CreationFeeUpdated(_creationFee);
    }

    /// @notice This function allows the owner to pause the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice This function allows the owner to unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Get the total number of NFTs created.
    function getTotalNFT() external view returns (uint256) {
        return nftCounter;
    }

    /// @notice  Get the NFT address by its ID.
    /// @param nftId The ID of the NFT to retrieve.
    function getNFTById(uint256 nftId) external view returns (address) {
        return IdToAddress[nftId];
    }

    /// @notice Get all NFT created by a specific creator.
    /// @param creator The address of the creator to retrieve lockers for.
    function getNFTByCreator(address creator) external view returns (address[] memory) {
        return creatorToNFT[creator];
    }

    /// @notice Get the NFT information by its address.
    /// @param nft The address of the NFT to retrieve information for.
    function getNFTInfo(address nft) external view returns (NFTInfo memory) {
        return nftInfo[nft];
    }

    /// @notice Validates if the NFT address is valid.
    /// @param nft The address of the NFT to validate.
    function isValidNFT(address nft) external view returns (bool) {
        return nft != address(0) && nftInfo[nft].nftAddress == nft;
    }
}