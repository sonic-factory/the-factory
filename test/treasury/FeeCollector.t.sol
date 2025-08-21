// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "@treasury/FeeCollector.sol";
import "./mocks/MockFactory.sol";

contract FeeCollectorTest is Test {

    FeeCollector public feeCollector;

    address public owner = makeAddr("owner");
    address public treasury = makeAddr("treasury");

    MockFactory public factory1;
    MockFactory public factory2;
    MockFactory public factory3;
    MockFactory public factory4;
    MockFactory public factory5;

    address[] public factories;

    function setUp() public {

        feeCollector = new FeeCollector();
        feeCollector.initialize(owner, treasury);



    }
}