//SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

abstract contract FactoryErrors {

    /**
     * COMMON ERRORS
     */
    /// @notice Thrown when the address is zero.
    error ZeroAddress();
    /// @notice Thrown when the amount is zero.
    error ZeroAmount();
    /// @notice Thrown when the payable amount is invalid
    error InvalidFee();
    /// @notice Thrown when the address is invalid
    error InvalidAddress();
    /// @notice Error thrown when an invalid implementation address is provided.
    error InvalidImplementationAddress();
    /// @notice Thrown when the caller is not the collector.
    error InvalidCollector();
    /// @notice Thrown when the input is invalid
    error InputCannotBeNull();

    /** 
     * VESTING ERRORS
     */
    /// @notice Thrown when tokens are not vested.
    error NotVested();
    /// @notice Thrown when the start timestamp is not in the future
    error InvalidTimestamp();

    /**
     * NFT ERRORS
     */
    /// @notice Error thrown when metadata is locked.
    error MetadataAlreadyLocked();

    /**
     * TOKEN ERRORS
     */
    /// @notice Thrown when the tax rate exceeds the maximum tax rate
    error TaxRateExceedsMax();

    /**
     * FEE COLLECTOR ERRORS
     */
    /// @notice Error thrown when empty factory list provided
    error EmptyFactoryList();
    /// @notice Error thrown when insufficient fees to collect
    error InsufficientFees();
}