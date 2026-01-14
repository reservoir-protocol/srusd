# Pendle SY Deployment Guide for Savingcoin

This guide explains how to deploy Pendle Standardized Yield (SY) contracts for the Savingcoin ERC4626 vault on Arbitrum.

## Overview

The deployment creates 3 contracts:
1. **SavingcoinExchangeRateOracle**: Custom oracle that provides exchange rates from the Savingcoin vault
2. **PendleERC20WithOracleSY**: The SY implementation contract
3. **TransparentUpgradeableProxy**: Proxy contract pointing to the SY implementation

## Prerequisites

- Foundry installed
- Private key with ETH on Arbitrum for gas fees
- Access to Arbitrum RPC endpoint

## Configuration

### Environment Variables

Ensure your `.env` file contains:
```bash
PRIVATE_KEY=your_private_key_here
ARBITRUM_RPC_URL=your_arbitrum_rpc_url
ARBISCAN_API_KEY=your_arbiscan_api_key
```

### Deployed Addresses

- **Savingcoin Vault**: `0x4809010926aec940b550D34a46A52739f996D75D`
- **Pendle Proxy Admin**: `0xA28c08f165116587D4F3E708743B4dEe155c5E64`
- **Pendle Pause Controller**: `0x2aD631F72fB16d91c4953A7f4260A97C2fE2f31e`

## Deployment Steps

### 1. Simulate Deployment (Dry Run)

First, simulate the deployment without broadcasting transactions:

```bash
forge script script/DeployPendleSY.s.sol --rpc-url $ARBITRUM_RPC_URL
```

### 2. Deploy to Arbitrum

Deploy the contracts with the `--broadcast` flag:

```bash
forge script script/DeployPendleSY.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

**Flags explanation:**
- `--broadcast`: Actually send transactions to the network
- `--verify`: Automatically verify contracts on Arbiscan
- `-vvvv`: Verbose output for debugging

### 3. Verify Deployment

The script will output:
- Exchange Rate Oracle address
- SY Implementation address
- **SY Proxy address** (this is the main contract address to share with Pendle)

Save these addresses for reference.

## What the Script Does

1. **Queries Savingcoin vault** for name, symbol, and underlying asset
2. **Deploys Exchange Rate Oracle** that reads from Savingcoin's `convertToAssets()` 
3. **Deploys SY Implementation** with:
   - Yield Token: Savingcoin vault (`srUSD`)
   - Underlying Asset: rUSD token
   - Exchange Rate Oracle: Custom oracle deployed in step 2
4. **Deploys Proxy** with Pendle's ProxyAdmin
5. **Initializes proxy** with proper name and symbol:
   - Name: `"SY " + vaultName`
   - Symbol: `"SY-" + vaultSymbol`
6. **Transfers ownership** to Pendle's Pause Controller

## Exchange Rate Oracle

The `SavingcoinExchangeRateOracle` contract:
- Implements `IPExchangeRateOracle` interface
- Calls `vault.convertToAssets()` to get the current exchange rate
- Normalizes the rate to 18 decimals as required by Pendle

### Formula

```solidity
exchangeRate = (assetsPerShare * 10^18) / 10^assetDecimals
```

This returns how many underlying assets (rUSD) you get for 1 share token (srUSD), normalized to 18 decimals.

## Post-Deployment

### 1. Verify Contracts on Arbiscan

If auto-verification fails, manually verify:

```bash
# Verify Exchange Rate Oracle
forge verify-contract \
  <ORACLE_ADDRESS> \
  script/SavingcoinExchangeRateOracle.sol:SavingcoinExchangeRateOracle \
  --rpc-url $ARBITRUM_RPC_URL \
  --etherscan-api-key $ARBISCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address)" 0x4809010926aec940b550D34a46A52739f996D75D)

# Verify SY Implementation
forge verify-contract \
  <SY_IMPL_ADDRESS> \
  lib/Pendle-SY-Public/contracts/core/StandardizedYield/implementations/PendleERC20WithOracleSY.sol:PendleERC20WithOracleSY \
  --rpc-url $ARBITRUM_RPC_URL \
  --etherscan-api-key $ARBISCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address,address)" 0x4809010926aec940b550D34a46A52739f996D75D <UNDERLYING_ASSET> <ORACLE_ADDRESS>)
```

### 2. Share with Pendle Team

Provide the Pendle team with:
- **SY Proxy Address** (the main contract)
- **Underlying Asset Address** (rUSD)
- **Yield Token Address** (Savingcoin vault - srUSD)
- Link to verified contracts on Arbiscan

### 3. Test the Deployment

You can test basic functionality:

```bash
# Check SY name
cast call <SY_PROXY_ADDRESS> "name()(string)" --rpc-url $ARBITRUM_RPC_URL

# Check SY symbol  
cast call <SY_PROXY_ADDRESS> "symbol()(string)" --rpc-url $ARBITRUM_RPC_URL

# Check exchange rate
cast call <SY_PROXY_ADDRESS> "exchangeRate()(uint256)" --rpc-url $ARBITRUM_RPC_URL

# Check owner (should be Pendle Pause Controller)
cast call <SY_PROXY_ADDRESS> "owner()(address)" --rpc-url $ARBITRUM_RPC_URL
```

## Security Considerations

- ✅ **Proxy Admin**: Using Pendle's proxy admin (`0xA28c08f165116587D4F3E708743B4dEe155c5E64`)
- ✅ **Ownership**: Transferred to Pendle's Pause Controller (`0x2aD631F72fB16d91c4953A7f4260A97C2fE2f31e`)
- ✅ **Upgradeability**: Contract is upgradeable through Pendle's proxy admin
- ✅ **Oracle**: Custom oracle reads directly from Savingcoin vault (no external dependencies)
- ✅ **Naming Convention**: Follows Pendle's requirements (`"SY " + name` and `"SY-" + symbol`)

## Troubleshooting

### "Insufficient funds" error
Ensure your deployer address has enough ETH on Arbitrum for gas fees.

### "Nonce too low" error
```bash
# Reset the nonce
cast nonce <YOUR_ADDRESS> --rpc-url $ARBITRUM_RPC_URL
```

### Verification fails
Use the manual verification commands above with the correct constructor arguments.

### Need to resume failed deployment
```bash
forge script script/DeployPendleSY.s.sol \
  --rpc-url $ARBITRUM_RPC_URL \
  --resume
```

## Contract Addresses Reference

After deployment, record your addresses here:

```
Exchange Rate Oracle: 0x...
SY Implementation:    0x...
SY Proxy (Main):      0x...
```

## Additional Resources

- [Pendle Documentation](https://docs.pendle.finance/)
- [Pendle SY GitHub](https://github.com/pendle-finance/Pendle-SY-Public)
- [Foundry Book](https://book.getfoundry.sh/)
- [Savingcoin on Arbiscan](https://arbiscan.io/address/0x4809010926aec940b550D34a46A52739f996D75D)

## Support

For issues or questions:
1. Check the Pendle documentation
2. Review deployment logs with `-vvvv` flag
3. Contact the Pendle team with your SY proxy address
