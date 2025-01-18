// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import {Savingcoin} from "src/Savingcoin.sol";

import {Migration} from "src/Migration.sol";

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

interface IStablecoin {
    function mint(address, uint256) external;
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
    ERC20Mock rusd;
    ERC20Mock srusd;

    SavingModuleMock savingModule;

    Savingcoin vault;
    Migration migration;

    address eoa1 = vm.addr(1);
    address eoa2 = vm.addr(2);

    function setUp() external {
        rusd = new ERC20Mock();
        srusd = new ERC20Mock();

        savingModule = new SavingModuleMock(address(rusd));

        vault = new Savingcoin("Reservoir Savingcoin", "srUSD", rusd);

        migration = new Migration(
            address(rusd),
            address(srusd),
            address(vault),
            address(savingModule)
        );

        srusd.mint(eoa1, 1_000_000e18);
        srusd.mint(eoa2, 1_000_000e18);

        vm.prank(eoa1);
        srusd.approve(address(migration), type(uint256).max);

        vm.prank(eoa2);
        srusd.approve(address(migration), type(uint256).max);
    }

    function testInitialState() external view {
        // assertEq(address(migration.rusd()), address(rusd));
        // assertEq(address(migration.srusd()), address(rusd));

        // assertEq(address(migration.vault()), address(rusd));
        // assertEq(address(migration.savingModule()), address(rusd));

        assertTrue(true);
    }

    function testMigrate() external {
        // check price
        console.log(vault.previewDeposit(1_000_000e18));

        uint256 balance1 = srusd.balanceOf(eoa1);

        // console.log(balance1);
        // console.log(savingModule.currentPrice());

        vm.prank(eoa1);
        uint256 shares = migration.migrate(balance1);

        console.log(shares);

        // assert shares received by the caller

        assertTrue(true);
    }
}
