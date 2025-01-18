// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import {Savingcoin} from "src/Savingcoin.sol";

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract SavingcoinTest is Test {
    ERC20Mock rusd;

    Savingcoin srusd;

    address eoa1 = vm.addr(1);
    address eoa2 = vm.addr(2);

    function setUp() external {
        rusd = new ERC20Mock();
        srusd = new Savingcoin("Reservoir Savingcoin", "srUSD", rusd);

        // rusd.grantRole(rusd.MINTER(), address(this));

        // TODO: Remove this

        rusd.mint(eoa1, 1_000_000e18);
        rusd.mint(eoa2, 1_000_000e18);

        vm.prank(eoa1);
        rusd.approve(address(srusd), type(uint256).max);

        vm.prank(eoa2);
        rusd.approve(address(srusd), type(uint256).max);
    }

    function testInitialState() external view {
        assertEq(srusd.symbol(), "srUSD");
        assertEq(srusd.name(), "Reservoir Savingcoin");

        assertEq(srusd.decimals(), 18);
        assertEq(srusd.asset(), address(rusd));

        assertEq(srusd.totalAssets(), 0);
        assertEq(srusd.totalSupply(), 0);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0e27);
        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(rusd.balanceOf(eoa1), 1_000_000e18);
        assertEq(rusd.balanceOf(eoa2), 1_000_000e18);

        assertEq(rusd.totalSupply(), 2_000_000e18);
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
        assertEq(srusd.compoundFactor(), 1.040021255292012108887922967e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 104.002125529201210888e18);
        assertEq(srusd.previewDeposit(100e18), 96.151881022780141593e18);

        assertEq(srusd.previewRedeem(100e18), 104.002125529201210888e18);
        assertEq(srusd.previewWithdraw(100e18), 96.151881022780141593e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        skip((1 * 365 days) / 4);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1.081583146666748810215206893e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 108.158314666674881021e18);
        assertEq(srusd.previewDeposit(100e18), 92.457061954212777596e18);

        assertEq(srusd.previewRedeem(100e18), 108.158314666674881021e18);
        assertEq(srusd.previewWithdraw(100e18), 92.457061954212777596e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        skip((1 * 365 days) / 4);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1.124685674124210103981851777e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 112.468567412421010398e18);
        assertEq(srusd.previewDeposit(100e18), 88.913731454674878494e18);

        assertEq(srusd.previewRedeem(100e18), 112.468567412421010398e18);
        assertEq(srusd.previewWithdraw(100e18), 88.913731454674878494e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        skip((1 * 365 days) / 4);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1.169328837664395990187857619e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 116.932883766439599018e18);
        assertEq(srusd.previewDeposit(100e18), 85.519142929664552823e18);

        assertEq(srusd.previewRedeem(100e18), 116.932883766439599018e18);
        assertEq(srusd.previewWithdraw(100e18), 85.519142929664552823e18);

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
        assertEq(srusd.compoundFactor(), 1.024111421005483501050066290e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 102.411142100548350105e18);
        assertEq(srusd.previewDeposit(100e18), 97.645625220953922074e18);

        assertEq(srusd.previewRedeem(100e18), 102.411142100548350105e18);
        assertEq(srusd.previewWithdraw(100e18), 97.645625220953922074e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        skip((1 * 365 days) / 4);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.048790593915935605980027195e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 104.879059391593560598e18);
        assertEq(srusd.previewDeposit(100e18), 95.347918431098520115e18);

        assertEq(srusd.previewRedeem(100e18), 104.879059391593560598e18);
        assertEq(srusd.previewWithdraw(100e18), 95.347918431098520115e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        skip((1 * 365 days) / 4);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.074037518731356314789882716e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 107.403751873135631478e18);
        assertEq(srusd.previewDeposit(100e18), 93.106617092966288390e18);

        assertEq(srusd.previewRedeem(100e18), 107.403751873135631478e18);
        assertEq(srusd.previewWithdraw(100e18), 93.106617092966288390e18);

        assertLe(srusd.previewWithdraw(srusd.previewMint(100e18)), 100e18);
        assertLe(srusd.previewRedeem(srusd.previewDeposit(100e18)), 100e18);

        assertLe(srusd.previewMint(srusd.previewWithdraw(100e18)), 100e18);
        assertLe(srusd.previewDeposit(srusd.previewRedeem(100e18)), 100e18);

        skip((1 * 365 days) / 4);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.099852195451745627479632852e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 109.985219545174562747e18);
        assertEq(srusd.previewDeposit(100e18), 90.921307802569505037e18);

        assertEq(srusd.previewRedeem(100e18), 109.985219545174562747e18);
        assertEq(srusd.previewWithdraw(100e18), 90.921307802569505037e18);

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
        assertEq(srusd.compoundFactor(), 1.040021255292012108887922967e27);
        assertEq(srusd.compoundFactorAccum(), 1.040021255292012108887922967e27);

        assertEq(srusd.previewMint(100e18), 104.002125529201210888e18);
        assertEq(srusd.previewDeposit(100e18), 96.151881022780141593e18);

        assertEq(srusd.previewRedeem(100e18), 104.002125529201210888e18);
        assertEq(srusd.previewWithdraw(100e18), 96.151881022780141593e18);

        skip((1 * 365 days) / 4);

        srusd.update(0.000000004978556233936620000e27);

        assertEq(srusd.lastTimestamp(), 365 days / 2 + 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1.081644211459172625006899668e27);
        assertEq(srusd.compoundFactorAccum(), 1.081644211459172625006899668e27);

        assertEq(srusd.previewMint(100e18), 108.164421145917262500e18);
        assertEq(srusd.previewDeposit(100e18), 92.451842242188679278e18);

        assertEq(srusd.previewRedeem(100e18), 108.164421145917262500e18);
        assertEq(srusd.previewWithdraw(100e18), 92.451842242188679278e18);

        skip((1 * 365 days) / 4);

        srusd.update(0.000000004978556233936620000e27);

        assertEq(srusd.lastTimestamp(), (3 * 365 days) / 4 + 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1.124932970581107301975927668e27);
        assertEq(srusd.compoundFactorAccum(), 1.124932970581107301975927668e27);

        assertEq(srusd.previewMint(100e18), 112.493297058110730197e18);
        assertEq(srusd.previewDeposit(100e18), 88.894185356077651263e18);

        assertEq(srusd.previewRedeem(100e18), 112.493297058110730197e18);
        assertEq(srusd.previewWithdraw(100e18), 88.894185356077651263e18);

        skip((1 * 365 days) / 4);

        srusd.update(0.000000004978556233936620000e27);

        assertEq(srusd.lastTimestamp(), 365 days + 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1.169954200183135344587613222e27);
        assertEq(srusd.compoundFactorAccum(), 1.169954200183135344587613222e27);

        assertEq(srusd.previewMint(100e18), 116.995420018313534458e18);
        assertEq(srusd.previewDeposit(100e18), 85.473431339745430802e18);

        assertEq(srusd.previewRedeem(100e18), 116.995420018313534458e18);
        assertEq(srusd.previewWithdraw(100e18), 85.473431339745430802e18);
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
        assertEq(srusd.compoundFactor(), 1.024111421005483501050066290e27);
        assertEq(srusd.compoundFactorAccum(), 1.024111421005483501050066290e27);

        assertEq(srusd.previewMint(100e18), 102.411142100548350105e18);
        assertEq(srusd.previewDeposit(100e18), 97.645625220953922074e18);

        assertEq(srusd.previewRedeem(100e18), 102.411142100548350105e18);
        assertEq(srusd.previewWithdraw(100e18), 97.645625220953922074e18);

        skip((1 * 365 days) / 4);

        srusd.update(0.000000003022265993024580000e27);

        assertEq(srusd.lastTimestamp(), 365 days / 2 + 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.048804202633870673104906829e27);
        assertEq(srusd.compoundFactorAccum(), 1.048804202633870673104906829e27);

        assertEq(srusd.previewMint(100e18), 104.880420263387067310e18);
        assertEq(srusd.previewDeposit(100e18), 95.346681247909926832e18);

        assertEq(srusd.previewRedeem(100e18), 104.880420263387067310e18);
        assertEq(srusd.previewWithdraw(100e18), 95.346681247909926832e18);

        skip((1 * 365 days) / 4);

        srusd.update(0.000000003022265993024580000e27);

        assertEq(srusd.lastTimestamp(), (3 * 365 days) / 4 + 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.074092362315896356710149382e27);
        assertEq(srusd.compoundFactorAccum(), 1.074092362315896356710149382e27);

        assertEq(srusd.previewMint(100e18), 107.409236231589635671e18);
        assertEq(srusd.previewDeposit(100e18), 93.101863031951679277e18);

        assertEq(srusd.previewRedeem(100e18), 107.409236231589635671e18);
        assertEq(srusd.previewDeposit(100e18), 93.101863031951679277e18);

        skip((1 * 365 days) / 4);

        srusd.update(0.000000003022265993024580000e27);

        assertEq(srusd.lastTimestamp(), 365 days + 1);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.099990255462469255355781368e27);
        assertEq(srusd.compoundFactorAccum(), 1.099990255462469255355781368e27);

        assertEq(srusd.previewMint(100e18), 109.999025546246925535e18);
        assertEq(srusd.previewDeposit(100e18), 90.909896249905384822e18);

        assertEq(srusd.previewRedeem(100e18), 109.999025546246925535e18);
        assertEq(srusd.previewWithdraw(100e18), 90.909896249905384822e18);
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

        assertEq(srusd.compoundFactor(), 1.048790593915935605980027195e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(
            srusd.previewMint(1_000_000_000e18),
            1_048_790_593.915935605980027195e18
        );
        assertEq(
            srusd.previewDeposit(1_000_000_000e18),
            953_479_184.310985201150422342e18
        );

        assertEq(
            srusd.previewRedeem(1_000_000_000e18),
            1_048_790_593.915935605980027195e18
        );
        assertEq(
            srusd.previewWithdraw(1_000_000_000e18),
            953_479_184.310985201150422342e18
        );

        vm.prank(eoa3);
        srusd.mint(1_000_000_000e18, eoa3);

        vm.prank(eoa4);
        srusd.deposit(1_000_000_000e18, eoa4);

        assertEq(rusd.balanceOf(eoa3), 1_951_209_406.084064394019972805e18);
        assertEq(rusd.balanceOf(eoa4), 2_000_000_000.000000000000000000e18);

        assertEq(srusd.balanceOf(eoa3), 1_000_000_000.000000000000000000e18);
        assertEq(srusd.balanceOf(eoa4), 953_479_184.310985201150422342e18);

        assertEq(srusd.totalSupply(), 1_953_479_184.310985201150422342e18);
        assertEq(srusd.totalAssets(), 2_048_790_593.915935605980027195e18);

        srusd.update(0.000000004978556233936620000e27);

        assertEq(srusd.compoundFactor(), 1.048790593915935605980027195e27);
        assertEq(srusd.compoundFactorAccum(), 1.048790593915935605980027195e27);

        skip(365 days / 2);

        assertEq(srusd.compoundFactor(), 1.134354230762085972907644497e27);
        assertEq(srusd.compoundFactorAccum(), 1.048790593915935605980027195e27);

        assertEq(
            srusd.previewMint(1_000_000_000e18),
            1_134_354_230.762085972907644497e18
        );
        assertEq(
            srusd.previewDeposit(1_000_000_000e18),
            881_558_840.158930225545284028e18
        );

        assertEq(
            srusd.previewRedeem(1_000_000_000e18),
            1_134_354_230.762085972907644497e18
        );
        assertEq(
            srusd.previewWithdraw(1_000_000_000e18),
            881_558_840.158930225545284028e18
        );

        vm.prank(eoa3);
        srusd.mint(1_000_000_000e18, eoa3);

        vm.prank(eoa4);
        srusd.deposit(1_000_000_000e18, eoa4);

        assertEq(rusd.balanceOf(eoa3), 816_855_175.321978421112328308e18);
        assertEq(rusd.balanceOf(eoa4), 1_000_000_000.000000000000000000e18);

        assertEq(srusd.balanceOf(eoa3), 2_000_000_000.000000000000000000e18);
        assertEq(srusd.balanceOf(eoa4), 1_835_038_024.469915426695706370e18);

        assertEq(srusd.totalSupply(), 3_835_038_024.469915426695706370e18);
        assertEq(srusd.totalAssets(), 4_183_144_824.678021578887671692e18);

        vm.prank(eoa3);
        srusd.withdraw(1_000_000_000e18, eoa3, eoa3);

        vm.prank(eoa4);
        srusd.redeem(1_000_000_000e18, eoa4, eoa4);

        assertEq(rusd.balanceOf(eoa3), 1_816_855_175.321978421112328308e18);
        assertEq(rusd.balanceOf(eoa4), 2_134_354_230.762085972907644497e18);

        assertEq(srusd.balanceOf(eoa3), 1_118_441_159.841069774454715972e18);
        assertEq(srusd.balanceOf(eoa4), 835_038_024.469915426695706370e18);

        assertEq(srusd.totalSupply(), 1_953_479_184.310985201150422342e18);
        assertEq(srusd.totalAssets(), 2_048_790_593.915935605980027195e18);

        srusd.update(0.000000012857214404249400000e27);

        assertEq(srusd.compoundFactor(), 1.134354230762085972907644497e27);
        assertEq(srusd.compoundFactorAccum(), 1.134354230762085972907644497e27);

        skip(365 days / 2);

        assertEq(srusd.compoundFactor(), 1.387636019826823051304703280e27);
        assertEq(srusd.compoundFactorAccum(), 1.134354230762085972907644497e27);

        assertEq(
            srusd.previewMint(1_000_000_000e18),
            1_387_636_019.826823051304703280e18
        );
        assertEq(
            srusd.previewDeposit(1_000_000_000e18),
            720_650_073.731006190546838253e18
        );

        assertEq(
            srusd.previewRedeem(1_000_000_000e18),
            1_387_636_019.826823051304703280e18
        );
        assertEq(
            srusd.previewWithdraw(1_000_000_000e18),
            720_650_073.731006190546838253e18
        );

        vm.prank(eoa3);
        srusd.mint(1_000_000_000e18, eoa3);

        vm.prank(eoa4);
        srusd.deposit(1_000_000_000e18, eoa4);

        assertEq(rusd.balanceOf(eoa3), 429_219_155.495155369807625028e18);
        assertEq(rusd.balanceOf(eoa4), 1_134_354_230.762085972907644497e18);

        assertEq(srusd.balanceOf(eoa3), 2_118_441_159.841069774454715972e18);
        assertEq(srusd.balanceOf(eoa4), 1_555_688_098.200921617242544623e18);

        assertEq(srusd.totalSupply(), 3_674_129_258.041991391697260595e18);
        assertEq(srusd.totalAssets(), 4_436_426_613.742758657284730475e18);
    }

    function testMinimalValues() external {
        srusd.update(0.000000021979553066486800000e27);

        skip(365 days);

        assertEq(srusd.compoundFactor(), 1.933373688273757765720383190e27);
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
    }
}
