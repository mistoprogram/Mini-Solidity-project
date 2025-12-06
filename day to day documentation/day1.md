# Day 1
The focus of Day 1 was establishing the core architecture of the `InvestmentPool` contract, including data structures, state variables, and essential functions for pool creation and investment.

## core components
### 1. Structures(`Struct`)
Two main data structures were defined to organize information efficiently:
- `investor`: Stores details about each individual contribution to a pool.
    - `ownershipPercent`: Represents the investor's share of the pool's total funding, calculated in basis points (1/100th of a percent).
    - `payoutAmount`: Reserved for tracking the final calculated return/payout for the investor.
- `Pool`: Stores all global parameters and status of a single investment pool.
    - `status`: A string indicating the pool's state (e.g., "open", "closed", "funded").
    - `totalProfit`: An int type, allowing the pool to track both profit (positive) and loss (negative).

### 2. State Variable & Mappings
These variables manage the contract's overall state:
| Var/Mapping | Type | Purpose
|-------------|----------|----------|
| pools | Pool[] | An array to store all created pools (accessed by index). |
|poolInvestors | mapping(uint => Investor[]) | Stores a list of all Investor structs for a given pool ID. | 
| investorByAddress | mapping(uint => mapping(address => Investor))| Provides quick lookup of an investor's record by their address within a specific pool.|
|poolExists|mapping(uint => bool)|Used as a safety flag to quickly verify if a pool ID is valid.|
|poolCount|uint public|Total number of pools created (also used to generate new pool IDs).|
|locked| bool private| A flag used by the nonReentrant modifier to prevent reentrancy attacks.|

### 3. Modifiers
Custom logic used to restrict and validate function execution:
- onlyPoolOwner(_poolId): Requires the caller to be the owner of the specified pool.
- nonReentrant(): Uses the locked flag to prevent external contracts from re-calling the function before the first call finishes (security).
- validPoolId(_poolId): Ensures the pool ID is valid and exists within the pools array.
- validAmount(_amount): Checks that the ETH sent (msg.value) exactly matches the amount specified in the function argument.

### 4. Core functionality implementation
- constructor(): Sets the contractOwner to the deployer address.
- receive() and fallback(): Declared external payable to ensure the contract can accept direct ETH transfers.

#### Pool creation and investment
- createPool(uint _targetAmount, uint _deadline):
    - Creates a new Pool struct using the current msg.sender as the owner.
    - Calculates the future deadline by adding the input days (multiplied by 86,400 seconds/day) to block.timestamp.
    - Increments poolCount and emits the poolCreated event.
- investIn(uint _poolId, uint _amount):
    - Utilizes the payable, validPoolId, validAmount, and nonReentrant modifiers.
    - Validates that the pool is "open" and the deadline has not passed.
    - Calculates the investor's ownershipPercent based on their contribution relative to the current amountRaised.
    - Updates the pool's amountRaised and stores the new Investor record.
    - Auto-Closes: If the investment causes amountRaised to meet or exceed targetAmount, the pool status is immediately set to "closed".

#### Getter and admin
- Getter Functions: A suite of public view functions (getPoolDetail, getPoolInvestors, getInvestorCount, getInvestorDetail, getPoolCount) are implemented to allow transparent reading of all crucial pool data.
- closePool(uint _poolId): Allows the pool owner to manually transition the pool status to "closed", provided the initial investment deadline has passed.