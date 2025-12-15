// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.20;

contract GlobalVar {
    
    enum sts {
        open,
        closed,
        complete,
        stuck,
        EmergencyWithdraw
    }

    enum EmergencyType {
        ownerInactive
    }

    //==================== EVENTS ====================
    event poolCreated(uint indexed id, address indexed owner, uint targetAmount, uint deadline);
    event investmentMade(uint indexed poolId, address indexed investor, uint amount, uint ownershipPercent);
    event poolStatusChanged(uint indexed poolId, sts newStatus);
    event withdrawalMade(uint indexed poolId, address indexed investor, uint amount);
    event returnDistributed(uint indexed poolId, int totalProfit);
    
    // emergency events
    event emergencyWithdrawTriggered(uint indexed poolId, EmergencyType emergencyType);
    
    //==================== STRUCTS ====================
    
    struct Strategy{
        uint strategyId;
        uint[] assetsAmount;       // amount (in wei) allocated to each asset
        uint[] assetsPercentage;   // percentage of pool allocated to each asset, scaled by SCALE (1e18 == 100%)
        address[] tokenAddresses;
        bool riskLimit;
    }
    
    struct Investor {
        uint amount;
        int payoutAmount;
        uint timestamp;
        uint ownershipPercent; // scaled by SCALE (1e18 == 100%)
        bool hasWithdrawn;
        address investorAddress;
    }

    struct Pool {
        uint id;
        uint targetAmount;
        uint amountRaised;
        uint deadline;
        uint totalReturnReceived;
        int totalProfit;
        int payoutAmount;
        address owner;
        uint lastOwnerActivity;
        sts status;
        Strategy poolstrategy;
    }

    //==================== STATE VARIABLES ====================
    Pool[] internal pools;
    mapping(uint => Investor[]) internal poolInvestors;
    mapping(uint => mapping(address => Investor)) internal investorByAddress;
    mapping(uint => bool) internal poolExists;
    mapping(uint => Strategy) internal poolStrategies;

    uint public poolCount = 0;
    address public contractOwner;
    
    bool internal locked; // Reentrancy guard
    
    uint internal constant EMERGENCY_INACTIVE_PERIOD = 7 days; // Time before owner inactivity triggers emergency

    // Standardized scale for percentages and external price feeds (Chainlink-style): 1e18 == 100%
    uint internal constant SCALE = 1e18;

    //==================== MODIFIERS ====================
    modifier onlyPoolOwner(uint _poolId) {
        _onlyPoolOwner(_poolId);
        _;
    }

    function _onlyPoolOwner(uint _poolId) internal view {
        require(poolExists[_poolId], "Pool does not exist");
        require(pools[_poolId].owner == msg.sender, "Only pool owner can call this");
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() internal {
        require(!locked, "No reentrancy");
        locked = true;
    }

    function _nonReentrantAfter() internal {
        locked = false;
    }

    modifier validPoolId(uint _poolId) {
        _validPoolId(_poolId);
        _;
    }

    function _validPoolId(uint _poolId) internal view {
        require(_poolId < poolCount, "Invalid pool ID");
        require(poolExists[_poolId], "Pool does not exist");
    }

    modifier validAmount(uint _amount) {
        _validAmount(_amount);
        _;
    }

    function _validAmount(uint _amount) internal view {
        require(_amount > 0, "Amount must be greater than 0");
        require(msg.value == _amount, "Sent amount doesn't match specified amount");
    }

    //==================== CONSTRUCTOR ====================
    constructor() {
        contractOwner = msg.sender;
        locked = false;
    }
}

contract PoolManagement is GlobalVar {
    receive() external payable {}
    fallback() external payable {}

    //Pool section
    function createPool(uint _targetAmount, uint64 _deadline) public returns(uint) {
        require(_targetAmount > 0, "Target amount must be greater than 0");
        require(_deadline > 0, "Deadline must be in the future");

        uint poolId = poolCount;
        uint64 deadlineTime = uint64(block.timestamp + (_deadline * 86400));

        Pool memory newPool = Pool({
            id: poolId,
            owner: msg.sender,
            targetAmount: _targetAmount,
            amountRaised: 0,
            deadline: deadlineTime,
            status: sts.open,
            totalReturnReceived: 0,
            totalProfit: 0,
            payoutAmount: 0,
            lastOwnerActivity: block.timestamp,
            poolstrategy: Strategy({
                strategyId: 0,
                assetsAmount: new uint[](0),
                assetsPercentage: new uint[](0),
                deadline: 0,
                assets: new string[](0),
                riskLimit: false
            })
        });

        pools.push(newPool);
        poolExists[poolId] = true;
        poolCount++;

        emit poolCreated(poolId, msg.sender, _targetAmount, deadlineTime);

        return poolId;
    }

    //Investment Function
    function investIn(uint _poolId, uint _amount) 
        public 
        payable 
        validPoolId(_poolId) 
        validAmount(_amount) 
        nonReentrant 
    {
        Pool storage pool = pools[_poolId];

        // Validation checks
        require(
            pool.status == sts.open,
            "Pool is not open for investment"
        );
        require(block.timestamp <= pool.deadline, "Investment deadline has passed");
        require(_amount <= pool.targetAmount - pool.amountRaised, "Investment exceeds pool target");

        // Update pool
        pool.amountRaised += _amount;

        // Calculate ownership percentage using SCALE (1e18 == 100%)
        uint ownershipScaled = (_amount * SCALE) / pool.amountRaised;

        // Create investor record
        Investor memory newInvestor = Investor({
            investorAddress: msg.sender,
            amount: _amount,
            timestamp: block.timestamp,
            ownershipPercent: ownershipScaled,
            hasWithdrawn: false,
            payoutAmount: 0
        });

        // Store investor
        poolInvestors[_poolId].push(newInvestor);
        investorByAddress[_poolId][msg.sender] = newInvestor;

        // Now recalculate ALL ownership percentages (including the new investor)
        Investor[] storage investors = poolInvestors[_poolId];
        for (uint i = 0; i < investors.length; i++) {
            uint percent = (investors[i].amount * SCALE) / pool.amountRaised;
            investors[i].ownershipPercent = percent;
            investorByAddress[_poolId][investors[i].investorAddress] = investors[i];
        }

        emit investmentMade(_poolId, msg.sender, _amount, ownershipScaled);

        // Recompute ownershipPercent for all investors (dilution) and keep mapping in sync
        Investor[] storage investors = poolInvestors[_poolId];
        for (uint i = 0; i < investors.length; i++) {
            uint percent = (investors[i].amount * SCALE) / pool.amountRaised;
            investors[i].ownershipPercent = percent;
            investorByAddress[_poolId][investors[i].investorAddress] = investors[i];
        }

        // Auto-close pool if target reached
        if (pool.amountRaised >= pool.targetAmount) {
            pool.status = sts.closed;
            emit poolStatusChanged(_poolId, pool.status);
        }
    }
}

contract investmentStrategy is PoolManagement{

    uint public idCount = 0;

    // setStrategy now expects percentages scaled by SCALE (1e18 == 100%)
    function setStrategy(
        uint _poolId,
        address[] memory _tokenAddresses,
        uint[] memory _percentages, // percentages scaled by SCALE (sum must be SCALE)
        uint _deadline
    )
    public
    onlyPoolOwner(_poolId)
    nonReentrant
    {
        require(pool.amountRaised > 0, "Pool has no funds to create strategy");
        require(_assets.length == _percentages.length, "Assets and percentages length mismatch");
        require(_assets.length > 0, "At least one asset required");

        Pool storage pool = pools[_poolId];
        require(pool.amountRaised > 0, "Pool has no funds to create strategy");

        uint totalPercent = 0;
        for (uint i = 0; i < _percentages.length; i++) {
            totalPercent += _percentages[i];
        }
        require(totalPercent == SCALE, "Percentages must sum to SCALE (1e18 == 100%)");

        uint newId = idCount;

        uint[] memory assetAmount = new uint[](_percentages.length);

        // Calculate each asset amount based on pool.amountRaised and scaled percentages
        // assetAmount (wei) = amountRaised * percentage / SCALE
        for (uint i = 0; i < _percentages.length; i++) {
            assetAmount[i] = (pool.amountRaised * _percentages[i]) / SCALE;
        }

        Strategy memory newStrategy = Strategy({
            strategyId: newId,
            assets: _assets,
            assetsPercentage: _percentages,
            riskLimit: false,
            assetsAmount: assetAmount
        });

        pool.poolstrategy = newStrategy;  // Assign directly to pool
        poolStrategies[_poolId] = newStrategy;  // Also store in mapping for easy access
        idCount++;
    }
}

contract Admin is investmentStrategy {
    //==================== ADMIN FUNCTIONS ====================
    function closePool(uint _poolId) 
        public 
        onlyPoolOwner(_poolId) 
    {
        Pool storage pool = pools[_poolId];
        require(
            block.timestamp > pool.deadline, "Deadline has not yet passed"
        );
        
        require(
            pool.status == sts.open,
            "Pool is already closed"
        );
        
        pool.status = sts.closed;
        pool.lastOwnerActivity = block.timestamp;
        emit poolStatusChanged(_poolId, pool.status);
    }

    function receiveReturn(uint _poolId, uint _returnAmount)
        public 
        payable
        onlyPoolOwner(_poolId)
        validPoolId(_poolId)
    {
        Pool storage investmentPool = pools[_poolId];

        require(
            investmentPool.status == sts.closed, 
            "Pool must be closed first"
        );
        require(_returnAmount > 0, "Return amount must be greater than 0");
        require(msg.value == _returnAmount, "Sent amount doesn't match return amount");

        investmentPool.totalReturnReceived = _returnAmount;
        uint originalInvestment = investmentPool.amountRaised;

        if (_returnAmount > originalInvestment) {
            investmentPool.totalProfit = int256(_returnAmount - originalInvestment);
        } else {
            investmentPool.totalProfit = -int256(originalInvestment - _returnAmount);
        }

        _distributeR(_poolId);
        investmentPool.status = sts.complete;
        investmentPool.lastOwnerActivity = block.timestamp;
        emit poolStatusChanged(_poolId, sts.complete);
    }

    function _distributeR(uint _poolId) 
        internal
    {
        Pool storage pool = pools[_poolId];
        Investor[] storage investors = poolInvestors[_poolId];
        
        int tProfit = pool.totalProfit;
        uint totalRaised = pool.amountRaised;
        
        // Loop through each investor
        for(uint i = 0; i < investors.length; i++) {
            uint correctOwnershipPercent = (investors[i].amount * SCALE) / totalRaised;
            
            int profitShare = (tProfit * int(correctOwnershipPercent)) / int(SCALE);
            int totalPayout = int(investors[i].amount) + profitShare;
            
            // Update array entry
            investors[i].payoutAmount = totalPayout;
            investors[i].ownershipPercent = correctOwnershipPercent;

            // Sync mapping entry so withdraw/emergencyWithdrawal see the updated values
            investorByAddress[_poolId][investors[i].investorAddress] = investors[i];
        }
        
        emit returnDistributed(_poolId, tProfit);
    }

    function withdraw(uint _poolId)
        public
        validPoolId(_poolId)
        nonReentrant
    {
        Pool storage pool = pools[_poolId];
        Investor storage investor = investorByAddress[_poolId][msg.sender];

        require(
            pool.status == sts.complete, 
            "Pool status must be completed!"
        );
        require(
            !investor.hasWithdrawn, 
            "You already withdrawn"
        );
        require(
            investor.payoutAmount > 0, 
            "You don't have enough funds to withdraw"
        );

        int payout = investor.payoutAmount;
        
        // mark withdrawn before external call (check-effects-interactions)
        investor.hasWithdrawn = true;

        (bool success, ) = payable(msg.sender).call{value: uint256(payout)}("");
        require(success, "Withdrawal failed");

        emit withdrawalMade(_poolId, msg.sender, uint256(payout));
    }
}

contract Emergency is Admin {
    //==================== EMERGENCY FUNCTIONS ====================
    
    function checkOwnerInactivity(uint _poolId) 
        public 
        validPoolId(_poolId) 
    {
        Pool storage pool = pools[_poolId];
        
        require(
            pool.status == sts.closed || pool.status == sts.complete,
            "Pool must be closed or complete"
        );
        
        require(
            block.timestamp > pool.lastOwnerActivity + EMERGENCY_INACTIVE_PERIOD,
            "Owner is still active"
        );
        
        pool.status = sts.stuck;
        emit poolStatusChanged(_poolId, pool.status);
    }

    function emergencyWithdrawal(uint _poolId)
        public 
        validPoolId(_poolId)
        nonReentrant
    {
        Pool storage pool = pools[_poolId];
        Investor storage investor = investorByAddress[_poolId][msg.sender];

        require(
            pool.status == sts.stuck, 
            "Pool is not in stuck state"
        );
        
        require(
            !investor.hasWithdrawn, 
            "You already withdrawn"
        );
        
        require(
            investor.payoutAmount > 0, 
            "You don't have funds to withdraw"
        );

        int payout = investor.payoutAmount;
        investor.hasWithdrawn = true;

        (bool success, ) = payable(msg.sender).call{value: uint256(payout)}("");
        require(success, "Emergency withdrawal failed");

        emit emergencyWithdrawTriggered(_poolId, EmergencyType.ownerInactive);
    }
}

contract GetterFunction is Emergency {
    function getPoolDetail(uint _poolId) 
        public 
        view 
        validPoolId(_poolId) 
        returns(Pool memory) 
    {
        return pools[_poolId];
    }

    function getPoolInvestors(uint _poolId) 
        public 
        view 
        validPoolId(_poolId) 
        returns(Investor[] memory) 
    {
        return poolInvestors[_poolId];
    }

    function getInvestorCount(uint _poolId) 
        public 
        view 
        validPoolId(_poolId) 
        returns(uint) 
    {
        return poolInvestors[_poolId].length;
    }

    function getInvestorDetail(uint _poolId, address _investor) 
        public 
        view 
        validPoolId(_poolId) 
        returns(Investor memory) 
    {
        return investorByAddress[_poolId][_investor];
    }

    function getPoolCount() public view returns(uint) {
        return poolCount;
    }

    function getInvestorDetails(uint _poolId, address _investorAddress) 
        public 
        view 
        validPoolId(_poolId) 
        returns(Investor memory) 
    {
        return investorByAddress[_poolId][_investorAddress];
    }

    function getTotalPooledAmount(uint _poolId) 
        public 
        view 
        validPoolId(_poolId) 
        returns(uint) 
    {
        return pools[_poolId].amountRaised;
    }

    function getPoolStatus(uint _poolId) 
        public 
        view 
        validPoolId(_poolId) 
        returns(sts) 
    {
        return pools[_poolId].status;
    }

    function hasDeadlinePassed(uint _poolId) 
        public 
        view 
        validPoolId(_poolId) 
        returns(bool) 
    {
        return block.timestamp > pools[_poolId].deadline;
    }

    function getInvestorPayoutAmount(uint _poolId, address _investorAddress) 
        public 
        view 
        validPoolId(_poolId) 
        returns(int) 
    {
        return investorByAddress[_poolId][_investorAddress].payoutAmount;
    }

    function getAllPools() 
        public 
        view 
        returns(Pool[] memory) 
    {
        return pools;
    }

    function getPoolProgress(uint _poolId) 
        public 
        view 
        validPoolId(_poolId) 
        returns(Pool memory, uint) 
    {
        Pool memory pool = pools[_poolId];
        uint progress = (pool.amountRaised * 100) / pool.targetAmount;
        return (pool, progress);
    }

    function isInvestor(uint _poolId, address _investorAddress) 
        public 
        view 
        validPoolId(_poolId) 
        returns(bool) 
    {
        return investorByAddress[_poolId][_investorAddress].amount > 0;
    }   

    function getRemainingAmount(uint _poolId) 
        public 
        view 
        validPoolId(_poolId) 
        returns(uint) 
    {
        Pool memory pool = pools[_poolId];
        if (pool.amountRaised >= pool.targetAmount) {
            return 0;
        }
        return pool.targetAmount - pool.amountRaised;
    }

    function getTotalProfit(uint _poolId) 
        public 
        view 
        validPoolId(_poolId) 
        returns(int) 
    {
        return pools[_poolId].totalProfit;
    }

    function getPoolFullInfo(uint _poolId) 
        public 
        view 
        validPoolId(_poolId) 
        returns(
            Pool memory,
            uint investorCount,
            uint progressPercent,
            uint timeRemaining,
            bool deadlinePassed
        ) 
    {
        Pool memory pool = pools[_poolId];
        uint investors = poolInvestors[_poolId].length;
        uint progress = (pool.amountRaised * 100) / pool.targetAmount;
        uint timeLeft = block.timestamp >= pool.deadline ? 0 : pool.deadline - block.timestamp;
        bool passed = block.timestamp > pool.deadline;
        
        return (pool, investors, progress, timeLeft, passed);
    }

    function getTimeUntilDeadline(uint _poolId) 
        public 
        view 
        validPoolId(_poolId) 
        returns(uint) 
    {
        Pool memory pool = pools[_poolId];
        if (block.timestamp >= pool.deadline) {
            return 0;
        }
        return pool.deadline - block.timestamp;
    }
}