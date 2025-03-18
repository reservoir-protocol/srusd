// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

import {Migration, ISavingModule} from "src/Migration.sol";

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract MigrationTest is Test {
    Migration migrationFork;

    IERC20 srusdFork;
    IERC4626 vaultFork;

    ISavingModule savingModuleFork;

    address constant eoaf = 0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69;
    string constant MAINNET_RPC_URL =
        "https://gateway.tenderly.co/public/polygon";

    function setUp() external {
        uint256 fork = vm.createSelectFork(MAINNET_RPC_URL, 69209000);

        console.log(fork);

        migrationFork = Migration(0xD58EFea2dd28E708C0d7fD4ac776d0a45b6286ee);

        srusdFork = IERC20(address(migrationFork.srusd()));
        vaultFork = IERC4626(address(migrationFork.vault()));

        savingModuleFork = ISavingModule(address(migrationFork.savingModule()));
    }

    function testInitialState() external view {
        assertEq(
            address(migrationFork.rusd()),
            0x5f920202D5350039240E479F169b75a5aFC88fb8
        );
        assertEq(
            address(migrationFork.srusd()),
            0xbb97eCFe1cd0f49b1F6bF4172b44E75394cfe64a
        );

        assertEq(
            address(migrationFork.vault()),
            0xe0a75d8F8C8A2D41E0b0765F0c3aB3FEa2AFD276
        );
        assertEq(
            address(migrationFork.savingModule()),
            0x23739D8B84E8849C7d8002811F27736E12a3DA7D
        );
    }

    function testMigrateFork() external {
        uint256 balance = srusdFork.balanceOf(eoaf);

        console.log(vaultFork.balanceOf(eoaf));
        assertEq(balance, 1_579_347_061_350_484_709_925);

        vm.prank(eoaf);
        srusdFork.approve(address(migrationFork), type(uint256).max);

        vm.prank(eoaf);
        migrationFork.migrate(balance / 10);

        assertEq(srusdFork.balanceOf(eoaf), 1_421_412_355_215_436_238_933);

        vm.prank(eoaf);
        migrationFork.migrateBalance();

        assertEq(srusdFork.balanceOf(eoaf), 0);
        console.log(vaultFork.balanceOf(eoaf));
    }
}
