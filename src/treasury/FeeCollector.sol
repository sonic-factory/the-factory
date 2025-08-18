//SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@common/FactoryErrors.sol";
import "@common/FactoryEvents.sol";
import "@treasury/interface/IFactory.sol";

/**
 * @title Fee Collector
 * @notice This contract is responsible for collecting fees from the whole protocol.
 */
contract FeeCollector is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    FactoryErrors,
    FactoryEvents
{
    using SafeERC20 for IERC20;
    
    /// @notice Structure to hold factory fee information
    struct FactoryFeeInfo {
        address factory;
        uint256 pendingFees;
        bool success;
    }
    
    /// @notice Treasury address where collected fees are sent
    address public treasury;

    /// @notice Disables the ability to call the initializer
    constructor() {
        _disableInitializers();
    }

    /// @notice Function to initialize the contract.
    /// @param _initialOwner The address of the initial owner of the contract.
    /// @param _treasury The treasury address where fees are sent.
    function initialize(
        address _initialOwner,
        address _treasury
    ) external initializer {
        if(_initialOwner == address(0) || _treasury == address(0)) revert ZeroAddress();
        
        __Ownable_init(_initialOwner);
        __UUPSUpgradeable_init();
        
        treasury = _treasury;
    }

    /// @notice Function to receive ETH from factory contracts
    receive() external payable {}

    /// @notice Collect fees from specified factories
    /// @param factories Array of factory addresses to collect from
    /// @dev Caller is responsible for providing valid factory addresses
    function collectFees(address[] calldata factories) external onlyOwner {
        if(factories.length == 0) revert EmptyFactoryList();
        
        uint256 initialBalance = address(this).balance;
        
        // Collect from all provided factories
        for(uint256 i = 0; i < factories.length; i++) {
            try IFactory(factories[i]).collectFees() {
                // Success - continue
            } catch {
                // Skip failed collections and continue
            }
        }
        
        uint256 collectedAmount = address(this).balance - initialBalance;
        
        if(collectedAmount > 0) {
            // Send to treasury
            (bool success, ) = treasury.call{value: collectedAmount}("");
            require(success, "Treasury transfer failed");
            
            emit FeesCollected(factories, collectedAmount);
        }
    }

    /// @notice Get total pending fees for specific factories
    /// @param factories Array of factory addresses to check
    /// @return total Total pending fees across provided factories
    function getTotalPendingFees(address[] calldata factories) external view returns (uint256 total) {
        for(uint256 i = 0; i < factories.length; i++) {
            try IFactory(factories[i]).pendingFees() returns (uint256 pending) {
                total += pending;
            } catch {
                // Skip factories that don't support pendingFees()
            }
        }
    }

    /// @notice Get individual pending fees for each factory
    /// @param factories Array of factory addresses to check
    /// @return factoryFees Array of FactoryFeeInfo structs with individual balances
    function getFactoryFees(address[] calldata factories) external view returns (FactoryFeeInfo[] memory factoryFees) {
        factoryFees = new FactoryFeeInfo[](factories.length);
        
        for(uint256 i = 0; i < factories.length; i++) {
            factoryFees[i].factory = factories[i];
            
            try IFactory(factories[i]).pendingFees() returns (uint256 pending) {
                factoryFees[i].pendingFees = pending;
                factoryFees[i].success = true;
            } catch {
                factoryFees[i].pendingFees = 0;
                factoryFees[i].success = false;
            }
        }
    }

    /// @notice Emergency function to collect any ETH
    function collectEth() external onlyOwner {
        uint256 balance = address(this).balance;
        if(balance > 0) {
            (bool success, ) = treasury.call{value: balance}("");
            require(success, "Failed to send Ether to treasury");
        }
    }

    /// @notice Emergency function to collect any ERC20 tokens
    /// @param token Address of the token to collect
    function collectTokens(address token) external onlyOwner {
        if(token == address(0)) revert ZeroAddress();
        
        uint256 balance = IERC20(token).balanceOf(address(this));
        if(balance > 0) {
            IERC20(token).safeTransfer(treasury, balance);
        }
    }

    /// @notice Set new treasury address
    /// @param _treasury New treasury address
    function setTreasury(address _treasury) external onlyOwner {
        if(_treasury == address(0)) revert ZeroAddress();
        
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /// @notice Function to authorize the upgrade of the contract.
    /// @dev This function is called by the UUPS proxy to authorize upgrades.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        if(newImplementation == address(0)) revert InvalidImplementationAddress();
    }
}