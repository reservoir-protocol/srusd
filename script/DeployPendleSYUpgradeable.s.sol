// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";

import {PendleERC20WithOracleSY} from "Pendle-SY-Public/core/StandardizedYield/implementations/PendleERC20WithOracleSY.sol";
import {ChronicleOracleWrapper} from "./ChronicleOracleWrapper.sol";

/// @title Deploy Pendle SY Upgradeable Script
/// @notice Deploys Pendle SY (Standardized Yield) contracts for wsrUSD as upgradeable proxy
/// @dev Deploys: Oracle Wrapper, SY Implementation, ProxyAdmin, TransparentProxy, and initializes with owner
contract DeployPendleSYUpgradeable is Script {
    // wsrUSD (OFT) on Arbitrum - the yield-bearing token
    address constant WSRUSD = 0x4809010926aec940b550D34a46A52739f996D75D;
    
    // rUSD on Arbitrum (underlying asset) - UPDATED ADDRESS
    address constant R_USD = 0x09D4214C03D01F49544C0448DBE3A27f768F2b34;
    
    // Chronicle Oracle on Arbitrum (needs wrapper)
    address constant CHRONICLE_ORACLE = 0x5e1a2a77D4df85d3C0907715ED616e0B04eE51Dd;
    
    // Owner for the SY contract - provided by Pendle team
    address constant OWNER = 0xb7570e32dED63B25163369D5eb4D8e89E70e5602;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("===== Pendle SY Upgradeable Deployment Script =====");
        console.log("Deployer:", deployer);
        console.log("wsrUSD (Yield Token):", WSRUSD);
        console.log("rUSD (Underlying Asset):", R_USD);
        console.log("Chronicle Oracle:", CHRONICLE_ORACLE);
        console.log("Owner:", OWNER);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy Oracle Wrapper
        console.log("=== Step 1: Deploying Chronicle Oracle Wrapper ===");
        ChronicleOracleWrapper oracleWrapper = new ChronicleOracleWrapper(CHRONICLE_ORACLE);
        console.log("Oracle Wrapper deployed at:", address(oracleWrapper));
        console.log("Note: Oracle wrapper deployed. The SY contract will call getExchangeRate()");
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
            WSRUSD,                      // yieldToken (wsrUSD)
            R_USD,                       // underlyingAsset (rUSD)
            address(oracleWrapper)       // exchangeRateOracle (wrapper)
        );
        console.log("SY Implementation deployed at:", address(syImplementation));
        console.log("");

        // Step 4: Deploy ProxyAdmin
        console.log("=== Step 4: Deploying ProxyAdmin ===");
        ProxyAdmin proxyAdmin = new ProxyAdmin();
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));
        console.log("");

        // Step 5: Prepare initialization data
        console.log("=== Step 5: Preparing Initialization Data ===");
        // The SY contract name and symbol will be empty strings as per Pendle design
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,address)",
            "",      // Empty name (Pendle SY standard)
            "",      // Empty symbol (Pendle SY standard)
            OWNER    // Owner address
        );
        console.log("Initialization data prepared for owner:", OWNER);
        console.log("");

        // Step 6: Deploy TransparentUpgradeableProxy
        console.log("=== Step 6: Deploying TransparentUpgradeableProxy ===");
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(syImplementation),  // _logic: implementation address
            address(proxyAdmin),        // _admin: proxy admin address
            initData                    // _data: initialization call
        );
        console.log("TransparentUpgradeableProxy deployed at:", address(proxy));
        console.log("");

        // Step 7: Wrap proxy as SY contract
        PendleERC20WithOracleSY sy = PendleERC20WithOracleSY(payable(address(proxy)));

        // Step 8: Verify deployment
        console.log("=== Step 7: Verifying Deployment ===");
        console.log("SY Contract (Proxy):", address(sy));
        console.log("SY Name:", sy.name());
        console.log("SY Symbol:", sy.symbol());
        console.log("SY Decimals:", sy.decimals());
        console.log("SY Yield Token:", address(sy.yieldToken()));
        console.log("SY Underlying Asset:", sy.underlyingAsset());
        console.log("SY Exchange Rate Oracle:", sy.exchangeRateOracle());
        console.log("NOTE: Skipping exchangeRate() - Chronicle needs to whitelist SY Proxy first");
        console.log("SY Owner:", sy.owner());
        console.log("");

        // Step 9: Transfer ProxyAdmin ownership to OWNER
        console.log("=== Step 8: Transferring ProxyAdmin Ownership ===");
        proxyAdmin.transferOwnership(OWNER);
        console.log("ProxyAdmin ownership transferred to:", OWNER);
        console.log("");

        vm.stopBroadcast();

        // Final Summary
        console.log("===== Deployment Summary =====");
        console.log("Oracle Wrapper:", address(oracleWrapper));
        console.log("SY Implementation:", address(syImplementation));
        console.log("ProxyAdmin:", address(proxyAdmin));
        console.log("SY Contract (Proxy - MAIN):", address(sy));
        console.log("Chronicle Oracle:", CHRONICLE_ORACLE);
        console.log("Yield Token (wsrUSD):", WSRUSD);
        console.log("Underlying Asset (rUSD):", R_USD);
        console.log("SY Owner:", OWNER);
        console.log("ProxyAdmin Owner:", OWNER);
        console.log("");
        console.log("===== Next Steps =====");
        console.log("1. Verify contracts on Arbiscan:");
        console.log("   - Oracle Wrapper:", address(oracleWrapper));
        console.log("   - SY Implementation:", address(syImplementation));
        console.log("   - ProxyAdmin:", address(proxyAdmin));
        console.log("   - Proxy:", address(proxy));
        console.log("");
        console.log("2. Share the SY PROXY address with Pendle team:");
        console.log("   SY Proxy Address:", address(sy));
        console.log("");
        console.log("3. Test deposit/withdrawal functions");
        console.log("");
        console.log("===== Verification Commands =====");
        console.log("Verify Oracle Wrapper:");
        console.log("forge verify-contract", address(oracleWrapper), "script/ChronicleOracleWrapper.sol:ChronicleOracleWrapper --chain arbitrum --constructor-args", CHRONICLE_ORACLE);
        console.log("");
        console.log("Verify SY Implementation:");
        console.log("forge verify-contract", address(syImplementation), "Pendle-SY-Public/core/StandardizedYield/implementations/PendleERC20WithOracleSY.sol:PendleERC20WithOracleSY --chain arbitrum");
        console.log("");
        console.log("Verify ProxyAdmin:");
        console.log("forge verify-contract", address(proxyAdmin), "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol:ProxyAdmin --chain arbitrum");
        console.log("");
        console.log("Verify Proxy:");
        console.log("forge verify-contract", address(proxy), "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy --chain arbitrum");
    }
}
