// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

import "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "@common/FactoryErrors.sol";
import "@common/FactoryEvents.sol";

/**
 * @title Vesting
 * @notice This contract allows for the vesting of native or ERC20 tokens to a beneficiary over a specified duration.
 */
contract Vesting is 
    Initializable,
    ReentrancyGuardUpgradeable,
    VestingWalletUpgradeable,
    FactoryErrors,
    FactoryEvents 
{
    /// @notice Disables the initializer function to prevent re-initialization.
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the given token address and unlock time.
    /// @dev _durationSeconds can be zero to mimic a non-vesting locker.
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
    {
        if(_beneficiary == address(0)) revert ZeroAddress();
        if(_startTimestamp < block.timestamp || _startTimestamp == 0) revert InvalidTimestamp();

        __VestingWallet_init(_beneficiary, _startTimestamp, _durationSeconds);
        __ReentrancyGuard_init();
    }

    /// @notice Release the vested ethers to the beneficiary.
    function release() public override nonReentrant onlyOwner {
        if(releasable() == 0) revert NotVested();
        /// @dev Calls the release function from the VestingWalletUpgradeable contract
        super.release();
    }
    
    /// @notice Release the vest ERC20 tokens to the beneficiary.
    /// @param _token The address of the ERC20 token to be released.
    function release(address _token) public override nonReentrant onlyOwner {
        if(_token == address(0)) revert ZeroAddress();
        if(releasable(_token) == 0) revert NotVested();
        /// @dev Calls the release function from the VestingWalletUpgradeable contract
        super.release(_token);
    }

}