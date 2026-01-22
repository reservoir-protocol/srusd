# Pendle SY Deployment Guide - wsrUSD on Arbitrum

## Overview

This guide provides instructions for deploying the Pendle Standardized Yield (SY) contract for wsrUSD on Arbitrum One using the corrected upgradeable proxy pattern.

## Key Issues Fixed from Previous Deployment

1. **Upgradeable Proxy Pattern**: The SY contract must be deployed using OpenZeppelin's `TransparentUpgradeableProxy` (not direct deployment)
2. **Chronicle Oracle Wrapper**: Created a wrapper contract to adapt Chronicle's `read()` function to Pendle's expected `getExchangeRate()` interface
3. **Updated rUSD Address**: Using the correct address `0x09D4214C03D01F49544C0448DBE3A27f768F2b34`
4. **Initialization**: The `initialize()` function is called during proxy deployment with proper owner setup

## Contract Addresses

### Existing Contracts (DO NOT REDEPLOY)
- **wsrUSD (OFT)**: `0x4809010926aec940b550D34a46A52739f996D75D`
- **rUSD (Underlying)**: `0x09D4214C03D01F49544C0448DBE3A27f768F2b34`
- **Chronicle Oracle**: `0x5e1a2a77D4df85d3C0907715ED616e0B04eE51Dd`

### Owner Address
- **SY Contract Owner**: `0xb7570e32dED63B25163369D5eb4D8e89E70e5602`

## Deployment Architecture

The deployment consists of 4 contracts:

1. **Chronicle Oracle Wrapper** (`ChronicleOracleWrapper.sol`)
   - Wraps Chronicle's `read()` to Pendle's `getExchangeRate()`
   - Immutable contract

2. **SY Implementation** (`PendleERC20WithOracleSY`)
   - The logic contract for the SY
   - Deployed from Pendle's audited contracts

3. **ProxyAdmin** (`ProxyAdmin`)
   - Manages proxy upgrades
   - Ownership transferred to Pendle team

4. **TransparentUpgradeableProxy**
   - The main SY contract that users interact with
   - Points to the implementation
   - Initialized with empty name/symbol (Pendle standard) and owner

## Prerequisites

1. **Environment Variables** (in `.env`):
   ```bash
   PRIVATE_KEY=<your-private-key>
   ARBITRUM_RPC_URL=<your-arbitrum-rpc-url>
   ARBISCAN_API_KEY=<your-arbiscan-api-key>
   ```

2. **Dependencies**:
   - OpenZeppelin Contracts v4.9.3 (already installed)
   - Pendle SY Public contracts (already installed)
   - Foundry/Forge

## Deployment Steps

### 1. Simulation (Dry Run)

Test the deployment without broadcasting:

```bash
source .env && forge script script/DeployPendleSYUpgradeable.s.sol:DeployPendleSYUpgradeable --rpc-url $ARBITRUM_RPC_URL
```

**Note**: The simulation may show an error when verifying `sy.exchangeRate()` due to Chronicle's "tolling" (whitelisting) requirement. This is expected and will work once the SY proxy is whitelisted by Chronicle.

### 2. Actual Deployment

Deploy to Arbitrum One mainnet:

```bash
source .env && forge script script/DeployPendleSYUpgradeable.s.sol:DeployPendleSYUpgradeable \
  --rpc-url $ARBITRUM_RPC_URL \
  --broadcast \
  --verify \
  -vvv
```

**Important**: 
- Double-check all addresses before deployment
- Ensure sufficient ETH for gas in deployer wallet
- Save all deployed contract addresses immediately

### 3. Post-Deployment Steps

After successful deployment, you will receive 4 contract addresses:

1. **Oracle Wrapper Address**
2. **SY Implementation Address**  
3. **ProxyAdmin Address**
4. **SY Proxy Address** ← **THIS IS THE MAIN ADDRESS TO SHARE**

## Verification

### Automatic Verification

The `--verify` flag should automatically verify contracts on Arbiscan. If verification fails, use manual commands:

```bash
# Verify Oracle Wrapper
forge verify-contract <ORACLE_WRAPPER_ADDRESS> \
  script/ChronicleOracleWrapper.sol:ChronicleOracleWrapper \
  --chain arbitrum \
  --constructor-args $(cast abi-encode "constructor(address)" 0x5e1a2a77D4df85d3C0907715ED616e0B04eE51Dd)

# Verify SY Implementation
forge verify-contract <SY_IMPL_ADDRESS> \
  Pendle-SY-Public/core/StandardizedYield/implementations/PendleERC20WithOracleSY.sol:PendleERC20WithOracleSY \
  --chain arbitrum \
  --constructor-args $(cast abi-encode "constructor(address,address,address)" 0x4809010926aec940b550D34a46A52739f996D75D 0x09D4214C03D01F49544C0448DBE3A27f768F2b34 <ORACLE_WRAPPER_ADDRESS>)

# Verify ProxyAdmin
forge verify-contract <PROXY_ADMIN_ADDRESS> \
  openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol:ProxyAdmin \
  --chain arbitrum

# Verify Proxy
forge verify-contract <PROXY_ADDRESS> \
  openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy \
  --chain arbitrum
```

## Integration with Pendle

### Address to Share with Pendle Team

**SY Proxy Address**: `<YOUR_DEPLOYED_PROXY_ADDRESS>`

This is the main contract address that Pendle will use to create markets.

### Contract Details

- **Token Type**: ERC20 Standardized Yield (SY)
- **Underlying Asset**: rUSD (Reservoir USD)
- **Yield Token**: wsrUSD (Wrapped Savings rUSD)
- **Exchange Rate Oracle**: Chronicle Oracle (via wrapper)
- **Network**: Arbitrum One (Chain ID: 42161)
- **Decimals**: 18
- **Upgradeable**: Yes (via TransparentProxy)
- **Owner**: `0xb7570e32dED63B25163369D5eb4D8e89E70e5602`

## Testing the Deployment

After deployment, test the SY contract functions:

```bash
# Check SY details
cast call <SY_PROXY_ADDRESS> "name()(string)" --rpc-url $ARBITRUM_RPC_URL
cast call <SY_PROXY_ADDRESS> "symbol()(string)" --rpc-url $ARBITRUM_RPC_URL
cast call <SY_PROXY_ADDRESS> "decimals()(uint8)" --rpc-url $ARBITRUM_RPC_URL
cast call <SY_PROXY_ADDRESS> "yieldToken()(address)" --rpc-url $ARBITRUM_RPC_URL
cast call <SY_PROXY_ADDRESS> "underlyingAsset()(address)" --rpc-url $ARBITRUM_RPC_URL
cast call <SY_PROXY_ADDRESS> "exchangeRateOracle()(address)" --rpc-url $ARBITRUM_RPC_URL
cast call <SY_PROXY_ADDRESS> "owner()(address)" --rpc-url $ARBITRUM_RPC_URL

# Note: exchangeRate() may revert until Chronicle whitelists the SY proxy
cast call <SY_PROXY_ADDRESS> "exchangeRate()(uint256)" --rpc-url $ARBITRUM_RPC_URL
```

## Chronicle Oracle Whitelisting

**Important**: After deployment, the SY Proxy address needs to be whitelisted ("tolled") by Chronicle Protocol to read the exchange rate.

Contact Chronicle Protocol or the oracle administrator to whitelist:
- **Contract to Whitelist**: `<SY_PROXY_ADDRESS>`
- **Chronicle Oracle**: `0x5e1a2a77D4df85d3C0907715ED616e0B04eE51Dd`

## Troubleshooting

### "NotTolled" Error
If you see `NotTolled(<address>)` error:
- The address needs to be whitelisted by Chronicle
- This is expected before whitelisting
- Contact Chronicle team to whitelist the SY Proxy

### Compilation Errors
If you encounter compilation errors:
- Ensure OpenZeppelin v4.9.3 is installed (not v5.x)
- Run: `forge build --skip test`
- The Savingcoin.sol uses v5 features but isn't needed for deployment

### Verification Failures
If Arbiscan verification fails:
- Wait a few minutes and retry
- Use manual verification commands above
- Ensure constructor arguments are correctly encoded

## Security Considerations

1. **Immutable Contracts**: Oracle Wrapper and SY Implementation are immutable
2. **Upgradeable Proxy**: Only ProxyAdmin (owned by Pendle team) can upgrade
3. **Access Control**: SY Owner can pause/unpause if needed
4. **Audited Code**: Uses Pendle's audited SY implementation
5. **Oracle Security**: Depends on Chronicle oracle security and whitelisting

## Files

- **Deployment Script**: `script/DeployPendleSYUpgradeable.s.sol`
- **Oracle Wrapper**: `script/ChronicleOracleWrapper.sol`
- **Old Script** (incorrect): `script/DeployPendleSY.s.sol` (DO NOT USE)

## Support

For questions or issues:
1. Review Pendle documentation: https://docs.pendle.finance/
2. Check Pendle GitHub: https://github.com/pendle-finance/Pendle-SY-Public
3. Contact Pendle team with deployment details

## Summary

The corrected deployment:
✅ Uses TransparentUpgradeableProxy pattern (required by Pendle)
✅ Deploys Chronicle oracle wrapper with correct interface
✅ Uses updated rUSD address
✅ Properly initializes with owner
✅ Transfers ProxyAdmin ownership to Pendle team
✅ Compatible with Pendle's SY standard

---

**Deployment Date**: January 19, 2026
**Network**: Arbitrum One
**Chain ID**: 42161
