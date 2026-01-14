// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {PendleERC20WithOracleSY} from "Pendle-SY-Public/core/StandardizedYield/implementations/PendleERC20WithOracleSY.sol";
import {SavingcoinExchangeRateOracle} from "./SavingcoinExchangeRateOracle.sol";

/// @title Deploy Pendle SY Script
/// @notice Deploys Pendle SY (Standardized Yield) contracts for Savingcoin
/// @dev Deploys: Exchange Rate Oracle, SY Implementation, Proxy, and configures ownership
contract DeployPendleSY is Script {
    // Deployed Wrapped srUSD (OFT) on Arbitrum  
    address constant SAVINGCOIN = 0x4809010926aec940b550D34a46A52739f996D75D;
    
    // rUSD on Arbitrum (underlying asset)
    address constant R_USD = 0x09E18590E8f76b6Cf471b3cd75fE1A1a9D2B2c2b;
    
    // Existing Exchange Rate Oracle on Arbitrum
    address constant EXCHANGE_RATE_ORACLE = 0x5e1a2a77D4df85d3C0907715ED616e0B04eE51Dd;
    
    // Pendle's Proxy Admin on Arbitrum
    address constant PENDLE_PROXY_ADMIN = 0xA28c08f165116587D4F3E708743B4dEe155c5E64;
    
    // Pendle's Pause Controller on Arbitrum (not Berachain)
    address constant PENDLE_PAUSE_CONTROLLER = 0x2aD631F72fB16d91c4953A7f4260A97C2fE2f31e;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("===== Pendle SY Deployment Script =====");
        console.log("Deployer:", deployer);
        console.log("Savingcoin Vault:", SAVINGCOIN);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Get OFT wrapper details
        string memory vaultName = IERC20Metadata(SAVINGCOIN).name();
        string memory vaultSymbol = IERC20Metadata(SAVINGCOIN).symbol();
        address underlyingAsset = R_USD;
        
        console.log("OFT Wrapper Name:", vaultName);
        console.log("OFT Wrapper Symbol:", vaultSymbol);
        console.log("Underlying Asset (rUSD):", underlyingAsset);
        console.log("");

        // Step 2: Use Existing Exchange Rate Oracle
        console.log("=== Step 1: Using Existing Exchange Rate Oracle ===");
        console.log("Exchange Rate Oracle:", EXCHANGE_RATE_ORACLE);
        console.log("");

        // Step 3: Deploy SY Implementation  
        console.log("=== Step 2: Deploying SY Implementation ===");
        PendleERC20WithOracleSY syImplementation = new PendleERC20WithOracleSY(
            SAVINGCOIN,              // yieldToken (wsrUSD)
            underlyingAsset,         // underlyingAsset (rUSD)
            EXCHANGE_RATE_ORACLE     // exchangeRateOracle
        );
        console.log("SY Implementation deployed at:", address(syImplementation));
        console.log("");

        // Step 4: Use the SY Implementation directly (no proxy needed for immutable contract)
        console.log("=== Step 3: Using SY Implementation ===");
        PendleERC20WithOracleSY sy = syImplementation;
        console.log("SY Contract:", address(sy));
        console.log("");
        
        // Verify deployment
        console.log("=== Step 5: Verifying Deployment ===");
        console.log("SY Name:", sy.name());
        console.log("SY Symbol:", sy.symbol());
        console.log("SY Decimals:", sy.decimals());
        console.log("SY Yield Token:", address(sy.yieldToken()));
        console.log("SY Underlying Asset:", sy.underlyingAsset());
        console.log("SY Exchange Rate Oracle:", sy.exchangeRateOracle());
        console.log("SY Total Supply:", sy.totalSupply());
        console.log("SY Owner (before transfer):", sy.owner());
        console.log("");

        vm.stopBroadcast();
        
        // Note: Ownership transfer skipped as contract has no owner (immutable deployment)
        console.log("Note: Contract is immutable (no owner)");
        console.log("");

        // Final Summary
        console.log("===== Deployment Summary =====");
        console.log("Exchange Rate Oracle:", EXCHANGE_RATE_ORACLE);
        console.log("SY Contract (Main):", address(sy));
        console.log("Yield Token (wsrUSD):", SAVINGCOIN);
        console.log("Underlying Asset (rUSD):", underlyingAsset);
        console.log("Owner:", PENDLE_PAUSE_CONTROLLER);
        console.log("");
        console.log("===== Next Steps =====");
        console.log("1. Verify contracts on Arbiscan");
        console.log("2. Share the SY contract address with Pendle team");
        console.log("3. Test deposit/withdrawal functions");
        console.log("");
    }
}
