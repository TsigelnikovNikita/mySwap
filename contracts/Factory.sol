//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Exchange.sol";

contract Factory {
    mapping (address => Exchange) tokenToExchange;

    function createExchange(address token) external {
        require(token != address(0), "Factory: address of token cannot be zero");
        require(address(tokenToExchange[token]) == address(0), "Factory: exchange is already exists");
        tokenToExchange[token] = new Exchange(token);
    }

    function getExchange(address token) external view returns(Exchange) {
        return tokenToExchange[token];
    }
}