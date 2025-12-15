// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.20;

import "./investment.sol";
import "./price.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract mainMechanism is GetterFunction, assetsPrice {
        function setSwapParameters(
        uint _poolId,
        uint _slippageTolerance,    // e.g., 200 = 2%
        uint _deadlineHours         // e.g., 24 = 24 hours from now
    )
        public
        onlyPoolOwner(_poolId)
        validPoolId(_poolId)
    {
        Pool storage pool = pools[_poolId];
        
        require(pool.status == sts.closed, "Pool must be closed first");
        require(_slippageTolerance > 0 && _slippageTolerance <= 1000, "Slippage must be 0.01% - 10%");
        require(_deadlineHours > 0 && _deadlineHours <= 168, "Deadline must be 1h - 7 days");
        
        uint deadline = block.timestamp + (_deadlineHours * 1 hours);
        
        poolSwapParams[_poolId] = SwapParams({
            slippageTolerance: _slippageTolerance,
            executionDeadline: deadline,
            maxPriceImpact: 500,  // Default 5% max impact
            isSet: true
        });
        
        pool.lastOwnerActivity = block.timestamp;
        
        emit swapParametersSet(_poolId, _slippageTolerance, deadline);
    }

    function executeStrategy(uint _poolId) 
    public 
    onlyPoolOwner(_poolId) 
    nonReentrant 
    {
        Pool storage pool = pools[_poolId];
        Strategy storage strat = pool.poolstrategy;
        
        require(pool.status == sts.closed, "Pool must be closed first");
        require(strat.tokenAddresses.length > 0, "No strategy set");
        
        // Loop through each asset and swap ETH → tokens
        for (uint i = 0; i < strat.tokenAddresses.length; i++) {
            uint ethAmount = strat.assetsAmount[i];
            address tokenAddress = strat.tokenAddresses[i];
            
            // Swap ETH for tokens via Uniswap
            _swapETHForToken(ethAmount, tokenAddress);
        }
        
        // Update pool status
        pool.status = sts.investing;  // New status: "actively invested"
        pool.lastOwnerActivity = block.timestamp;
        
        emit strategyExecuted(_poolId);
    }
}