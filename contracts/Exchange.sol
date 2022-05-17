//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    IERC20 public immutable token;
    uint8 public constant FEE = 1; //1%

    constructor(address _token) ERC20("mySwap", "LPT") {
        require(_token != address(0), "Exchange: token address can't be zero");
        token = IERC20(_token);
    }

    function addLiquidity(uint _tokenAmount) external payable {
        uint tokenReserve = getReserve();
        uint ethReserve = address(this).balance - msg.value;
        uint realTokenAmount = _tokenAmount;
        uint lpTokens = msg.value;

        if (tokenReserve != 0) {
            realTokenAmount = msg.value * tokenReserve / ethReserve;
            require(_tokenAmount >= realTokenAmount, "Exchange: insufficient token amount");
            lpTokens = totalSupply() * msg.value / ethReserve;
        }
        _mint(msg.sender, lpTokens);
        token.transferFrom(msg.sender, address(this), realTokenAmount);
    }

    function removeLiquidity(uint lpTokensAmount) external {
        lpTokensAmount = lpTokensAmount == 0 ? balanceOf(msg.sender) : lpTokensAmount;
        require(lpTokensAmount > 0, "Exchange: invalid amount");
        uint ethAmount = (lpTokensAmount * address(this).balance) / totalSupply();
        uint tokenAmount = (lpTokensAmount * getReserve()) / totalSupply();

        _burn(msg.sender, lpTokensAmount);
        token.transfer(msg.sender, tokenAmount);
        payable(msg.sender).transfer(ethAmount);
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
        uint inputAmountWithFee = inputAmount * 99;
        uint numerator = outputReserve * inputAmountWithFee;
        uint denominator = inputReserve * 100 + inputAmountWithFee;
        return numerator / denominator;
    }

    /*
     * @dev return amount of token for ethSold.
     *
     * @param {ethSold} - amount of ETH that we want to swap to tokens
     *
     * NOTE:
     * please check getAmount function.
     */
    function getTokenAmount(uint ethSold) external view returns(uint) {
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
    function getEthAmount(uint tokenSold) external view returns(uint) {
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
    function tokenToEthSwap(uint tokenSold, uint minEth) external {
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
