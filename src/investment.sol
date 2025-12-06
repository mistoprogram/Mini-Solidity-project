// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.20;

contract investmentPool {

    //events
    event poolCreated(uint id, address owner, uint targetAmount,uint deadline);
    event investmentMade(uint poolId, address investor, uint amount, uint ownershipPercent);

    //structure stuff

    struct investor{
        address InvestorAddress;
        uint amount;
        uint timeStamp;
        uint percent;
        bool withdraw;
    }

      struct pool{
        uint id;
        address owner;
        uint target;
        uint amountRaised;
        uint deadline;
        string poolStatus;
        uint totalReturnReceived;
        uint totalProfit;
    }
    //allow contract to receive payments
    receive() external payable{}
    fallback() external payable{}

    //global var
    // enum status{open, closed, completed}
    investor[] investors;
    mapping(address => investor) investorByAddress;
    mapping(uint => pool) poolById;
    mapping(uint => investor[]) investorByPoolId;

    uint public poolCount = 0;

    //system functions

    function createPool(uint _targetAmount, uint _deadline) public returns(uint) {
        //get the pool id going by adding it from the previous state variable
        uint poolId = poolCount;
        poolCount = poolCount + 1;
        //convert block time into days
        uint deadlineTime = block.timestamp + (_deadline * 86400);
        //ADD new pool
        pool memory newPool = pool({
            id : poolId,
            owner : msg.sender,
            target: _targetAmount,
            amountRaised: 0,
            poolStatus : "open",
            totalReturnReceived: 0,
            totalProfit: 0,
            deadline: deadlineTime
        });

        poolById[poolId] = newPool;

        emit poolCreated(poolId, msg.sender, _targetAmount, _deadline);

        return poolId;
    }

    function investIn(uint _poolId, uint _amount) public payable {
        pool memory selectPool = poolById[_poolId];
        require(keccak256(abi.encodePacked(selectPool.poolStatus)) == keccak256(abi.encodePacked("open")), "pool isn't open for investment");
        require(block.timestamp <= selectPool.deadline);
        require(_amount > 0, "investment amount must be greater than 0");
        require(msg.value >= _amount, "amount sent");

        selectPool.amountRaised += _amount;
        poolById[_poolId] = selectPool;

        uint ownershipBps = (_amount * 10_000) / selectPool.amountRaised;
        investor memory newInvestor = investor({
            InvestorAddress : msg.sender,
            amount : _amount,
            timeStamp : block.timestamp,
            percent : ownershipBps,
            withdraw : false
        });

        investors.push(newInvestor);
        investorByAddress[msg.sender] = newInvestor;
        investorByPoolId[_poolId].puhs(newInvestor);

        emit investmentMade(_poolId, msg.sender, _amount, ownershipBps);
    }

    function getPoolDetail(uint _poolId) public view returns(pool memory) {
        return poolById[_poolId];
    }

    function getInvestors(uint _poolId) public view returns(investor[]) {
        return investorByPoolId[_poolId];
    }

    function investorCount(uint _poolId) public view returns(uint) {
        return investorByPoolId[_poolId].length;
    }
}