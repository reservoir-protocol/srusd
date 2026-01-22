// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Savingcoin (wsrUSD) interface for exchange rate
interface ISavingcoin {
    /// @notice Returns the compound factor (exchange rate) in RAY format (1e27)
    /// @dev This represents how many underlying tokens (rUSD) per share (wsrUSD)
    /// @return Exchange rate in RAY format (needs to be converted to 1e18 for Pendle)
    function compoundFactor() external view returns (uint256);
}

/// @title Savingcoin Exchange Rate Oracle for Pendle
/// @notice Provides fundamental exchange rate (wsrUSD/rUSD) for Pendle SY
/// @dev Wraps Savingcoin's compoundFactor() to Pendle's getExchangeRate() interface
/// @dev Converts from RAY (1e27) to standard 1e18 format expected by Pendle
contract SavingcoinExchangeRateOracle {
    /// @notice The Savingcoin (wsrUSD) contract address
    address public immutable savingcoin;

    /// @notice RAY precision used by Savingcoin (1e27)
    uint256 private constant RAY = 1e27;

    /// @notice Target precision for Pendle (1e18)
    uint256 private constant TARGET_PRECISION = 1e18;

    /// @notice Constructor
    /// @param _savingcoin Address of the Savingcoin (wsrUSD) contract
    constructor(address _savingcoin) {
        require(_savingcoin != address(0), "Invalid savingcoin address");
        savingcoin = _savingcoin;
    }

    /// @notice Get the exchange rate from Savingcoin's compoundFactor
    /// @dev Converts from RAY (1e27) to standard precision (1e18)
    /// @return The exchange rate in 18 decimals (1e18 = 1:1 ratio)
    function getExchangeRate() external view returns (uint256) {
        // Get compound factor in RAY format (1e27)
        uint256 compoundFactorRay = ISavingcoin(savingcoin).compoundFactor();
        
        // Convert from RAY (1e27) to standard precision (1e18)
        // This represents: how many rUSD per 1 wsrUSD
        return compoundFactorRay / (RAY / TARGET_PRECISION);
    }
}
