# Token Swap Architecture for Investment Pool

## The Core Question
**How does the pool convert ETH (raised from investors) into ERC20 tokens (needed for strategy execution)?**

---

## Architecture Options

### Option 1: Direct DEX Integration (Uniswap V3)
**How it works:**
- Pool contract integrates directly with Uniswap V3 Router
- When `executeStrategy()` is called, contract swaps ETH → tokens automatically
- Owner triggers execution, contract handles the swap

**Flow:**
```
Pool raises ETH
    ↓
Owner calls executeStrategy(poolId)
    ↓
Contract loops through strategy assets:
    - ETH → WBTC (via Uniswap)
    - ETH → LINK (via Uniswap)
    - ETH → USDC (via Uniswap)
    ↓
Tokens held in contract
    ↓
Owner can later call accessToken() to receive them
```

**Pros:**
- ✅ Fully on-chain and transparent
- ✅ No manual intervention needed
- ✅ Can't be front-run (owner controls timing)
- ✅ Trustless (uses DEX prices)

**Cons:**
- ❌ Slippage risk (large swaps move price)
- ❌ Gas costs (multiple swaps = expensive)
- ❌ Limited to tokens available on DEX
- ❌ No access to best prices (CEX might be cheaper)

**When to use:** 
- Pure DeFi approach
- Pool sizes < $100K (slippage manageable)
- Only crypto assets (BTC, ETH, LINK, etc.)

---

### Option 2: Owner Manual Swap + Proof of Execution
**How it works:**
- Pool contract gives ETH to owner
- Owner swaps on CEX/DEX manually (gets best prices)
- Owner deposits tokens back to contract
- Contract verifies correct amounts using oracle prices

**Flow:**
```
Pool raises ETH
    ↓
Owner calls withdrawForExecution(poolId)
    - Contract sends ETH to owner's wallet
    - Emits event: "ETH withdrawn for execution"
    ↓
Owner trades manually:
    - Coinbase: ETH → WBTC (better liquidity)
    - Uniswap: ETH → LINK
    - Returns to contract
    ↓
Owner calls depositTokens(poolId, [tokenAddresses])
    - Contract checks: did owner buy the right amounts?
    - Uses Chainlink oracle to verify values match
    - Locks tokens in contract
    ↓
Investors can verify on-chain
```

**Pros:**
- ✅ Owner can get best prices (CEX + DEX)
- ✅ No slippage issues (can split orders)
- ✅ Gas efficient (fewer on-chain operations)
- ✅ Can access any exchange

**Cons:**
- ❌ Requires trust in owner (temporarily holds ETH)
- ❌ Manual process (slower)
- ❌ Owner could run away with ETH (before depositing tokens)
- ❌ Verification complexity (oracle pricing might differ from actual)

**When to use:**
- Large pools ($100K+) where slippage matters
- Need access to CEX liquidity
- Owner has proven reputation

---

### Option 3: Two-Step Approval System
**How it works:**
- Owner proposes a swap plan
- Investors vote to approve
- Contract executes swap automatically after approval
- Combines transparency with automation

**Flow:**
```
Pool raises ETH
    ↓
Owner calls proposeSwapPlan(poolId, [tokens, amounts, deadline])
    - "I want to swap 10 ETH → 0.5 BTC, 5 ETH → 100 LINK"
    - Plan stored on-chain
    - 48-hour review period
    ↓
Investors review plan:
    - Check if amounts make sense
    - Vote yes/no (weighted by investment)
    - Need 66% approval
    ↓
If approved:
    - Contract auto-executes swaps via Uniswap
    - Tokens locked in contract
    - Event emitted: "Strategy executed"
    ↓
If rejected:
    - Owner can propose new plan
    - Or investors can emergency withdraw
```

**Pros:**
- ✅ Democratic (investors have control)
- ✅ Still automated after approval
- ✅ Transparent (everyone sees the plan)
- ✅ Prevents owner from making bad decisions

**Cons:**
- ❌ Slow (48-hour voting period)
- ❌ Complex governance logic
- ❌ What if not enough voters participate?
- ❌ Market might move during voting

**When to use:**
- High-stakes pools ($500K+)
- Community-driven projects
- When investor protection is priority

---

### Option 4: Hybrid: Owner Proposes, Contract Executes
**How it works:**
- Owner sets slippage tolerance and swap parameters
- Contract executes automatically via DEX
- Oracle validates no manipulation occurred
- Best of both worlds

**Flow:**
```
Pool raises ETH
    ↓
Owner calls setSwapParameters(poolId, slippageTolerance, deadline)
    - "Max 2% slippage, execute within 24 hours"
    ↓
Contract auto-executes via Uniswap:
    - Checks current prices from Chainlink
    - Executes swaps with slippage protection
    - If slippage exceeds 2%, transaction reverts
    ↓
After execution:
    - Oracle validates: "Did we get fair prices?"
    - If prices deviate >3% from oracle, flag for review
    - Investors can dispute within 7 days
    ↓
Tokens locked, ready for accessToken()
```

**Pros:**
- ✅ Automated (fast)
- ✅ Owner controls timing
- ✅ Slippage protection built-in
- ✅ Oracle verification prevents manipulation

**Cons:**
- ❌ Still limited to DEX tokens
- ❌ Oracle prices might lag market
- ❌ Moderate complexity

**When to use:**
- Medium-sized pools ($50K-$500K)
- Want automation with safety
- Only need crypto assets

---

## Key Architectural Decisions

### Decision 1: Who Controls the Swap?
- **Contract-controlled:** Automated, trustless, limited to DEX
- **Owner-controlled:** Flexible, manual, requires trust
- **Hybrid:** Owner proposes, contract executes

### Decision 2: Where Does Swap Happen?
- **On-chain (DEX):** Uniswap, SushiSwap, Curve
  - Pros: Transparent, automated
  - Cons: Slippage, limited tokens
  
- **Off-chain (CEX):** Coinbase, Binance, Kraken
  - Pros: Better prices, more liquidity
  - Cons: Requires trust, manual process

### Decision 3: How Do You Prevent Price Manipulation?
- **Chainlink oracles:** Verify swap prices match market
- **Slippage limits:** Max 2-5% deviation allowed
- **Time-weighted average price (TWAP):** Use 1-hour TWAP instead of spot
- **Multi-oracle consensus:** Check 3 oracles, use median

### Decision 4: What Happens If Swap Fails?
- **Revert and retry:** Owner tries again with better parameters
- **Partial execution:** Buy what you can, refund rest
- **Emergency exit:** Investors withdraw ETH instead
- **Hold in stablecoin:** Convert ETH → USDC, wait for better prices

---

## Recommended Architecture for Your Project

### Phase 1 (MVP): **Option 4 - Hybrid Approach**

**Why?**
- Balances automation with flexibility
- Owner can time the market (important for strategy)
- Slippage protection prevents bad trades
- Oracle verification adds safety
- Not too complex to implement

**Implementation steps:**
1. Add `executeStrategy(poolId)` function
2. Integrate Uniswap V3 Router for swaps
3. Add slippage tolerance parameter (owner-set)
4. Use Chainlink price feeds to validate post-swap
5. Emit events for full transparency

**Risk mitigation:**
- Max 5% slippage on any single swap
- Split large orders across multiple blocks
- Oracle check: if deviation >3%, flag for review
- 7-day dispute window before tokens are locked

### Phase 2 (Advanced): **Option 3 - Governance**

**When to add:**
- Once you have $500K+ AUM
- Community governance token launched
- Proven track record (10+ successful pools)

**New features:**
- Investor voting on execution plans
- Multi-sig requirement for large swaps ($100K+)
- DAO treasury to cover slippage losses

---

## Critical Functions You'll Need

### In Your Contract:
```
1. setSwapParameters(poolId, slippageTolerance, maxDelay)
   - Owner sets acceptable slippage
   
2. executeStrategy(poolId)
   - Triggers automatic swaps via Uniswap
   - Loops through strategy.assetsAmount[]
   - For each asset: ETH → Token swap
   - Validates slippage within tolerance
   
3. validateSwapPrices(poolId)
   - Called after execution
   - Compares actual prices vs oracle prices
   - If deviation >3%, emit warning event
   
4. disputeSwap(poolId)
   - Investors can flag suspicious swaps
   - Requires 33% of investors to agree
   - Triggers investigation
   
5. emergencyConvert(poolId)
   - If swap fails repeatedly
   - Converts all ETH → USDC
   - Allows investors to withdraw stablecoin
```

---

## Example Flow for Phase 1

```
Day 1: Pool raises 100 ETH
    ↓
Day 2: Owner calls setStrategy()
    - 50% BTC, 30% LINK, 20% USDC
    ↓
Day 3: Owner calls setSwapParameters()
    - 2% max slippage, execute within 24 hours
    ↓
Day 3 (1 hour later): Owner calls executeStrategy()
    ↓
Contract executes:
    - 50 ETH → WBTC (via Uniswap)
    - 30 ETH → LINK (via Uniswap)
    - 20 ETH → USDC (via Uniswap)
    ↓
Contract validates with Chainlink:
    - WBTC price check: ✓ within 2%
    - LINK price check: ✓ within 2%
    - USDC price check: ✓ (stablecoin)
    ↓
Tokens locked in contract
    ↓
Owner can now call accessToken() to receive them
```

---

## Security Considerations

### 1. **Front-running Protection**
- Use commit-reveal pattern for large swaps
- Or use private mempools (Flashbots)

### 2. **Sandwich Attack Protection**
- Set strict slippage limits
- Use TWAP instead of spot price
- Split large orders

### 3. **Oracle Manipulation**
- Use multiple oracles (Chainlink + Band + API3)
- Require 2/3 agreement
- Circuit breaker if prices diverge >5%

### 4. **Owner Rug Pull**
- Timelock on accessToken() (7-day delay)
- Investors can dispute during timelock
- Multi-sig for pools >$100K

---

## Questions to Think About

1. **How large will your typical pool be?**
   - <$50K: Direct DEX is fine
   - >$100K: Need slippage protection
   - >$1M: Need governance

2. **What assets do you want to support?**
   - Crypto only: DEX works
   - Stocks/commodities: Need synthetic tokens (Synthetix, Mirror)
   - Real estate: Need RWA tokenization partner

3. **How much trust are investors willing to give the owner?**
   - High trust: Manual swaps (Option 2)
   - Low trust: Automated + governance (Option 3)
   - Medium: Hybrid (Option 4)

4. **What's your timeline?**
   - MVP (1 month): Option 1 or 4
   - Production (3 months): Option 4 + oracle validation
   - Enterprise (6+ months): Option 3 with full governance

---

## My Recommendation

Start with **Option 4 (Hybrid)** because:
- ✅ You maintain flexibility (owner can time swaps)
- ✅ Automated execution (no manual token deposits)
- ✅ Oracle validation (prevents bad prices)
- ✅ Not overly complex (realistic for solo dev)
- ✅ Can upgrade to governance later

**Implementation priority:**
1. Integrate Uniswap V3 Router (Week 1)
2. Add slippage protection logic (Week 1)
3. Integrate Chainlink price validation (Week 2)
4. Add emergency fallback mechanisms (Week 2)
5. Test with small amounts on testnet (Week 3)
6. Deploy to mainnet (Week 4)

---

## Next Steps for Discussion

1. **Slippage tolerance:** What's acceptable? 2%? 5%?
2. **Swap timing:** Should owner decide, or auto-execute after pool closes?
3. **Partial fills:** If can't buy all at once, buy in batches?
4. **Emergency scenarios:** What if all swaps fail? Convert to USDC?
5. **Multi-asset priority:** Buy BTC first or USDC first?

Let me know which architecture resonates with you, and we can dive deeper into the specific implementation details! 🚀