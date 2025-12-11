// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.20;

import "./src/investment.sol";
import "./src/price.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract mainMechanism is GetterFunction, getPrice{
    function accessToken(uint _poolId, address _tokenAddress)
    internal
    onlyPoolOwner
    validPoolId(_poolId)
    {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, address(this), _amount);
    }
}