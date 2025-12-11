// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract getPrice{
    AggregatorV3Interface internal BTC;
    AggregatorV3Interface internal ETH;
    AggregatorV3Interface internal GLD;
    AggregatorV3Interface internal LINK;
    AggregatorV3Interface internal USDC;

    struct Prices {
        int btc;
        int eth;
        int gld;
        int link;
        int usdc;
    }

    int public BTCPrice;

    constructor() {
        BTC = AggregatorV3Interface(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43);
        ETH = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        GLD = AggregatorV3Interface(0xC5981F461d74c46eB4b0CF3f4Ec79f025573B0Ea);
        LINK = AggregatorV3Interface(0xc59E3633BAAC79493d908e63626716e204A45EdF);
        USDC = AggregatorV3Interface(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E);
    }

    function _decimalPrice(AggregatorV3Interface feed)
    internal
    returns(uint)
    {
        (, int256 answer,,,) = feed.latestRoundData();
        uint8 feedDecimals = feed.decimals();

        // assume answer is positive; add checks if needed
        if (feedDecimals < 18) {
            return uint256(answer) * (10 ** (18 - feedDecimals));
        } else if (feedDecimals > 18) {
            return uint256(answer) / (10 ** (feedDecimals - 18));
        } else {
            return uint256(answer);
        }
    }

    function getAllPrices()
    public
    view
    returns(Prices memory p)
    {
        (, p.btc,,,)  = _decimalPrice(BTC);
        (, p.eth,,,)  = _decimalPrice(ETH);
        (, p.gld,,,)  = _decimalPrice(GLD);
        (, p.link,,,) = _decimalPrice(LINK);
        (, p.usdc,,,) = _decimalPrice(USDC);
    }
}