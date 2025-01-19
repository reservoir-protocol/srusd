// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import {Savingcoin} from "src/Savingcoin.sol";

import {Migration} from "src/Migration.sol";

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

interface IStablecoin {
    function mint(address, uint256) external;
}

contract StablecoinMock is ERC20Burnable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

contract SavingModuleMock {
    IStablecoin rusd;

    uint256 public currentPrice = 1e8;

    constructor(address token_) {
        rusd = IStablecoin(token_);
    }

    function redeem(uint256 amount) external {
        rusd.mint(msg.sender, amount);
    }

    // TODO: Implement our redeem

    function setCurrentPrice(uint256 price) external {
        currentPrice = price;
    }
}

contract MigrationTest is Test {
    // ERC20Mock rusd;
    StablecoinMock rusd;

    ERC20Mock srusd;

    SavingModuleMock savingModule;

    Savingcoin vault;
    Migration migration;

    address eoa1 = vm.addr(1);
    address eoa2 = vm.addr(2);

    function setUp() external {
        // rusd = new ERC20Mock();
        rusd = new StablecoinMock("Reservoir Stablecoin Mock", "rUSDM");
        srusd = new ERC20Mock();

        savingModule = new SavingModuleMock(address(rusd));

        vault = new Savingcoin("Reservoir Savingcoin", "srUSD", rusd);

        migration = new Migration(
            address(rusd),
            address(srusd),
            address(vault),
            address(savingModule)
        );

        srusd.mint(eoa1, 2_000_000e18);
        srusd.mint(eoa2, 2_000_000e18);

        vm.prank(eoa1);
        srusd.approve(address(migration), type(uint256).max);

        vm.prank(eoa2);
        srusd.approve(address(migration), type(uint256).max);
    }

    function testInitialState() external view {
        assertEq(address(migration.rusd()), address(rusd));
        assertEq(address(migration.srusd()), address(srusd));

        assertEq(address(migration.vault()), address(vault));
        assertEq(address(migration.savingModule()), address(savingModule));
    }

    function testMigrate() external {
        assertEq(vault.previewDeposit(1_000_000e18), 1_000_000e18);

        vm.prank(eoa1);
        uint256 shares = migration.migrate(1_000_000e18);

        assertEq(shares, 1_000_000e18);
        assertEq(vault.balanceOf(eoa1), 1_000_000e18);

        savingModule.setCurrentPrice(1.50000000e8);

        vm.prank(eoa2);
        shares = migration.migrate(1_000_000e18);

        assertEq(shares, 1_500_000e18);
        assertEq(vault.balanceOf(eoa2), 1_500_000e18);

        vault.update(0.000000003022265993024580000e27);

        skip(365 days);

        assertEq(vault.compoundFactor(), 1.099996495534941038654051027e27);
        assertEq(vault.compoundFactorAccum(), 1.000000000000000000000000000e27);

        assertEq(
            vault.previewDeposit(1_000_000e18),
            909_093.805352251068337179e18
        );
        assertEq(
            vault.previewDeposit(1_500_000e18),
            1_363_640.708028376602505769e18
        );

        uint256 balance = srusd.balanceOf(eoa1);

        vm.prank(eoa1);
        shares = migration.migrate(balance);

        assertEq(shares, 1_363_640.708028376602505769e18);
        assertEq(vault.balanceOf(eoa1), 2_363_640.708028376602505769e18);

        vault.update(0.000000012857214404249400000e27);

        skip(365 days);

        assertEq(vault.compoundFactor(), 1.648648309468955367634227975e27);
        assertEq(vault.compoundFactorAccum(), 1.099996495534941038654051027e27);

        assertEq(
            vault.previewDeposit(1_000_000e18),
            606_557.501837434998839723e18
        );
        assertEq(
            vault.previewDeposit(2_000_000e18),
            1_213_115.003674869997679446e18
        );

        balance = srusd.balanceOf(eoa2);
        savingModule.setCurrentPrice(2.00000000e8);

        vm.prank(eoa2);
        shares = migration.migrate(balance);

        assertEq(shares, 1_213_115.003674869997679446e18);
        assertEq(vault.balanceOf(eoa2), 2_713_115.003674869997679446e18);

        assertEq(srusd.balanceOf(eoa1), 0);
        assertEq(srusd.balanceOf(eoa2), 0);

        // TODO: Check the balance in the migration contract
    }
}
