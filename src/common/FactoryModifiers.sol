// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

import "@common/FactoryErrors.sol";

abstract contract FactoryModifiers is FactoryErrors {

    /// @notice The address that collects the fees.
    address public feeCollector;

    /// @notice Modifier to check if the caller is the collector.
    modifier onlyCollector {
        require(msg.sender == feeCollector, InvalidCollector());
        _;
    }
}