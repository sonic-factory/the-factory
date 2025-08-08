// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@taxToken/TaxToken.sol";

/**
 * @title Tax Token Factory
 * @notice This is a factory for creating TaxToken contracts.
 * @dev Proxy implementation are Clones. Implementation is immutable and not upgradeable.
 */
contract TaxTokenFactory is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice The address of the token implementation contract.
    address public immutable tokenImplementation;
    /// @notice The address of the treasury where the fees are sent.
    address public treasury;

    /// @notice The fee to create a new token.
    uint256 public creationFee;
    /// @notice The number of tokens created.
    uint256 public tokenCounter;

    /// @notice Mapping from token ID to token address.
    mapping(uint256 tokenId => address tokenAddress) public IdToAddress;

    /// @notice Emitted when a new token is created.
    event TokenCreated(address token, address owner);
    /// @notice Emitted when the treasury address is updated.
    event TreasuryUpdated(address treasury);
    /// @notice Emitted when the creation fee is updated.
    event CreationFeeUpdated(uint256 creationFee);

    /// @notice Thrown when the address set is zero
    error ZeroAddress();
    /// @notice Thrown when the payable amount is zero
    error IncorrectFee();

    /**
     * @notice Constructor arguments for the token factory.
     * @param _tokenImplementation This is the address of the token to be cloned.
     * @param _treasury The multi-sig or contract address where the fees are sent.
     * @param _creationFee The amount to collect for every contract creation.
    */
    constructor(
        address _tokenImplementation,
        address _treasury,
        uint256 _creationFee
    ) Ownable (msg.sender) {
        if (_tokenImplementation == address(0)) revert ZeroAddress();
        if (_treasury == address(0)) revert ZeroAddress();

        tokenImplementation = _tokenImplementation;
        treasury = _treasury;
        creationFee = _creationFee;

        _pause();
    }

    receive() external payable {}

    /**
     * @notice This function is called to create a new token
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param initialSupply The initial supply of the token
     * @param transferTaxRate The transfer tax rate of the token
     * @param taxBeneficiary The address of the tax beneficiary
     * @param developer The address of the developer
    */
    function createToken(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint256 transferTaxRate,
        address taxBeneficiary,
        address developer
    ) external payable whenNotPaused nonReentrant returns (address token) {
        if (developer == address(0) || taxBeneficiary == address(0)) revert ZeroAddress();
        if (msg.value != creationFee) revert IncorrectFee();

        tokenCounter = tokenCounter + 1;

        token = Clones.clone(tokenImplementation);

        TaxToken(token).initialize(
            name,
            symbol,
            initialSupply,
            transferTaxRate,
            taxBeneficiary,
            developer
        );

        IdToAddress[tokenCounter] = token;

        emit TokenCreated(token, msg.sender);
    }

    /// @notice This function sets the treasury address.
    function setTreasury(address _treasury) external onlyOwner {
        if(_treasury == address(0)) revert ZeroAddress();

        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /// @notice This function sets the creation fee.
    function setCreationFee(uint256 _creationFee) external onlyOwner {       
        creationFee = _creationFee;
        emit CreationFeeUpdated(_creationFee);
    }

    /// @notice This function allows the owner to collect the contract balance.
    function collectFees() external onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "TokenFactory: Failed to send Ether");
    }

    /// @notice This function allows the owner to collect foreign tokens sent to the contract.
    function collectTokens(address token) external onlyOwner {
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

    /// @notice This function allows the UI to get a token address by its ID.
    function getTokenById(uint256 tokenId) external view returns (address) {
        return IdToAddress[tokenId];
    }
}