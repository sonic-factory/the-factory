// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@standardNFT/StandardNFT.sol";

/**
 * @title Standard NFT Factory
 * @notice This is a factory for creating standard NFT contracts.
 * @dev Proxy implementation are Clones. Implementation is immutable and not upgradeable.
 */
contract StandardNFTFactory is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Information of each NFT
    struct NFTInfo {
        address nftAddress;
        address creator;
        uint256 nftId;
    }

    /// @notice The address of the NFT implementation contract.
    address public immutable nftImplementation;
    /// @notice The address of the treasury where the fees are sent.
    address public treasury;
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

    /// @notice Emitted when a new NFT is created.
    event NFTCreated(
        address indexed nft,
        address indexed creator,
        uint256 indexed nftId
    );
    /// @notice Emitted when the treasury address is updated.
    event TreasuryUpdated(address treasury);
    /// @notice Emitted when the creation fee is updated.
    event CreationFeeUpdated(uint256 creationFee);

    /// @notice Thrown when the address set is zero
    error ZeroAddress();
    /// @notice Thrown when the amount set is zero
    error ZeroAmount();
    /// @notice Thrown when the payable amount is invalid
    error InvalidFee();
    /// @notice Thrown when the input is invalid
    error InputCannotBeNull();

    /**
     * @notice Constructor arguments for the NFT factory.
     * @param _nftImplementation This is the address of the NFT to be cloned.
     * @param _treasury The multi-sig or contract address where the fees are sent.
     * @param _owner The owner of the factory contract.
     * @param _creationFee The amount to collect for every contract creation.
    */
    constructor(
        address _nftImplementation,
        address _treasury,
        address _owner,
        uint256 _creationFee
    ) Ownable (_owner) {
        require(
            _nftImplementation != address(0) && 
            _treasury != address(0) &&
            _owner != address(0),
            ZeroAddress()
        );

        nftImplementation = _nftImplementation;
        treasury = _treasury;
        creationFee = _creationFee;

        _pause();
    }

    /// @notice This function allows the contract to receive Ether.
    receive() external payable {}

    /**
     * @notice This function is called to create a new NFT contract.
     * @param _name The name of the NFT.
     * @param _symbol The symbol of the NFT.
     * @param baseURI The base URI for the NFT metadata.
    */
    function createNFT(
        string memory _name,
        string memory _symbol,
        string memory baseURI
    ) external payable whenNotPaused nonReentrant returns (address nft) {
        require(
            bytes(_name).length > 0 && 
            bytes(_symbol).length > 0 && 
            bytes(baseURI).length > 0,
            InputCannotBeNull()
        );
        require(msg.value >= creationFee, InvalidFee());

        uint256 excessEth = msg.value - creationFee;

        if (creationFee > 0) {
            (bool success, ) = treasury.call{value: creationFee}("");
            require(success, "Fee transfer failed");
        }

        if (excessEth > 0) {
            (bool success, ) = msg.sender.call{value: excessEth}("");
            require(success, "Excess Ether refund failed");
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

    /// @notice This function sets the treasury address.
    /// @param _treasury The address of the treasury to set.
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), ZeroAddress());

        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /// @notice This function sets the creation fee.
    /// @param _creationFee The amount to set as the creation fee.
    function setCreationFee(uint256 _creationFee) external onlyOwner {       
        creationFee = _creationFee;
        emit CreationFeeUpdated(_creationFee);
    }

    /// @notice This function allows the owner to collect foreign tokens sent to the contract.
    /// @param token The address of the token to collect.
    function collectTokens(address token) external onlyOwner {
        require(token != address(0), ZeroAddress());
        require(IERC20(token).balanceOf(address(this)) > 0, ZeroAmount());

        IERC20(token).safeTransfer(treasury, IERC20(token).balanceOf(address(this)));
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

    /// @notice Get all lockers created by a specific creator.
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