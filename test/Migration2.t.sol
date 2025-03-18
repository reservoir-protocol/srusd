// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {Migration} from "../src/Migration.sol";

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}

contract MockSavingModule {
    uint256 private _redeemFee;
    uint256 private _currentPrice;
    MockToken public rusd;

    constructor(address rusd_) {
        rusd = MockToken(rusd_);
        _redeemFee = 1e6; // 1%
        _currentPrice = 1.02e8; // 1.02 USD
    }

    function redeem(uint256 amount) external {
        // Calculate rUSD to return based on price and fee
        uint256 rusdAmount = (amount * _currentPrice * 1e6) /
            (1e8 * (1e6 + _redeemFee));
        rusd.mint(msg.sender, rusdAmount);
    }

    function previewRedeem(uint256 amount) external view returns (uint256) {
        return (amount * _currentPrice * 1e6) / (1e8 * (1e6 + _redeemFee));
    }

    function redeemFee() external view returns (uint256) {
        return _redeemFee;
    }

    function currentPrice() external view returns (uint256) {
        return _currentPrice;
    }

    function setRedeemFee(uint256 fee) external {
        _redeemFee = fee;
    }

    function setCurrentPrice(uint256 price) external {
        _currentPrice = price;
    }
}

contract MockVault {
    MockToken public immutable asset;
    MockToken public immutable share;
    uint256 public constant EXCHANGE_RATE = 1e18; // 1:1 exchange rate

    constructor(address asset_, address share_) {
        asset = MockToken(asset_);
        share = MockToken(share_);
    }

    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256) {
        require(
            asset.transferFrom(msg.sender, address(this), assets),
            "transfer failed"
        );
        uint256 shares = (assets * 1e18) / EXCHANGE_RATE;
        share.mint(receiver, shares);
        return shares;
    }
}

contract MigrationTest2 is Test {
    Migration public migration;
    MockToken public rusd;
    MockToken public srusd;
    MockVault public vault;
    MockSavingModule public savingModule;

    address public constant ADMIN = address(0x1);
    address public constant USER = address(0x2);

    function setUp() public {
        // Deploy mock tokens
        rusd = new MockToken("rUSD", "rUSD");
        srusd = new MockToken("srUSD v1", "srUSDv1");

        // Deploy mock vault and saving module
        vault = new MockVault(address(rusd), address(srusd));
        savingModule = new MockSavingModule(address(rusd));

        // Deploy migration contract
        migration = new Migration(
            address(rusd),
            address(srusd),
            address(vault),
            address(savingModule)
        );

        // Setup initial balances and approvals for migration contract
        srusd.mint(address(this), 1000e18);
        srusd.approve(address(migration), type(uint256).max);

        // Setup user balance and approval
        srusd.mint(USER, 100e18);
        vm.prank(USER);
        srusd.approve(address(migration), type(uint256).max);
    }

    function testConstructor() public {
        assertEq(address(migration.rusd()), address(rusd));
        assertEq(address(migration.srusd()), address(srusd));
        assertEq(address(migration.vault()), address(vault));
        assertEq(address(migration.savingModule()), address(savingModule));

        // Check approvals
        assertEq(
            rusd.allowance(address(migration), address(vault)),
            type(uint256).max
        );
        assertEq(
            srusd.allowance(address(migration), address(savingModule)),
            type(uint256).max
        );
    }

    function testPreviewRedeemValue() public {
        uint256 amount = 100e18;
        uint256 expectedValue = savingModule.previewRedeem(amount);

        assertEq(
            migration.previewRedeemValue(amount),
            expectedValue,
            "Preview value should match saving module calculation"
        );
    }

    function testFailMigrateInsufficientBalance() public {
        uint256 balance = 100e18;
        uint256 migrateAmount = 200e18;

        vm.startPrank(USER);
        srusd.transfer(address(0xdead), srusd.balanceOf(USER));
        srusd.mint(USER, balance);
        srusd.approve(address(migration), type(uint256).max);

        // Should revert when trying to migrate more than balance
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        migration.migrate(migrateAmount);
        vm.stopPrank();
    }

    function testFailMigrateNoApproval() public {
        uint256 amount = 100e18;
        address newUser = address(0x3);

        srusd.mint(newUser, amount);

        vm.prank(newUser);
        migration.migrate(amount); // Should fail due to no approval
    }

    function testMigrateWithDifferentPrices() public {
        uint256 amount = 100e18;
        srusd.mint(USER, amount);

        // Test with different prices
        uint256[] memory prices = new uint256[](3);
        prices[0] = 98e6; // Below peg (0.98)
        prices[1] = 100e6; // At peg (1.00)
        prices[2] = 105e6; // Above peg (1.05)

        for (uint256 i = 0; i < prices.length; i++) {
            // Reset user balance and approval
            vm.startPrank(USER);
            srusd.transfer(address(0xdead), srusd.balanceOf(USER));
            srusd.mint(USER, amount);
            srusd.approve(address(migration), type(uint256).max);
            vm.stopPrank();

            savingModule.setCurrentPrice(prices[i]);

            vm.prank(USER);
            uint256 sharesReceived = migration.migrate(amount);

            assertTrue(
                sharesReceived > 0,
                "Should receive shares at any price"
            );
        }
    }

    function testMigrateWithDifferentFees() public {
        uint256 amount = 100e18;
        srusd.mint(USER, amount);

        // Test with different fees
        uint256[] memory fees = new uint256[](3);
        fees[0] = 0; // No fee
        fees[1] = 0.5e6; // 0.5%
        fees[2] = 2e6; // 2%

        for (uint256 i = 0; i < fees.length; i++) {
            // Reset user balance and approval
            vm.startPrank(USER);
            srusd.transfer(address(0xdead), srusd.balanceOf(USER));
            srusd.mint(USER, amount);
            srusd.approve(address(migration), type(uint256).max);
            vm.stopPrank();

            savingModule.setRedeemFee(fees[i]);

            vm.prank(USER);
            uint256 sharesReceived = migration.migrate(amount);

            assertTrue(
                sharesReceived > 0,
                "Should receive shares at any fee level"
            );
        }
    }
}
