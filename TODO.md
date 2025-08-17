### TODO List

## High Priority
- [x] Convert the `StandardNFT` contract to have a `collectFee` function or make a separate smart contract for this that is imported into all the factories.
- [x] Revise the `FeeCollector` contract logic that stores or takes an array of factory address inputs. The list of factory addresses can be stored off-chain for more efficiency.
- [] In line with the `FeeCollector`, consider creating a variable for `pendingFees` or a simple balance check and a getter function for it.
- [x] Pattern the getter functions of VestingFactory to all existing and new factories.
- [x] Fix all existing contracts to properly reflect the structure modularity.
- [] Double check all the contracts if the modularization has been implemented correctly.
- [x] Introduce a referral module in the factory contracts or in the FeeCollector contract.
- [] Implement the referral module in all the factory contracts.

## Medium Priority
- [] Deploy the `StandardNFT` contract at Sonic Mainnet.
- [] Create modules for `Omnichain` contracts.