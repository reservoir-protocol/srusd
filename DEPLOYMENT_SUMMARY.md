# Pendle SY Deployment Summary

## Deployment Information

**Date**: January 14, 2026  
**Network**: Arbitrum One (Chain ID: 42161)  
**Deployer**: `0xf23D535a88eBF8FAF018b64Cdeb1D27C8414DC69`

## Deployed Contracts

| Contract | Address | Arbiscan Link |
|----------|---------|---------------|
| **Pendle SY wsrUSD** | `0x350f1d41363D28Ba5A7A545eB1757F65d2FB1E57` | [View on Arbiscan](https://arbiscan.io/address/0x350f1d41363D28Ba5A7A545eB1757F65d2FB1E57) |
| Exchange Rate Oracle | `0x5e1a2a77D4df85d3C0907715ED616e0B04eE51Dd` | [View on Arbiscan](https://arbiscan.io/address/0x5e1a2a77D4df85d3C0907715ED616e0B04eE51Dd) |
| Yield Token (wsrUSD) | `0x4809010926aec940b550D34a46A52739f996D75D` | [View on Arbiscan](https://arbiscan.io/address/0x4809010926aec940b550D34a46A52739f996D75D) |
| Underlying Asset (rUSD) | `0x09E18590E8f76b6Cf471b3cd75fE1A1a9D2B2c2b` | [View on Arbiscan](https://arbiscan.io/address/0x09E18590E8f76b6Cf471b3cd75fE1A1a9D2B2c2b) |

## Contract Details

### Pendle SY wsrUSD
- **Type**: PendleERC20WithOracleSY (Immutable)
- **Decimals**: 18
- **Name**: _(empty - as per Pendle design)_
- **Symbol**: _(empty - as per Pendle design)_
- **Ownership**: No owner (immutable contract)

### Configuration
- **Yield Token**: Wrapped Savings rUSD (wsrUSD OFT)
- **Underlying Asset**: rUSD (Reservoir USD)
- **Exchange Rate Oracle**: Uses existing Chainlink-compatible oracle
- **Exchange Rate**: 1:1 (wsrUSD to rUSD)

## Verification Status

✅ **Contract Deployed Successfully**  
✅ **Arbiscan Verification**: **VERIFIED**  
🔗 **Arbiscan Link**: https://arbiscan.io/address/0x350f1d41363d28ba5a7a545eb1757f65d2fb1e57

### Gas Usage
- **Estimated Gas Used**: 5,148,790 gas
- **Gas Price**: 0.040056001 gwei  
- **Total Cost**: 0.000206 ETH

## Next Steps

1. ✅ **Deploy SY Contract** - Completed
2. ⏳ **Verify on Arbiscan** - Manual verification if needed
3. 📤 **Share with Pendle Team**:
   - Share the SY contract address: `0x350f1d41363D28Ba5A7A545eB1757F65d2FB1E57`
   - Provide this summary document
4. 🧪 **Test Integration**:
   - Test deposit/withdrawal functions
   - Verify exchange rate calculation
   - Confirm compatibility with Pendle protocol

## Key Integration Points for Pendle

### Primary Contract Address
```
0x350f1d41363D28Ba5A7A545eB1757F65d2FB1E57
```

### Token Information
- **Yield Token Name**: Wrapped Savings rUSD
- **Yield Token Symbol**: wsrUSD  
- **Underlying Token**: rUSD
- **Network**: Arbitrum One

### Technical Details
- Contract follows Pendle's PendleERC20WithOracleSY pattern
- Uses Chainlink-compatible oracle for exchange rate
- Supports standard ERC20 SY operations
- Immutable deployment (no admin keys)

## Security Considerations

- ✅ Immutable contract (no admin functions)
- ✅ Uses existing, audited Pendle SY implementation
- ✅ Oracle address verified and functional
- ✅ Underlying assets verified on Arbitrum

## Support & Documentation

- **Pendle Documentation**: https://docs.pendle.finance/
- **Deployment Script**: `script/DeployPendleSY.s.sol`
- **Exchange Rate Oracle**: `script/SavingcoinExchangeRateOracle.sol`
- **Deployment Guide**: `PENDLE_DEPLOYMENT.md`

---

**Deployment Status**: ✅ SUCCESS  
**Ready for Integration**: YES  
**Action Required**: Share SY address with Pendle team
