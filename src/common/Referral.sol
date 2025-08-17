//SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.28;

abstract contract Referral {

    /// @notice Referral rate in basis points (0..10_000)
    uint256 internal referralRate;

    /// @notice Thrown when the referral rate is above the required threshold.
    error InvalidReferralRate(uint256 rate);

    /// @notice Emitted when a referral payment is made.
    event ReferralPaid(address indexed referrer, uint256 amount, address indexed payer);

    /// @notice Internal setter for referral rate. Factories should expose an onlyOwner wrapper.
    /// @dev _referralRate must be <= 10_000.
    function _setReferralRate(uint16 _referralRate) internal {
        if(_referralRate > 10_000) revert InvalidReferralRate(_referralRate);
        referralRate = _referralRate;
    }

    /// @notice Internal view getter for referral rate.
    function _getReferralRate() internal view returns (uint256) {
        return referralRate;
    }

    /// @notice Distribute referral share of `fee` to `referrer`.
    /// @param referrer The referral address (can be zero address to skip).
    /// @param fee The fee amount (in wei) to split.
    /// @return remainder The amount remaining after referral payout (kept by factory).
    function _distributeReferral(address referrer, uint256 fee) internal returns (uint256 remainder) {
        if (referrer == address(0) || referralRate == 0 || fee == 0) {
            return fee;
        }

        uint256 referralAmount = (fee * referralRate) / 10_000;

        if (referralAmount == 0) {
            return fee;
        }

        // attempt to send referral payment immediately
        (bool sent, ) = referrer.call{value: referralAmount}("");
        if (sent) {
            emit ReferralPaid(referrer, referralAmount, msg.sender);
            return fee - referralAmount;
        }

        // if sending the referral fails, do not reduce the fee (keep full amount in factory)
        return fee;
    }
}