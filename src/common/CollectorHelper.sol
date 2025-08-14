//SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@common/FactoryErrors.sol";
import "@common/FactoryEvents.sol";

/**
 * @title Collector Helper
 * @notice Helper contract for fee collection related functions 
 */
abstract contract CollectorHelper is 
    Ownable,
    FactoryErrors,
    FactoryEvents
{
    using SafeERC20 for IERC20;

    constructor(
        address _initialOwner,
        address _feeCollector
    ) Ownable(_initialOwner) {
        if (_feeCollector == address(0)) revert ZeroAddress();
        
        feeCollector = _feeCollector;
        emit FeeCollectorUpdated(_feeCollector);
    }

    /// @notice The address that collects the fees.
    address public feeCollector;

    /// @notice This function allows the owner to collect the contract balance.
    function collectFees() external onlyOwner {
        if(feeCollector == address(0)) revert ZeroAddress();
        if(address(this).balance == 0) revert ZeroAmount();

        (bool success, ) = feeCollector.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    /// @notice This function allows the owner to collect foreign tokens sent to the contract.
    /// @param token The address of the token to collect.
    function collectTokens(address token) external onlyOwner {
        if(token == address(0)) revert ZeroAddress();
        if(IERC20(token).balanceOf(address(this)) == 0) revert ZeroAmount();

        IERC20(token).safeTransfer(feeCollector, IERC20(token).balanceOf(address(this)));
    }

    /// @notice This function allows the owner to update the fee collector address.
    /// @param newFeeCollector The new address for the fee collector.
    function setFeeCollector(address newFeeCollector) external onlyOwner {
        if (newFeeCollector == address(0)) revert ZeroAddress();

        feeCollector = newFeeCollector;
        emit FeeCollectorUpdated(newFeeCollector);
    }





}