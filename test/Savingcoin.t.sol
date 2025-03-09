// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import {Savingcoin} from "src/Savingcoin.sol";

import {StablecoinMock} from "./StablecoinMock.sol";

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract SavingcoinTest is Test {
    Savingcoin srusd;
    StablecoinMock rusd;

    address eoa1 = vm.addr(1);
    address eoa2 = vm.addr(2);

    function setUp() external {
        rusd = new StablecoinMock("Reservoir Stablecoin Mock", "rUSDM");
        srusd = new Savingcoin(
            address(this),
            "Reservoir Savingcoin",
            "srUSD",
            rusd
        );

        srusd.grantRole(srusd.MANAGER(), address(this));

        srusd.setCap(type(uint256).max);

        rusd.mint(eoa1, 1_000_000e18);
        rusd.mint(eoa2, 1_000_000e18);

        vm.prank(eoa1);
        rusd.approve(address(srusd), type(uint256).max);

        vm.prank(eoa2);
        rusd.approve(address(srusd), type(uint256).max);
    }

    function testCompounding1() external {
        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000000000000000000000000e27);
        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 100e18);
        assertEq(srusd.previewDeposit(100e18), 100e18);

        assertEq(srusd.previewRedeem(100e18), 100e18);
        assertEq(srusd.previewWithdraw(100e18), 100e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        srusd.update(0.000000004978556233936620000e27);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 100e18);
        assertEq(srusd.previewDeposit(100e18), 100e18);

        assertEq(srusd.previewRedeem(100e18), 100e18);
        assertEq(srusd.previewWithdraw(100e18), 100e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        skip((1 * 365 days) / 4);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1.040031333856555538544750431e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 104.003133385655553854e18);
        assertEq(srusd.previewDeposit(100e18), 96.150949249950503062e18);

        assertEq(srusd.previewRedeem(100e18), 104.003133385655553854e18);
        assertEq(srusd.previewWithdraw(100e18), 96.150949249950503062e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        skip((1 * 365 days) / 4);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1.081663775198494858451164292e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 108.166377519849485845e18);
        assertEq(srusd.previewDeposit(100e18), 92.450170092503205604e18);

        assertEq(srusd.previewRedeem(100e18), 108.166377519849485845e18);
        assertEq(srusd.previewWithdraw(100e18), 92.450170092503205604e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        skip((1 * 365 days) / 4);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1.124957795436176455110636035e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 112.495779543617645511e18);
        assertEq(srusd.previewDeposit(100e18), 88.892223695580779527e18);

        assertEq(srusd.previewRedeem(100e18), 112.495779543617645511e18);
        assertEq(srusd.previewWithdraw(100e18), 88.892223695580779527e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        skip((1 * 365 days) / 4);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1.169973865979958823914560113e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 116.997386597995882391e18);
        assertEq(srusd.previewDeposit(100e18), 85.471994638308407561e18);

        assertEq(srusd.previewRedeem(100e18), 116.997386597995882391e18);
        assertEq(srusd.previewWithdraw(100e18), 85.471994638308407561e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);
    }

    function testCompounding2() external {
        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000000000000000000000000e27);
        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 100e18);
        assertEq(srusd.previewDeposit(100e18), 100e18);

        assertEq(srusd.previewRedeem(100e18), 100e18);
        assertEq(srusd.previewWithdraw(100e18), 100e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        srusd.update(0.000000003022265993024580000e27);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 100e18);
        assertEq(srusd.previewDeposit(100e18), 100e18);

        assertEq(srusd.previewRedeem(100e18), 100e18);
        assertEq(srusd.previewWithdraw(100e18), 100e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        skip((1 * 365 days) / 4);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.024113675693626149158879167e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 102.411367569362614915e18);
        assertEq(srusd.previewDeposit(100e18), 97.645410244395564886e18);

        assertEq(srusd.previewRedeem(100e18), 102.411367569362614915e18);
        assertEq(srusd.previewWithdraw(100e18), 97.645410244395564886e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        skip((1 * 365 days) / 4);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.048808631424582285126511705e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 104.880863142458228512e18);
        assertEq(srusd.previewDeposit(100e18), 95.346278628705963749e18);

        assertEq(srusd.previewRedeem(100e18), 104.880863142458228512e18);
        assertEq(srusd.previewWithdraw(100e18), 95.346278628705963749e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        skip((1 * 365 days) / 4);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.074098395326982538194401147e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 107.409839532698253819e18);
        assertEq(srusd.previewDeposit(100e18), 93.101340096088205686e18);

        assertEq(srusd.previewRedeem(100e18), 107.409839532698253819e18);
        assertEq(srusd.previewWithdraw(100e18), 93.101340096088205686e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        skip((1 * 365 days) / 4);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.099996495534941038654051027e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 109.999649553494103865e18);
        assertEq(srusd.previewDeposit(100e18), 90.909380535225106833e18);

        assertEq(srusd.previewRedeem(100e18), 109.999649553494103865e18);
        assertEq(srusd.previewWithdraw(100e18), 90.909380535225106833e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);
    }

    function testCompounding3() external {
        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000000000000000000000000e27);
        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 100e18);
        assertEq(srusd.previewDeposit(100e18), 100e18);

        assertEq(srusd.previewRedeem(100e18), 100e18);
        assertEq(srusd.previewWithdraw(100e18), 100e18);

        srusd.update(0.000000004978556233936620000e27);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 100e18);
        assertEq(srusd.previewDeposit(100e18), 100e18);

        assertEq(srusd.previewRedeem(100e18), 100e18);
        assertEq(srusd.previewWithdraw(100e18), 100e18);

        skip((1 * 365 days) / 4);

        srusd.update(0.000000004978556233936620000e27);

        assertEq(srusd.lastTimestamp(), 365 days / 4 + 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1.040031333856555538544750431e27);
        assertEq(srusd.compoundFactorAccum(), 1.040031333856555538544750431e27);

        assertEq(srusd.previewMint(100e18), 104.003133385655553854e18);
        assertEq(srusd.previewDeposit(100e18), 96.150949249950503062e18);

        assertEq(srusd.previewRedeem(100e18), 104.003133385655553854e18);
        assertEq(srusd.previewWithdraw(100e18), 96.150949249950503062e18);

        skip((1 * 365 days) / 4);

        srusd.update(0.000000004978556233936620000e27);

        assertEq(srusd.lastTimestamp(), 365 days / 2 + 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1.081665175403446086816146732e27);
        assertEq(srusd.compoundFactorAccum(), 1.081665175403446086816146732e27);

        assertEq(srusd.previewMint(100e18), 108.166517540344608681e18);
        assertEq(srusd.previewDeposit(100e18), 92.450050416665572073e18);

        assertEq(srusd.previewRedeem(100e18), 108.166517540344608681e18);
        assertEq(srusd.previewWithdraw(100e18), 92.450050416665572073e18);

        skip((1 * 365 days) / 4);

        srusd.update(0.000000004978556233936620000e27);

        assertEq(srusd.lastTimestamp(), (3 * 365 days) / 4 + 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1.124965675161031143307831512e27);
        assertEq(srusd.compoundFactorAccum(), 1.124965675161031143307831512e27);

        assertEq(srusd.previewMint(100e18), 112.496567516103114330e18);
        assertEq(srusd.previewDeposit(100e18), 88.891601057681767802e18);

        assertEq(srusd.previewRedeem(100e18), 112.496567516103114330e18);
        assertEq(srusd.previewWithdraw(100e18), 88.891601057681767802e18);

        skip((1 * 365 days) / 4);

        srusd.update(0.000000004978556233936620000e27);

        assertEq(srusd.lastTimestamp(), 365 days + 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1.169999551680567789360873840e27);
        assertEq(srusd.compoundFactorAccum(), 1.169999551680567789360873840e27);

        assertEq(srusd.previewMint(100e18), 116.999955168056778936e18);
        assertEq(srusd.previewDeposit(100e18), 85.470118220440061165e18);

        assertEq(srusd.previewRedeem(100e18), 116.999955168056778936e18);
        assertEq(srusd.previewWithdraw(100e18), 85.470118220440061165e18);
    }

    function testCompounding4() external {
        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000000000000000000000000e27);
        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 100e18);
        assertEq(srusd.previewDeposit(100e18), 100e18);

        assertEq(srusd.previewRedeem(100e18), 100e18);
        assertEq(srusd.previewWithdraw(100e18), 100e18);

        srusd.update(0.000000003022265993024580000e27);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 100e18);
        assertEq(srusd.previewDeposit(100e18), 100e18);

        assertEq(srusd.previewRedeem(100e18), 100e18);
        assertEq(srusd.previewWithdraw(100e18), 100e18);

        skip((1 * 365 days) / 4);

        srusd.update(0.000000003022265993024580000e27);

        assertEq(srusd.lastTimestamp(), 365 days / 4 + 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.024113675693626149158879167e27);
        assertEq(srusd.compoundFactorAccum(), 1.024113675693626149158879167e27);

        assertEq(srusd.previewMint(100e18), 102.411367569362614915e18);
        assertEq(srusd.previewDeposit(100e18), 97.645410244395564886e18);

        assertEq(srusd.previewRedeem(100e18), 102.411367569362614915e18);
        assertEq(srusd.previewWithdraw(100e18), 97.645410244395564886e18);

        skip((1 * 365 days) / 4);

        srusd.update(0.000000003022265993024580000e27);

        assertEq(srusd.lastTimestamp(), 365 days / 2 + 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.048808820742709674863513039e27);
        assertEq(srusd.compoundFactorAccum(), 1.048808820742709674863513039e27);

        assertEq(srusd.previewMint(100e18), 104.880882074270967486e18);
        assertEq(srusd.previewDeposit(100e18), 95.346261417963103306e18);

        assertEq(srusd.previewRedeem(100e18), 104.880882074270967486e18);
        assertEq(srusd.previewWithdraw(100e18), 95.346261417963103306e18);

        skip((1 * 365 days) / 4);

        srusd.update(0.000000003022265993024580000e27);

        assertEq(srusd.lastTimestamp(), (3 * 365 days) / 4 + 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.074099456510713858118158365e27);
        assertEq(srusd.compoundFactorAccum(), 1.074099456510713858118158365e27);

        assertEq(srusd.previewMint(100e18), 107.409945651071385811e18);
        assertEq(srusd.previewDeposit(100e18), 93.101248114263920062e18);

        assertEq(srusd.previewRedeem(100e18), 107.409945651071385811e18);
        assertEq(srusd.previewDeposit(100e18), 93.101248114263920062e18);

        skip((1 * 365 days) / 4);

        srusd.update(0.000000003022265993024580000e27);

        assertEq(srusd.lastTimestamp(), 365 days + 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.099999942467713315943987204e27);
        assertEq(srusd.compoundFactorAccum(), 1.099999942467713315943987204e27);

        assertEq(srusd.previewMint(100e18), 109.999994246771331594e18);
        assertEq(srusd.previewDeposit(100e18), 90.909095663825594472e18);

        assertEq(srusd.previewRedeem(100e18), 109.999994246771331594e18);
        assertEq(srusd.previewWithdraw(100e18), 90.909095663825594472e18);
    }

    function testCompounding5() external {
        address eoa3 = vm.addr(3);
        address eoa4 = vm.addr(4);

        vm.prank(eoa3);
        rusd.approve(address(srusd), type(uint256).max);

        vm.prank(eoa4);
        rusd.approve(address(srusd), type(uint256).max);

        rusd.mint(eoa3, 3_000_000_000e18);
        rusd.mint(eoa4, 3_000_000_000e18);

        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(1_000_000_000e18), 1_000_000_000e18);
        assertEq(srusd.previewDeposit(1_000_000_000e18), 1_000_000_000e18);

        assertEq(srusd.previewRedeem(1_000_000_000e18), 1_000_000_000e18);
        assertEq(srusd.previewWithdraw(1_000_000_000e18), 1_000_000_000e18);

        srusd.update(0.000000003022265993024580000e27);

        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        skip(365 days / 2);

        assertEq(srusd.compoundFactor(), 1.048808631424582285126511705e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(
            srusd.previewMint(1_000_000_000e18),
            1_048_808_631.424582285126511705e18
        );
        assertEq(
            srusd.previewDeposit(1_000_000_000e18),
            953_462_786.287059637493724391e18
        );

        assertEq(
            srusd.previewRedeem(1_000_000_000e18),
            1_048_808_631.424582285126511705e18
        );
        assertEq(
            srusd.previewWithdraw(1_000_000_000e18),
            953_462_786.287059637493724391e18
        );

        vm.prank(eoa3);
        srusd.mint(1_000_000_000e18, eoa3);

        vm.prank(eoa4);
        srusd.deposit(1_000_000_000e18, eoa4);

        assertEq(rusd.balanceOf(eoa3), 1_951_191_368.575417714873488295e18);
        assertEq(rusd.balanceOf(eoa4), 2_000_000_000.000000000000000000e18);

        assertEq(srusd.balanceOf(eoa3), 1_000_000_000.000000000000000000e18);
        assertEq(srusd.balanceOf(eoa4), 953_462_786.287059637493724391e18);

        assertEq(srusd.totalSupply(), 1_953_462_786.287059637493724391e18);
        assertEq(srusd.totalAssets(), 2_048_808_631.424582285126511704e18);

        srusd.update(0.000000004978556233936620000e27);

        assertEq(srusd.compoundFactor(), 1.048808631424582285126511705e27);
        assertEq(srusd.compoundFactorAccum(), 1.048808631424582285126511705e27);

        skip(365 days / 2);

        assertEq(srusd.compoundFactor(), 1.134458303727480423165050805e27);
        assertEq(srusd.compoundFactorAccum(), 1.048808631424582285126511705e27);

        assertEq(
            srusd.previewMint(1_000_000_000e18),
            1_134_458_303.727480423165050805e18
        );
        assertEq(
            srusd.previewDeposit(1_000_000_000e18),
            881_477_967.691106964425297633e18
        );

        assertEq(
            srusd.previewRedeem(1_000_000_000e18),
            1_134_458_303.727480423165050805e18
        );
        assertEq(
            srusd.previewWithdraw(1_000_000_000e18),
            881_477_967.691106964425297633e18
        );

        vm.prank(eoa3);
        srusd.mint(1_000_000_000e18, eoa3);

        vm.prank(eoa4);
        srusd.deposit(1_000_000_000e18, eoa4);

        assertEq(rusd.balanceOf(eoa3), 816_733_064.847937291708437490e18);
        assertEq(rusd.balanceOf(eoa4), 1_000_000_000.000000000000000000e18);

        assertEq(srusd.balanceOf(eoa3), 2_000_000_000.000000000000000000e18);
        assertEq(srusd.balanceOf(eoa4), 1_834_940_753.978166601919022024e18);

        assertEq(srusd.totalSupply(), 3_834_940_753.978166601919022024e18);
        assertEq(srusd.totalAssets(), 4_350_580_382.653455704781265899e18);

        vm.prank(eoa3);
        srusd.withdraw(1_000_000_000e18, eoa3, eoa3);

        vm.prank(eoa4);
        srusd.redeem(1_000_000_000e18, eoa4, eoa4);

        assertEq(rusd.balanceOf(eoa3), 1_816_733_064.847937291708437490e18);
        assertEq(rusd.balanceOf(eoa4), 2_134_458_303.727480423165050805e18);

        assertEq(srusd.balanceOf(eoa3), 1_118_522_032.308893035574702367e18);
        assertEq(srusd.balanceOf(eoa4), 834_940_753.978166601919022024e18);

        assertEq(srusd.totalSupply(), 1_953_462_786.287059637493724391e18);
        assertEq(srusd.totalAssets(), 2_216_122_078.925975281616215095e18);

        srusd.update(0.000000012857214404249400000e27);

        assertEq(srusd.compoundFactor(), 1.134458303727480423165050805e27);
        assertEq(srusd.compoundFactorAccum(), 1.134458303727480423165050805e27);

        skip(365 days / 2);

        assertEq(srusd.compoundFactor(), 1.389338791643179135596698592e27);
        assertEq(srusd.compoundFactorAccum(), 1.134458303727480423165050805e27);

        assertEq(
            srusd.previewMint(1_000_000_000e18),
            1_389_338_791.643179135596698592e18
        );
        assertEq(
            srusd.previewDeposit(1_000_000_000e18),
            719_766_845.937767372248216924e18
        );

        assertEq(
            srusd.previewRedeem(1_000_000_000e18),
            1_389_338_791.643179135596698592e18
        );
        assertEq(
            srusd.previewWithdraw(1_000_000_000e18),
            719_766_845.937767372248216924e18
        );

        vm.prank(eoa3);
        srusd.mint(1_000_000_000e18, eoa3);

        vm.prank(eoa4);
        srusd.deposit(1_000_000_000e18, eoa4);

        assertEq(rusd.balanceOf(eoa3), 427_394_273.204758156111738898e18);
        assertEq(rusd.balanceOf(eoa4), 1_134_458_303.727480423165050805e18);

        assertEq(srusd.balanceOf(eoa3), 2_118_522_032.308893035574702367e18);
        assertEq(srusd.balanceOf(eoa4), 1_554_707_599.915933974167238948e18);

        assertEq(srusd.totalSupply(), 3_673_229_632.224827009741941315e18);
        assertEq(srusd.totalAssets(), 5_103_360_418.663160457601557279e18);
    }

    function testMinimalValues() external {
        srusd.update(0.000000021979553066486800000e27);

        skip(365 days);

        assertEq(srusd.compoundFactor(), 1.988877792846064175716411401e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(0), 0);
        assertEq(srusd.previewMint(1), 1);

        assertEq(srusd.previewDeposit(0), 0);
        assertEq(srusd.previewDeposit(1), 0);

        assertEq(srusd.previewRedeem(0), 0);
        assertEq(srusd.previewRedeem(1), 1);

        assertEq(srusd.previewWithdraw(0), 0);
        assertEq(srusd.previewWithdraw(1), 0);

        vm.prank(eoa1);
        srusd.mint(0, eoa1);

        vm.prank(eoa2);
        srusd.deposit(0, eoa2);

        assertEq(srusd.balanceOf(eoa1), 0);
        assertEq(srusd.balanceOf(eoa2), 0);

        vm.prank(eoa1);
        srusd.mint(1, eoa1);

        vm.prank(eoa2);
        srusd.deposit(1, eoa2);

        assertEq(srusd.balanceOf(eoa1), 1);
        assertEq(srusd.balanceOf(eoa2), 0);

        vm.prank(eoa1);
        srusd.mint(99, eoa1);

        assertEq(srusd.balanceOf(eoa1), 100);

        vm.prank(eoa1);
        srusd.withdraw(0, eoa1, eoa1);

        assertEq(srusd.balanceOf(eoa1), 100);

        vm.prank(eoa1);
        srusd.withdraw(1, eoa1, eoa1);

        assertEq(srusd.balanceOf(eoa1), 100);

        vm.prank(eoa1);
        srusd.redeem(0, eoa1, eoa1);

        assertEq(srusd.balanceOf(eoa1), 100);

        vm.prank(eoa1);
        srusd.redeem(1, eoa1, eoa1);

        assertEq(srusd.balanceOf(eoa1), 99);

        // TODO: Handle case where `n` = 0, 1, 2, ...
    }

    function testAPY() external {
        // Test with zero rate
        assertEq(srusd.currentRate(), 0.000000000000000000000000000e27);
        assertEq(srusd.apy(), 1e27);

        // Test with 10% APR rate
        srusd.update(0.000000003022265993024580000e27);
        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);

        // The APY should be approximately 10% in RAY format
        // For 10% APR, the APY should be close to 0.1 * 1e27 = 0.1e27
        uint256 apyAt10Percent = srusd.apy();
        assertApproxEqRel(apyAt10Percent, 0.1e27, 0.01e27); // Allow 1% relative error

        // Test with 17% APR rate
        srusd.update(0.000000004978556233936620000e27);
        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);

        // The APY should be approximately 17% in RAY format
        // For 17% APR, the APY should be close to 0.17 * 1e27 = 0.17e27
        uint256 apyAt17Percent = srusd.apy();
        assertApproxEqRel(apyAt17Percent, 0.17e27, 0.01e27); // Allow 1% relative error

        // Test with 50% APR rate
        srusd.update(0.000000012857214404249400000e27);
        assertEq(srusd.currentRate(), 0.000000012857214404249400000e27);

        // The APY should be approximately 50% in RAY format
        // For 50% APR, the APY should be close to 0.5 * 1e27 = 0.5e27
        uint256 apyAt50Percent = srusd.apy();
        assertApproxEqRel(apyAt50Percent, 0.5e27, 0.01e27); // Allow 1% relative error

        // Test with 100% APR rate
        srusd.update(0.000000021979553066486800000e27);
        assertEq(srusd.currentRate(), 0.000000021979553066486800000e27);

        // The APY should be approximately 100% in RAY format
        // For 100% APR, the APY should be close to 1 * 1e27 = 1e27
        uint256 apyAt100Percent = srusd.apy();
        assertApproxEqRel(apyAt100Percent, 1e27, 0.01e27); // Allow 1% relative error

        // Verify that APY is always higher than APR due to compounding
        // (except at 0% where they're equal)
        assertTrue(apyAt10Percent > 0.1e27);
        assertTrue(apyAt17Percent > 0.17e27);
        assertTrue(apyAt50Percent > 0.5e27);
        assertTrue(apyAt100Percent > 1e27);
    }
}
