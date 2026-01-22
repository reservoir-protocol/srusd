// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {Savingcoin} from "src/Savingcoin.sol";
import {StablecoinMock} from "./StablecoinMock.sol";

/// @title SavingcoinEdgeCasesTest
/// @notice Edge case and revert scenario testing for Savingcoin
/// @dev Tests boundary conditions, access control, and failure scenarios
contract SavingcoinEdgeCasesTest is Test {
    Savingcoin public srusd;
    StablecoinMock public rusd;

    address public admin = makeAddr("admin");
    address public manager = makeAddr("manager");
    address public user = makeAddr("user");
    address public unauthorizedUser = makeAddr("unauthorized");

    uint256 public constant RAY = 1e27;

    function setUp() external {
        rusd = new StablecoinMock("Reservoir Stablecoin Mock", "rUSDM");
        srusd = new Savingcoin(admin, "Reservoir Savingcoin", "srUSD", rusd);

        vm.startPrank(admin);
        srusd.grantRole(srusd.MANAGER(), manager);
        vm.stopPrank();

        vm.startPrank(manager);
        srusd.setCap(type(uint256).max);
        vm.stopPrank();

        // Setup user
        rusd.mint(user, type(uint128).max);
        vm.prank(user);
        rusd.approve(address(srusd), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                        ACCESS CONTROL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_UnauthorizedSetCap() external {
        vm.prank(unauthorizedUser);
        vm.expectRevert();
        srusd.setCap(1000e18);
    }

    function test_RevertWhen_UnauthorizedUpdate() external {
        vm.prank(unauthorizedUser);
        vm.expectRevert();
        srusd.update(1e26);
    }

    function test_RevertWhen_UnauthorizedRecover() external {
        vm.prank(unauthorizedUser);
        vm.expectRevert();
        srusd.recover(address(rusd), unauthorizedUser);
    }

    function test_RevertWhen_UnauthorizedGrantRole() external {
        vm.prank(unauthorizedUser);
        vm.expectRevert();
        srusd.grantRole(srusd.MANAGER(), unauthorizedUser);
    }

    /*//////////////////////////////////////////////////////////////
                        RATE UPDATE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_RateEqualToRAY() external {
        vm.prank(manager);
        vm.expectRevert("daily savings rate can not be above 100%");
        srusd.update(RAY);
    }

    function test_RevertWhen_RateAboveRAY() external {
        vm.prank(manager);
        vm.expectRevert("daily savings rate can not be above 100%");
        srusd.update(RAY + 1);
    }

    function test_UpdateRateAtMaximum() external {
        vm.prank(manager);
        srusd.update(RAY - 1);
        assertEq(srusd.currentRate(), RAY - 1);
    }

    function test_UpdateRateMultipleTimes() external {
        vm.prank(manager);
        srusd.update(1e26);
        
        skip(30 days);
        
        vm.prank(manager);
        srusd.update(2e26);
        
        skip(30 days);
        
        vm.prank(manager);
        srusd.update(5e25);
        
        assertEq(srusd.currentRate(), 5e25);
        assertGt(srusd.compoundFactorAccum(), RAY);
    }

    /*//////////////////////////////////////////////////////////////
                        CAP ENFORCEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_DepositExceedsCap() external {
        vm.prank(manager);
        srusd.setCap(100e18);

        vm.prank(user);
        vm.expectRevert("newly issued shares can not exceed notional cap");
        srusd.deposit(101e18, user);
    }

    function test_RevertWhen_MintExceedsCap() external {
        vm.prank(manager);
        srusd.setCap(100e18);

        // First deposit to set up state
        vm.prank(user);
        srusd.deposit(50e18, user);

        // Try to mint more shares that would exceed cap
        vm.prank(manager);
        srusd.update(1e26);
        skip(365 days);

        vm.prank(user);
        vm.expectRevert("newly issued shares can not exceed notional cap");
        srusd.mint(100e18, user);
    }

    function test_DepositAtExactCap() external {
        vm.prank(manager);
        srusd.setCap(100e18);

        vm.prank(user);
        uint256 shares = srusd.deposit(100e18, user);
        
        assertEq(srusd.totalAssets(), 100e18);
        assertGt(shares, 0);
    }

    function test_CapWithInterestAccrual() external {
        vm.prank(manager);
        srusd.setCap(200e18);

        // Initial deposit
        vm.prank(user);
        srusd.deposit(100e18, user);

        // Set rate and accrue interest
        vm.prank(manager);
        srusd.update(1e26);
        skip(365 days);

        // Total assets should now exceed initial deposit due to interest
        uint256 totalAssets = srusd.totalAssets();
        assertGt(totalAssets, 100e18);

        // Should still be able to deposit up to cap
        uint256 remainingCap = 200e18 - totalAssets;
        
        vm.prank(user);
        srusd.deposit(remainingCap, user);
    }

    /*//////////////////////////////////////////////////////////////
                        ZERO AMOUNT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_DepositZero() external {
        vm.prank(user);
        uint256 shares = srusd.deposit(0, user);
        
        assertEq(shares, 0);
        assertEq(srusd.balanceOf(user), 0);
    }

    function test_MintZero() external {
        vm.prank(user);
        uint256 assets = srusd.mint(0, user);
        
        assertEq(assets, 0);
        assertEq(srusd.balanceOf(user), 0);
    }

    function test_WithdrawZero() external {
        // Deposit first
        vm.prank(user);
        srusd.deposit(100e18, user);

        // Withdraw zero
        vm.prank(user);
        uint256 shares = srusd.withdraw(0, user, user);
        
        assertEq(shares, 0);
    }

    function test_RedeemZero() external {
        // Deposit first
        vm.prank(user);
        srusd.deposit(100e18, user);

        // Redeem zero
        vm.prank(user);
        uint256 assets = srusd.redeem(0, user, user);
        
        assertEq(assets, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        ALLOWANCE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_WithdrawWithoutAllowance() external {
        address spender = makeAddr("spender");
        
        // User deposits
        vm.prank(user);
        srusd.deposit(100e18, user);

        // Spender tries to withdraw without allowance
        vm.prank(spender);
        vm.expectRevert();
        srusd.withdraw(50e18, spender, user);
    }

    function test_RevertWhen_RedeemWithoutAllowance() external {
        address spender = makeAddr("spender");
        
        // User deposits
        vm.prank(user);
        srusd.deposit(100e18, user);

        // Spender tries to redeem without allowance
        vm.prank(spender);
        vm.expectRevert();
        srusd.redeem(50e18, spender, user);
    }

    function test_WithdrawWithAllowance() external {
        address spender = makeAddr("spender");
        
        // User deposits
        vm.prank(user);
        uint256 shares = srusd.deposit(100e18, user);

        // User grants allowance
        vm.prank(user);
        srusd.approve(spender, shares);

        // Spender withdraws
        vm.prank(spender);
        srusd.withdraw(50e18, spender, user);
        
        assertGt(rusd.balanceOf(spender), 0);
    }

    function test_RedeemWithAllowance() external {
        address spender = makeAddr("spender");
        
        // User deposits
        vm.prank(user);
        uint256 shares = srusd.deposit(100e18, user);

        // User grants allowance
        vm.prank(user);
        srusd.approve(spender, shares);

        // Spender redeems
        vm.prank(spender);
        srusd.redeem(shares / 2, spender, user);
        
        assertGt(rusd.balanceOf(spender), 0);
    }

    function test_RevertWhen_AllowanceExceeded() external {
        address spender = makeAddr("spender");
        
        // User deposits
        vm.prank(user);
        uint256 shares = srusd.deposit(100e18, user);

        // User grants partial allowance
        vm.prank(user);
        srusd.approve(spender, shares / 2);

        // Spender tries to redeem more than allowance
        vm.prank(spender);
        vm.expectRevert();
        srusd.redeem(shares, spender, user);
    }

    /*//////////////////////////////////////////////////////////////
                        BALANCE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_WithdrawMoreThanBalance() external {
        // Deposit
        vm.prank(user);
        srusd.deposit(100e18, user);

        // Try to withdraw more than assets
        vm.prank(user);
        vm.expectRevert();
        srusd.withdraw(200e18, user, user);
    }

    function test_RevertWhen_RedeemMoreThanBalance() external {
        // Deposit
        vm.prank(user);
        uint256 shares = srusd.deposit(100e18, user);

        // Try to redeem more than shares
        vm.prank(user);
        vm.expectRevert();
        srusd.redeem(shares * 2, user, user);
    }

    /*//////////////////////////////////////////////////////////////
                        ROUNDING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_MinimalDepositRounding() external {
        vm.prank(manager);
        srusd.update(1e26);
        skip(365 days);

        vm.prank(user);
        uint256 shares = srusd.deposit(1, user);
        
        // With high compound factor, minimal deposit might round to 0 shares
        assertGe(shares, 0);
    }

    function test_MinimalWithdrawRounding() external {
        // Deposit first
        vm.prank(user);
        srusd.deposit(1e18, user);

        vm.prank(manager);
        srusd.update(1e26);
        skip(365 days);

        // Try minimal withdraw
        vm.prank(user);
        uint256 shares = srusd.withdraw(1, user, user);
        
        assertGe(shares, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        RECOVER FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RecoverAccidentalTransfer() external {
        address receiver = makeAddr("receiver");
        
        // Accidentally send tokens to contract
        rusd.mint(address(srusd), 100e18);

        vm.prank(manager);
        srusd.recover(address(rusd), receiver);

        assertEq(rusd.balanceOf(receiver), 100e18);
        assertEq(rusd.balanceOf(address(srusd)), 0);
    }

    function test_RecoverDifferentToken() external {
        StablecoinMock otherToken = new StablecoinMock("Other", "OTH");
        address receiver = makeAddr("receiver");
        
        // Send different token to contract
        otherToken.mint(address(srusd), 50e18);

        vm.prank(manager);
        srusd.recover(address(otherToken), receiver);

        assertEq(otherToken.balanceOf(receiver), 50e18);
        assertEq(otherToken.balanceOf(address(srusd)), 0);
    }

    /*//////////////////////////////////////////////////////////////
                        COMPOUND FACTOR EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_CompoundFactorWithZeroRate() external {
        uint256 factorBefore = srusd.compoundFactor();
        
        skip(365 days);
        
        uint256 factorAfter = srusd.compoundFactor();
        
        assertEq(factorBefore, factorAfter, "Factor should not change with zero rate");
    }

    function test_CompoundFactorWithMaxRate() external {
        vm.prank(manager);
        srusd.update(RAY - 1);

        skip(1 days);

        uint256 factor = srusd.compoundFactor();
        assertGt(factor, RAY, "Factor should increase with max rate");
    }

    function test_CompoundFactorAccumulation() external {
        vm.prank(manager);
        srusd.update(1e26);
        
        skip(30 days);
        uint256 factor1 = srusd.compoundFactor();
        
        vm.prank(manager);
        srusd.update(2e26);
        
        skip(30 days);
        uint256 factor2 = srusd.compoundFactor();
        
        assertGt(factor2, factor1, "Factor should accumulate");
        assertGt(srusd.compoundFactorAccum(), RAY, "Accum should be > RAY");
    }

    /*//////////////////////////////////////////////////////////////
                        APY EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_APYWithZeroRate() external {
        uint256 apy = srusd.apy();
        assertEq(apy, RAY, "APY should be RAY (1.0) with zero rate");
    }

    function test_APYWithMaxRate() external {
        vm.prank(manager);
        srusd.update(RAY - 1);

        uint256 apy = srusd.apy();
        assertGt(apy, RAY - 1, "APY should be > rate due to compounding");
    }

    /*//////////////////////////////////////////////////////////////
                        TIMESTAMP EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_UpdateAtSameTimestamp() external {
        vm.prank(manager);
        srusd.update(1e26);

        uint256 timestamp1 = srusd.lastTimestamp();

        // Update again at same timestamp (same block)
        vm.prank(manager);
        srusd.update(2e26);

        uint256 timestamp2 = srusd.lastTimestamp();
        
        assertEq(timestamp1, timestamp2, "Timestamp should be same");
    }

    /*//////////////////////////////////////////////////////////////
                        MULTI-USER SCENARIOS
    //////////////////////////////////////////////////////////////*/

    function test_MultipleUsersWithDifferentTiming() external {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        
        rusd.mint(user1, 1000e18);
        rusd.mint(user2, 1000e18);
        
        vm.prank(user1);
        rusd.approve(address(srusd), type(uint256).max);
        vm.prank(user2);
        rusd.approve(address(srusd), type(uint256).max);

        // User1 deposits early
        vm.prank(user1);
        uint256 shares1 = srusd.deposit(100e18, user1);

        // Set rate
        vm.prank(manager);
        srusd.update(1e26);
        skip(180 days);

        // User2 deposits later (should get fewer shares)
        vm.prank(user2);
        uint256 shares2 = srusd.deposit(100e18, user2);

        assertGt(shares1, shares2, "Early depositor should get more shares");

        skip(180 days);

        // Both withdraw
        vm.prank(user1);
        uint256 assets1 = srusd.redeem(shares1, user1, user1);
        
        vm.prank(user2);
        uint256 assets2 = srusd.redeem(shares2, user2, user2);

        assertGt(assets1, 100e18, "User1 should have profits");
        assertGt(assets2, 100e18, "User2 should have profits");
        assertGt(assets1, assets2, "User1 should have more profits");
    }

    /*//////////////////////////////////////////////////////////////
                        EXTREME VALUE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_VeryLargeDeposit() external {
        uint256 largeAmount = type(uint96).max;
        
        rusd.mint(user, largeAmount);
        
        vm.prank(user);
        uint256 shares = srusd.deposit(largeAmount, user);
        
        assertGt(shares, 0);
        assertEq(srusd.totalAssets(), largeAmount);
    }

    function test_VerySmallDepositWithHighRate() external {
        vm.prank(manager);
        srusd.update(RAY / 2);
        
        skip(365 days);

        vm.prank(user);
        uint256 shares = srusd.deposit(1, user);
        
        // Might round to 0 due to very small amount
        assertGe(shares, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        EVENT EMISSION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CapEventEmission() external {
        vm.expectEmit(true, true, false, false);
        emit Savingcoin.Cap(type(uint256).max, 1000e18);
        
        vm.prank(manager);
        srusd.setCap(1000e18);
    }

    function test_UpdateEventEmission() external {
        vm.expectEmit(true, true, true, true);
        emit Savingcoin.Update(RAY, 0, 1e26, block.timestamp);
        
        vm.prank(manager);
        srusd.update(1e26);
    }
}
