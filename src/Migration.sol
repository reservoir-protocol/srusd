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

    /// @notice Convert srUSD v1 to srUSD v2
    /// @param amount Amountof srUSD v1 to exchange
    function migrate(uint256 amount) external returns (uint256) {
        require(
            srusd.transferFrom(msg.sender, address(this), amount),
            "transfer into migration contract failed"
        );

        uint256 balanceBefore = rusd.balanceOf(address(this));

        savingModule.redeem((amount * savingModule.currentPrice()) / 1e8);

        uint256 balanceAfter = rusd.balanceOf(address(this));

        // Should be same as `amount`
        uint256 balance = balanceAfter - balanceBefore;

        return vault.deposit(balance, msg.sender);
    }

    // TODO: add recover method
}
