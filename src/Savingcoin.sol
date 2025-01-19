// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {console} from "forge-std/console.sol";

interface IStablecoin {
    function mint(address, uint256) external;
}

contract Savingcoin is ERC4626 {
    event Update(
        uint256 compoundFactorAccum,
        uint256 currentRate,
        uint256 rate,
        uint256 timestamp
    );

    uint256 public cap = 0;

    uint256 public compoundFactorAccum = 1e27;
    uint256 public currentRate = 0.000000000000000000000000000e27;

    //                           0.000000000000000000000000001
    //  10% APR                  0.000000003022265993024580000
    //  17% APR                  0.000000004978556233936620000
    //  50% APR                  0.000000012857214404249400000
    // 100% APR                  0.000000021979553066486800000

    uint256 public lastTimestamp;

    constructor(
        string memory name,
        string memory symbol,
        IERC20Metadata asset
    ) ERC20(name, symbol) ERC4626(asset) {
        lastTimestamp = block.timestamp;
    }

    function _convertToShares(
        uint256 assets,
        Math.Rounding // Math.Rounding rounding
    ) internal view override returns (uint256) {
        uint256 accum = compoundFactorAccum *
            _compoundFactor(currentRate, block.timestamp, lastTimestamp);

        return (assets * 1e27) / (accum / 1e27);
    }

    function _convertToAssets(
        uint256 shares,
        Math.Rounding // Math.Rounding rounding
    ) internal view override returns (uint256) {
        uint256 accum = compoundFactorAccum *
            _compoundFactor(currentRate, block.timestamp, lastTimestamp);

        return (shares * (accum / 1e27)) / 1e27;
    }

    /// @notice Compound factor calculation based on the initial time stamp
    /// @return uint256 Current compound factor
    function compoundFactor() external view returns (uint256) {
        uint256 accum = compoundFactorAccum *
            _compoundFactor(currentRate, block.timestamp, lastTimestamp);

        return accum / 1e27;
    }

    function _compoundFactor(
        uint256 rate,
        uint256 currentTimestamp,
        uint256 lastUpdateTimestamp
    ) private pure returns (uint256) {
        uint256 n = currentTimestamp - lastUpdateTimestamp;

        uint256 term1 = 1e27;
        uint256 term2 = n * rate;

        if (n == 0) return term1 + term2;

        uint256 term3 = ((n - 1) * n * rate * rate) / 2;

        if (n == 1) return term1 + term2 + term3 / 1e27;

        // uint256 term4 = (n * (n - 1) * (n - 2) * rate ** 3) / 6;

        return term1 + term2 + term3 / 1e27; // return term1 + term2 + term3 + term4;
    }

    // function _deposit(
    //     address caller,
    //     address receiver,
    //     uint256 assets,
    //     uint256 shares
    // ) internal override {
    //     // TODO: Check cap against max

    //     ERC20Burnable(asset()).burnFrom(caller, assets);
    //     _mint(receiver, shares);

    //     emit Deposit(caller, receiver, assets, shares);
    // }

    // function _withdraw(
    //     address caller,
    //     address receiver,
    //     address owner,
    //     uint256 assets,
    //     uint256 shares
    // ) internal override {
    //     if (caller != owner) {
    //         _spendAllowance(owner, caller, shares);
    //     }

    //     _burn(owner, shares);
    //     IStablecoin(asset()).mint(receiver, assets);

    //     emit Withdraw(caller, receiver, owner, assets, shares);
    // }

    // function totalAssets() public view override returns (uint256) {
    //     return _convertToAssets(totalSupply(), Math.Rounding.Floor);
    // }

    function setCap(uint256 cap_) external {
        cap = cap_;
    }

    /// @notice Set the interest for srUSD
    /// @param rate New value for the interest rate
    function update(uint256 rate) external {
        require(1e27 > rate, "SM: Savings rate can not be above 100% per anum");

        uint256 accum = compoundFactorAccum *
            _compoundFactor(currentRate, block.timestamp, lastTimestamp);

        compoundFactorAccum = accum / 1e27;

        emit Update(compoundFactorAccum, currentRate, rate, block.timestamp);

        currentRate = rate;
        lastTimestamp = block.timestamp;
    }
}
