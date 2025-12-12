// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.20;

import "./src/investment.sol";
import "./src/price.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract mainMechanism is GetterFunction, getPrice{
    function accessToken(uint _poolId, address[] memory _tokenAddresses)
    internal
    onlyPoolOwner
    validPoolId(_poolId)
    {
        Pool storage pool = pools[_poolId];
        Strategy strat = pool.poolstrategy;

        uint amount = strat.assetAmount;

        for(uint i = 0; i < amount.length; i++) {
            amount[i] = amount[i];
        }

        IERC20[] memory token = IERC20[](_tokenAddresses.length);
        token.transfer(msg.sender, address(this)[i], _amount);
    }
}