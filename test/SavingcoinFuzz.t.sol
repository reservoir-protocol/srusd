// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {Savingcoin} from "src/Savingcoin.sol";
import {StablecoinMock} from "./StablecoinMock.sol";

/// @title SavingcoinFuzzTest
/// @notice Comprehensive fuzz testing for Savingcoin contract
contract SavingcoinFuzzTest is Test {
    Savingcoin public srusd;
    StablecoinMock public rusd;

    address public admin = makeAddr("admin");
    address public manager = makeAddr("manager");

    uint256 public constant RAY = 1e27;
    uint256 public constant MAX_RATE = RAY - 1; // Just below 100%
    
    function setUp() external {
        rusd = new StablecoinMock("Reservoir Stablecoin Mock", "rUSDM");
        srusd = new Savingcoin(admin, "Reservoir Savingcoin", "srUSD", rusd);

        vm.startPrank(admin);
        srusd.grantRole(srusd.MANAGER(), manager);
        vm.stopPrank();

        vm.startPrank(manager);
        srusd.setCap(type(uint256).max);
        vm.stopPrank();
    }

    /// @notice Fuzz test for deposit functionality
    function testFuzz_Deposit(uint96 amount, address user) public {
        // Bound inputs
        amount = uint96(bound(amount, 1, type(uint96).max));
        vm.assume(user != address(0));
        vm.assume(user != address(srusd));

        // Setup
        rusd.mint(user, amount);
        vm.startPrank(user);
        rusd.approve(address(srusd), type(uint256).max);

        // Preview deposit
        uint256 expectedShares = srusd.previewDeposit(amount);

        // Execute deposit
        uint256 actualShares = srusd.deposit(amount, user);

        // Assertions
        assertEq(actualShares, expectedShares, "Shares should match preview");
        assertEq(srusd.balanceOf(user), actualShares, "User should receive shares");
        assertEq(rusd.balanceOf(user), 0, "User rUSD should be burned");
        
        vm.stopPrank();
    }

    /// @notice Fuzz test for mint functionality
    function testFuzz_Mint(uint96 shares, address user) public {
        // Bound inputs
        shares = uint96(bound(shares, 1, type(uint96).max));
        vm.assume(user != address(0));
        vm.assume(user != address(srusd));

        // Preview mint to get required assets
        uint256 requiredAssets = srusd.previewMint(shares);

        // Setup
        rusd.mint(user, requiredAssets);
        vm.startPrank(user);
        rusd.approve(address(srusd), type(uint256).max);

        // Execute mint
        uint256 actualAssets = srusd.mint(shares, user);

        // Assertions
        assertEq(srusd.balanceOf(user), shares, "User should receive exact shares");
        assertEq(actualAssets, requiredAssets, "Assets should match preview");
        
        vm.stopPrank();
    }

    /// @notice Fuzz test for withdraw functionality
    function testFuzz_Withdraw(uint96 depositAmount, uint96 withdrawAmount) public {
        address user = makeAddr("user");
        
        // Bound inputs
        depositAmount = uint96(bound(depositAmount, 100, type(uint96).max));
        withdrawAmount = uint96(bound(withdrawAmount, 1, depositAmount));

        // Setup - deposit first
        rusd.mint(user, depositAmount);
        vm.startPrank(user);
        rusd.approve(address(srusd), type(uint256).max);
        srusd.deposit(depositAmount, user);

        uint256 sharesBefore = srusd.balanceOf(user);

        // Preview withdraw
        uint256 expectedShares = srusd.previewWithdraw(withdrawAmount);

        // Execute withdraw
        uint256 actualShares = srusd.withdraw(withdrawAmount, user, user);

        // Assertions
        assertEq(actualShares, expectedShares, "Shares burned should match preview");
        assertEq(srusd.balanceOf(user), sharesBefore - actualShares, "Shares should be burned");
        assertEq(rusd.balanceOf(user), withdrawAmount, "User should receive assets");
        
        vm.stopPrank();
    }

    /// @notice Fuzz test for redeem functionality
    function testFuzz_Redeem(uint96 depositAmount, uint96 redeemShares) public {
        address user = makeAddr("user");
        
        // Bound inputs
        depositAmount = uint96(bound(depositAmount, 100, type(uint96).max));

        // Setup - deposit first
        rusd.mint(user, depositAmount);
        vm.startPrank(user);
        rusd.approve(address(srusd), type(uint256).max);
        uint256 shares = srusd.deposit(depositAmount, user);

        // Bound redeem amount to available shares
        redeemShares = uint96(bound(redeemShares, 1, shares));

        // Preview redeem
        uint256 expectedAssets = srusd.previewRedeem(redeemShares);

        // Execute redeem
        uint256 actualAssets = srusd.redeem(redeemShares, user, user);

        // Assertions
        assertEq(actualAssets, expectedAssets, "Assets received should match preview");
        assertEq(srusd.balanceOf(user), shares - redeemShares, "Shares should be burned");
        assertEq(rusd.balanceOf(user), actualAssets, "User should receive assets");
        
        vm.stopPrank();
    }

    /// @notice Fuzz test for rate updates
    function testFuzz_UpdateRate(uint88 rate, uint32 timeDelta) public {
        // Bound inputs - rate must be below RAY (100%)
        rate = uint88(bound(rate, 0, MAX_RATE));
        timeDelta = uint32(bound(timeDelta, 1, 365 days * 10));

        vm.prank(manager);
        srusd.update(rate);

        uint256 factorBefore = srusd.compoundFactor();
        
        // Move time forward
        skip(timeDelta);

        uint256 factorAfter = srusd.compoundFactor();

        // Assertions
        if (rate > 0) {
            assertGe(factorAfter, factorBefore, "Compound factor should increase with positive rate");
        } else {
            assertEq(factorAfter, factorBefore, "Compound factor should stay constant with zero rate");
        }
    }

    /// @notice Fuzz test for cap enforcement
    function testFuzz_CapEnforcement(uint128 cap, uint96 depositAmount) public {
        address user = makeAddr("user");
        
        // Bound inputs
        cap = uint128(bound(cap, 1e18, type(uint128).max));
        depositAmount = uint96(bound(depositAmount, 1e18, type(uint96).max));

        vm.prank(manager);
        srusd.setCap(cap);

        rusd.mint(user, depositAmount);
        vm.startPrank(user);
        rusd.approve(address(srusd), type(uint256).max);

        if (depositAmount <= cap) {
            // Should succeed
            uint256 shares = srusd.deposit(depositAmount, user);
            assertGt(shares, 0, "Should receive shares when under cap");
        } else {
            // Should revert
            vm.expectRevert("newly issued shares can not exceed notional cap");
            srusd.deposit(depositAmount, user);
        }
        
        vm.stopPrank();
    }

    /// @notice Fuzz test for conversions consistency
    function testFuzz_ConversionConsistency(uint96 amount, uint88 rate, uint32 timeDelta) public {
        // Bound inputs
        amount = uint96(bound(amount, 1e18, type(uint96).max));
        rate = uint88(bound(rate, 0, MAX_RATE / 10)); // Use lower rate to avoid overflow
        timeDelta = uint32(bound(timeDelta, 0, 365 days));

        vm.prank(manager);
        srusd.update(rate);

        skip(timeDelta);

        // Test asset to share to asset conversion
        uint256 shares = srusd.convertToShares(amount);
        uint256 assetsBack = srusd.convertToAssets(shares);
        
        // Should be approximately equal (allowing for rounding)
        assertApproxEqAbs(assetsBack, amount, 2, "Asset->Share->Asset should be consistent");

        // Test share to asset to share conversion
        uint256 assets = srusd.convertToAssets(amount);
        uint256 sharesBack = srusd.convertToShares(assets);
        
        // Should be approximately equal (allowing for rounding)
        assertApproxEqAbs(sharesBack, amount, 2, "Share->Asset->Share should be consistent");
    }

    /// @notice Fuzz test for multiple sequential deposits
    function testFuzz_SequentialDeposits(
        uint64 deposit1,
        uint64 deposit2,
        uint64 deposit3,
        uint88 rate
    ) public {
        address user = makeAddr("user");
        
        // Bound inputs
        deposit1 = uint64(bound(deposit1, 1e18, type(uint64).max));
        deposit2 = uint64(bound(deposit2, 1e18, type(uint64).max));
        deposit3 = uint64(bound(deposit3, 1e18, type(uint64).max));
        rate = uint88(bound(rate, 0, MAX_RATE / 10));

        // Setup rate
        vm.prank(manager);
        srusd.update(rate);

        uint256 totalDeposited = uint256(deposit1) + uint256(deposit2) + uint256(deposit3);
        rusd.mint(user, totalDeposited);
        
        vm.startPrank(user);
        rusd.approve(address(srusd), type(uint256).max);

        // First deposit
        uint256 shares1 = srusd.deposit(deposit1, user);
        skip(30 days);

        // Second deposit
        uint256 shares2 = srusd.deposit(deposit2, user);
        skip(30 days);

        // Third deposit
        uint256 shares3 = srusd.deposit(deposit3, user);

        // Total shares should equal sum
        assertEq(
            srusd.balanceOf(user),
            shares1 + shares2 + shares3,
            "Total shares should equal sum of individual deposits"
        );

        vm.stopPrank();
    }

    /// @notice Fuzz test for allowance-based operations
    function testFuzz_AllowanceWithdraw(
        uint96 depositAmount,
        uint96 withdrawAmount,
        uint96 allowanceAmount
    ) public {
        address owner = makeAddr("owner");
        address spender = makeAddr("spender");
        
        // Bound inputs
        depositAmount = uint96(bound(depositAmount, 1e18, type(uint96).max));
        
        // Setup - deposit first
        rusd.mint(owner, depositAmount);
        vm.startPrank(owner);
        rusd.approve(address(srusd), type(uint256).max);
        uint256 shares = srusd.deposit(depositAmount, owner);
        vm.stopPrank();

        // Bound withdraw and allowance to available shares
        withdrawAmount = uint96(bound(withdrawAmount, 1, depositAmount));
        allowanceAmount = uint96(bound(allowanceAmount, 0, shares));

        uint256 requiredShares = srusd.previewWithdraw(withdrawAmount);

        // Grant allowance
        vm.prank(owner);
        srusd.approve(spender, allowanceAmount);

        vm.prank(spender);
        if (requiredShares <= allowanceAmount) {
            // Should succeed
            srusd.withdraw(withdrawAmount, spender, owner);
            assertEq(rusd.balanceOf(spender), withdrawAmount, "Spender should receive assets");
        } else {
            // Should revert due to insufficient allowance
            vm.expectRevert();
            srusd.withdraw(withdrawAmount, spender, owner);
        }
    }

    /// @notice Fuzz test for zero edge cases
    function testFuzz_ZeroAmountOperations(uint88 rate, uint32 timeDelta) public {
        address user = makeAddr("user");
        
        // Bound inputs
        rate = uint88(bound(rate, 0, MAX_RATE / 10));
        timeDelta = uint32(bound(timeDelta, 0, 365 days));

        vm.prank(manager);
        srusd.update(rate);

        skip(timeDelta);

        rusd.mint(user, 1e18);
        vm.startPrank(user);
        rusd.approve(address(srusd), type(uint256).max);

        // Zero deposit
        uint256 shares = srusd.deposit(0, user);
        assertEq(shares, 0, "Zero deposit should give zero shares");

        // Zero mint
        uint256 assets = srusd.mint(0, user);
        assertEq(assets, 0, "Zero mint should require zero assets");

        // Make a real deposit first
        srusd.deposit(1e18, user);

        // Zero withdraw
        uint256 sharesSpent = srusd.withdraw(0, user, user);
        assertEq(sharesSpent, 0, "Zero withdraw should burn zero shares");

        // Zero redeem
        uint256 assetsReceived = srusd.redeem(0, user, user);
        assertEq(assetsReceived, 0, "Zero redeem should give zero assets");

        vm.stopPrank();
    }

    /// @notice Fuzz test for APY calculation
    function testFuzz_APYCalculation(uint88 rate) public {
        // Bound rate to reasonable range
        rate = uint88(bound(rate, 0, MAX_RATE));

        vm.prank(manager);
        srusd.update(rate);

        uint256 apy = srusd.apy();

        // APY should be >= rate due to compounding (except at 0)
        if (rate > 0) {
            assertGe(apy, rate, "APY should be >= rate due to compounding");
        } else {
            assertEq(apy, RAY, "APY should be RAY when rate is zero");
        }
    }

    /// @notice Fuzz test for recover function
    function testFuzz_Recover(uint96 amount) public {
        address receiver = makeAddr("receiver");
        
        // Bound inputs
        amount = uint96(bound(amount, 1, type(uint96).max));

        // Send tokens directly to contract (simulating accidental transfer)
        rusd.mint(address(srusd), amount);

        uint256 balanceBefore = rusd.balanceOf(receiver);

        // Recover tokens
        vm.prank(manager);
        srusd.recover(address(rusd), receiver);

        uint256 balanceAfter = rusd.balanceOf(receiver);

        assertEq(balanceAfter - balanceBefore, amount, "Should recover all tokens");
        assertEq(rusd.balanceOf(address(srusd)), 0, "Contract should have no tokens left");
    }
}
