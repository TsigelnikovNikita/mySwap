const { expect } = require("chai");
const { ethers } = require("hardhat");

const toWei = (value) => ethers.utils.parseEther(value.toString());

const fromWei = (value) =>
  ethers.utils.formatEther(
    typeof value === "string" ? value : value.toString()
  );

describe("Exchange", () => {
  let token;
  let exchange;

  beforeEach(async () => {
    const Token = await ethers.getContractFactory("TestToken");
    token = await Token.deploy("TestToken", "TTN", toWei(2000));
    await token.deployed();

    const Exchange = await ethers.getContractFactory("Exchange");
    exchange = await Exchange.deploy(token.address);
    await exchange.deployed();

  });

  it("addLiquidity", async () => {
    await token.approve(exchange.address, toWei(2000));
    await exchange.addLiquidity(toWei(2000), { value: toWei(1000) });

    expect(await ethers.provider.getBalance(exchange.address)).to.equal(toWei(1000));
    expect(await exchange.getReserve()).to.equal(toWei(2000));
  });

  describe("getAmount", () => {
    beforeEach(async () => {
      await token.approve(exchange.address, toWei(2000));
      await exchange.addLiquidity(toWei(2000), { value: toWei(1000) });
    });

    it("getTokenAmount", async () => {
      let tokensOut = await exchange.getTokenAmount(toWei(1));
      expect(fromWei(tokensOut)).to.equal("1.998001998001998001");
      
      tokensOut = await exchange.getTokenAmount(toWei(100));
      expect(fromWei(tokensOut)).to.equal("181.818181818181818181");
      
      tokensOut = await exchange.getTokenAmount(toWei(1000));
      expect(fromWei(tokensOut)).to.equal("1000.0");
    });

    it("getEthAmount", async () => {
      let etherOut = await exchange.getEthAmount(toWei(2));
      expect(fromWei(etherOut)).to.equal("0.999000999000999");

      etherOut = await exchange.getEthAmount(toWei(200));
      expect(fromWei(etherOut)).to.equal("90.90909090909090909");

      etherOut = await exchange.getEthAmount(toWei(2000));
      expect(fromWei(etherOut)).to.equal("500.0");
    });
  });

});
