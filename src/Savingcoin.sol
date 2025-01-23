// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";

import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import {ERC4626} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

interface IStablecoin {
    function mint(address, uint256) external;

    function burnFrom(address, uint256) external;
}


contract Savingcoin is AccessControl, ERC4626 {
    uint256 public constant RAY = 1e27;

    bytes32 public constant MANAGER =
        keccak256(abi.encode("savingcoin.manager"));

    event Cap(uint256, uint256);
    event Update(uint256, uint256, uint256, uint256);

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
        address admin,
        string memory name,
        string memory symbol,
        IERC20Metadata asset
    ) ERC20(name, symbol) ERC4626(asset) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        lastTimestamp = block.timestamp;
    }

    /// @notice Conversion method from assets to shares
    /// @param assets Number of asset tokens being burned
    function _convertToShares(
        uint256 assets,
        Math.Rounding // Math.Rounding rounding
    ) internal view override returns (uint256) {
        uint256 accum = compoundFactorAccum *
            _compoundFactor(currentRate, block.timestamp, lastTimestamp);

        return (assets * RAY) / (accum / RAY);
    }

    /// @notice Conversion method from shares to assets
    /// @param shares Number of tokens to burn
    function _convertToAssets(
        uint256 shares,
        Math.Rounding // Math.Rounding rounding
    ) internal view override returns (uint256) {
        uint256 accum = compoundFactorAccum *
            _compoundFactor(currentRate, block.timestamp, lastTimestamp);

        return (shares * (accum / RAY)) / RAY;
    }

    /// @notice Compound factor calculation based on the initial time stamp
    /// @return uint256 Current compound factor
    function compoundFactor() external view returns (uint256) {
        uint256 accum = compoundFactorAccum *
            _compoundFactor(currentRate, block.timestamp, lastTimestamp);

        return accum / RAY;
    }

    function _compoundFactor(
        uint256 rate,
        uint256 currentTimestamp,
        uint256 lastUpdateTimestamp
    ) private pure returns (uint256) {
        // https://github.com/aave/protocol-v2/blob/master/contracts/protocol/libraries/math/MathUtils.sol#L45

        uint256 n = currentTimestamp - lastUpdateTimestamp;

        uint256 term1 = RAY;
        uint256 term2 = n * rate;

        if (n == 0) return term1 + term2;

        uint256 term3 = ((n - 1) * n * ((rate * rate) / RAY)) / 2;

        if (n == 1) return term1 + term2 + term3;

        uint256 term4 = (n * (n - 1) * (n - 2) * ((rate * rate) / RAY) * rate) /
            RAY /
            6;

        return term1 + term2 + term3 + term4;
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override {
        require(
            cap >= _convertToAssets(shares + totalSupply(), Math.Rounding.Ceil),
            "newly issued shares can not exceed notional cap"
        );

        IStablecoin(asset()).burnFrom(caller, assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);
        IStablecoin(asset()).mint(receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function totalAssets() public view override returns (uint256) {
        return _convertToAssets(totalSupply(), Math.Rounding.Ceil);
    }

    function setCap(uint256 cap_) external onlyRole(MANAGER) {
        emit Cap(cap, cap_);

        cap = cap_;
    }

    /// @notice Set the interest for srUSD
    /// @param rate New value for the interest rate
    function update(uint256 rate) external onlyRole(MANAGER) {
        require(RAY > rate, "daily savings rate can not be above 100%");

        uint256 accum = compoundFactorAccum *
            _compoundFactor(currentRate, block.timestamp, lastTimestamp);

        compoundFactorAccum = accum / RAY;

        emit Update(compoundFactorAccum, currentRate, rate, block.timestamp);

        currentRate = rate;
        lastTimestamp = block.timestamp;
    }
}
