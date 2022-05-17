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
     * @dev return amount of outputReserve for inputReserve.
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
    function getAmount(uint inputAmount, uint inputReserve, uint outputReserve)
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
     * please check getAmount function.
     */
    function getTokenAmount(uint ethSold) public view returns(uint) {
        require(ethSold >0, "Exchange: ethSold too little");
        return getAmount(ethSold, address(this).balance, getReserve());
    }

    /*
     * @dev return amount of ETH for tokenSold.
     *
     * @param {tokenSold} - amount of tokens that we want to swap to ETH
     *
     * NOTE:
     * please check getAmount function.
     */
    function getEthAmount(uint tokenSold) public view returns(uint) {
        require(tokenSold >0, "Exchange: tokenSold too little");
        return getAmount(tokenSold, getReserve(), address(this).balance);
    }
 
    /*
     * @dev swap amount of tokens that greater than or equal to minTokens to the msg.value.
     *
     * @param {minTokens} - amount of token (greater than or equal) that we want to get.
     */
    function ethToTokenSwap(uint minTokens) external payable {
        uint tokenBought = getAmount(
            msg.value,
            address(this).balance - msg.value,
            getReserve()
        );

        require(tokenBought >= minTokens, "Exchange: not enough ETH");
        token.transfer(msg.sender, tokenBought);
    }


    /*
     * @dev swap amount of ETH that greater than or equal to minEth to the tokenSold value.
     *
     * @param {tokenSold} - amount of token that we want to swap on the ETH.
     * @param {minEth} - amount of ETH (greater than or equal) that we want to get.
     */
    function tokenToEthSwap(uint tokenSold, uint minEth) external payable {
        uint ethBought = getAmount(
            tokenSold,
            getReserve(),
            address(this).balance
        );

        require(ethBought >= minEth, "Exchange: not enough ETH");
        token.transferFrom(msg.sender, address(this), tokenSold);
        payable(msg.sender).transfer(ethBought);
    }
}
