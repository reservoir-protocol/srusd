// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import {Migration, ISavingModule} from "src/Migration.sol";
import {Savingcoin} from "src/Savingcoin.sol";

import {StablecoinMock} from "./StablecoinMock.sol";

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

interface IStablecoin {
    function mint(address, uint256) external;
}

interface ISavingcoin is IERC20 {
    function burn(address, uint256) external;
}

contract SavingModuleMock {
    IStablecoin rusd;
    ISavingcoin srusd;

    uint256 public redeemFee = 0e6; // 230
    uint256 public currentPrice = 1e8;

    constructor(address rusd_, address srusd_) {
        rusd = IStablecoin(rusd_);
        srusd = ISavingcoin(srusd_);
    }

    function redeem(uint256 amount) external {
        uint256 burnAmount = (amount * (1e6 + redeemFee)) / 1e6;

        assert(srusd.allowance(msg.sender, address(this)) >= burnAmount);

        // srusd.burn(msg.sender, burnAmount);

        rusd.mint(msg.sender, amount);
    }

    function setRedeemFee(uint256 fee) external {
        currentPrice = fee;
    }

    function setCurrentPrice(uint256 price) external {
        currentPrice = price;
    }
}

contract MigrationTest is Test {
    ERC20Mock srusd;
    StablecoinMock rusd;

    SavingModuleMock savingModule;

    Savingcoin vault;
    Migration migration;

    address eoa1 = vm.addr(1);
    address eoa2 = vm.addr(2);

    function setUp() external {
        srusd = new ERC20Mock();
        rusd = new StablecoinMock("Reservoir Stablecoin Mock", "rUSDM");

        savingModule = new SavingModuleMock(address(rusd), address(srusd));
        vault = new Savingcoin(
            address(this),
            "Reservoir Savingcoin",
            "srUSD",
            rusd
        );

        vault.grantRole(vault.MANAGER(), address(this));

        vault.setCap(type(uint256).max);

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

    function testMigrateFork() external {
        uint256 fork = vm.createSelectFork(
            "https://gateway.tenderly.co/public/polygon"
        );

        console.log(fork);

        IERC20 srusdFork = IERC20(0xbb97eCFe1cd0f49b1F6bF4172b44E75394cfe64a);
        ISavingModule savingModuleFork = ISavingModule(
            0x23739D8B84E8849C7d8002811F27736E12a3DA7D
        );

        console.log(
            srusdFork.balanceOf(0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69)
        );
        console.log(savingModuleFork.currentPrice());

        uint256 balance = srusdFork.balanceOf(
            0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69
        );

        uint256 fee = savingModuleFork.redeemFee();
        uint256 price = savingModuleFork.currentPrice();

        // uint256 amount = (balance * price) / 1e8;
        uint256 amount = (balance * price * 1e6) / (1e8 * (1e6 + fee));

        console.log(amount);
        console.log(savingModuleFork.previewRedeem(amount));

        vm.prank(0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69);
        srusdFork.approve(address(savingModuleFork), type(uint256).max);

        vm.prank(0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69);
        savingModuleFork.redeem(amount);

        console.log(
            srusdFork.balanceOf(0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69)
        );

        assertTrue(true);
    }

    function testMigrateFork2() external {
        uint256 fork = vm.createSelectFork(
            "https://gateway.tenderly.co/public/polygon"
        );

        console.log(fork);

        Migration migrationFork = Migration(
            0x762925054575EBA0E7C5305C8a2985d77C4a2e1A
        );

        IERC20 srusdFork = IERC20(address(migrationFork.srusd()));
        ISavingModule savingModuleFork = ISavingModule(
            address(migrationFork.savingModule())
        );

        console.log(
            srusdFork.balanceOf(0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69)
        );
        console.log(savingModuleFork.currentPrice());

        uint256 balance = srusdFork.balanceOf(
            0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69
        );

        uint256 fee = savingModuleFork.redeemFee();
        uint256 price = savingModuleFork.currentPrice();

        // uint256 amount = (balance * price) / 1e8;
        uint256 amount = (balance * price * 1e6) / (1e8 * (1e6 + fee));

        console.log(amount);
        console.log(savingModuleFork.previewRedeem(amount));

        vm.prank(0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69);
        srusdFork.approve(address(migrationFork), type(uint256).max);

        vm.prank(0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69);
        migrationFork.migrate(amount);

        console.log(
            srusdFork.balanceOf(0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69)
        );

        assertTrue(true);
    }

    function testMigrateFork3() external {
        uint256 fork = vm.createSelectFork(
            "https://gateway.tenderly.co/public/polygon"
        );

        console.log(fork);

        Migration migrationFork = Migration(
            0x5Afec4a9E2A05bC581246A21f6245f82B6eb767C
        );

        IERC20 srusdFork = IERC20(address(migrationFork.srusd()));
        ISavingModule savingModuleFork = ISavingModule(
            address(migrationFork.savingModule())
        );

        console.log(
            srusdFork.balanceOf(0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69)
        );
        console.log(savingModuleFork.currentPrice());

        uint256 balance = srusdFork.balanceOf(
            0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69
        );

        uint256 fee = savingModuleFork.redeemFee();
        uint256 price = savingModuleFork.currentPrice();

        // uint256 amount = (balance * price) / 1e8;
        uint256 amount = (balance * price * 1e6) / (1e8 * (1e6 + fee));

        console.log(amount);
        console.log(savingModuleFork.previewRedeem(amount));

        vm.prank(0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69);
        srusdFork.approve(
            address(migrationFork),
            balance /* type(uint256).max */
        );

        vm.prank(0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69);
        migrationFork.migrateBalance();

        // migrationFork.migrate(amount);

        console.log(
            srusdFork.balanceOf(0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69)
        );

        assertTrue(true);
    }
}
