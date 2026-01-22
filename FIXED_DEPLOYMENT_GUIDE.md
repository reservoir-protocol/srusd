# Pendle SY Fixed Deployment Guide

## Overview

This guide provides instructions for the **CORRECTED** deployment of Pendle SY (Standardized Yield) contracts for wsrUSD on Arbitrum One.

## What Was Fixed

The previous deployment had **3 critical issues** that have been corrected:

### 1. ✅ Wrong Oracle Type (CRITICAL)
- **Problem**: Used `ChronicleOracleWrapper` which wraps a **price feed oracle**
- **Solution**: Created `SavingcoinExchangeRateOracle` which calls `compoundFactor()` on wsrUSD to get the **fundamental exchange rate** (wsrUSD/rUSD ratio)
- **Why**: Pendle requires a fundamental oracle that returns how many underlying tokens per yield token, not a price feed

### 2. ✅ Wrong Owner Address
- **Problem**: Owner was set to `0xb7570e32dED63B25163369D5eb4D8e89E70e5602`
- **Solution**: Owner now set to Pendle's Pause Controller: `0x2aD631F72fB16d91c4953A7f4260A97C2fE2f31e`
- **Why**: Pendle team's infrastructure uses this address for ownership

### 3. ✅ Wrong ProxyAdmin Address
- **Problem**: Deployed a new ProxyAdmin owned by different address
- **Solution**: Use Pendle's existing ProxyAdmin: `0xA28c08f165116587D4F3E708743B4dEe155c5E64`
- **Why**: Pendle manages upgrades through their existing ProxyAdmin

---

## Contract Addresses

### Deployed Contracts (Previous - DEPRECATED)
- ❌ Old SY Proxy: `0xd3fD63209FA2D55B07A0f6db36C2f43900be3094` (DO NOT USE)
- ❌ Old Oracle Wrapper: `0xBc658B22848d019b704176EF5330710194cE72eF` (WRONG TYPE)

### Existing Contracts (DO NOT REDEPLOY)
- **wsrUSD (Savingcoin OFT)**: `0x4809010926aec940b550D34a46A52739f996D75D`
- **rUSD (Underlying Asset)**: `0x09D4214C03D01F49544C0448DBE3A27f768F2b34`

### Pendle Infrastructure (DO NOT REDEPLOY)
- **Pendle ProxyAdmin**: `0xA28c08f165116587D4F3E708743B4dEe155c5E64`
- **Pendle Pause Controller**: `0x2aD631F72fB16d91c4953A7f4260A97C2fE2f31e`

---

## New Contract Files

### 1. SavingcoinExchangeRateOracle.sol
**Location**: `script/SavingcoinExchangeRateOracle.sol`

This oracle wrapper:
- Calls `compoundFactor()` on the wsrUSD (Savingcoin) contract
- Converts from RAY precision (1e27) to standard precision (1e18)
- Provides the fundamental exchange rate (wsrUSD → rUSD)

### 2. DeployPendleSYFixed.s.sol
**Location**: `script/DeployPendleSYFixed.s.sol`

This deployment script:
- Deploys the correct exchange rate oracle
- Deploys SY implementation with correct oracle
- Creates proxy using Pendle's existing ProxyAdmin
- Initializes with Pendle's Pause Controller as owner

---

## Deployment Instructions

### Prerequisites

1. Ensure you have the `.env` file with:
   ```bash
   PRIVATE_KEY=<your_deployer_private_key>
   ARBITRUM_RPC_URL=<your_arbitrum_rpc_url>
   ARBISCAN_API_KEY=<your_arbiscan_api_key>
   ```

2. Ensure deployer has sufficient ETH on Arbitrum One

### Step 1: Deploy Contracts

Run the deployment script:

```bash
forge script script/DeployPendleSYFixed.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

Or if you prefer to specify directly:

```bash
forge script script/DeployPendleSYFixed.s.sol \
  --rpc-url https://arb1.arbitrum.io/rpc \
  --broadcast \
  --verify \
  -vvvv
```

**Expected Gas Usage**: ~2-3M gas (~$5-10 depending on gas prices)

### Step 2: Verify Deployment Output

The script will output addresses for:
1. **Exchange Rate Oracle** - New fundamental oracle
2. **SY Implementation** - New implementation contract
3. **SY Proxy** - Main contract to share with Pendle ⭐

**Save the SY Proxy address** - this is what you'll share with the Pendle team!

### Step 3: Manual Verification (if auto-verify fails)

If automatic verification fails, verify manually:

#### Verify Exchange Rate Oracle
```bash
forge verify-contract <ORACLE_ADDRESS> \
  script/SavingcoinExchangeRateOracle.sol:SavingcoinExchangeRateOracle \
  --chain arbitrum \
  --watch \
  --constructor-args $(cast abi-encode "constructor(address)" 0x4809010926aec940b550D34a46A52739f996D75D)
```

#### Verify SY Implementation
```bash
forge verify-contract <IMPLEMENTATION_ADDRESS> \
  Pendle-SY-Public/core/StandardizedYield/implementations/PendleERC20WithOracleSY.sol:PendleERC20WithOracleSY \
  --chain arbitrum \
  --watch \
  --constructor-args $(cast abi-encode "constructor(address,address,address)" \
    0x4809010926aec940b550D34a46A52739f996D75D \
    0x09D4214C03D01F49544C0448DBE3A27f768F2b34 \
    <ORACLE_ADDRESS>)
```

#### Verify Proxy
```bash
forge verify-contract <PROXY_ADDRESS> \
  openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy \
  --chain arbitrum \
  --watch
```

---

## Testing the Deployment

### Test Oracle Functionality

```bash
export ORACLE_ADDRESS=<deployed_oracle_address>
export ARBITRUM_RPC=<your_rpc_url>

# Get exchange rate
cast call $ORACLE_ADDRESS "getExchangeRate()(uint256)" --rpc-url $ARBITRUM_RPC

# Should return something like: 1000000000000000000 (1e18 for 1:1 ratio)
```

### Test SY Contract

```bash
export SY_PROXY=<deployed_sy_proxy_address>

# Check basic info
cast call $SY_PROXY "name()(string)" --rpc-url $ARBITRUM_RPC
cast call $SY_PROXY "symbol()(string)" --rpc-url $ARBITRUM_RPC
cast call $SY_PROXY "decimals()(uint8)" --rpc-url $ARBITRUM_RPC

# Check configuration
cast call $SY_PROXY "yieldToken()(address)" --rpc-url $ARBITRUM_RPC
# Should return: 0x4809010926aec940b550D34a46A52739f996D75D (wsrUSD)

cast call $SY_PROXY "underlyingAsset()(address)" --rpc-url $ARBITRUM_RPC
# Should return: 0x09D4214C03D01F49544C0448DBE3A27f768F2b34 (rUSD)

cast call $SY_PROXY "owner()(address)" --rpc-url $ARBITRUM_RPC
# Should return: 0x2aD631F72fB16d91c4953A7f4260A97C2fE2f31e (Pendle Pause Controller)

cast call $SY_PROXY "exchangeRate()(uint256)" --rpc-url $ARBITRUM_RPC
# Should return current exchange rate in 1e18 format
```

---

## What to Share with Pendle Team

Send the following information to the Pendle team:

```
Subject: Corrected wsrUSD SY Deployment on Arbitrum

Hi Pendle Team,

I've redeployed the wsrUSD SY contract with the following corrections:

1. ✅ Using fundamental exchange rate oracle (compoundFactor) instead of price feed
2. ✅ Owner set to Pendle's Pause Controller (0x2aD631F72fB16d91c4953A7f4260A97C2fE2f31e)
3. ✅ ProxyAdmin set to Pendle's existing ProxyAdmin (0xA28c08f165116587D4F3E708743B4dEe155c5E64)

**Main SY Contract (Proxy)**: <YOUR_SY_PROXY_ADDRESS>

**Supporting Contracts**:
- Exchange Rate Oracle: <YOUR_ORACLE_ADDRESS>
- SY Implementation: <YOUR_IMPLEMENTATION_ADDRESS>

**Token Configuration**:
- Yield Token (wsrUSD): 0x4809010926aec940b550D34a46A52739f996D75D
- Underlying Asset (rUSD): 0x09D4214C03D01F49544C0448DBE3A27f768F2b34

**Network**: Arbitrum One (Chain ID: 42161)

All contracts are verified on Arbiscan.

Best regards
```

---

## Verification Checklist

Before sharing with Pendle, verify:

- [ ] SY Proxy deployed successfully
- [ ] All 3 contracts verified on Arbiscan
- [ ] Owner is Pendle's Pause Controller: `0x2aD631F72fB16d91c4953A7f4260A97C2fE2f31e`
- [ ] ProxyAdmin is Pendle's ProxyAdmin: `0xA28c08f165116587D4F3E708743B4dEe155c5E64`
- [ ] Exchange rate oracle returns valid exchange rate
- [ ] Yield token is wsrUSD: `0x4809010926aec940b550D34a46A52739f996D75D`
- [ ] Underlying asset is rUSD: `0x09D4214C03D01F49544C0448DBE3A27f768F2b34`

---

## Troubleshooting

### Issue: "Insufficient funds for gas"
**Solution**: Ensure deployer wallet has at least 0.01 ETH on Arbitrum

### Issue: "Verification failed"
**Solution**: Wait a few minutes and try manual verification commands above

### Issue: "Owner not set correctly"
**Solution**: Check that `PENDLE_PAUSE_CONTROLLER` constant is correct in deployment script

### Issue: "Exchange rate returns 0"
**Solution**: This is normal if compoundFactor hasn't been updated yet. Try again after some time.

---

## Additional Resources

- **Pendle SY Documentation**: https://pendle.notion.site/oft-sy-deployment
- **Arbitrum Explorer**: https://arbiscan.io/
- **wsrUSD Contract**: https://arbiscan.io/address/0x4809010926aec940b550D34a46A52739f996D75D
- **Foundry Book**: https://book.getfoundry.sh/

---

## Support

If you encounter any issues during deployment, check:
1. Gas prices on Arbitrum
2. RPC endpoint connectivity
3. Deployer wallet balance
4. Environment variables in `.env` file

For Pendle-specific questions, refer to their documentation or contact their team directly.
