// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {console} from "forge-std/console.sol";

contract Savingcoin is ERC4626 {
    uint256 public rate = 0.000000004978556233936620000 * 1e27;
    //                    0.000000000000000000000000001

    uint256 public lastUpdateTimestamp;
    uint256 public currentTimestamp;

    constructor(
        string memory name,
        string memory symbol,
        IERC20Metadata asset
    ) ERC20(name, symbol) ERC4626(asset) {
        lastUpdateTimestamp = block.timestamp;
        currentTimestamp = block.timestamp;
    }

    function _convertToAssets(
        uint256 shares,
        Math.Rounding rounding
    ) internal view override returns (uint256) {
        // uint256 exp = lastUpdateTimestamp - currentTimestamp;
        uint256 exp = block.timestamp - lastUpdateTimestamp;

        uint256 ratePerSecond = rate;
        // uint256 ratePerSecond = rate / 31536000;

        // uint256 n = daysCount;
        // uint256 r = discountRate;

        console.log(ratePerSecond);

        uint256 term1 = 1e27;
        // uint256 term2 = (ratePerSecond * exp) / 1e27;
        uint256 term2 = ratePerSecond * exp;

        console.log(term2);

        // console.log(exp);
        // console.log(exp - 1);
        // console.log(ratePerSecond);

        // uint256 term3 = ((exp - 1) * exp * ratePerSecond * ratePerSecond) /
        //     (2 * 1e27);

        uint256 term3 = ((exp - 1) * exp * ratePerSecond * ratePerSecond) / 2;

        // if (n == 0) return term1 + term2;

        // uint256 term3 = (1e12 * (n * (n - 1) * r ** 2)) / 2;

        // if (n == 1) return term1 + term2 + term3;

        // uint256 term4 = (n * (n - 1) * (n - 2) * r ** 3) / 6;

        // return term1 + term2 + term3 + term4;

        // return term1 + term2 + term3;

        // return term1 + term2 + term3 / (1e27 * 1e27);
        return term1 + term2 + term3 / 1e27;
    }
}
