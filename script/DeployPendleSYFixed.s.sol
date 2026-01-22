// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {PendleERC20WithOracleSY} from "Pendle-SY-Public/core/StandardizedYield/implementations/PendleERC20WithOracleSY.sol";
import {SavingcoinExchangeRateOracle} from "./SavingcoinExchangeRateOracle.sol";

/// @title Deploy Pendle SY Fixed Script
/// @notice CORRECTED deployment for Pendle SY (Standardized Yield) contracts for wsrUSD
/// @dev Deploys: Exchange Rate Oracle (fundamental), SY Implementation, Proxy with Pendle's ProxyAdmin
contract DeployPendleSYFixed is Script {
    // ===== EXISTING CONTRACTS (DO NOT REDEPLOY) =====
    
    /// @notice wsrUSD (Savingcoin OFT) on Arbitrum - the yield-bearing token
    address constant WSRUSD = 0x4809010926aec940b550D34a46A52739f996D75D;
    
    /// @notice rUSD on Arbitrum - the underlying asset
    address constant R_USD = 0x09D4214C03D01F49544C0448DBE3A27f768F2b34;
    
    // ===== PENDLE'S INFRASTRUCTURE ON ARBITRUM =====
    
    /// @notice Pendle's ProxyAdmin on Arbitrum (MUST USE THIS - DO NOT DEPLOY NEW ONE)
    address constant PENDLE_PROXY_ADMIN = 0xA28c08f165116587D4F3E708743B4dEe155c5E64;
    
    /// @notice Pendle's Pause Controller on Arbitrum (OWNER OF SY CONTRACT)
    address constant PENDLE_PAUSE_CONTROLLER = 0x2aD631F72fB16d91c4953A7f4260A97C2fE2f31e;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("===== Pendle SY FIXED Deployment Script =====");
        console.log("Network: Arbitrum One");
        console.log("Deployer:", deployer);
        console.log("");
        
        console.log("===== Token Configuration =====");
        console.log("wsrUSD (Yield Token):", WSRUSD);
        console.log("rUSD (Underlying Asset):", R_USD);
        console.log("");
        
        console.log("===== Pendle Configuration =====");
        console.log("Pendle ProxyAdmin:", PENDLE_PROXY_ADMIN);
        console.log("Pendle Pause Controller (Owner):", PENDLE_PAUSE_CONTROLLER);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy Fundamental Exchange Rate Oracle
        console.log("=== Step 1: Deploying Fundamental Exchange Rate Oracle ===");
        console.log("Oracle Type: SavingcoinExchangeRateOracle (calls compoundFactor())");
        SavingcoinExchangeRateOracle exchangeRateOracle = new SavingcoinExchangeRateOracle(WSRUSD);
        console.log("Exchange Rate Oracle deployed at:", address(exchangeRateOracle));
        console.log("");

        // Step 2: Get token details
        string memory wsrUSDName = IERC20Metadata(WSRUSD).name();
        string memory wsrUSDSymbol = IERC20Metadata(WSRUSD).symbol();
        
        console.log("=== Step 2: Token Information ===");
        console.log("wsrUSD Name:", wsrUSDName);
        console.log("wsrUSD Symbol:", wsrUSDSymbol);
        console.log("");

        // Step 3: Deploy SY Implementation  
        console.log("=== Step 3: Deploying SY Implementation ===");
        PendleERC20WithOracleSY syImplementation = new PendleERC20WithOracleSY(
            WSRUSD,                             // yieldToken (wsrUSD)
            R_USD,                              // underlyingAsset (rUSD)
            address(exchangeRateOracle)         // exchangeRateOracle (fundamental oracle)
        );
        console.log("SY Implementation deployed at:", address(syImplementation));
        console.log("");

        // Step 4: Prepare initialization data
        console.log("=== Step 4: Preparing Initialization Data ===");
        // The SY contract name and symbol will be empty strings as per Pendle design
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,address)",
            "",                          // Empty name (Pendle SY standard)
            "",                          // Empty symbol (Pendle SY standard)
            PENDLE_PAUSE_CONTROLLER      // Owner address (Pendle's Pause Controller)
        );
        console.log("Initialization prepared with owner:", PENDLE_PAUSE_CONTROLLER);
        console.log("");

        // Step 5: Deploy TransparentUpgradeableProxy using Pendle's ProxyAdmin
        console.log("=== Step 5: Deploying TransparentUpgradeableProxy ===");
        console.log("Using Pendle's existing ProxyAdmin:", PENDLE_PROXY_ADMIN);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(syImplementation),   // _logic: implementation address
            PENDLE_PROXY_ADMIN,          // _admin: Pendle's proxy admin (MUST USE THIS)
            initData                     // _data: initialization call
        );
        console.log("TransparentUpgradeableProxy deployed at:", address(proxy));
        console.log("");

        // Step 6: Wrap proxy as SY contract
        PendleERC20WithOracleSY sy = PendleERC20WithOracleSY(payable(address(proxy)));

        // Step 7: Verify deployment
        console.log("=== Step 6: Verifying Deployment ===");
        console.log("SY Contract (Proxy):", address(sy));
        console.log("SY Name:", sy.name());
        console.log("SY Symbol:", sy.symbol());
        console.log("SY Decimals:", sy.decimals());
        console.log("SY Yield Token:", address(sy.yieldToken()));
        console.log("SY Underlying Asset:", sy.underlyingAsset());
        console.log("SY Exchange Rate Oracle:", sy.exchangeRateOracle());
        console.log("SY Owner:", sy.owner());
        
        // Test exchange rate function
        console.log("");
        console.log("=== Testing Exchange Rate Oracle ===");
        try exchangeRateOracle.getExchangeRate() returns (uint256 rate) {
            console.log("Exchange Rate (1e18):", rate);
            console.log("Exchange Rate Oracle Working: YES");
        } catch {
            console.log("Exchange Rate Oracle: Unable to read (may need time)");
        }
        console.log("");

        vm.stopBroadcast();

        // Final Summary
        console.log("========================================");
        console.log("===== DEPLOYMENT SUMMARY =====");
        console.log("========================================");
        console.log("");
        console.log("=== DEPLOYED CONTRACTS ===");
        console.log("Exchange Rate Oracle:", address(exchangeRateOracle));
        console.log("SY Implementation:", address(syImplementation));
        console.log("SY Proxy (MAIN CONTRACT):", address(sy));
        console.log("");
        console.log("=== CONFIGURATION ===");
        console.log("Yield Token (wsrUSD):", WSRUSD);
        console.log("Underlying Asset (rUSD):", R_USD);
        console.log("ProxyAdmin:", PENDLE_PROXY_ADMIN, "(Pendle's existing)");
        console.log("SY Owner:", PENDLE_PAUSE_CONTROLLER, "(Pendle's Pause Controller)");
        console.log("");
        console.log("=== KEY FIXES APPLIED ===");
        console.log("1. [OK] Using fundamental oracle (compoundFactor) instead of price feed");
        console.log("2. [OK] Owner set to Pendle's Pause Controller:", PENDLE_PAUSE_CONTROLLER);
        console.log("3. [OK] ProxyAdmin set to Pendle's ProxyAdmin:", PENDLE_PROXY_ADMIN);
        console.log("");
        console.log("========================================");
        console.log("===== NEXT STEPS =====");
        console.log("========================================");
        console.log("");
        console.log("1. Verify contracts on Arbiscan:");
        console.log("   a) Exchange Rate Oracle:", address(exchangeRateOracle));
        console.log("   b) SY Implementation:", address(syImplementation));
        console.log("   c) SY Proxy:", address(proxy));
        console.log("");
        console.log("2. Share SY PROXY address with Pendle team:");
        console.log("   >>> SY Proxy Address:", address(sy), "<<<");
        console.log("");
        console.log("3. Test deposit/withdrawal functions");
        console.log("");
        console.log("========================================");
        console.log("===== VERIFICATION COMMANDS =====");
        console.log("========================================");
        console.log("");
        console.log("See deployment script output for verification commands");
        console.log("Or check broadcast/ directory for deployment details");
        console.log("");
    }
}
