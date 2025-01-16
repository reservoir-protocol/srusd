// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {console} from "forge-std/console.sol";

contract Savingcoin is ERC4626 {
    uint256 public currentRate = 0.000000004978556233936620000 * 1e27;
    //                           0.000000000000000000000000001

    // 0.000000000000000000000000001

    // 0.000000004978556233936620000
    // 0.000000003022265993024580000
    // 0.000000012857214404249400000
    // 0.000000021979553066486800000

    uint256 public compoundFactorAccum = 1e27;

    uint256 public lastTimestamp;

    // uint256 public currentTimestamp;

    constructor(
        string memory name,
        string memory symbol,
        IERC20Metadata asset
    ) ERC20(name, symbol) ERC4626(asset) {
        lastTimestamp = block.timestamp;
        // currentTimestamp = block.timestamp;
    }

    function _convertToShares(
        uint256 assets,
        Math.Rounding rounding
    ) internal view override returns (uint256) {
        return
            (1e27 * assets) /
            (_compoundFactor(currentRate, block.timestamp, lastTimestamp));
    }

    function _convertToAssets(
        uint256 shares,
        Math.Rounding rounding
    ) internal view override returns (uint256) {
        return
            (shares *
                _compoundFactor(currentRate, block.timestamp, lastTimestamp)) /
            1e27;
    }

    /// @notice Compound factor calculation based on the initial time stamp
    /// @return uint256 Current compound factor
    function compoundFactor() external view returns (uint256) {
        return _compoundFactor(currentRate, block.timestamp, lastTimestamp);
    }

    function _compoundFactor(
        uint256 rate,
        uint256 currentTimestamp,
        uint256 lastUpdateTimestamp
    ) private view returns (uint256) {
        uint256 n = currentTimestamp - lastUpdateTimestamp;

        uint256 term1 = 1e27;
        uint256 term2 = n * rate;

        if (n == 0) return term1 + term2;

        uint256 term3 = ((n - 1) * n * rate * currentRate) / 2;

        // if (n == 1) return term1 + term2 + term3;

        // uint256 term4 = (n * (n - 1) * (n - 2) * r ** 3) / 6;

        return term1 + term2 + term3 / 1e27; // return term1 + term2 + term3 + term4;
    }
}
