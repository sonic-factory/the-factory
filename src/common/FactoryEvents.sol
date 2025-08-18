//SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

abstract contract FactoryEvents {
    
  /**
    * COMMON EVENTS
    */
  /// @notice Emitted when a new fee collector is set.
  event FeeCollectorUpdated(address indexed feeCollector);
  /// @notice Emitted when a new creation fee is set.
  event CreationFeeUpdated(uint256 creationFee);

  /**
   * YIELD FARM EVENTS
   */
  /// @notice Emitted when a new yield farm is created.
  event YieldFarmCreated(
    address indexed yieldFarm, 
    address indexed creator,
    address feeAddress,
    uint256 rewardPerSec,
    uint64 startTimestamp
  );
  /// @notice Emitted when a user deposits into a yield farm.
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  /// @notice Emitted when a user withdraws from a yield farm.
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  /// @notice Emitted when a user emergency withdraws from a yield farm.
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
  /// @notice Emitted when the fee address is set.
  event SetFeeAddress(address indexed user, address indexed newAddress);
  /// @notice Emitted when the dev address is set.
  event SetDevAddress(address indexed user, address indexed newAddress);
  /// @notice Emitted when the emission rate is updated.
  event UpdateEmissionRate(address indexed user, uint256 rewardPerSecond);

  /**
    * VESTING EVENTS
    */
  /// @notice Emitted when a new vesting contract is created.
  event LockerCreated(
    address indexed locker, 
    address indexed creator,
    uint64 startTimestamp,
    uint64 durationSeconds,
    uint256 lockerId
  );
  
  /**
    * NFT EVENTS
    */
  /// @notice Event emitted when metadata is locked.
  event MetadataLocked();
  /// @notice Emitted when a new NFT is created.
  event NFTCreated(address indexed nft, address indexed creator, uint256 nftId);

  /**
    * TOKEN EVENTS
    */
  /// @notice Event emitted when a token is created on the platform.
  event TokenCreated(address indexed token, address indexed owner);
  /// @notice Event emitted when a tax token is created on the platform.
  event TaxTokenCreated(address indexed taxToken, address indexed owner);
  /// @notice Event emitted when the transfer tax rate is updated.
  event TransferTaxRateUpdated(address indexed owner, uint256 newRate);
  /// @notice Event emitted when the tax beneficiary address is updated.
  event TaxBeneficiaryUpdated(address indexed owner, address indexed taxBeneficiary);
  /// @notice Event emitted when a no tax sender address is set.
  event SetNoTaxSenderAddr(address indexed owner, address indexed noTaxSenderAddr, bool _value);
  /// @notice Event emitted when a no tax recipient address is set.
  event SetNoTaxRecipientAddr(address indexed owner, address indexed noTaxRecipientAddr, bool _value);

  /**
    * FEE COLLECTOR EVENTS
    */
  /// @notice Emitted when fees are collected from factories
  event FeesCollected(address[] factories, uint256 totalAmount);
  /// @notice Emitted when treasury is updated
  event TreasuryUpdated(address indexed newTreasury);
  /// @notice Emitted when collection threshold is updated
  event CollectionThresholdUpdated(uint256 newThreshold);
}