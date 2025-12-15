// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.20;

import "./investment.sol";
import "./price.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract mainMechanism is GetterFunction, assetsPrice {
    // SCALE is defined in GlobalVar as 1e18

    /// @notice Transfers strategy tokens (held by this contract) to the pool owner.
    /// @dev For each asset: compute tokenAmount = (assetWeiAllocated * SCALE) / tokenPrice
    ///      where tokenPrice is returned by getPrice(tokenAddress) and scaled by SCALE (1e18).
    ///      This yields token units scaled consistently with price feed = 1e18.
    /// @param _poolId Id of the pool whose strategy tokens to transfer.
    /// @param _tokenAddresses ERC20 token addresses corresponding to strategy assets (order must match strategy.assetsAmount)
    function accessToken(uint _poolId, address[] memory _tokenAddresses)
        internal
        onlyPoolOwner(_poolId)
        validPoolId(_poolId)
    {
        Pool storage pool = pools[_poolId];
        Strategy storage strat = pool.poolstrategy;

        uint len = strat.assetsAmount.length;
        require(len > 0, "No strategy asset amounts defined");
        require(_tokenAddresses.length == len, "Token addresses length must match strategy assets");

        // Transfer each token amount to the pool owner (msg.sender is validated by onlyPoolOwner).
        for (uint i = 0; i < len; i++) {
            uint assetWei = strat.assetsAmount[i];
            if (assetWei == 0) {
                continue; // nothing allocated
            }

            // getPrice should return token price scaled by SCALE (1e18)
            uint tokenPrice = _decimalPrice(_tokenAddresses[i]);
            require(tokenPrice > 0, "Invalid token price");

    
            // Therefore tokens = (assetWei / price) with proper SCALE adjustment:
            uint tokensToSend = (assetWei * SCALE) / tokenPrice;

            IERC20 token = IERC20(_tokenAddresses[i]);

            // Ensure contract has the tokens (or this transfer will fail)
            uint contractBal = token.balanceOf(address(this));
            require(contractBal >= tokensToSend, "Contract doesn't hold enough tokens");

            bool ok = token.transfer(msg.sender, tokensToSend);
            require(ok, "Token transfer failed");
        }

        // Update owner activity timestamp
        pool.lastOwnerActivity = block.timestamp;
    }
}