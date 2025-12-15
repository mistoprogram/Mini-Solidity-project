// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract assetsPrice{
    AggregatorV3Interface internal BTC;
    AggregatorV3Interface internal ETH;
    AggregatorV3Interface internal DAI;
    AggregatorV3Interface internal LINK;
    AggregatorV3Interface internal USDC;

    struct Prices {
        int btc;
        int eth;
        int dai;
        int link;
        int usdc;
        //addresses
        address btcAddress;       
        address ethAddress;       
        address daiAddress;       
        address linkAddress;       
        address usdcAddress;       
    }

     mapping(address => AggregatorV3Interface) public priceFeeds;

    constructor() {
        BTC = AggregatorV3Interface(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43);
        ETH = AggregatorV3Interface(0xaaabb530434B0EeAAc9A42E25dbC6A22D7bE218E);
        DAI = AggregatorV3Interface(0x14866185B1962B63C3Ea9E03Bc1da838bab34C19);
        LINK = AggregatorV3Interface(0xc59E3633BAAC79493d908e63626716e204A45EdF);
        USDC = AggregatorV3Interface(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E);

        priceFeeds[0x2260fac5e5542a773aa44fbcfedf7c193bc2c599] = BTC;
        priceFeeds[0x7f39c581f595b53c5cb19bd0b3f8da6c935e2ca0] = ETH;
        priceFeeds[0x6b175474e89094c44da98b954eedeac495271d0f] = DAI;
        priceFeeds[0x514910771AF9Ca656af840dff83E8264EcF986CA] = LINK;
        priceFeeds[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = USDC;
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
    returns(Prices memory p)
    {
        p.btc = int256(_decimalPrice(BTC));
        p.eth = int256(_decimalPrice(ETH));
        p.dai = int256(_decimalPrice(DAI));
        p.link = int256(_decimalPrice(LINK));
        p.usdc = int256(_decimalPrice(USDC));
        
        // Set addresses if needed
        p.btcAddress = address(BTC);
        p.ethAddress = address(ETH);
    }

    function getPrice(address _tokenAddress) public returns(uint) {
    AggregatorV3Interface feed = priceFeeds[_tokenAddress];
    require(address(feed) != address(0), "Price feed not found");
    return _decimalPrice(feed);
}
}