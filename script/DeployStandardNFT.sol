// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "@standardNFT/StandardNFT.sol";
import "@standardNFT/StandardNFTFactory.sol";

contract Deploy is Script {

    // Command line input
    // forge script script/DeployStandardNFT.sol \
    // --rpc-url $TESTNET_RPC_URL \ 
    // --etherscan-api-key $SONICSCAN_API_KEY \
    // --verify -vvvv --slow --broadcast --interactives 1

    function run() external {
        
        vm.startBroadcast();

        address OWNER = vm.envAddress("OWNER");
        address COLLECTOR = vm.envAddress("COLLECTOR");

        StandardNFT nftImplementation = new StandardNFT();

        StandardNFTFactory factory = new StandardNFTFactory(
            address(nftImplementation),
            OWNER,     
            COLLECTOR,
            10e18,
            1_000
        );

        factory.unpause();

        console.log("NFT Implementation deployed at: ", address(nftImplementation));
        console.log("NFT Factory deployed at: ", address(factory));

        vm.stopBroadcast();
    }
}