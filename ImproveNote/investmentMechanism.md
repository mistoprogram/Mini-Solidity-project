# Investment Execution Architecture - Multi-Asset Design

## Vision Statement

Transform your Investment Pool from a capital aggregator into a **portfolio manager**. Pool owners don't just collect money—they deploy it strategically across multiple assets, track performance in real-time, and generate measurable returns. This architecture enables institutional-grade portfolio management on-chain with transparency and flexibility.

---

## Core Problem We're Solving

**Current State:** Pool collects money, then... nothing happens until owner calls `receiveReturn()` with a lump sum. Investors don't know:
- Where their money went
- What assets were purchased
- How the portfolio is performing
- If the owner actually invested or disappeared with the money

**Solution:** Make capital deployment **transparent, granular, and verifiable on-chain**. Every investment decision, every asset purchase, every price movement is recorded and visible to all investors.

---

## Architecture Overview

Think of this as a **portfolio management system** layered on top of your existing pool contract. Instead of treating the pool as a black box that goes from "closed" to "completed", we make it a **live portfolio** where:

1. Pool owner defines an **investment strategy** (what assets, what allocation)
2. Owner **executes purchases** in stages (buy BTC, then ETH, then stocks)
3. Pool **tracks holdings** in real-time (knows exactly what it owns and current value)
4. Pool **auto-rebalances** if needed (sell underperformers, buy winners)
5. When time comes to liquidate, pool **returns actual gains/losses** (based on real prices, not made-up numbers)

---

## Key Architectural Components

### 1. Investment Strategy Definition

**What it does:**
Before the pool owner can spend a single dollar, they must define their investment thesis. This is the blueprint that guides all capital deployment.

**What gets defined:**
- **Asset allocation percentages:** "50% crypto, 30% stocks, 20% cash reserves"
- **Specific assets:** "Crypto basket: 60% BTC, 40% ETH" and "Stock basket: 70% SPX (S&P 500), 30% AAPL"
- **Rebalancing rules:** "If BTC drops below 55% allocation, buy more. If goes above 65%, sell"
- **Risk limits:** "Single asset can't exceed 30% of portfolio"
- **Time horizon:** "Liquidate on 2025-12-31" or "Hold for 5 years"

**Data structure:**
Each strategy needs:
- Strategy ID (unique identifier)
- Array of asset allocations (asset name, target percentage)
- Rebalancing triggers and rules
- Risk constraints
- Target liquidation date

**Who controls it:**
- Pool owner defines strategy before first investment
- Cannot change strategy mid-pool (prevents moving goalposts)
- Exception: governance vote can adjust if market conditions drastically change

**Why it matters:**
Investors can review the strategy upfront and know exactly what they're funding. No surprises. Creates accountability.

---

### 2. Asset Ledger System

**What it does:**
Tracks every single asset the pool owns and its current value. Think of it as a live portfolio dashboard on-chain.

**What it tracks:**
- **Asset holdings:** "Currently own 2.5 BTC, 15 ETH, 100 shares of SPX"
- **Entry prices:** "Bought BTC at $40K, ETH at $2K, SPX at $450"
- **Current prices:** "BTC now $45K (from oracle), ETH now $2.2K, SPX now $480"
- **Unrealized gains/losses:** "BTC up $12.5K, ETH up $3K, SPX up $3K"
- **Total portfolio value:** "Sum of all holdings at current prices"

**Data structure:**
For each asset in the pool:
- Asset identifier (ticker, token address, or oracle ID)
- Quantity held
- Average purchase price
- Current market price (from oracle)
- Timestamp of last price update
- Cumulative gains/losses

**How it updates:**
- When owner buys an asset: add to holdings
- When owner sells an asset: subtract from holdings
- When oracle sends new price: recalculate unrealized gains/losses
- This happens continuously (prices update daily or hourly depending on asset)

**Why it matters:**
Investors can see portfolio performance in real-time. Builds trust. Shows owner is actually doing their job.

---

### 3. Investment Execution Module

**What it does:**
Pool owner executes purchases and sales. This is the mechanism for moving capital from the pool into actual assets.

**Types of execution:**

**A. Single Asset Purchase**
- Owner says: "Buy 0.5 BTC"
- Pool deducts cash, adds BTC to holdings
- Records: timestamp, amount bought, price paid
- Emits event so investors can see it happened

**B. Basket Purchase** 
- Owner says: "Execute my strategy: buy 50% in crypto basket (60% BTC, 40% ETH)"
- Pool automatically calculates amounts needed
- Executes all trades (could be multiple assets)
- Updates asset ledger

**C. Rebalancing**
- Owner says: "Rebalance to target allocation"
- Pool calculates current allocation vs target
- If BTC is 65% (target 60%), sell 5% worth
- If ETH is 30% (target 40%), buy 10% more
- Executes automatically, updates ledger

**D. Liquidation**
- Owner says: "Liquidate entire portfolio"
- Pool sells ALL assets at current market prices
- Converts to cash/stablecoins
- Calculates final profit/loss
- Triggers payout distribution

**Data structure needed:**
- Investment execution record: what, when, how much, at what price
- History of all executions (immutable log)
- Current portfolio state (what we own now)
- Pending orders (waiting to execute)

**Who can execute:**
- Only pool owner can execute
- Requires no multi-sig yet (simple version)
- Advanced version: multi-sig or DAO voting for large trades

**Why it matters:**
Capital actually moves. Portfolio is actively managed, not static.

---

### 4. Price Oracle Integration

**What it does:**
Provides real-time asset prices so portfolio value can be calculated accurately.

**What prices it needs:**
- Crypto prices: BTC, ETH, XRP, etc. (from Chainlink)
- Stock prices: SPX, AAPL, etc. (from Chainlink stock feeds)
- Stablecoin prices: USDC, USDT (should always be $1)

**How it works:**
- Contract queries oracle (e.g., Chainlink)
- Oracle returns current price with timestamp
- Contract records the price
- Portfolio value recalculated based on new prices

**Key decisions:**
- **Price freshness:** How old can a price be? (e.g., must be < 1 hour old)
- **Price accuracy:** What if oracle disagrees? (use median of multiple oracles)
- **Emergency handling:** What if oracle goes down? (fall back to last known price, emit alert)

**Why it matters:**
Without real prices, you can't calculate actual portfolio value or profit/loss. This is the heart of the system.

---

### 5. Performance Tracking System

**What it does:**
Continuously calculates how well the portfolio is performing.

**Metrics it tracks:**

**A. Unrealized P&L (before liquidation)**
- Current portfolio value vs amount invested
- "Started with $1M, now worth $1.2M, so +$200K unrealized profit"

**B. Realized P&L (when assets sold)**
- Difference between sale price and purchase price
- "Bought BTC at $40K, sold at $45K, made $5K per BTC"

**C. Return metrics**
- Percentage return: (Current Value / Invested Amount) - 1
- "Up 20%"
- Time-weighted return: accounts for timing of cash flows
- Money-weighted return: IRR-style calculation

**D. Risk metrics**
- Volatility: how much does portfolio value swing day-to-day
- Drawdown: peak-to-trough loss (if portfolio was worth $1M then drops to $900K, that's 10% drawdown)
- Sharpe ratio: return per unit of risk

**E. Attribution analytics**
- Which assets are winning/losing
- Which decisions made/lost money
- "BTC is +$100K, ETH is +$50K, SPX is -$10K"

**Data structure:**
- Daily snapshots: date, portfolio value, holdings, prices
- Transaction history: every buy/sell with P&L
- Performance metrics: calculated daily

**Why it matters:**
Investors can see if money is actually being made. Transparency = trust.

---

### 6. Staged Liquidation & Distribution

**What it does:**
When pool reaches completion date, convert portfolio back to cash and distribute to investors.

**The flow:**

**Stage 1: Pre-liquidation Review**
- Owner reviews portfolio (5 days before maturity)
- Investors can see what will be liquidated and at what prices
- Gives community a chance to object if prices seem wrong

**Stage 2: Market Liquidation**
- Owner executes final liquidation
- All assets sold at market prices
- Pool converts to stablecoins (USDC) or ETH
- Records final prices and P&L

**Stage 3: Profit/Loss Calculation**
- Original investment: $6M
- Final value: $7.2M
- Total profit: $1.2M
- This is **real**, not made-up

**Stage 4: Distribution**
- Each investor gets their share
- Alice: $1M + ($1.2M × 16.67%) = $1.2M
- Bob: $3M + ($1.2M × 50%) = $3.6M
- Charlie: $2M + ($1.2M × 33.3%) = $2.4M

**Data needed:**
- Liquidation schedule: which assets to sell when
- Final prices: what each asset sold for
- Final portfolio value: total cash after liquidation
- Calculated payouts for each investor

**Why it matters:**
Profits/losses are real, not fiction. Based on actual market prices, not owner's word.

---

## How Components Interact

Here's the flow from pool creation to investor payout:

```
1. Pool Created
   ↓
2. Owner Defines Strategy
   (e.g., 50% BTC, 40% ETH, 10% USDC)
   ↓
3. Investors Deposit Capital
   (pool collects money, enters "investing" phase)
   ↓
4. Owner Executes Investments
   (buys BTC, ETH according to strategy)
   ↓
5. Asset Ledger Updated
   (records: 0.5 BTC at $40K, 5 ETH at $2K, etc.)
   ↓
6. Prices Updated from Oracle
   (BTC now $45K, ETH now $2.2K, prices refresh daily)
   ↓
7. Portfolio Tracked
   (investors can see real-time value: $1.025M → $1.050M → $1.075M)
   ↓
8. Optional Rebalancing
   (owner adjusts allocation if needed)
   ↓
9. Hold Period Passes
   (portfolio matures)
   ↓
10. Pre-liquidation Review
    (investors review what will be liquidated)
    ↓
11. Owner Liquidates Portfolio
    (sells all assets at market prices)
    ↓
12. Final P&L Calculated
    (total return computed from real prices)
    ↓
13. Profits Distributed
    (investors receive payouts based on calculated gains)
```

---

## Key Design Decisions to Make

### Decision 1: Where Do Assets Actually Live?

**Option A: On-Chain (Recommended for starting)**
- Pool contract owns the assets directly
- BTC is actually in pool wallet (via wrapped BTC or bridge)
- ETH is actually in pool wallet
- Everything is on-chain and transparent
- **Pros:** Fully trustless, no custodian needed, transparent
- **Cons:** Can only trade assets available on-chain (limits stocks)
- **Best for:** Crypto-only or crypto + stablecoins

**Option B: Off-Chain with Oracle Confirmation**
- Owner manages assets in traditional broker/exchange
- Submits price proofs to smart contract
- Contract trusts oracle's word about what's owned
- **Pros:** Can trade real stocks, commodities, anything
- **Cons:** Requires trust in oracle/owner, less transparent
- **Best for:** Crypto + traditional assets

**Option C: Hybrid**
- Crypto assets on-chain (BTC, ETH directly held)
- Exposure to stocks via synthetic assets or tokenized funds
- Use Chainlink price feeds for both
- **Pros:** Best of both worlds
- **Cons:** More complex

---

### Decision 2: Who Executes Trades?

**Option A: Pool Owner Direct (Simplest)**
- Owner calls `investIn(asset, amount)`
- Pool transfers to owner's wallet
- Owner trades on exchange (CEX/DEX)
- Owner reports back to contract with results

**Option B: Smart Contract Direct (Most Trustless)**
- Pool contract integrates with DEX (Uniswap)
- Owner calls `buyAsset(BTC, 0.5)`
- Contract automatically executes on DEX
- Asset received directly to pool wallet
- No intermediary involved

**Option C: DAO Governance (Most Decentralized)**
- Owner proposes trade: "Buy 0.5 BTC at $45K"
- Investors vote (or token holders vote)
- If approved, trade executes automatically
- Prevents owner from making unilateral decisions

---

### Decision 3: Price Update Frequency

**Crypto assets:** 
- Should update hourly or more (prices move fast)
- Use Chainlink automation to refresh prices
- Investors see portfolio value updates frequently

**Stock assets:**
- Update daily (markets close)
- Less frequent updates acceptable
- Can batch stock price updates once per day

**Impact:**
- More frequent = better tracking but higher gas costs
- Less frequent = cheaper but less accurate

---

### Decision 4: Rebalancing Strategy

**Option A: Manual Rebalancing**
- Owner monitors portfolio
- When allocation drifts (e.g., BTC goes from 50% to 60%), owner rebalances manually
- Owner calls `rebalance()` to restore target allocation

**Option B: Automatic Rebalancing**
- Smart contract checks allocation every day
- If BTC > 60%, automatically sells until it's 60%
- If ETH < 40%, automatically buys until it's 40%
- Executes via DEX integration (Uniswap)

**Option C: Threshold-Based**
- Rebalance only if allocation drifts > 10% from target
- Less frequent, cheaper, but allows some drift
- Triggers automatically or manually

---

## Data Structures Overview

Your contract will need several new data structures:

### 1. Investment Strategy Structure
Defines what the pool owner will invest in and how

### 2. Asset Holding Structure
What the pool currently owns (ticker, quantity, purchase price)

### 3. Investment Execution Record
History of each buy/sell (timestamp, asset, amount, price)

### 4. Portfolio Snapshot Structure
Daily snapshot of portfolio state (date, total value, all holdings with current prices)

### 5. Liquidation Record
Final state when pool matures (all assets sold, final prices, total return)

---

## New Functions to Implement

### Strategy Definition
- `defineStrategy()`: Owner sets up investment plan before investing starts
- `getStrategy()`: Investors view the strategy
- `updateStrategy()`: Change strategy (restricted, needs governance)

### Investment Execution
- `investInAsset()`: Owner buys a specific asset
- `investInBasket()`: Owner buys entire strategy allocation
- `liquidateAsset()`: Owner sells a specific asset
- `rebalancePortfolio()`: Restore target allocation

### Portfolio Tracking
- `updateAssetPrice()`: Refresh prices from oracle
- `getCurrentPortfolioValue()`: Calculate total value
- `getAssetHoldings()`: See what pool owns
- `getUnrealizedPnL()`: See current gains/losses
- `getExecutionHistory()`: See all trades made

### Performance Analytics
- `getPortfolioReturn()`: Calculate total return %
- `getAssetContribution()`: Which assets made/lost money
- `getVolatility()`: How risky is portfolio
- `getPortfolioSnapshots()`: Historical daily values

### Liquidation
- `prepareForLiquidation()`: Owner marks pool ready to sell
- `liquidatePortfolio()`: Sell all assets
- `calculateFinalReturns()`: Compute actual profit/loss
- `distributeReturns()`: Pay investors

---

## State Transitions

Pool now has more states:

```
"open" (collecting capital)
  ↓
"investing" (owner deploying capital, executing trades)
  ↓
"active" (portfolio is live, tracked daily, rebalancing as needed)
  ↓
"pending_liquidation" (maturity approaching, reviewing holdings)
  ↓
"liquidating" (selling assets)
  ↓
"completed" (ready for payouts)
```

This is more complex than the simple open→closed→completed flow. Portfolio is actively managed, not static.

---

## Interaction with Existing Pool Structure

**What stays the same:**
- Investor deposits
- Ownership percentage calculation
- Withdrawal mechanism
- Emergency withdraw

**What changes:**
- Pool goes into "investing" state instead of just "closed"
- Instead of owner submitting lump sum return, portfolio is live and tracked
- Profit calculation comes from real asset prices, not owner's number
- Multiple state transitions instead of simple close → complete

**What's new:**
- Strategy definition before investing
- Real-time portfolio tracking
- Asset ledger
- Price oracle integration
- Liquidation workflow
- Performance analytics

---

## Trust Model

**Before this design:** 
Owner has pool funds → Owner makes investment → Owner comes back with returns (or doesn't)
- Single point of failure: owner could disappear with money

**With this design:**
Owner has pool funds → Owner declares strategy (public) → Owner executes trades (on-chain) → Portfolio tracked in real-time → Investor can see everything
- Owner can't hide what was bought
- Owner can't claim fake profits (prices are from oracle)
- Owner can't disappear undetected (all trades logged)
- If owner tries to rug, investor can see it happening

---

## Roadmap to Implementation

### Phase 1: Basic Asset Tracking
- Define investment strategy structure
- Create asset holding ledger
- Track current holdings (what pool owns)
- Simple manual price updates

### Phase 2: Oracle Integration
- Integrate Chainlink price feeds
- Auto-update prices daily/hourly
- Calculate real-time portfolio value
- Track unrealized gains/losses

### Phase 3: Investment Execution
- Owner can invest in single assets
- Owner can execute basket strategy
- History of all trades recorded
- Pool state updates correctly

### Phase 4: Advanced Features
- Rebalancing (manual and/or automatic)
- Liquidation workflow
- Performance analytics
- Investor dashboard queries

---

## Example Usage

**Real scenario:**

1. **Pool creation:** Target $1M, 6-month investment period
2. **Strategy:** "40% BTC, 30% ETH, 30% USDC cash"
3. **Investors deposit:** Pool reaches $1M
4. **Owner invests:**
   - Buys 10 BTC at $40K = $400K
   - Buys 150 ETH at $2K = $300K
   - Keeps $300K in USDC
5. **Portfolio tracked:** Daily prices update
   - Week 1: BTC $42K, ETH $2.1K → Portfolio worth $1.05M (+5%)
   - Week 12: BTC $48K, ETH $2.5K → Portfolio worth $1.15M (+15%)
6. **Rebalancing:** BTC now 45%, ETH 33%, USDC 22%, so rebalance
7. **Maturity:** 6 months pass
8. **Liquidation:** All assets sold at current prices
   - Final value: $1.18M
   - Total profit: $180K (18% return)
9. **Distribution:** Each investor gets their share of the $180K

Investors see the ENTIRE process on-chain, in real-time. No black box. This is institutional-grade transparency.

---

## Benefits of This Architecture

1. **Transparency:** Every trade on-chain, every price auditable
2. **Trust:** Owner can't hide bad investments or fake profits
3. **Real Returns:** Calculated from oracle prices, not fiction
4. **Professional:** Mimics how real investment funds work
5. **Scalable:** Can manage multiple asset classes
6. **Governance-Ready:** Can add voting for large trades later
7. **Performance Tracking:** Investors know exactly how they're doing