# Investment Pool Smart Contract
## A Decentralized Multi-Pool Investment Management System

![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-blue)
![License](https://img.shields.io/badge/License-UNLICENSED-red)
![Status](https://img.shields.io/badge/Critical%20fix-incoming-blue)

---

## 📋 Overview

**Disclaimer:** this project is a documented learning project where i learn solidity by building Dapp.

A comprehensive smart contract system for managing decentralized investment pools on the Ethereum blockchain. Pool creators can launch investment campaigns with target amounts and deadlines, while investors contribute funds and receive proportional ownership. Returns are then distributed based on each investor's contribution percentage.

### Key Features
- ✅ **Multi-Pool Management** - Create and manage multiple independent investment pools
- ✅ **Dynamic Ownership Tracking** - Calculate investor ownership percentages in real-time
- ✅ **Secure Investment** - Reentrancy protection and comprehensive input validation
- ✅ **Automated Pool Closure** - Auto-close pools when targets are reached
- ✅ **Return Distribution** - Proportional payout calculation and distribution
- ✅ **Transparent Operations** - Event-driven architecture for blockchain transparency

---

## 📁 Project Structure

```
mini-solidity-project/
├── src/
│   └── InvestmentPool.sol          # Main smart contract
├── day to day documentation/
│   ├── day1.md     # day one progress, finished phase one
│   ├── day2.md     # day two progess, finished phase two
│   └── ongoing     # ongoing documentation
├── idea/
│   └── [Full project specifications and design documents]
├── README.md                        # This file
└── flowchart.md                    # System flow diagram
```

---

## 🏗️ System Architecture

### Contract Structure

```
InvestmentPool (Main Contract)
├── Data Structures
│   ├── Investor Struct (ownership, amounts, payouts)
│   └── Pool Struct (metadata, status, returns)
├── State Management
│   ├── pools[] - Array of all pools
│   ├── poolInvestors - Multi-level mapping
│   └── poolExists - Validation flags
└── Core Functions
    ├── Phase 1: Pool Creation & Investment
    ├── Phase 2: Return Management & Distribution
    └── Phase 3: Investor Withdrawals (Coming Soon)
```

---

## 🚀 How It Works

### Phase 1: Pool Creation & Investment

**1. Create a Pool**
```solidity
function createPool(uint _targetAmount, uint _deadline) public returns(uint)
```
- Pool creator defines target amount (in wei) and deadline (in days)
- Contract auto-generates unique pool ID
- Pool status: `"open"`

**2. Invest in Pool**
```solidity
function investIn(uint _poolId, uint _amount) public payable
```
- Investors send ETH to contribute to pools
- Ownership percentage calculated: `(investment × 10000) / totalRaised`
- Stored in basis points (1% = 100 basis points)
- Pool auto-closes when target reached

### Phase 2: Return Distribution

**3. Close Pool**
```solidity
function closePool(uint _poolId) public onlyPoolOwner
```
- After deadline, pool owner manually closes pool
- Pool status: `"closed"`

**4. Receive Returns**
```solidity
function receiveReturn(uint _poolId, uint _returnAmount) public payable onlyPoolOwner
```
- Pool owner deposits returns to contract
- Triggers automatic distribution to all investors
- Calculates profit/loss: `returns - originalInvestment`

**5. Distribute Returns**
```solidity
function _distributeR(uint _poolId) private
```
- Iterates through all investors
- Calculates each investor's share: `(totalProfit × ownershipPercent) / 10000`
- Stores individual payout amounts
- Pool status: `"completed"`

### Phase 3: Investor Withdrawals (Planned)
- Investors claim their calculated payouts
- Verification that investor hasn't already withdrawn

---

## 📊 Example Scenario

### Setup
```
Pool Creator: Alice
Target Amount: 100 ETH
Deadline: 30 days
```

### Investment Phase
```
Bob invests 40 ETH  → 40% ownership
Charlie invests 60 ETH → 60% ownership
Pool closes automatically (100 ETH target reached)
```

### Return Phase
```
Alice deposits 120 ETH in returns
Total Profit: 120 - 100 = 20 ETH

Bob's payout: 40 ETH + (20 ETH × 40%) = 48 ETH
Charlie's payout: 60 ETH + (20 ETH × 60%) = 72 ETH
```

---

## 🔒 Security Features

### Protection Mechanisms

| Feature | Type | Purpose |
|---------|------|---------|
| `nonReentrant()` | Modifier | Prevents reentrancy attacks |
| `onlyPoolOwner()` | Modifier | Access control for pool creators |
| `validPoolId()` | Modifier | Pool existence validation |
| `validAmount()` | Modifier | ETH amount verification |
| Solidity 0.8.20+ | Language | Built-in overflow/underflow protection |
| `receive()` / `fallback()` | Functions | Safe ETH reception |

### Validation Checks
- ✅ Pool existence verification
- ✅ Caller authorization
- ✅ Deadline enforcement
- ✅ Pool status validation
- ✅ Amount verification
- ✅ Investment target limits

---

## 📖 Documentation

### Phase 1: Core Architecture

Covers:
- Data structures and state management
- Pool creation mechanism
- Investment functionality
- Real-time ownership calculation
- Getter functions and data retrieval

### Phase 2: Return Management

Covers:
- Pool closure procedures
- Return receipt and profit calculation
- Distribution algorithm
- Error handling and edge cases
- Gas optimization strategies

### System Flowchart
**Interactive Diagram:** [Claude Artifacts Flowchart](https://claude.ai/public/artifacts/f843d054-7990-49e7-adc9-5a3fef1e5b26)

Visual representation of system flow and component interactions.

---

## 🛠️ Installation & Deployment

### Prerequisites
- **Foundry** (Forge, Cast, Anvil) - [Install Guide](https://book.getfoundry.sh/getting-started/installation)
- Solidity 0.8.20 or higher
- Git
- (Optional) RPC endpoint for testnet/mainnet (Infura, Alchemy, etc.)

### Local Setup

**1. Clone Repository**
```bash
git clone https://github.com/yourusername/mini-solidity-project.git
cd mini-solidity-project
```

**2. Install Foundry** (if not already installed)
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

**3. Install Dependencies**
```bash
forge install
```

**4. Compile Contract**
```bash
forge build
```

### Running Tests

**Run All Tests**
```bash
forge test
```

**Run Tests with Verbose Output**
```bash
forge test -vv
```

**Run Specific Test**
```bash
forge test --match "testInvestIn"
```

**Run with Gas Report**
```bash
forge test --gas-report
```

### Local Testing with Anvil

**Start Local Blockchain**
```bash
anvil
```

This starts a local Ethereum node on `http://127.0.0.1:8545`

**Deploy to Local Network (in another terminal)**
```bash
forge create src/InvestmentPool.sol:InvestmentPool \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb476caded87985833a5d6ff01edb
```

The private key above is the first Anvil default account (for testing only).

### Deployment to Testnet

**Setup Environment Variables**
```bash
# Create .env file
cat > .env << EOF
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_INFURA_KEY
PRIVATE_KEY=your_private_key_here
EOF

# Load environment variables
source .env
```

**Deploy to Sepolia Testnet**
```bash
forge create src/InvestmentPool.sol:InvestmentPool \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --verify
```

**Deploy to Mainnet**
```bash
forge create src/InvestmentPool.sol:InvestmentPool \
  --rpc-url $MAINNET_RPC_URL \
  --private-key $PRIVATE_KEY \
  --verify
```

### Interact with Deployed Contract

**Call a Read Function** (getPoolCount)
```bash
cast call 0xYourContractAddress "getPoolCount()" \
  --rpc-url http://localhost:8545
```

**Send Transaction** (createPool)
```bash
cast send 0xYourContractAddress \
  "createPool(uint256,uint256)" 100000000000000000000 30 \
  --rpc-url http://localhost:8545 \
  --private-key 0xYourPrivateKey
```

**Get Pool Details**
```bash
cast call 0xYourContractAddress \
  "getPoolDetail(uint256)" 0 \
  --rpc-url http://localhost:8545
```

### Environment Setup (forge config)

**Create `foundry.toml` for custom configuration**
```toml
[profile.default]
src = "src"
test = "test"
out = "out"
libs = ["lib"]
solc_version = "0.8.20"
optimizer_runs = 200

[profile.prod]
optimizer_runs = 1000

[rpc_endpoints]
sepolia = "${SEPOLIA_RPC_URL}"
mainnet = "${MAINNET_RPC_URL}"
```

---

## 📝 Function Reference

### Pool Management
| Function | Access | Purpose |
|----------|--------|---------|
| `createPool()` | Public | Create new investment pool |
| `closePool()` | Owner Only | Close pool after deadline |
| `getPoolDetail()` | Public View | Retrieve pool information |
| `getPoolCount()` | Public View | Get total pool count |

### Investment Management
| Function | Access | Purpose |
|----------|--------|---------|
| `investIn()` | Public Payable | Invest ETH in pool |
| `getPoolInvestors()` | Public View | List all investors in pool |
| `getInvestorCount()` | Public View | Count investors in pool |
| `getInvestorDetail()` | Public View | Get specific investor info |

### Return Distribution
| Function | Access | Purpose |
|----------|--------|---------|
| `receiveReturn()` | Owner Payable | Deposit returns and trigger distribution |
| `_distributeR()` | Private | Calculate and store payouts |

---

## 💰 Gas Optimization

### Strategies Implemented
1. **Efficient Data Storage** - Mappings for O(1) lookups
2. **Storage Access** - Proper use of `memory` vs `storage`
3. **Event Indexing** - Indexed parameters for filtering
4. **Reentrancy Guard** - Lightweight bool-based protection
5. **Validation Checks** - Early exit on failed conditions

### Estimated Gas Costs (Approximate)
- Create Pool: ~45,000 gas
- Invest: ~65,000 gas
- Close Pool: ~25,000 gas
- Receive Returns: ~125,000 gas (includes distribution)

---

## ⚠️ Known Limitations

### Current Version (Phase 2)
1. **String-based Status** - Pool status uses string comparison (consider enum upgrade)
2. **Large Investor Arrays** - Performance degrades with many investors per pool
3. **No Partial Distribution** - Must distribute 100% or not at all
4. **Fixed Deadline** - Cannot modify deadline after creation
5. **No Investor Limits** - No minimum/maximum investment enforcement

### Future Improvements
- Phase 3: Investor withdrawal mechanism
- Phase 4: Pool upgrades and modifications
- Phase 5: ERC20 token support
- Phase 6: Multi-signature management
- Phase 7: Refund mechanism for unfunded pools

---

## 🧪 Testing

### Test Coverage

```
✅ Pool Creation Tests
   - Valid pool creation
   - ID incrementation
   - Status initialization

✅ Investment Tests
   - Ownership calculation
   - Deadline enforcement
   - Auto-closing on target

✅ Distribution Tests
   - Profit/loss calculation
   - Individual payout math
   - Event emissions

✅ Security Tests
   - Reentrancy protection
   - Access control
   - Input validation
```

### Running Tests
```bash
npx hardhat test
npx hardhat test --grep "Phase 1"
npx hardhat test --grep "Phase 2"
```

---

## 📊 State Diagram

```
Pool Lifecycle:
┌─────────────────────────────────────────────────┐
│                  POOL STATES                    │
└─────────────────────────────────────────────────┘

"open"
  ├─ Investments accepted
  ├─ Deadline enforced
  └─ Auto-close on target → "closed"
      OR manual closePool() after deadline

"closed"
  ├─ No new investments
  ├─ Owner deposits returns
  └─ Triggers distribution → "completed"

"completed"
  ├─ Distribution finished
  ├─ Payouts calculated
  └─ Investors claim returns
```

---

## 🔍 Events

All contract events are indexed for efficient filtering:

```solidity
event poolCreated(uint indexed id, address indexed owner, uint targetAmount, uint deadline)
event investmentMade(uint indexed poolId, address indexed investor, uint amount, uint ownershipPercent)
event poolStatusChanged(uint indexed poolId, string newStatus)
event returnsReceived(uint indexed poolId, uint returnAmount)
event returnDistributed(uint indexed poolId, uint totalProfit)
```

Monitor events for real-time contract activity.

---

## 📚 Learning Resources

This project is designed as an educational tool for understanding:
- Smart contract architecture and design patterns
- Solidity security best practices
- Blockchain state management
- Gas optimization techniques
- Event-driven development

### Recommended Reading Order
1. **Start Here:** README.md (this file)
2. **Phase 1:** Core Architecture & Pool Creation
3. **Phase 2:** Return Management & Distribution
4. **Next:** Phase 3 Documentation (Coming Soon)

---

## 🤝 Contributing

This is an educational project. Improvements and suggestions are welcome:
- Report issues via GitHub Issues
- Submit security findings responsibly
- Suggest documentation improvements
- Propose optimization techniques

---

## 📄 License

**UNLICENSED** - For educational purposes only.
Not intended for production use without thorough auditing.

---

## ⚡ Quick Start

### Deploy Locally with Anvil
```bash
# Terminal 1: Start local blockchain
anvil

# Terminal 2: Deploy contract
forge create src/InvestmentPool.sol:InvestmentPool \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb476caded87985833a5d6ff01edb

# Terminal 2: Run tests
forge test -vv
```

### Interact with Contract Using Cast
```bash
# Get pool count
cast call 0xYourContractAddress "getPoolCount()" \
  --rpc-url http://localhost:8545

# Create a new pool (100 ETH target, 30 days)
cast send 0xYourContractAddress \
  "createPool(uint256,uint256)" 100000000000000000000 30 \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb476caded87985833a5d6ff01edb

# Invest 10 ETH in pool 0
cast send 0xYourContractAddress \
  "investIn(uint256,uint256)" 0 10000000000000000000 \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb476caded87985833a5d6ff01edb \
  --value 10000000000000000000

# Get pool details
cast call 0xYourContractAddress \
  "getPoolDetail(uint256)" 0 \
  --rpc-url http://localhost:8545
```

### Complete Workflow Example
```bash
# 1. Start Anvil (Terminal 1)
anvil

# 2. Deploy contract (Terminal 2)
DEPLOYED_ADDRESS=$(forge create src/InvestmentPool.sol:InvestmentPool \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb476caded87985833a5d6ff01edb \
  --json | jq -r '.deployedTo')

echo "Contract deployed at: $DEPLOYED_ADDRESS"

# 3. Create pool
cast send $DEPLOYED_ADDRESS \
  "createPool(uint256,uint256)" 100000000000000000000 30 \
  --rpc-url http://localhost:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb476caded87985833a5d6ff01edb

# 4. Verify pool created
cast call $DEPLOYED_ADDRESS "getPoolCount()" \
  --rpc-url http://localhost:8545
```

---

## 📞 Support

For questions or clarifications:
- Review the detailed documentation in `docs/` folder
- Check the interactive flowchart
- See the `idea/` folder for design specifications

---

## 🎯 Project Roadmap

```
Phase 1: ✅ COMPLETE - Pool Creation & Investment
Phase 2: ✅ COMPLETE - Return Management & Distribution
Phase 3: ✅ COMPLETE - Investor Withdrawals
Phase 4: ⏳ PLANNED - Advanced Features
Phase 5+: ⏳ FUTURE - Token support, upgrades, etc.
```

## Current critial issue
- **String comparison is inefficient:** using keccak256(abi.encodePacked()) to compare status strings. Upcoming update will try to use enum instead.
- **Precision loss in ownership calculation:** when calculating ownershipPercent, early investors get recalculated when new investors join. This breaks fairness.
- **Integer overflow in profit calculation:** When _returnAmount is very large or very negative, casting to int256 could cause issues. 
- **No emergency withdrawal:** If something goes wrong, investors are stuck. Add an emergency function that lets investors withdraw their original investment if pool gets stuck.

---

## Version History

| Version | Phase | Status | Date |
|---------|-------|--------|------|
| 1.0 | Phase 1 | Complete | Dec, 6 2025|
| 1.1 | Phase 2 | Complete | Dec, 7 2025 |
| 2.0 | Phase 3 | Complete | Dec, 7 2025 |
| 2.1 | Critical update| complete | Dec, 8 2025|
| 2.2 | testing and emergency features| ongoing| TBA|

---

## Current version problem
we might face problems in our current version so i will put this specific section for those problems. I added a new folder inside day to day documentation called Problems, you can freely check it out.

**we're currently have no issue in this version except the emergency features missing. I'm working on it right now.**

**Happy Learning! 🚀**

This project demonstrates core blockchain principles in a practical, well-documented format. For production use, conduct thorough security audits and testing.