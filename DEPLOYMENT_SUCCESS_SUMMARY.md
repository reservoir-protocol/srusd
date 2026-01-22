# Pendle SY Deployment - SUCCESS ✅

**Deployment Date**: January 19, 2026  
**Network**: Arbitrum One (Chain ID: 42161)  
**Status**: ✅ ALL CONTRACTS DEPLOYED AND VERIFIED

---

## 🎯 Deployed Contract Addresses

### Main Contract (Share with Pendle Team)
**SY Proxy Address**: `0xd3fD63209FA2D55B07A0f6db36C2f43900be3094`

### Supporting Contracts
- **Oracle Wrapper**: `0xBc658B22848d019b704176EF5330710194cE72eF`
- **SY Implementation**: `0x62DD25F8fc8F68eB0Feeb88f0182c3840C65560a`
- **ProxyAdmin**: `0xf3FCE677743350629Dd1eC0820fBE6F72c5871C3`

### Reference Contracts
- **wsrUSD (OFT)**: `0x4809010926aec940b550D34a46A52739f996D75D`
- **rUSD (Underlying)**: `0x09D4214C03D01F49544C0448DBE3A27f768F2b34`
- **Chronicle Oracle**: `0x5e1a2a77D4df85d3C0907715ED616e0B04eE51Dd`

---

## ✅ Verification Status

All 4 contracts have been **successfully verified** on Arbiscan:

1. ✅ **Oracle Wrapper**: [View on Arbiscan](https://arbiscan.io/address/0xbc658b22848d019b704176ef5330710194ce72ef)
2. ✅ **SY Implementation**: [View on Arbiscan](https://arbiscan.io/address/0x62dd25f8fc8f68eb0feeb88f0182c3840c65560a)
3. ✅ **ProxyAdmin**: [View on Arbiscan](https://arbiscan.io/address/0xf3fce677743350629dd1ec0820fbe6f72c5871c3)
4. ✅ **SY Proxy (MAIN)**: [View on Arbiscan](https://arbiscan.io/address/0xd3fd63209fa2d55b07a0f6db36c2f43900be3094)

---

## 📋 Contract Details

### SY Proxy (Main Contract)
- **Address**: `0xd3fD63209FA2D55B07A0f6db36C2f43900be3094`
- **Type**: TransparentUpgradeableProxy
- **Implementation**: `0x62DD25F8fc8F68eB0Feeb88f0182c3840C65560a`
- **Name**: "" (empty - Pendle standard)
- **Symbol**: "" (empty - Pendle standard)
- **Decimals**: 18
- **Owner**: `0xb7570e32dED63B25163369D5eb4D8e89E70e5602`
- **Yield Token**: wsrUSD (`0x4809010926aec940b550D34a46A52739f996D75D`)
- **Underlying Asset**: rUSD (`0x09D4214C03D01F49544C0448DBE3A27f768F2b34`)
- **Exchange Rate Oracle**: Oracle Wrapper (`0xBc658B22848d019b704176EF5330710194cE72eF`)

---

## 🔧 What Was Fixed

This deployment corrects the previous attempt by:

1. ✅ **Upgradeable Proxy Pattern**: Uses OpenZeppelin's `TransparentUpgradeableProxy` (required by Pendle)
2. ✅ **Chronicle Oracle Wrapper**: Created wrapper to adapt Chronicle's `read()` to Pendle's `getExchangeRate()`
3. ✅ **Updated rUSD Address**: Uses correct address `0x09D4214C03D01F49544C0448DBE3A27f768F2b34`
4. ✅ **Proper Initialization**: Called `initialize()` during proxy deployment with owner
5. ✅ **ProxyAdmin Ownership**: Transferred to Pendle team owner
6. ✅ **All Contracts Verified**: Automatic verification on Arbiscan successful

---

## ⚠️ Important Post-Deployment Action Required

### Chronicle Oracle Whitelisting

The SY Proxy contract needs to be **whitelisted ("tolled")** by Chronicle Protocol to read the exchange rate.

**Contract to Whitelist**: `0xd3fD63209FA2D55B07A0f6db36C2f43900be3094` (SY Proxy)  
**Chronicle Oracle**: `0x5e1a2a77D4df85d3C0907715ED616e0B04eE51Dd`

Without whitelisting, calls to `exchangeRate()` will revert with `NotTolled` error. This is expected and will work once whitelisted.

---

## 📊 Gas Usage

- **Total Gas Used**: 8,081,340 gas
- **Gas Price**: ~0.040136001 gwei
- **Total Cost**: ~0.00032435 ETH

---

## 🧪 Testing the Deployment

Test the SY contract with these commands:

```bash
# Set environment
export ARBITRUM_RPC_URL="<your-rpc-url>"
export SY_PROXY="0xd3fD63209FA2D55B07A0f6db36C2f43900be3094"

# Check contract details
cast call $SY_PROXY "name()(string)" --rpc-url $ARBITRUM_RPC_URL
cast call $SY_PROXY "symbol()(string)" --rpc-url $ARBITRUM_RPC_URL
cast call $SY_PROXY "decimals()(uint8)" --rpc-url $ARBITRUM_RPC_URL
cast call $SY_PROXY "yieldToken()(address)" --rpc-url $ARBITRUM_RPC_URL
cast call $SY_PROXY "underlyingAsset()(address)" --rpc-url $ARBITRUM_RPC_URL
cast call $SY_PROXY "exchangeRateOracle()(address)" --rpc-url $ARBITRUM_RPC_URL
cast call $SY_PROXY "owner()(address)" --rpc-url $ARBITRUM_RPC_URL

# This will revert until Chronicle whitelists the SY Proxy
cast call $SY_PROXY "exchangeRate()(uint256)" --rpc-url $ARBITRUM_RPC_URL
```

---

## 📦 Deployment Artifacts

Deployment transaction details saved to:
- **Broadcast**: `broadcast/DeployPendleSYUpgradeable.s.sol/42161/run-latest.json`
- **Cache**: `cache/DeployPendleSYUpgradeable.s.sol/42161/run-latest.json`
- **Log**: `deployment_final.log`

---

## 📝 Integration with Pendle

### Information to Share with Pendle Team

**Main SY Contract Address**: `0xd3fD63209FA2D55B07A0f6db36C2f43900be3094`

### Contract Specifications

- **Network**: Arbitrum One (42161)
- **Token Type**: ERC20 Standardized Yield (SY)
- **Underlying**: rUSD (Reservoir USD)
- **Yield Token**: wsrUSD (Wrapped Savings rUSD OFT)
- **Exchange Rate**: Chronicle Oracle via wrapper
- **Decimals**: 18
- **Upgradeable**: Yes (TransparentProxy pattern)
- **Owner**: `0xb7570e32dED63B25163369D5eb4D8e89E70e5602`

### Arbiscan Links

- Main SY Contract: https://arbiscan.io/address/0xd3fd63209fa2d55b07a0f6db36c2f43900be3094
- Oracle Wrapper: https://arbiscan.io/address/0xbc658b22848d019b704176ef5330710194ce72ef
- SY Implementation: https://arbiscan.io/address/0x62dd25f8fc8f68eb0feeb88f0182c3840c65560a

---

## 🔐 Security & Ownership

- **SY Owner**: `0xb7570e32dED63B25163369D5eb4D8e89E70e5602` (Pendle team)
- **ProxyAdmin Owner**: `0xb7570e32dED63B25163369D5eb4D8e89E70e5602` (Pendle team)
- **Deployer**: `0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69`

All ownership has been transferred to the Pendle team address.

---

## 📚 Documentation

- **Deployment Guide**: `PENDLE_SY_DEPLOYMENT_GUIDE.md`
- **Deployment Script**: `script/DeployPendleSYUpgradeable.s.sol`
- **Oracle Wrapper**: `script/ChronicleOracleWrapper.sol`

---

## ✅ Checklist

- [x] Deploy Chronicle Oracle Wrapper
- [x] Deploy SY Implementation
- [x] Deploy ProxyAdmin
- [x] Deploy TransparentUpgradeableProxy
- [x] Initialize proxy with owner
- [x] Transfer ProxyAdmin ownership to Pendle team
- [x] Verify all contracts on Arbiscan
- [ ] Chronicle whitelists SY Proxy (action required)
- [ ] Share SY Proxy address with Pendle team
- [ ] Pendle creates markets using SY

---

## 🎉 Summary

**All contracts have been successfully deployed and verified on Arbitrum One!**

The Pendle SY (Standardized Yield) contract for wsrUSD is now live and ready for integration. The main contract address to share with the Pendle team is:

### `0xd3fD63209FA2D55B07A0f6db36C2f43900be3094`

Next steps:
1. Request Chronicle to whitelist the SY Proxy address
2. Share the SY Proxy address with Pendle team  
3. Pendle can create markets using this SY contract

---

**Deployment Completed**: January 19, 2026, 8:15 AM EST
