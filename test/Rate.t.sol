// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import {Savingcoin} from "src/Savingcoin.sol";

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract RateTest is Test {
    ERC20Mock rusd;

    Savingcoin srusd;

    address eoa1 = vm.addr(1);
    address eoa2 = vm.addr(2);

    function setUp() external {
        rusd = new ERC20Mock();
        srusd = new Savingcoin("Reservoir Savingcoin", "srUSD", rusd);

        // rusd.grantRole(rusd.MINTER(), address(this));

        rusd.mint(eoa1, 1_000e18);
        rusd.mint(eoa2, 1_000e18);

        vm.prank(eoa1);
        rusd.approve(address(srusd), type(uint256).max);

        vm.prank(eoa2);
        rusd.approve(address(srusd), type(uint256).max);
    }

    function testInitialState() external {
        assertEq(srusd.symbol(), "srUSD");
        assertEq(srusd.name(), "Reservoir Savingcoin");

        assertEq(srusd.decimals(), 18);
        assertEq(srusd.asset(), address(rusd));

        assertEq(srusd.totalAssets(), 0);
        assertEq(srusd.totalSupply(), 0);

        assertEq(rusd.balanceOf(eoa1), 1_000e18);
        assertEq(rusd.balanceOf(eoa2), 1_000e18);

        assertEq(rusd.totalSupply(), 2_000e18);
    }

    function testMint() external {
        // assertEq(srusd.previewMint(12e18), 12e18);
        // assertEq(srusd.previewMint(24e18), 24e18);
        // assertEq(srusd.previewMint(76e18), 76e18);
        // assertEq(srusd.previewMint(88e18), 88e18);
        // assertEq(srusd.previewMint(100e18), 100e18);

        // vm.prank(eoa1);
        // srusd.mint(12e18, eoa1);

        // vm.prank(eoa2);
        // srusd.mint(24e18, eoa2);

        // assertEq(rusd.balanceOf(eoa1), 988e18);
        // assertEq(rusd.balanceOf(eoa2), 976e18);

        // assertEq(srusd.balanceOf(eoa1), 12e18);
        // assertEq(srusd.balanceOf(eoa2), 24e18);

        // assertEq(srusd.totalSupply(), 36e18);
        // assertEq(srusd.totalAssets(), 36e18);

        // assertEq(srusd.previewMint(12e18), 12e18);
        // assertEq(srusd.previewMint(24e18), 24e18);
        // assertEq(srusd.previewMint(76e18), 76e18);
        // assertEq(srusd.previewMint(88e18), 88e18);
        // assertEq(srusd.previewMint(100e18), 100e18);

        // vm.prank(eoa1);
        // srusd.mint(76e18, eoa2);

        // vm.prank(eoa2);
        // srusd.mint(100e18, eoa2);

        // assertEq(srusd.balanceOf(eoa1), 12e18);
        // assertEq(srusd.balanceOf(eoa2), 200e18);

        // assertEq(srusd.totalSupply(), 212e18);
        // assertEq(srusd.totalAssets(), 212e18);

        // assertEq(srusd.previewMint(12e18), 12e18);
        // assertEq(srusd.previewMint(24e18), 24e18);
        // assertEq(srusd.previewMint(76e18), 76e18);
        // assertEq(srusd.previewMint(88e18), 88e18);
        // assertEq(srusd.previewMint(100e18), 100e18);

        // vm.prank(eoa1);
        // srusd.mint(100e18, eoa1);

        // vm.prank(eoa2);
        // srusd.mint(88e18, eoa1);

        // assertEq(srusd.balanceOf(eoa1), 200e18);
        // assertEq(srusd.balanceOf(eoa2), 200e18);

        // assertEq(srusd.totalSupply(), 400e18);
        // assertEq(srusd.totalAssets(), 400e18);

        // vm.roll(100);

        vm.warp(31536000);
        // vm.warp(1641070800);

        console.log(block.timestamp);

        console.log(" - - - - - - - - - - - - - - - - - ");
        // console.log(srusd.currentTimestamp());
        // console.log(srusd.lastUpdateTimestamp());
        console.log(srusd.convertToAssets(1));
        // console.log(uint256(1e36));
        // console.log(uint256(1e76));
        // console.log(type(uint256).max);
        console.log(" - - - - - - - - - - - - - - - - - ");

        assertTrue(true);
    }

    // function testDeposit() external {
    //     assertEq(srusd.previewDeposit(12e18), 12e18);
    //     assertEq(srusd.previewDeposit(24e18), 24e18);
    //     assertEq(srusd.previewDeposit(76e18), 76e18);
    //     assertEq(srusd.previewDeposit(88e18), 88e18);
    //     assertEq(srusd.previewDeposit(100e18), 100e18);

    //     vm.prank(eoa1);
    //     srusd.deposit(12e18, eoa1);

    //     vm.prank(eoa2);
    //     srusd.deposit(24e18, eoa2);

    //     assertEq(srusd.balanceOf(eoa1), 12e18);
    //     assertEq(srusd.balanceOf(eoa2), 24e18);

    //     assertEq(srusd.totalSupply(), 36e18);
    //     assertEq(srusd.totalAssets(), 36e18);

    //     assertEq(srusd.previewDeposit(12e18), 12e18);
    //     assertEq(srusd.previewDeposit(24e18), 24e18);
    //     assertEq(srusd.previewDeposit(76e18), 76e18);
    //     assertEq(srusd.previewDeposit(88e18), 88e18);
    //     assertEq(srusd.previewDeposit(100e18), 100e18);

    //     vm.prank(eoa1);
    //     srusd.deposit(76e18, eoa2);

    //     vm.prank(eoa2);
    //     srusd.deposit(100e18, eoa2);

    //     assertEq(srusd.balanceOf(eoa1), 12e18);
    //     assertEq(srusd.balanceOf(eoa2), 200e18);

    //     assertEq(srusd.totalSupply(), 212e18);
    //     assertEq(srusd.totalAssets(), 212e18);

    //     assertEq(srusd.previewDeposit(12e18), 12e18);
    //     assertEq(srusd.previewDeposit(24e18), 24e18);
    //     assertEq(srusd.previewDeposit(76e18), 76e18);
    //     assertEq(srusd.previewDeposit(88e18), 88e18);
    //     assertEq(srusd.previewDeposit(100e18), 100e18);

    //     vm.prank(eoa1);
    //     srusd.deposit(100e18, eoa1);

    //     vm.prank(eoa2);
    //     srusd.deposit(88e18, eoa1);

    //     assertEq(srusd.balanceOf(eoa1), 200e18);
    //     assertEq(srusd.balanceOf(eoa2), 200e18);

    //     assertEq(srusd.totalSupply(), 400e18);
    //     assertEq(srusd.totalAssets(), 400e18);
    // }

    // function testWithdraw() external {
    //     vm.prank(eoa1);
    //     srusd.mint(100e18, eoa1);

    //     vm.prank(eoa2);
    //     srusd.mint(100e18, eoa2);

    //     vm.prank(eoa1);
    //     srusd.deposit(100e18, eoa2);

    //     vm.prank(eoa2);
    //     srusd.deposit(100e18, eoa1);

    //     assertEq(srusd.balanceOf(eoa1), 200e18);
    //     assertEq(srusd.balanceOf(eoa2), 200e18);

    //     assertEq(srusd.totalSupply(), 400e18);
    //     assertEq(srusd.totalAssets(), 400e18);

    //     assertEq(srusd.previewWithdraw(10e18), 10e18);
    //     assertEq(srusd.previewWithdraw(12e18), 12e18);
    //     assertEq(srusd.previewWithdraw(24e18), 24e18);
    //     assertEq(srusd.previewWithdraw(64e18), 64e18);
    //     assertEq(srusd.previewWithdraw(90e18), 90e18);
    //     assertEq(srusd.previewWithdraw(100e18), 100e18);

    //     vm.prank(eoa1);
    //     srusd.withdraw(12e18, eoa1, eoa1);

    //     vm.prank(eoa2);
    //     srusd.withdraw(24e18, eoa2, eoa2);

    //     assertEq(srusd.balanceOf(eoa1), 188e18);
    //     assertEq(srusd.balanceOf(eoa2), 176e18);

    //     assertEq(srusd.totalSupply(), 364e18);
    //     assertEq(srusd.totalAssets(), 364e18);

    //     assertEq(srusd.previewWithdraw(10e18), 10e18);
    //     assertEq(srusd.previewWithdraw(12e18), 12e18);
    //     assertEq(srusd.previewWithdraw(24e18), 24e18);
    //     assertEq(srusd.previewWithdraw(64e18), 64e18);
    //     assertEq(srusd.previewWithdraw(90e18), 90e18);
    //     assertEq(srusd.previewWithdraw(100e18), 100e18);

    //     vm.prank(eoa1);
    //     srusd.withdraw(64e18, eoa2, eoa1);

    //     vm.prank(eoa2);
    //     srusd.withdraw(10e18, eoa1, eoa2);

    //     assertEq(srusd.balanceOf(eoa1), 124e18);
    //     assertEq(srusd.balanceOf(eoa2), 166e18);

    //     assertEq(srusd.totalSupply(), 290e18);
    //     assertEq(srusd.totalAssets(), 290e18);

    //     assertEq(srusd.previewWithdraw(10e18), 10e18);
    //     assertEq(srusd.previewWithdraw(12e18), 12e18);
    //     assertEq(srusd.previewWithdraw(24e18), 24e18);
    //     assertEq(srusd.previewWithdraw(64e18), 64e18);
    //     assertEq(srusd.previewWithdraw(90e18), 90e18);
    //     assertEq(srusd.previewWithdraw(100e18), 100e18);

    //     vm.prank(eoa1);
    //     srusd.withdraw(90e18, eoa1, eoa1);

    //     vm.prank(eoa2);
    //     srusd.withdraw(100e18, eoa1, eoa2);

    //     assertEq(srusd.balanceOf(eoa1), 34e18);
    //     assertEq(srusd.balanceOf(eoa2), 66e18);

    //     assertEq(srusd.totalSupply(), 100e18);
    //     assertEq(srusd.totalAssets(), 100e18);
    // }

    // function testRedeem() external {
    //     vm.prank(eoa1);
    //     srusd.mint(100e18, eoa1);

    //     vm.prank(eoa2);
    //     srusd.mint(100e18, eoa2);

    //     vm.prank(eoa1);
    //     srusd.deposit(100e18, eoa2);

    //     vm.prank(eoa2);
    //     srusd.deposit(100e18, eoa1);

    //     assertEq(srusd.balanceOf(eoa1), 200e18);
    //     assertEq(srusd.balanceOf(eoa2), 200e18);

    //     assertEq(srusd.totalSupply(), 400e18);
    //     assertEq(srusd.totalAssets(), 400e18);

    //     assertEq(srusd.previewRedeem(10e18), 10e18);
    //     assertEq(srusd.previewRedeem(12e18), 12e18);
    //     assertEq(srusd.previewRedeem(24e18), 24e18);
    //     assertEq(srusd.previewRedeem(64e18), 64e18);
    //     assertEq(srusd.previewRedeem(90e18), 90e18);
    //     assertEq(srusd.previewRedeem(100e18), 100e18);

    //     vm.prank(eoa1);
    //     srusd.redeem(12e18, eoa1, eoa1);

    //     vm.prank(eoa2);
    //     srusd.redeem(24e18, eoa2, eoa2);

    //     assertEq(srusd.balanceOf(eoa1), 188e18);
    //     assertEq(srusd.balanceOf(eoa2), 176e18);

    //     assertEq(srusd.totalSupply(), 364e18);
    //     assertEq(srusd.totalAssets(), 364e18);

    //     assertEq(srusd.previewRedeem(10e18), 10e18);
    //     assertEq(srusd.previewRedeem(12e18), 12e18);
    //     assertEq(srusd.previewRedeem(24e18), 24e18);
    //     assertEq(srusd.previewRedeem(64e18), 64e18);
    //     assertEq(srusd.previewRedeem(90e18), 90e18);
    //     assertEq(srusd.previewRedeem(100e18), 100e18);

    //     vm.prank(eoa1);
    //     srusd.redeem(64e18, eoa2, eoa1);

    //     vm.prank(eoa2);
    //     srusd.redeem(10e18, eoa1, eoa2);

    //     assertEq(srusd.balanceOf(eoa1), 124e18);
    //     assertEq(srusd.balanceOf(eoa2), 166e18);

    //     assertEq(srusd.totalSupply(), 290e18);
    //     assertEq(srusd.totalAssets(), 290e18);

    //     assertEq(srusd.previewRedeem(10e18), 10e18);
    //     assertEq(srusd.previewRedeem(12e18), 12e18);
    //     assertEq(srusd.previewRedeem(24e18), 24e18);
    //     assertEq(srusd.previewRedeem(64e18), 64e18);
    //     assertEq(srusd.previewRedeem(90e18), 90e18);
    //     assertEq(srusd.previewRedeem(100e18), 100e18);

    //     vm.prank(eoa1);
    //     srusd.redeem(90e18, eoa1, eoa1);

    //     vm.prank(eoa2);
    //     srusd.redeem(100e18, eoa1, eoa2);

    //     assertEq(srusd.balanceOf(eoa1), 34e18);
    //     assertEq(srusd.balanceOf(eoa2), 66e18);

    //     assertEq(srusd.totalSupply(), 100e18);
    //     assertEq(srusd.totalAssets(), 100e18);
    // }
}
