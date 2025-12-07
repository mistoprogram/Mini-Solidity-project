// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.20;

contract InvestmentPool {
    
    //==================== EVENTS ====================
    event poolCreated(uint indexed id, address indexed owner, uint targetAmount, uint deadline);
    event investmentMade(uint indexed poolId, address indexed investor, uint amount, uint ownershipPercent);
    event poolStatusChanged(uint indexed poolId, string newStatus);
    event withdrawalMade(uint indexed poolId, address indexed investor, uint amount);
    event returnDistributed(uint indexed poolId, int totalProfit);
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
    // Investor[] investors;
    mapping(uint => Investor[]) private poolInvestors;
    mapping(uint => mapping(address => Investor)) private investorByAddress;
    mapping(uint => bool) private poolExists;

    uint public poolCount = 0;
    address public contractOwner;
    
    bool private locked; // Reentrancy guard

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

    function receiveReturn(uint _poolId, uint _returnAmount)
    public payable
    onlyPoolOwner(_poolId)
    validPoolId(_poolId)
    {
        Pool storage investmentPool = pools[_poolId];

        require(
        keccak256(abi.encodePacked(investmentPool.status)) == keccak256(abi.encodePacked("closed")), 
        "Pool must be closed first"
        );
        require(_returnAmount > 0, "Return amount must be greater than 0");
        require(msg.value == _returnAmount, "Sent amount doesn't match return amount");

        investmentPool.totalReturnReceived = _returnAmount;
        uint originalInvestment = investmentPool.amountRaised;
        uint256 returnUint = _returnAmount;
        uint256 investmentUint = originalInvestment;

        if (_returnAmount > originalInvestment) {
            investmentPool.totalProfit = int256(returnUint - investmentUint);;
        } else {
            investmentPool.totalProfit = int256(_returnAmount - originalInvestment);
        }

        _distributeR(_poolId);
        investmentPool.status = "completed";
        emit poolStatusChanged(_poolId, "completed");
    }

    function _distributeR(uint _poolId) 
    private
    returns(uint)
    {
        Pool storage pool = pools[_poolId];
        Investor[] storage investors = poolInvestors[_poolId];  // Use storage to modify
    
        int tProfit = pool.totalProfit;
    
        // Loop through each investor
        for(uint i = 0; i < investors.length; i++) {
            uint profitShare = (uint(tProfit) * investors[i].ownershipPercent) / 10000;
            uint totalPayout = investors[i].amount + profitShare;
            
            // Update the investor's payout amount
            investors[i].payoutAmount = totalPayout;
        }
        emit returnDistributed(_poolId,tProfit);
        return tProfit
    }
}