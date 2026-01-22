// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Chronicle oracle interface
interface IChronicle {
    function read() external view returns (uint256);
}

/// @title Chronicle Oracle Wrapper for Pendle
/// @notice Wraps Chronicle oracle's read() function to Pendle's getExchangeRate() interface
/// @dev Chronicle oracles use read() but Pendle expects getExchangeRate()
contract ChronicleOracleWrapper {
    address public immutable chronicleOracle;

    /// @notice Constructor
    /// @param _chronicleOracle Address of the Chronicle oracle
    constructor(address _chronicleOracle) {
        chronicleOracle = _chronicleOracle;
    }

    /// @notice Get the exchange rate from Chronicle oracle
    /// @return The exchange rate in 18 decimals (1e18 = 1:1)
    function getExchangeRate() external view returns (uint256) {
        return IChronicle(chronicleOracle).read();
    }
}
