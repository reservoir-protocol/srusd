// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

import {Savingcoin} from "src/Savingcoin.sol";

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract RatesTest is Test {
    ERC20Mock rusd;

    Savingcoin srusd;

    address eoa1 = vm.addr(1);
    address eoa2 = vm.addr(2);

    function setUp() external {
        rusd = new ERC20Mock();
        srusd = new Savingcoin("Reservoir Savingcoin", "srUSD", rusd);

        // rusd.grantRole(rusd.MINTER(), address(this));

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

    function testDeposit() external {
        assertEq(srusd.previewDeposit(100e18), 100e18);

        vm.prank(eoa1);
        srusd.deposit(100e18, eoa1);

        vm.prank(eoa2);
        srusd.deposit(100e18, eoa2);

        assertEq(rusd.balanceOf(eoa1), 1_000_000e18 - 100e18);
        assertEq(rusd.balanceOf(eoa2), 1_000_000e18 - 100e18);

        assertEq(srusd.balanceOf(eoa1), 100e18);
        assertEq(srusd.balanceOf(eoa2), 100e18);

        assertEq(srusd.totalSupply(), 200e18);
        assertEq(srusd.totalAssets(), 200e18);

        srusd.update(0.000000012857214404249400000e27);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000012857214404249400000e27);
        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        vm.warp(365 days);

        assertEq(srusd.compoundFactor(), 1.498775946215446644688504438e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewDeposit(100e18), 66.721113487649447483e18);

        vm.prank(eoa1);
        srusd.deposit(100e18, eoa2);

        vm.prank(eoa2);
        srusd.deposit(100e18, eoa1);

        assertEq(rusd.balanceOf(eoa1), 1_000_000e18 - 200e18);
        assertEq(rusd.balanceOf(eoa2), 1_000_000e18 - 200e18);

        assertEq(srusd.balanceOf(eoa1), 166.721113487649447483e18);
        assertEq(srusd.balanceOf(eoa2), 166.721113487649447483e18);

        assertEq(
            srusd.totalSupply(),
            srusd.balanceOf(eoa2) + srusd.balanceOf(eoa2)
        );
        assertEq(srusd.totalAssets(), 400e18);

        srusd.update(0.000000021979553066486800000e27);

        assertEq(srusd.lastTimestamp(), 365 days);

        assertEq(srusd.currentRate(), 0.000000021979553066486800000e27);

        assertEq(srusd.compoundFactor(), 1.498775946215446644688504438e27);
        assertEq(srusd.compoundFactorAccum(), 1.498775946215446644688504438e27);

        vm.warp(2 * 365 days);

        assertEq(srusd.compoundFactor(), 2.980882195879748914500237647e27);
        assertEq(srusd.compoundFactorAccum(), 1.498775946215446644688504438e27);

        assertEq(srusd.previewDeposit(100e18), 33.547115729102793796e18);

        vm.prank(eoa1);
        srusd.deposit(100e18, eoa1);

        vm.prank(eoa2);
        srusd.deposit(100e18, eoa2);

        assertEq(rusd.balanceOf(eoa1), 1_000_000e18 - 300e18);
        assertEq(rusd.balanceOf(eoa2), 1_000_000e18 - 300e18);

        assertEq(srusd.balanceOf(eoa1), 200.268229216752241279e18);
        assertEq(srusd.balanceOf(eoa2), 200.268229216752241279e18);

        assertEq(
            srusd.totalSupply(),
            srusd.balanceOf(eoa2) + srusd.balanceOf(eoa2)
        );
        assertEq(srusd.totalAssets(), 600e18);
    }

    function testMint() external {
        assertEq(srusd.previewMint(100e18), 100e18);

        vm.prank(eoa1);
        srusd.mint(100e18, eoa1);

        vm.prank(eoa2);
        srusd.mint(100e18, eoa2);

        assertEq(rusd.balanceOf(eoa1), 1_000_000e18 - 100e18);
        assertEq(rusd.balanceOf(eoa2), 1_000_000e18 - 100e18);

        assertEq(srusd.balanceOf(eoa1), 100e18);
        assertEq(srusd.balanceOf(eoa2), 100e18);

        assertEq(srusd.totalSupply(), 200e18);
        assertEq(srusd.totalAssets(), 200e18);

        srusd.update(0.000000004978556233936620000e27);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        vm.warp(365 days);

        assertEq(srusd.compoundFactor(), 1.169973860158389478332097594e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewMint(100e18), 116.997386015838947833e18);

        vm.prank(eoa1);
        srusd.mint(100e18, eoa2);

        vm.prank(eoa2);
        srusd.mint(100e18, eoa1);

        assertEq(rusd.balanceOf(eoa1), 999_783.002613984161052167e18);
        assertEq(rusd.balanceOf(eoa2), 999_783.002613984161052167e18);

        assertEq(srusd.balanceOf(eoa1), 200e18);
        assertEq(srusd.balanceOf(eoa2), 200e18);

        assertEq(srusd.totalSupply(), 400e18);
        assertEq(
            srusd.totalAssets(),
            2_000_000e18 - rusd.balanceOf(eoa1) - rusd.balanceOf(eoa2)
        );

        srusd.update(0.000000003022265993024580000e27);

        assertEq(srusd.lastTimestamp(), 365 days);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.169973860158389478332097594e27);
        assertEq(srusd.compoundFactorAccum(), 1.169973860158389478332097594e27);

        vm.warp(2 * 365 days);

        assertEq(srusd.compoundFactor(), 1.286967146041715602961404116e27);
        assertEq(srusd.compoundFactorAccum(), 1.169973860158389478332097594e27);

        assertEq(srusd.previewMint(100e18), 128.696714604171560296e18);

        vm.prank(eoa1);
        srusd.mint(100e18, eoa1);

        vm.prank(eoa2);
        srusd.mint(100e18, eoa2);

        assertEq(rusd.balanceOf(eoa1), 999_654.305899379989491871e18);
        assertEq(rusd.balanceOf(eoa2), 999_654.305899379989491871e18);

        assertEq(srusd.balanceOf(eoa1), 300e18);
        assertEq(srusd.balanceOf(eoa2), 300e18);

        assertEq(srusd.totalSupply(), 600e18);
        assertEq(
            srusd.totalAssets(),
            2_000_000e18 - rusd.balanceOf(eoa1) - rusd.balanceOf(eoa2)
        );
    }

    function testWithdraw() external {
        assertEq(srusd.previewWithdraw(100e18), 100e18);

        vm.prank(eoa1);
        srusd.deposit(400e18, eoa1);

        vm.prank(eoa2);
        srusd.deposit(400e18, eoa2);

        assertEq(rusd.balanceOf(eoa1), 1_000_000e18 - 400e18);
        assertEq(rusd.balanceOf(eoa2), 1_000_000e18 - 400e18);

        assertEq(srusd.balanceOf(eoa1), 400e18);
        assertEq(srusd.balanceOf(eoa2), 400e18);

        assertEq(srusd.totalSupply(), 800e18);
        assertEq(srusd.totalAssets(), 800e18);

        srusd.update(0.000000012857214404249400000e27);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000012857214404249400000e27);
        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        vm.warp(365 days);

        assertEq(srusd.compoundFactor(), 1.498775946215446644688504438e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewWithdraw(100e18), 66.721113487649447483e18);

        vm.prank(eoa1);
        srusd.withdraw(100e18, eoa2, eoa1);

        vm.prank(eoa2);
        srusd.withdraw(100e18, eoa1, eoa2);

        assertEq(rusd.balanceOf(eoa1), 1_000_000e18 - 300e18);
        assertEq(rusd.balanceOf(eoa2), 1_000_000e18 - 300e18);

        assertEq(srusd.balanceOf(eoa1), 333.278886512350552517e18);
        assertEq(srusd.balanceOf(eoa2), 333.278886512350552517e18);

        assertEq(
            srusd.totalSupply(),
            srusd.balanceOf(eoa2) + srusd.balanceOf(eoa2)
        );
        assertEq(srusd.totalAssets(), 600e18);

        srusd.update(0.000000021979553066486800000e27);

        assertEq(srusd.lastTimestamp(), 365 days);

        assertEq(srusd.currentRate(), 0.000000021979553066486800000e27);

        assertEq(srusd.compoundFactor(), 1.498775946215446644688504438e27);
        assertEq(srusd.compoundFactorAccum(), 1.498775946215446644688504438e27);

        vm.warp(2 * 365 days);

        assertEq(srusd.compoundFactor(), 2.980882195879748914500237647e27);
        assertEq(srusd.compoundFactorAccum(),1.498775946215446644688504438e27);

        assertEq(srusd.previewWithdraw(100e18), 33.547115729102793796e18);

        vm.prank(eoa1);
        srusd.withdraw(100e18, eoa1, eoa1);

        vm.prank(eoa2);
        srusd.withdraw(100e18, eoa2, eoa2);

        assertEq(rusd.balanceOf(eoa1), 1_000_000e18 - 200e18);
        assertEq(rusd.balanceOf(eoa2), 1_000_000e18 - 200e18);

        assertEq(srusd.balanceOf(eoa1), 299.731770783247758721e18);
        assertEq(srusd.balanceOf(eoa2), 299.731770783247758721e18);

        assertEq(
            srusd.totalSupply(),
            srusd.balanceOf(eoa2) + srusd.balanceOf(eoa2)
        );
        assertEq(srusd.totalAssets(), 400e18);
    }

    function testRedeem() external {
        assertEq(srusd.previewRedeem(100e18), 100e18);

        vm.prank(eoa1);
        srusd.mint(400e18, eoa1);

        vm.prank(eoa2);
        srusd.mint(400e18, eoa2);

        assertEq(rusd.balanceOf(eoa1), 1_000_000e18 - 400e18);
        assertEq(rusd.balanceOf(eoa2), 1_000_000e18 - 400e18);

        assertEq(srusd.balanceOf(eoa1), 400e18);
        assertEq(srusd.balanceOf(eoa2), 400e18);

        assertEq(srusd.totalSupply(), 800e18);
        assertEq(srusd.totalAssets(), 800e18);

        srusd.update(0.000000004978556233936620000e27);

        assertEq(srusd.lastTimestamp(), 1);

        assertEq(srusd.currentRate(), 0.000000004978556233936620000e27);
        assertEq(srusd.compoundFactor(), 1e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        vm.warp(365 days);

        assertEq(srusd.compoundFactor(), 1.169973860158389478332097594e27);
        assertEq(srusd.compoundFactorAccum(), 1e27);

        assertEq(srusd.previewRedeem(100e18), 116.997386015838947833e18);

        vm.prank(eoa1);
        srusd.redeem(100e18, eoa2, eoa1);

        vm.prank(eoa2);
        srusd.redeem(100e18, eoa1, eoa2);

        assertEq(rusd.balanceOf(eoa1), 999_716.997386015838947833e18);
        assertEq(rusd.balanceOf(eoa2), 999_716.997386015838947833e18);

        assertEq(srusd.balanceOf(eoa1), 300e18);
        assertEq(srusd.balanceOf(eoa2), 300e18);

        assertEq(srusd.totalSupply(), 600e18);
        assertEq(
            srusd.totalAssets(),
            2_000_000e18 - rusd.balanceOf(eoa1) - rusd.balanceOf(eoa2)
        );

        srusd.update(0.000000003022265993024580000e27);

        assertEq(srusd.lastTimestamp(), 365 days);

        assertEq(srusd.currentRate(), 0.000000003022265993024580000e27);
        assertEq(srusd.compoundFactor(), 1.169973860158389478332097594e27);
        assertEq(srusd.compoundFactorAccum(), 1.169973860158389478332097594e27);

        vm.warp(2 * 365 days);

        assertEq(srusd.compoundFactor(), 1.286967146041715602961404116e27);
        assertEq(srusd.compoundFactorAccum(), 1.169973860158389478332097594e27);

        assertEq(srusd.previewRedeem(100e18), 128.696714604171560296e18);

        vm.prank(eoa1);
        srusd.redeem(100e18, eoa1, eoa1);

        vm.prank(eoa2);
        srusd.redeem(100e18, eoa2, eoa2);

        assertEq(rusd.balanceOf(eoa1), 999_845.694100620010508129e18);
        assertEq(rusd.balanceOf(eoa2), 999_845.694100620010508129e18);

        assertEq(srusd.balanceOf(eoa1), 200e18);
        assertEq(srusd.balanceOf(eoa2), 200e18);

        assertEq(srusd.totalSupply(), 400e18);
        assertEq(
            srusd.totalAssets(),
            2_000_000e18 - rusd.balanceOf(eoa1) - rusd.balanceOf(eoa2)
        );
    }
}
