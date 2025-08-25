//SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Registration-Based Airdrop
 * @notice Users register on-chain, then claim tokens based on their registration.
 */
contract RegistrationAirdrop is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice The ERC20 token being airdropped.
    IERC20 public immutable token;
    
    /// @notice Registration phase status
    bool public registrationOpen;
    /// @notice Claim phase status  
    bool public claimingOpen;
    
    /// @notice Fixed amount per user or dynamic calculation
    uint256 public baseAmount;
    
    /// @notice Total tokens allocated for airdrop
    uint256 public totalAllocated;
    /// @notice Total registered users
    uint256 public totalRegistered;
    
    /// @notice User registration data
    struct UserData {
        bool isRegistered;
        bool hasClaimed;
        uint256 amount;
        uint256 registrationTime;
    }
    
    /// @notice Mapping of user address to their data
    mapping(address => UserData) public users;
    
    /// @notice Array of registered addresses (for admin purposes)
    address[] private registeredUsers;

    /// @notice Thrown when user registration is already closed.
    error RegistrationClosed();
    /// @notice Thrown when claiming is already closed.
    error ClaimingClosed();
    /// @notice Thrown when user is already registered.
    error AlreadyRegistered();
    /// @notice Thrown when user is not registered.
    error NotRegistered();
    /// @notice Thrown when user has already claimed.
    error AlreadyClaimed();
    /// @notice Thrown when address is zero.
    error ZeroAddress();
    /// @notice Thrown when amount is zero.
    error ZeroAmount();
    /// @notice Thrown when contract has insufficient funds for claim.
    error InsufficientFunds();

    /// @notice Emitted when a user registers.
    event UserRegistered(address indexed user, uint256 amount, uint256 timestamp);
    /// @notice Emitted when a user claims their tokens.
    event Claimed(address indexed user, uint256 amount);
    /// @notice Emitted when registration status changes.
    event RegistrationStatusChanged(bool isOpen);
    /// @notice Emitted when claiming status changes.
    event ClaimingStatusChanged(bool isOpen);
    /// @notice Emitted when base amount changes.
    event BaseAmountChanged(uint256 newAmount);
    /// @notice Emitted when owner withdraws tokens.
    event TokensWithdrawn(address indexed owner, uint256 amount);

    /// @notice Constructor to initialize the airdrop contract
    /// @param _token The ERC20 token address to be airdropped
    /// @param _owner The owner address with admin privileges
    /// @param _baseAmount The base amount allocated per user
    constructor(
        address _token,
        address _owner,
        uint256 _baseAmount
    ) Ownable(_owner) {
        if (_token == address(0) || _owner == address(0)) revert ZeroAddress();
        if (_baseAmount == 0) revert ZeroAmount();

        token = IERC20(_token);
        baseAmount = _baseAmount;
        registrationOpen = false;
        claimingOpen = false;
    }

    /// @notice Register for the airdrop
    function register() external {
        if (!registrationOpen) revert RegistrationClosed();
        if (users[msg.sender].isRegistered) revert AlreadyRegistered();

        uint256 userAmount = _calculateAllocation(msg.sender);
        
        users[msg.sender] = UserData({
            isRegistered: true,
            hasClaimed: false,
            amount: userAmount,
            registrationTime: block.timestamp
        });
        
        registeredUsers.push(msg.sender);
        totalRegistered++;
        totalAllocated += userAmount;

        emit UserRegistered(msg.sender, userAmount, block.timestamp);
    }

    /// @notice Claim tokens after registration
    function claim() external nonReentrant {
        if (!claimingOpen) revert ClaimingClosed();
        if (!users[msg.sender].isRegistered) revert NotRegistered();
        if (users[msg.sender].hasClaimed) revert AlreadyClaimed();

        uint256 amount = users[msg.sender].amount;
        if (amount == 0) revert ZeroAmount();

        if (token.balanceOf(address(this)) < amount) revert InsufficientFunds();

        users[msg.sender].hasClaimed = true;

        token.safeTransfer(msg.sender, amount);

        emit Claimed(msg.sender, amount);
    }

    /// @notice Calculate allocation for a user
    function _calculateAllocation(address user) internal view returns (uint256) {

        // TODO: Implement dynamic allocation logic here.
        
        return baseAmount;
    }

    /// @notice Batch register multiple users
    function batchRegister(address[] calldata addresses, uint256[] calldata amounts) 
        external onlyOwner {
        if (addresses.length != amounts.length) revert("Array length mismatch");
        
        for (uint256 i = 0; i < addresses.length; i++) {
            if (!users[addresses[i]].isRegistered) {
                users[addresses[i]] = UserData({
                    isRegistered: true,
                    hasClaimed: false,
                    amount: amounts[i],
                    registrationTime: block.timestamp
                });
                
                registeredUsers.push(addresses[i]);
                totalRegistered++;
                totalAllocated += amounts[i];
                
                emit UserRegistered(addresses[i], amounts[i], block.timestamp);
            }
        }
    }

    /// @notice Toggle registration phase
    /// @param _isOpen True to open registration, false to close
    function setRegistrationStatus(bool _isOpen) external onlyOwner {
        registrationOpen = _isOpen;
        emit RegistrationStatusChanged(_isOpen);
    }

    /// @notice Toggle claiming phase
    /// @param _isOpen True to open claiming, false to close
    function setClaimingStatus(bool _isOpen) external onlyOwner {
        claimingOpen = _isOpen;
        emit ClaimingStatusChanged(_isOpen);
    }

    /// @notice Update base amount for new registrations
    /// @param _baseAmount New base amount
    function setBaseAmount(uint256 _baseAmount) external onlyOwner {
        if (_baseAmount == 0) revert ZeroAmount();
        baseAmount = _baseAmount;
        emit BaseAmountChanged(_baseAmount);
    }

    /// @notice Withdraw tokens from contract
    /// @param _amount Amount to withdraw
    function withdrawToken(uint256 _amount) external onlyOwner {
        if (_amount == 0) revert ZeroAmount();
        token.safeTransfer(owner(), _amount);
        emit TokensWithdrawn(owner(), _amount);
    }

    /// @notice Get user registration data
    /// @param user The address of the user
    function getUserData(address user) external view returns (UserData memory) {
        return users[user];
    }

    /// @notice Check if user can claim
    /// @param user The address of the user
    function canClaim(address user) external view returns (bool) {
        return claimingOpen && 
               users[user].isRegistered && 
               !users[user].hasClaimed &&
               users[user].amount > 0;
    }

    /// @notice Get all registered users
    /// @param offset The starting index
    /// @param limit The maximum number of users to return
    function getRegisteredUsers(uint256 offset, uint256 limit) 
        external view returns (address[] memory) {
        if (offset >= registeredUsers.length) {
            return new address[](0);
        }
        
        uint256 end = offset + limit;
        if (end > registeredUsers.length) {
            end = registeredUsers.length;
        }
        
        address[] memory result = new address[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            result[i - offset] = registeredUsers[i];
        }
        
        return result;
    }

    /// @notice Get contract stats
    function getStats() external view returns (
        uint256 _totalRegistered,
        uint256 _totalAllocated,
        uint256 _contractBalance,
        bool _registrationOpen,
        bool _claimingOpen
    ) {
        return (
            totalRegistered,
            totalAllocated,
            token.balanceOf(address(this)),
            registrationOpen,
            claimingOpen
        );
    }
}