// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@standardERC20/StandardERC20.sol";

/**
 * @title Standard ERC20 Factory
 * @notice This contract clones a standard ERC20 token implementation.
 * @dev Proxy implementation are Clones. Implementation is immutable and not upgradeable.
 */
contract StandardERC20Factory is 
    Ownable,
    Pausable,
    ReentrancyGuard,
    FactoryErrors,
    FactoryEvents
{
    using SafeERC20 for IERC20;

    /// @notice The address of the token implementation contract
    address public immutable tokenImplementation;
    /// @notice The treasury address
    address public treasury;
    /// @notice Array for the tokens created on the platform.
    address[] public tokens;
    /// @notice The fee to be paid when creating a token.
    uint256 public creationFee;
    /// @notice The count of tokens created by the platform.
    uint256 public tokenCounter;

    /// @notice The mapping for the token ID and token address.
    mapping(uint256 tokenId => address tokenAddress) public IdToAddress;

    /// @notice Constructor arguments for the token factory.
    /// @param _tokenImplementation This is the address of the token to be cloned.
    /// @param _treasury The multi-sig or contract address where the fees are sent.
    /// @param _creationFee The amount to collect for every contract creation.
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

    /// @notice This function allows the contract to receive ETH. 
    receive() external payable {}

    /// @notice This function is called to create a new token
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param initialSupply The initial supply of the token
    /// @param developer The address of the developer
    function createToken(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address developer
    ) external payable whenNotPaused nonReentrant {
        if (developer == address(0)) revert ZeroAddress();
        if (msg.value != creationFee) revert InvalidFee();

        tokenCounter = tokenCounter + 1;

        address token = Clones.clone(tokenImplementation);

        StandardERC20(token).initialize(name, symbol, initialSupply, msg.sender);

        tokens.push(token);
        IdToAddress[tokenCounter] = token;

        emit TokenCreated(token, msg.sender);
    }

    /// @notice This function sets the treasury address.
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "TokenFactory: treasury is the zero address");

        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /// @notice This function sets the creation fee.
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

    /// @notice This function allows the UI to get all the tokens created by the factory.
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    /// @notice This function allows the UI to get a token address by its ID.
    function getTokenById(uint256 tokenId) external view returns (address) {
        return IdToAddress[tokenId];
    }
}