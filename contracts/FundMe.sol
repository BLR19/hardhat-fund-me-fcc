//SPDX-License-Identifier: MIT

//Best practices
    //pragma
    //Imports
    //Error codes
    //Interfaces, Libaries
    //Contracts
        //Type declarations
        //State variable
        //Events
        //Modifiers
        //functions
            //Constructor
            //Receive
            //Fallback
            //External
            //public
            //internal
            //private
            //view/pure

pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error FundMe__NotOwner(); //déclarer l'erreur possible en dehors du contrat

/** @title A contract for crowd funding
 *   @author Benjamin Lecomte
 *   @notice This contract is to demo a sample funding contract
 *   @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConverter for uint256; //a approfondir

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] private s_funders;
    mapping(address => uint256) public s_addressToAmountFunded; //address est la variable dont on va demander l'équivalent

    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    //modifie toutes les fonctions qui auront cette propriété
    modifier onlyOwner() {
        /*require(msg.sender == i_owner, "Sender is not i_owner!");*/
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; //correspond au reste du code de la fonction qui possède cette propriété
    }

    constructor(address s_priceFeedAddress) {
        //fonction appelée dès le déploiement du contrat
        i_owner = msg.sender; //dans ce cas msg.sender = celui qui déploie le contrat
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        //require(msg.value >= 1e18, "Didn't send enough!"); //recquiert un envoi de+ de 1e18 Wei (1ETH)
        //require(getConversionRate(msg.value) >= minimumUSD, "Didn't send enough!");
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
        //Ajout dans l'array de la liste des donateurs et ajout au mapping de leur équivalent en ETH
    }

    function withdraw() public onlyOwner {
        /*starting index, ending index, step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex = funderIndex + 1
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0); //Identifier s_funders correspond maintenant à un nouvel array "address[]" de 0 éléments

        /*
        //Méthode transfer --- payable(msg.sender) = adresse payable --- revert if failed
        payable(msg.sender).transfer(address(this).balance); //(this) = ce contrat

        //Méthode send --- renvoie un bouléen false mais envoi retire les fonds
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");
        */

        //Méthode call --- permet d'appeler des fonctions. Ici pas de fonction ("")
        //retourne 2 variables (donc à déclarer avant) mais dataReturned ne sert pas dans ce cas
        (
            bool callSuccess, /*bytes memory dataReturned*/

        ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
        //meilleure méthode à ce jour (pas de gas limit)
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders; //On écrit l'array s_funders dans memory pour le lire sans dépenser trop de gas
        //mappings can't be in memory
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex = funderIndex + 1
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool success, /*bytes memory dataReturned*/) = i_owner.call{value: address(this).balance}(""); //i_owner remplace payable(msg.sender)
        require(success, "Call failed");
    }

    function getOwner() public view returns(address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns(address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) public view returns(uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
