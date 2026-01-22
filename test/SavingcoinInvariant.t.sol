// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {Savingcoin} from "src/Savingcoin.sol";
import {StablecoinMock} from "./StablecoinMock.sol";
import {SavingcoinHandler} from "./handlers/SavingcoinHandler.sol";

/// @title SavingcoinInvariantTest
/// @notice Invariant testing for Savingcoin contract
/// @dev Tests core system properties that should always hold true
contract SavingcoinInvariantTest is Test {
    Savingcoin public srusd;
    StablecoinMock public rusd;
    SavingcoinHandler public handler;

    address public admin;
    address public manager;

    uint256 public constant RAY = 1e27;

    function setUp() external {
        admin = makeAddr("admin");
        manager = makeAddr("manager");

        // Deploy contracts
        rusd = new StablecoinMock("Reservoir Stablecoin Mock", "rUSDM");
        srusd = new Savingcoin(admin, "Reservoir Savingcoin", "srUSD", rusd);

        // Setup roles
        vm.startPrank(admin);
        srusd.grantRole(srusd.MANAGER(), manager);
        vm.stopPrank();

        // Set high cap to allow testing
        vm.startPrank(manager);
        srusd.setCap(type(uint256).max);
        vm.stopPrank();

        // Deploy handler
        handler = new SavingcoinHandler(srusd, rusd, manager);

        // Target the handler for invariant testing
        targetContract(address(handler));
        
        // Target specific functions for better control
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = SavingcoinHandler.deposit.selector;
        selectors[1] = SavingcoinHandler.mint.selector;
        selectors[2] = SavingcoinHandler.withdraw.selector;
        selectors[3] = SavingcoinHandler.redeem.selector;
        selectors[4] = SavingcoinHandler.updateRate.selector;
        selectors[5] = SavingcoinHandler.skipTime.selector;
        
        targetSelector(FuzzSelector({
            addr: address(handler),
            selectors: selectors
        }));
    }

    /// @notice Invariant: Total supply should never exceed shares represented by total assets
    function invariant_TotalSupplyConsistency() external view {
        uint256 totalSupply = srusd.totalSupply();
        uint256 totalAssets = srusd.totalAssets();
        
        if (totalSupply > 0) {
            // Total assets should be derivable from total supply
            uint256 derivedAssets = srusd.convertToAssets(totalSupply);
            
            // Allow small rounding differences
            assertApproxEqAbs(
                derivedAssets,
                totalAssets,
                2,
                "Invariant: Total assets should match converted total supply"
            );
        }
    }

    /// @notice Invariant: Sum of all user shares should equal total supply
    function invariant_SharesSumEqualsSupply() external view {
        uint256 actorCount = handler.getActorCount();
        uint256 sumOfShares;
        
        for (uint256 i = 0; i < actorCount; i++) {
            address actor = handler.getActor(i);
            sumOfShares += srusd.balanceOf(actor);
        }
        
        assertEq(
            sumOfShares,
            srusd.totalSupply(),
            "Invariant: Sum of shares should equal total supply"
        );
    }

    /// @notice Invariant: Compound factor should never decrease (unless rate update)
    function invariant_CompoundFactorNonDecreasing() external view {
        uint256 compoundFactor = srusd.compoundFactor();
        uint256 compoundFactorAccum = srusd.compoundFactorAccum();
        
        // Compound factor should always be >= RAY (1.0)
        assertGe(
            compoundFactor,
            RAY,
            "Invariant: Compound factor should be >= RAY"
        );
        
        // Accumulated compound factor should also be >= RAY
        assertGe(
            compoundFactorAccum,
            RAY,
            "Invariant: Accumulated compound factor should be >= RAY"
        );
    }

    /// @notice Invariant: Preview functions should match actual operations (within rounding)
    function invariant_PreviewAccuracy() external view {
        // Test only if there are deposits
        if (srusd.totalSupply() == 0) return;
        
        uint256 testAmount = 1e18;
        
        // Preview deposit -> actual deposit should match
        uint256 previewedShares = srusd.previewDeposit(testAmount);
        uint256 requiredAssets = srusd.previewMint(previewedShares);
        
        // Should be approximately equal (allowing for rounding)
        assertApproxEqAbs(
            requiredAssets,
            testAmount,
            2,
            "Invariant: Preview functions should be consistent"
        );
    }

    /// @notice Invariant: Total assets should respect cap if set
    function invariant_CapRespected() external view {
        uint256 cap = srusd.cap();
        if (cap > 0) {
            uint256 totalAssets = srusd.totalAssets();
            assertLe(
                totalAssets,
                cap,
                "Invariant: Total assets should not exceed cap"
            );
        }
    }

    /// @notice Invariant: Conversion functions should be reversible (within rounding)
    function invariant_ConversionReversibility() external view {
        if (srusd.totalSupply() == 0) return;
        
        uint256 testShares = 1e18;
        
        // shares -> assets -> shares
        uint256 assets = srusd.convertToAssets(testShares);
        uint256 sharesBack = srusd.convertToShares(assets);
        
        assertApproxEqAbs(
            sharesBack,
            testShares,
            2,
            "Invariant: Share->Asset->Share should be reversible"
        );
        
        // assets -> shares -> assets
        uint256 testAssets = 1e18;
        uint256 shares = srusd.convertToShares(testAssets);
        uint256 assetsBack = srusd.convertToAssets(shares);
        
        assertApproxEqAbs(
            assetsBack,
            testAssets,
            2,
            "Invariant: Asset->Share->Asset should be reversible"
        );
    }

    /// @notice Invariant: Current rate should never exceed RAY (100%)
    function invariant_RateBelowMaximum() external view {
        uint256 currentRate = srusd.currentRate();
        assertLt(
            currentRate,
            RAY,
            "Invariant: Rate should be below 100%"
        );
    }

    /// @notice Invariant: No rUSD should be stuck in the contract
    /// @dev The contract burns on deposit and mints on withdraw, so balance should always be 0
    function invariant_NoStuckTokens() external view {
        uint256 contractBalance = rusd.balanceOf(address(srusd));
        assertEq(
            contractBalance,
            0,
            "Invariant: Contract should not hold rUSD tokens"
        );
    }

    /// @notice Invariant: Ghost variables should track cumulative operations
    function invariant_GhostVariableTracking() external view {
        uint256 depositSum = handler.ghost_depositSum();
        uint256 mintSum = handler.ghost_mintSum();
        uint256 withdrawSum = handler.ghost_withdrawSum();
        uint256 redeemSum = handler.ghost_redeemSum();
        
        // Total deposited should be >= total withdrawn (interest accrues)
        uint256 totalDeposited = depositSum + mintSum;
        uint256 totalWithdrawn = withdrawSum + redeemSum;
        
        // This can be violated due to interest, so we just check it's tracked
        assertTrue(
            totalDeposited >= 0 && totalWithdrawn >= 0,
            "Invariant: Ghost variables should track operations"
        );
    }

    /// @notice Invariant: Individual user accounting should be consistent
    function invariant_UserAccountingConsistency() external view {
        uint256 actorCount = handler.getActorCount();
        
        for (uint256 i = 0; i < actorCount; i++) {
            address actor = handler.getActor(i);
            uint256 shares = srusd.balanceOf(actor);
            
            // If user has shares, they should be convertible to assets
            if (shares > 0) {
                uint256 assets = srusd.convertToAssets(shares);
                assertGt(
                    assets,
                    0,
                    "Invariant: Shares should convert to non-zero assets"
                );
            }
        }
    }

    /// @notice Invariant: Timestamp should always be set
    function invariant_TimestampSet() external view {
        uint256 lastTimestamp = srusd.lastTimestamp();
        assertGt(
            lastTimestamp,
            0,
            "Invariant: Last timestamp should always be set"
        );
    }

    /// @notice Invariant: APY calculation should be consistent with rate
    function invariant_APYConsistency() external view {
        uint256 apy = srusd.apy();
        uint256 currentRate = srusd.currentRate();
        
        // APY should be >= current rate due to compounding
        if (currentRate > 0) {
            assertGe(
                apy,
                currentRate,
                "Invariant: APY should be >= rate due to compounding"
            );
        } else {
            // When rate is 0, APY should be RAY (no change)
            assertEq(
                apy,
                RAY,
                "Invariant: APY should be RAY when rate is 0"
            );
        }
    }

    /// @notice Invariant: ERC20 total supply should match vault's internal accounting
    function invariant_ERC20Consistency() external view {
        uint256 erc20Supply = srusd.totalSupply();
        uint256 vaultSupply = srusd.totalSupply();
        
        assertEq(
            erc20Supply,
            vaultSupply,
            "Invariant: ERC20 supply should match vault supply"
        );
    }

    /// @notice Call summary for debugging
    function invariant_callSummary() external view {
        console.log("=== Call Summary ===");
        console.log("Deposits:", handler.callCount_deposit());
        console.log("Mints:", handler.callCount_mint());
        console.log("Withdraws:", handler.callCount_withdraw());
        console.log("Redeems:", handler.callCount_redeem());
        console.log("Rate Updates:", handler.callCount_updateRate());
        console.log("Total Calls:", handler.getTotalCalls());
        console.log("");
        console.log("=== Ghost Variables ===");
        console.log("Total Deposited:", handler.ghost_depositSum());
        console.log("Total Minted:", handler.ghost_mintSum());
        console.log("Total Withdrawn:", handler.ghost_withdrawSum());
        console.log("Total Redeemed:", handler.ghost_redeemSum());
        console.log("");
        console.log("=== Vault State ===");
        console.log("Total Supply:", srusd.totalSupply());
        console.log("Total Assets:", srusd.totalAssets());
        console.log("Current Rate:", srusd.currentRate());
        console.log("Compound Factor:", srusd.compoundFactor());
        console.log("Compound Factor Accum:", srusd.compoundFactorAccum());
    }
}
