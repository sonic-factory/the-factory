//SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@standardYield/StandardYieldFarm.sol";
import "@common/CollectorHelper.sol";

/**
 * @title Standard Yield Farm Factory
 * @notice This is a factory for creating Standard Yield Farm contracts.
 * @dev Proxy implementation are Clones. Implementation is immutable and not upgradeable.
 */
contract StandardYieldFarmFactory is 
    Ownable,
    Pausable, 
    ReentrancyGuard,
    FactoryErrors,
    FactoryEvents,
    CollectorHelper
{
    using SafeERC20 for IERC20;

    /// @notice Information of each yield farm.
    struct YieldFarmInfo {
        address yieldFarmAddress;
        address creator;
        uint64 startTimestamp;
        uint64 durationSeconds;
        uint256 yieldFarmId;
    }

    /// @notice The address of the standard yield farm implementation contract.
    address public immutable yieldFarmImplementation;
    /// @notice The address of the standard token implementation contract.
    address public immutable tokenImplementation;
    /// @notice The fee to create a new yield farm.
    uint256 public creationFee;
    /// @notice The number of yield farms created.
    uint256 internal yieldFarmCounter;

    /// @notice Mapping from yield farm ID to yield farm address.
    mapping(uint256 yieldFarmId => address yieldFarmAddress) internal IdToAddress;
    /// @notice Mapping from creator address to their yield farm addresses.
    mapping(address creator => address[] yieldFarm) internal creatorToYieldFarms;
    /// @notice Mapping from yield farm address to its registry information.
    mapping(address yieldFarm => YieldFarmInfo info) internal yieldFarmInfo;

    /**
     * @notice Constructor arguments for the yield farm factory.
     * @param _yieldFarmImplementation This is the address of the yield farm to be cloned.
     * @param _initialOwner The initial owner of the factory.
     * @param _feeCollector The address that will collect the creation fees.
     * @param _creationFee The amount to collect for every contract creation.
     */
    constructor(
        address _yieldFarmImplementation,
        address _initialOwner,
        address _feeCollector,
        uint256 _creationFee
    ) Ownable(_initialOwner) CollectorHelper(_feeCollector) {
        if(_yieldFarmImplementation == address(0)) revert ZeroAddress();

        yieldFarmImplementation = _yieldFarmImplementation;
        creationFee = _creationFee;

        _pause();
    }

    /// @notice This function allows the contract to receive ETH.
    receive() external payable {}

    /**
     * @notice This function is called to create a new yield farm contract.
     * @param _startTimestamp The timestamp when the vesting starts.
     * @param _durationSeconds The duration in seconds for which the tokens will be vested.
     * @param _isNative A boolean indicating if the locker is for native tokens.
     * @param _token The address of the token to be vested (if not native).
     * @param _amount The amount of tokens to be vested. 
    */
    function createYieldFarm(
        uint64 _startTimestamp,
        uint64 _durationSeconds,
        bool _isNative,
        address _token,
        uint256 _amount
    ) external payable whenNotPaused nonReentrant returns (address payable yieldFarm) {
        if(_startTimestamp < block.timestamp) revert InvalidTimestamp();
        if(msg.value < creationFee) revert InvalidFee();

        yieldFarmCounter = yieldFarmCounter + 1;

        yieldFarm = payable(Clones.clone(yieldFarmImplementation));

        StandardYieldFarm(yieldFarm).initialize(
            msg.sender,
            _startTimestamp,
            _durationSeconds
        );

        IdToAddress[yieldFarmCounter] = yieldFarm;
        creatorToYieldFarms[msg.sender].push(yieldFarm);

        yieldFarmInfo[yieldFarm] = YieldFarmInfo({
            yieldFarmAddress: yieldFarm,
            creator: msg.sender,
            startTimestamp: _startTimestamp,
            durationSeconds: _durationSeconds,
            yieldFarmId: yieldFarmCounter
        });

        if (_isNative == true) {
            // Transfer ETH to the yield farm if it is native.
            require(msg.value >= (creationFee + _amount), InvalidFee());

            (bool success, ) = yieldFarm.call{value: _amount}("");
            require(success, "Failed to send ETH");

            // Refund excess ETH if any.
            uint256 excessNative = msg.value - (creationFee + _amount);
            if (excessNative > 0) {
                (bool excessSuccess, ) = msg.sender.call{value: excessNative}("");
                require(excessSuccess, "Failed to refund excess ETH");
            }
        } else {
            // Transfer tokens to the yield farm if not native.
            require(_token != address(0), InvalidAddress());
            require(_amount > 0, ZeroAmount());

            IERC20(_token).safeTransferFrom(msg.sender, yieldFarm, _amount);

            // Refund excess ETH if any.
            uint256 excessNative = msg.value - creationFee;
            if (excessNative > 0) {
                (bool excessSuccess, ) = msg.sender.call{value: excessNative}("");
                require(excessSuccess, "Failed to refund excess ETH");
            }
        }

        emit YieldFarmCreated(yieldFarm, msg.sender, _startTimestamp, _durationSeconds, yieldFarmCounter);
    }

    /// @notice This function sets the creation fee.
    /// @param _creationFee The amount to set as the creation fee.
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

    /// @notice Get the total number of yield farms created.
    function getTotalLockers() external view returns (uint256) {
        return yieldFarmCounter;
    }

    /// @notice  Get the yield farm address by its ID.
    /// @param yieldFarmId The ID of the yield farm to retrieve.
    function getLockerById(uint256 yieldFarmId) external view returns (address) {
        return IdToAddress[yieldFarmId];
    }

    /// @notice Get all yield farms created by a specific creator.
    /// @param creator The address of the creator to retrieve yield farms for.
    function getLockersByCreator(address creator) external view returns (address[] memory) {
        return creatorToYieldFarms[creator];
    }

    /// @notice Get the yield farm information by its address.
    /// @param yieldFarm The address of the yield farm to retrieve information for.
    function getLockerInfo(address yieldFarm) external view returns (YieldFarmInfo memory) {
        return yieldFarmInfo[yieldFarm];
    }

    /// @notice Validates if the yield farm address is valid.
    /// @param yieldFarm The address of the yield farm to validate.
    function isValidLocker(address yieldFarm) external view returns (bool) {
        return yieldFarmInfo[yieldFarm].yieldFarmAddress == yieldFarm;
    }
}