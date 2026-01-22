// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

import {Savingcoin} from "src/Savingcoin.sol";
import {StablecoinMock} from "../StablecoinMock.sol";

/// @title SavingcoinHandler
/// @notice Handler contract for invariant testing of Savingcoin
/// @dev Implements bounded random actions to test system invariants
contract SavingcoinHandler is Test {
    Savingcoin public srusd;
    StablecoinMock public rusd;
    address public manager;

    uint256 public constant RAY = 1e27;
    uint256 public constant MAX_RATE = RAY - 1;

    // Ghost variables for tracking state
    uint256 public ghost_depositSum;
    uint256 public ghost_withdrawSum;
    uint256 public ghost_mintSum;
    uint256 public ghost_redeemSum;
    uint256 public ghost_zeroDepositCount;
    uint256 public ghost_zeroWithdrawCount;
    
    // Track individual user deposits for verification
    mapping(address => uint256) public ghost_userDepositedAssets;
    mapping(address => uint256) public ghost_userWithdrawnAssets;
    
    // Actor management
    address[] public actors;
    address internal currentActor;

    // Call counts for metrics
    uint256 public callCount_deposit;
    uint256 public callCount_mint;
    uint256 public callCount_withdraw;
    uint256 public callCount_redeem;
    uint256 public callCount_updateRate;

    modifier useActor(uint256 actorSeed) {
        currentActor = actors[bound(actorSeed, 0, actors.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    modifier countCall(string memory functionName) {
        _;
        // Increment call counter based on function
        if (keccak256(bytes(functionName)) == keccak256("deposit")) {
            callCount_deposit++;
        } else if (keccak256(bytes(functionName)) == keccak256("mint")) {
            callCount_mint++;
        } else if (keccak256(bytes(functionName)) == keccak256("withdraw")) {
            callCount_withdraw++;
        } else if (keccak256(bytes(functionName)) == keccak256("redeem")) {
            callCount_redeem++;
        } else if (keccak256(bytes(functionName)) == keccak256("updateRate")) {
            callCount_updateRate++;
        }
    }

    constructor(Savingcoin _srusd, StablecoinMock _rusd, address _manager) {
        srusd = _srusd;
        rusd = _rusd;
        manager = _manager;

        // Initialize actors
        for (uint256 i = 0; i < 5; i++) {
            address actor = makeAddr(string(abi.encodePacked("actor", vm.toString(i))));
            actors.push(actor);
            
            // Setup approvals
            vm.prank(actor);
            rusd.approve(address(srusd), type(uint256).max);
        }
    }

    /// @notice Handler for deposit action
    function deposit(uint256 assets, uint256 actorSeed) external useActor(actorSeed) countCall("deposit") {
        // Bound inputs to reasonable range
        assets = bound(assets, 0, 1e30);

        // Skip if would exceed cap
        uint256 cap = srusd.cap();
        if (cap > 0) {
            uint256 currentAssets = srusd.totalAssets();
            if (currentAssets + assets > cap) {
                return; // Skip this action
            }
        }

        // Setup
        rusd.mint(currentActor, assets);

        // Pre-state
        uint256 sharesBefore = srusd.balanceOf(currentActor);
        uint256 totalSupplyBefore = srusd.totalSupply();

        // Action
        try srusd.deposit(assets, currentActor) returns (uint256 shares) {
            // Post-state assertions
            assertEq(srusd.balanceOf(currentActor), sharesBefore + shares, "Handler: deposit shares mismatch");
            assertEq(srusd.totalSupply(), totalSupplyBefore + shares, "Handler: deposit total supply mismatch");

            // Update ghost variables
            ghost_depositSum += assets;
            ghost_userDepositedAssets[currentActor] += assets;
            
            if (assets == 0) {
                ghost_zeroDepositCount++;
            }
        } catch {
            // Deposit failed, could be due to cap or other reason
        }
    }

    /// @notice Handler for mint action
    function mint(uint256 shares, uint256 actorSeed) external useActor(actorSeed) countCall("mint") {
        // Bound inputs
        shares = bound(shares, 0, 1e30);

        // Preview to get required assets
        uint256 requiredAssets = srusd.previewMint(shares);

        // Skip if would exceed cap
        uint256 cap = srusd.cap();
        if (cap > 0) {
            uint256 currentAssets = srusd.totalAssets();
            if (currentAssets + requiredAssets > cap) {
                return;
            }
        }

        // Setup
        rusd.mint(currentActor, requiredAssets);

        // Pre-state
        uint256 sharesBefore = srusd.balanceOf(currentActor);

        // Action
        try srusd.mint(shares, currentActor) returns (uint256 assets) {
            // Post-state
            assertEq(srusd.balanceOf(currentActor), sharesBefore + shares, "Handler: mint shares mismatch");

            // Update ghost variables
            ghost_mintSum += assets;
            ghost_userDepositedAssets[currentActor] += assets;
        } catch {
            // Mint failed
        }
    }

    /// @notice Handler for withdraw action
    function withdraw(uint256 assets, uint256 actorSeed) external useActor(actorSeed) countCall("withdraw") {
        // Get max withdrawable assets
        uint256 maxAssets = srusd.convertToAssets(srusd.balanceOf(currentActor));
        
        if (maxAssets == 0) return;

        // Bound to available assets
        assets = bound(assets, 0, maxAssets);

        // Pre-state
        uint256 sharesBefore = srusd.balanceOf(currentActor);
        uint256 assetsBefore = rusd.balanceOf(currentActor);

        // Action
        try srusd.withdraw(assets, currentActor, currentActor) returns (uint256 shares) {
            // Post-state
            assertEq(srusd.balanceOf(currentActor), sharesBefore - shares, "Handler: withdraw shares mismatch");
            assertEq(rusd.balanceOf(currentActor), assetsBefore + assets, "Handler: withdraw assets mismatch");

            // Update ghost variables
            ghost_withdrawSum += assets;
            ghost_userWithdrawnAssets[currentActor] += assets;
            
            if (assets == 0) {
                ghost_zeroWithdrawCount++;
            }
        } catch {
            // Withdraw failed
        }
    }

    /// @notice Handler for redeem action
    function redeem(uint256 shares, uint256 actorSeed) external useActor(actorSeed) countCall("redeem") {
        // Bound to available shares
        uint256 maxShares = srusd.balanceOf(currentActor);
        
        if (maxShares == 0) return;

        shares = bound(shares, 0, maxShares);

        // Pre-state
        uint256 sharesBefore = srusd.balanceOf(currentActor);
        uint256 assetsBefore = rusd.balanceOf(currentActor);

        // Action
        try srusd.redeem(shares, currentActor, currentActor) returns (uint256 assets) {
            // Post-state
            assertEq(srusd.balanceOf(currentActor), sharesBefore - shares, "Handler: redeem shares mismatch");
            assertEq(rusd.balanceOf(currentActor), assetsBefore + assets, "Handler: redeem assets mismatch");

            // Update ghost variables
            ghost_redeemSum += assets;
            ghost_userWithdrawnAssets[currentActor] += assets;
        } catch {
            // Redeem failed
        }
    }

    /// @notice Handler for rate update action
    function updateRate(uint256 rate, uint256 timeDelta) external countCall("updateRate") {
        // Bound inputs
        rate = bound(rate, 0, MAX_RATE);
        timeDelta = bound(timeDelta, 0, 365 days);

        // Skip time
        skip(timeDelta);

        // Action
        vm.prank(manager);
        try srusd.update(rate) {
            // Rate updated successfully
        } catch {
            // Update failed
        }
    }

    /// @notice Handler for time skip action
    function skipTime(uint256 timeDelta) external {
        timeDelta = bound(timeDelta, 1, 30 days);
        skip(timeDelta);
    }

    /// @notice Helper to get total calls
    function getTotalCalls() external view returns (uint256) {
        return callCount_deposit + callCount_mint + callCount_withdraw + 
               callCount_redeem + callCount_updateRate;
    }

    /// @notice Helper to get actor count
    function getActorCount() external view returns (uint256) {
        return actors.length;
    }

    /// @notice Helper to get actor by index
    function getActor(uint256 index) external view returns (address) {
        return actors[index];
    }
}
