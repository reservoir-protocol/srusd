// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Savingcoin Exchange Rate Oracle
/// @notice Provides exchange rate for Savingcoin OFT wrapper to Pendle SY
/// @dev Returns 1:1 exchange rate as the OFT wrapper is a 1:1 representation of the underlying asset
contract SavingcoinExchangeRateOracle {
    address public immutable wsrUSD;

    /// @notice Constructor
    /// @param _wsrUSD Address of the Wrapped Savings rUSD (OFT wrapper)
    constructor(address _wsrUSD) {
        wsrUSD = _wsrUSD;
    }

    /// @notice Get the current exchange rate
    /// @dev Returns 1:1 exchange rate (1e18) as the OFT wrapper represents the underlying 1:1
    /// @return exchangeRate The exchange rate in 18 decimal format (always 1e18 for 1:1)
    function getExchangeRate() external pure returns (uint256 exchangeRate) {
        // Return 1:1 exchange rate
        // This means 1 wsrUSD token = 1 rUSD token
        return 1e18;
    }
}
