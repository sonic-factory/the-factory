//SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Fee Collector
 * @dev This contract is responsible for collecting fees from the whole protocol.
 */
contract FeeCollector is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    /// @notice Error thrown when an invalid implementation address is provided.
    error InvalidImplementationAddress();

    /// @dev Prevents the contract from being initialized again.
    constructor() {
        _disableInitializers();
    }

    /// @notice Function to initialize the contract.
    /// @param _initialOwner The address of the initial owner of the contract.
    /// @dev This function can only be called once during the contract's lifetime.
    function initialize(address _initialOwner) external initializer {
        __Ownable_init(_initialOwner);
        __UUPSUpgradeable_init();
    }


    /// TODO: Add the fee collection logic here.


    /// @notice Function to authorize the upgrade of the contract.
    /// @dev This function is called by the UUPS proxy to authorize upgrades.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // Only the owner can authorize upgrades
        if(newImplementation == address(0)) revert InvalidImplementationAddress();
    }



}