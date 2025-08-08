// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

import "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/// @title Vesting
/// @notice This contract allows for the vesting of native or ERC20 tokens to a beneficiary over a specified duration.
contract Vesting is Initializable, ReentrancyGuardUpgradeable, VestingWalletUpgradeable {

    /// @notice Thrown when the address is zero.
    error ZeroAddress();
    /// @notice Thrown when the amount is zero.
    error ZeroAmount();
    /// @notice Thrown when tokens are not vested.
    error NotVested();
    

    /// @notice Modifier to ensure that the amount is not zero.
    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, ZeroAmount());
        _;
    }
    /// @notice Modifier to ensure that the address is not zero.
    modifier nonZeroAddress(address addr) {
        require(addr != address(0), ZeroAddress());
        _;
    }

    /// @notice Disables the initializer function to prevent re-initialization.
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the given token address and unlock time.
    /// @param _beneficiary The address of the beneficiary who will receive the vested tokens.
    /// @param _startTimestamp The timestamp when the vesting starts.
    /// @param _durationSeconds The duration in seconds for which the tokens will be vested.
    function initialize(
        address _beneficiary,
        uint64 _startTimestamp,
        uint64 _durationSeconds
    )
        public
        override 
        initializer
        nonZeroAddress(_beneficiary)
        nonZeroAmount(_startTimestamp)
        nonZeroAmount(_durationSeconds)
    {
        __VestingWallet_init(_beneficiary, _startTimestamp, _durationSeconds);
        __ReentrancyGuard_init();
    }

    /// @notice Release the vested ethers to the beneficiary.
    function release() public override nonReentrant onlyOwner {
        require(releasable() > 0, NotVested());
        /// @dev Calls the release function from the VestingWalletUpgradeable contract
        super.release();
    }

    /// @notice Release the vest ERC20 tokens to the beneficiary.
    /// @param _token The address of the ERC20 token to be released.
    function release(address _token) public override nonReentrant onlyOwner nonZeroAddress(_token) {
        require(releasable(_token) > 0, NotVested());
        /// @dev Calls the release function from the VestingWalletUpgradeable contract
        super.release(_token);
    }

}