// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {console} from "forge-std/console.sol";

interface ISavingModule {
    function redeem(uint256) external;

    function previewRedeem(uint256) external view returns (uint256);

    function redeemFee() external view returns (uint256);

    function currentPrice() external view returns (uint256);
}

contract Migration {
    IERC20 public rusd;
    IERC20 public srusd;

    IERC4626 public vault;
    ISavingModule public savingModule;

    constructor(
        address rusd_,
        address srusd_,
        address vault_,
        address savingModule_
    ) {
        rusd = IERC20(rusd_);
        srusd = IERC20(srusd_);

        vault = IERC4626(vault_);
        savingModule = ISavingModule(savingModule_);

        rusd.approve(vault_, type(uint256).max);
        srusd.approve(savingModule_, type(uint256).max);
    }

    /// @notice Convert all srUSD v1 to srUSD v2
    function migrateBalance() external returns (uint256) {
        uint256 amount = _previewRedeemValue(srusd.balanceOf(msg.sender));

        return _migrate(amount);
    }

    /// @notice Convert srUSD v1 to srUSD v2
    /// @param amount Amountof srUSD v1 to exchange
    function migrate(uint256 amount) external returns (uint256) {
        return _migrate(amount);
    }

    function _migrate(uint256 amount) private returns (uint256) {
        require(
            srusd.transferFrom(msg.sender, address(this), amount),
            "transfer into migration contract failed"
        );

        uint256 balanceBefore = rusd.balanceOf(address(this));

        savingModule.redeem(amount);

        uint256 balanceAfter = rusd.balanceOf(address(this));

        // Should be same as `amount`
        uint256 balance = balanceAfter - balanceBefore;

        return vault.deposit(balance, msg.sender);
    }

    /// @notice Calculates the amount of rUSD returned to the sender
    /// @param amount Amountof srUSD v1 to exchange
    function previewRedeemValue(
        uint256 amount
    ) external view returns (uint256) {
        return _previewRedeemValue(amount);
    }

    function _previewRedeemValue(
        uint256 amount
    ) private view returns (uint256) {
        uint256 fee = savingModule.redeemFee();
        uint256 price = savingModule.currentPrice();

        return (amount * price * 1e6) / (1e8 * (1e6 + fee));
    }

    // TODO: add recover method
}
