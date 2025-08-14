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
 * @dev This contract is responsible for collecting fees from the whole protocol.
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
    /// @notice Minimum ETH threshold to trigger collection (if not owner)
    uint256 public collectionThreshold;

    /// @dev Prevents the contract from being initialized again.
    constructor() {
        _disableInitializers();
    }

    /// @notice Function to initialize the contract.
    /// @param _initialOwner The address of the initial owner of the contract.
    /// @param _treasury The treasury address where fees are sent.
    /// @param _collectionThreshold Minimum ETH amount for non-owner collections.
    function initialize(
        address _initialOwner,
        address _treasury,
        uint256 _collectionThreshold
    ) external initializer {
        if(_initialOwner == address(0) || _treasury == address(0)) revert ZeroAddress();
        
        __Ownable_init(_initialOwner);
        __UUPSUpgradeable_init();
        
        treasury = _treasury;
        collectionThreshold = _collectionThreshold;
    }

    /// @notice Function to receive ETH from factory contracts
    receive() external payable {}

    /// @notice Collect fees from specified factories
    /// @param factories Array of factory addresses to collect from
    /// @dev Caller is responsible for providing valid factory addresses
    function collectFees(address[] calldata factories) external {
        if(factories.length == 0) revert EmptyFactoryList();
        
        // Only check threshold if not owner
        if(msg.sender != owner()) {
            uint256 totalPending = getTotalPendingFees(factories);
            if(totalPending < collectionThreshold) revert InsufficientFees();
        }
        
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
    function getTotalPendingFees(address[] calldata factories) public view returns (uint256 total) {
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

    /// @notice Get balances for factories that implement balance checking
    /// @param factories Array of factory addresses to check
    /// @return factoryBalances Array of FactoryFeeInfo structs with ETH balances
    function getFactoryBalances(address[] calldata factories) external view returns (FactoryFeeInfo[] memory factoryBalances) {
        factoryBalances = new FactoryFeeInfo[](factories.length);
        
        for(uint256 i = 0; i < factories.length; i++) {
            factoryBalances[i].factory = factories[i];
            factoryBalances[i].pendingFees = factories[i].balance;
            factoryBalances[i].success = true; // Balance is always accessible
        }
    }

    /// @notice Get detailed fee information for factories with filtering options
    /// @param factories Array of factory addresses to check
    /// @param minAmount Minimum amount to include in results (0 for all)
    /// @return filteredFees Array of factories with fees >= minAmount
    function getFilteredFactoryFees(
        address[] calldata factories, 
        uint256 minAmount
    ) external view returns (FactoryFeeInfo[] memory filteredFees) {
        // First pass: count valid entries
        uint256 validCount = 0;
        FactoryFeeInfo[] memory tempFees = new FactoryFeeInfo[](factories.length);
        
        for(uint256 i = 0; i < factories.length; i++) {
            uint256 pending = 0;
            bool success = false;
            
            try IFactory(factories[i]).pendingFees() returns (uint256 _pending) {
                pending = _pending;
                success = true;
            } catch {
                // Try direct balance check as fallback
                pending = factories[i].balance;
                success = true;
            }
            
            if(pending >= minAmount) {
                tempFees[validCount] = FactoryFeeInfo({
                    factory: factories[i],
                    pendingFees: pending,
                    success: success
                });
                validCount++;
            }
        }
        
        // Second pass: create properly sized array
        filteredFees = new FactoryFeeInfo[](validCount);
        for(uint256 i = 0; i < validCount; i++) {
            filteredFees[i] = tempFees[i];
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

    /// @notice Set new collection threshold
    /// @param _threshold New threshold amount
    function setCollectionThreshold(uint256 _threshold) external onlyOwner {
        
        collectionThreshold = _threshold;
        emit CollectionThresholdUpdated(_threshold);
    }

    /// @notice Function to authorize the upgrade of the contract.
    /// @dev This function is called by the UUPS proxy to authorize upgrades.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        if(newImplementation == address(0)) revert InvalidImplementationAddress();
    }
}