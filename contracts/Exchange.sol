//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Exchange {
    IERC20 public immutable token;

    constructor(address _token) {
        require(_token != address(0), "Exchange: token address can't be zero");
        token = IERC20(_token);
    }

    function addLiquidity(uint256 _tokenAmount) external payable {
        token.transferFrom(msg.sender, address(this), _tokenAmount);
    }

    function getReserve() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    /*
     * @dev return price of outputReserve for inputReserve.
     *
     * @param {inputAmount} - amount of ethers (or tokens) that we want to get
     * @param {inputReserve} - total amount of ethers (or tokens) that we have in the contract
     * @param {outputReserve} - total amount of ethers (or tokens) that we have in the contract
     *
     * For example if we want to swap (buy) ETH to tokens, then:
     *      {inputAmount} should be amount of ETH that we want to swap,
     *      {inputReserve} should be total amount of ETH in the contract,
     *      {outputReserver} should be total amount of tokens in the contract
     * and vice versa.
     */
    function getPrice(uint inputAmount, uint inputReserve, uint outputReserve)
        private
        pure
        returns (uint)
    {
        require(inputReserve > 0 && outputReserve > 0,
                                            "Exchange: invalid reserves");
        return (outputReserve * inputAmount) / (inputReserve + inputAmount);
    }

    /*
     * @dev return amount of token for ethSold.
     *
     * @param {ethSold} - amount of ETH that we want to swap to tokens
     *
     * NOTE:
     * please check getPrice function.
     */
    function getTokenAmount(uint ethSold) public view returns(uint) {
        require(ethSold >0, "Exchange: ethSold too little");
        return getPrice(ethSold, address(this).balance, getReserve());
    }

    /*
     * @dev return amount of ETH for tokenSold.
     *
     * @param {tokenSold} - amount of tokens that we want to swap to ETH
     *
     * NOTE:
     * please check getPrice function.
     */
    function getEthAmount(uint tokenSold) public view returns(uint) {
        require(tokenSold >0, "Exchange: tokenSold too little");
        return getPrice(tokenSold, getReserve(), address(this).balance);
    }
}
