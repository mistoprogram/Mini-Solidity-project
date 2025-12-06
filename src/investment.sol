// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.20;

contract InvestmentPool {
    
    //==================== EVENTS ====================
    event poolCreated(uint indexed id, address indexed owner, uint targetAmount, uint deadline);
    event investmentMade(uint indexed poolId, address indexed investor, uint amount, uint ownershipPercent);
    event poolStatusChanged(uint indexed poolId, string newStatus);
    event withdrawalMade(uint indexed poolId, address indexed investor, uint amount);

    //==================== STRUCTS ====================
    struct Investor {
        address investorAddress;
        uint amount;
        uint timestamp;
        uint ownershipPercent;
        bool hasWithdrawn;
        uint payoutAmount;
    }

    struct Pool {
        uint id;
        address owner;
        uint targetAmount;
        uint amountRaised;
        uint deadline;
        string status;
        uint totalReturnReceived;
        int totalProfit;
        uint payoutAmount;
    }

    //==================== STATE VARIABLES ====================
    Pool[] private pools;
    mapping(uint => Investor[]) private poolInvestors;
    mapping(uint => mapping(address => Investor)) private investorByAddress;
    mapping(uint => bool) private poolExists;

    uint public poolCount = 0;
    address public contractOwner;
    
    bool private locked; // Reentrancy guard

    //==================== MODIFIERS ====================
    modifier onlyPoolOwner(uint _poolId) {
        require(poolExists[_poolId], "Pool does not exist");
        require(pools[_poolId].owner == msg.sender, "Only pool owner can call this");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier validPoolId(uint _poolId) {
        require(_poolId < poolCount, "Invalid pool ID");
        require(poolExists[_poolId], "Pool does not exist");
        _;
    }

    modifier validAmount(uint _amount) {
        require(_amount > 0, "Amount must be greater than 0");
        require(msg.value == _amount, "Sent amount doesn't match specified amount");
        _;
    }

    //==================== CONSTRUCTOR ====================
    constructor() {
        contractOwner = msg.sender;
        locked = false;
    }

    //make contract able to receive payment
    receive() external payable {}
    fallback() external payable {}

    //Pool section
    function createPool(uint _targetAmount, uint _deadline) public returns(uint) {
        require(_targetAmount > 0, "Target amount must be greater than 0");
        require(_deadline > 0, "Deadline must be in the future");

        uint poolId = poolCount;
        uint deadlineTime = block.timestamp + (_deadline * 86400);

        Pool memory newPool = Pool({
            id: poolId,
            owner: msg.sender,
            targetAmount: _targetAmount,
            amountRaised: 0,
            deadline: deadlineTime,
            status: "open",
            totalReturnReceived: 0,
            totalProfit: 0,
            payoutAmount:0
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
            keccak256(abi.encodePacked(pool.status)) == keccak256(abi.encodePacked("open")),
            "Pool is not open for investment"
        );
        require(block.timestamp <= pool.deadline, "Investment deadline has passed");
        require(_amount <= pool.targetAmount - pool.amountRaised, "Investment exceeds pool target");

        // Update pool
        pool.amountRaised += _amount;

        // Calculate ownership percentage (in basis points: 1% = 100)
        uint ownershipBps = (_amount * 10000) / pool.amountRaised;

        // Create investor record
        Investor memory newInvestor = Investor({
            investorAddress: msg.sender,
            amount: _amount,
            timestamp: block.timestamp,
            ownershipPercent: ownershipBps,
            hasWithdrawn: false,
            payoutAmount:0
        });

        // Store investor
        poolInvestors[_poolId].push(newInvestor);
        investorByAddress[_poolId][msg.sender] = newInvestor;

        emit investmentMade(_poolId, msg.sender, _amount, ownershipBps);

        // Auto-close pool if target reached
        if (pool.amountRaised >= pool.targetAmount) {
            pool.status = "closed";
            emit poolStatusChanged(_poolId, "closed");
        }
    }

    //==================== GETTER FUNCTIONS ====================
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
            keccak256(abi.encodePacked(pool.status)) == keccak256(abi.encodePacked("open")),
            "Pool is already closed"
        );
        
        pool.status = "closed";
        emit poolStatusChanged(_poolId, "closed");
    }
}