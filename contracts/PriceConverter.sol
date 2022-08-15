//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; //Importe le contrat à l'adresse GitHub

library PriceConverter {
//Toutes les fonctions doivent êtres internes
//Une librairie ne peut pas envoyer d'ETH, uniquement faire des view

    function getPrice (AggregatorV3Interface priceFeed) internal view returns(uint256) {

        /*AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); 
        //variable priceFeed dans Aggregator, et trouver le contrat à tel adresse */
        
        (,int256 price,,,) = priceFeed.latestRoundData(); //La fonction renvoi plusieurs data (d'où les virgules)
        return uint256(price * 1e10); //Même nombre de décimal nécessaire par rapport à msg.value qui est en Wei
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18; //Division pour avoir un résultat lisible
        return ethAmountInUsd;
    }

}