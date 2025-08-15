// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@vesting/Vesting.sol";
import "@common/CollectorHelper.sol";

/**
 * @title Vesting Factory
 * @notice This is a factory for creating Vesting contracts.
 * @dev Proxy implementation are Clones. Implementation is immutable and not upgradeable.
 */
contract VestingFactory is 
    Pausable, 
    ReentrancyGuard,
    FactoryErrors,
    FactoryEvents,
    CollectorHelper
{
    using SafeERC20 for IERC20;

    /// @notice Information of each locker
    struct LockerInfo {
        address lockerAddress;
        address creator;
        uint64 startTimestamp;
        uint64 durationSeconds;
        uint256 lockerId;
    }

    /// @notice The address of the locker implementation contract.
    address public immutable lockerImplementation;
    /// @notice The fee to create a new locker.
    uint256 public creationFee;
    /// @notice The number of lockers created.
    uint256 internal lockerCounter;

    /// @notice Mapping from locker ID to locker address.
    mapping(uint256 lockerId => address lockerAddress) internal IdToAddress;
    /// @notice Mapping from creator address to their locker addresses.
    mapping(address creator => address[] lockers) internal creatorToLockers;
    /// @notice Mapping from locker address to its registry information.
    mapping(address locker => LockerInfo info) internal lockerInfo;

    /**
     * @notice Constructor arguments for the locker factory.
     * @param _lockerImplementation This is the address of the locker to be cloned.
     * @param _initialOwner The initial owner of the factory.
     * @param _feeCollector The address that will collect the creation fees.
     * @param _creationFee The amount to collect for every contract creation.
     */
    constructor(
        address _lockerImplementation,
        address _initialOwner,
        address _feeCollector,
        uint256 _creationFee
    ) CollectorHelper(_initialOwner, _feeCollector) {
        if(_lockerImplementation == address(0)) revert ZeroAddress();

        lockerImplementation = _lockerImplementation;
        creationFee = _creationFee;

        _pause();
    }

    /// @notice This function allows the contract to receive ETH.
    receive() external payable {}

    /**
     * @notice This function is called to create a new token vesting contract (locker).
     * @param _startTimestamp The timestamp when the vesting starts.
     * @param _durationSeconds The duration in seconds for which the tokens will be vested.
     * @param _isNative A boolean indicating if the locker is for native tokens.
     * @param _token The address of the token to be vested (if not native).
     * @param _amount The amount of tokens to be vested. 
    */
    function createLocker(
        uint64 _startTimestamp,
        uint64 _durationSeconds,
        bool _isNative,
        address _token,
        uint256 _amount
    ) external payable whenNotPaused nonReentrant returns (address payable locker) {
        if(_startTimestamp < block.timestamp) revert InvalidTimestamp();
        if(msg.value < creationFee) revert InvalidFee();

        lockerCounter = lockerCounter + 1;

        locker = payable(Clones.clone(lockerImplementation));

        Vesting(locker).initialize(
            msg.sender,
            _startTimestamp,
            _durationSeconds
        );

        IdToAddress[lockerCounter] = locker;
        creatorToLockers[msg.sender].push(locker);

        lockerInfo[locker] = LockerInfo({
            lockerAddress: locker,
            creator: msg.sender,
            startTimestamp: _startTimestamp,
            durationSeconds: _durationSeconds,
            lockerId: lockerCounter
        });

        if (_isNative == true) {
            // Transfer ETH to the locker if it is native.
            require(msg.value >= (creationFee + _amount), InvalidFee());

            (bool success, ) = locker.call{value: _amount}("");
            require(success, "Failed to send ETH");

            // Refund excess ETH if any.
            uint256 excessNative = msg.value - (creationFee + _amount);
            if (excessNative > 0) {
                (bool excessSuccess, ) = msg.sender.call{value: excessNative}("");
                require(excessSuccess, "Failed to refund excess ETH");
            }
        } else {
            // Transfer tokens to the locker if not native.
            require(_token != address(0), InvalidAddress());
            require(_amount > 0, ZeroAmount());

            IERC20(_token).safeTransferFrom(msg.sender, locker, _amount);

            // Refund excess ETH if any.
            uint256 excessNative = msg.value - creationFee;
            if (excessNative > 0) {
                (bool excessSuccess, ) = msg.sender.call{value: excessNative}("");
                require(excessSuccess, "Failed to refund excess ETH");
            }
        }

        emit LockerCreated(locker, msg.sender, _startTimestamp, _durationSeconds, lockerCounter);
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

    /// @notice Get the total number of lockers created.
    function getTotalLockers() external view returns (uint256) {
        return lockerCounter;
    }

    /// @notice  Get the locker address by its ID.
    /// @param lockerId The ID of the locker to retrieve.
    function getLockerById(uint256 lockerId) external view returns (address) {
        return IdToAddress[lockerId];
    }

    /// @notice Get all lockers created by a specific creator.
    /// @param creator The address of the creator to retrieve lockers for.
    function getLockersByCreator(address creator) external view returns (address[] memory) {
        return creatorToLockers[creator];
    }

    /// @notice Get the locker information by its address.
    /// @param locker The address of the locker to retrieve information for.
    function getLockerInfo(address locker) external view returns (LockerInfo memory) {
        return lockerInfo[locker];
    }

    /// @notice Validates if the locker address is valid.
    /// @param locker The address of the locker to validate.
    function isValidLocker(address locker) external view returns (bool) {
        return lockerInfo[locker].lockerAddress == locker;
    }
}