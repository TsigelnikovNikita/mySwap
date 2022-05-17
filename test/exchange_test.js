const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

const toWei = (value) => ethers.utils.parseEther(value.toString());

const fromWei = (value) =>
  ethers.utils.formatEther(
    typeof value === "string" ? value : value.toString()
  );

describe("Exchange", () => {
  let exchangeOwner;
  let client;
  let marketMaker;
  let token;
  let exchange;

  beforeEach(async () => {
    [exchangeOwner, client, marketMaker] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("TestToken");
    token = await Token.deploy("TestToken", "TestToken");
    await token.deployed();

    token.connect(marketMaker).mint(toWei(4000));
    token.connect(client).mint(toWei(4000));

    const Exchange = await ethers.getContractFactory("Exchange");
    exchange = await Exchange.connect(exchangeOwner).deploy(token.address);
    await exchange.deployed();
  });

  it("addLiquidity", async () => {
    await token.connect(marketMaker).approve(exchange.address, toWei(2000));
    await exchange.connect(marketMaker).addLiquidity(toWei(2000), { value: toWei(1000) });

    expect(await ethers.provider.getBalance(exchange.address)).to.equal(toWei(1000));
    expect(await exchange.getReserve()).to.equal(toWei(2000));
  });

  describe("getAmount", () => {
    beforeEach(async () => {
      await token.connect(marketMaker).approve(exchange.address, toWei(2000));
      await exchange.connect(marketMaker).addLiquidity(toWei(2000), { value: toWei(1000) });
    });

    it("getTokenAmount", async () => {
      let tokensOut = await exchange.getTokenAmount(toWei(1));
      expect(fromWei(tokensOut)).to.equal("1.978041738678708079");

      tokensOut = await exchange.getTokenAmount(toWei(100));
      expect(fromWei(tokensOut)).to.equal("180.1637852593266606");

      tokensOut = await exchange.getTokenAmount(toWei(1000));
      expect(fromWei(tokensOut)).to.equal("994.974874371859296482");
    });

    it("getEthAmount", async () => {
      let etherOut = await exchange.getEthAmount(toWei(2));
      expect(fromWei(etherOut)).to.equal("0.989020869339354039");

      etherOut = await exchange.getEthAmount(toWei(200));
      expect(fromWei(etherOut)).to.equal("90.0818926296633303");

      etherOut = await exchange.getEthAmount(toWei(2000));
      expect(fromWei(etherOut)).to.equal("497.487437185929648241");
    });
  });

  describe("Swap", () => {
    beforeEach(async () => {
      await token.connect(marketMaker).approve(exchange.address, toWei(2000));
      await exchange.connect(marketMaker).addLiquidity(toWei(2000), { value: toWei(1000) });
    });

    it("ethToTokenSwap", async () => {
      const tokensOut = await exchange.getTokenAmount(toWei(500));
      
      const tx = await exchange.connect(client).ethToTokenSwap(tokensOut, {value: toWei(500)});

      await expect(() => tx)
        .to.changeEtherBalances([exchange, client], [toWei(500), BigNumber.from(0).sub(toWei(500))]);
    });

    it("tokenToEthSwap", async () => {
      const ethersOut = await exchange.getEthAmount(toWei(1000));
      
      await token.connect(client).approve(exchange.address, toWei(1000));
      const tx = await exchange.connect(client).tokenToEthSwap(toWei(1000), ethersOut);

      await expect(() => tx)
        .to.changeEtherBalances([exchange, client], [BigNumber.from(0).sub(ethersOut), ethersOut]);
    });
  });

  it("removeLiqudity", async () => {
    await token.connect(marketMaker).approve(exchange.address, toWei(200));
    await exchange.connect(marketMaker).addLiquidity(toWei(200), { value: toWei(100) });

    await exchange.connect(client).ethToTokenSwap(toWei(18), {value: toWei(10)});

    const tx = await exchange.connect(marketMaker).removeLiquidity(toWei(100));

    await expect(() => tx)
      .to.changeEtherBalances([exchange, marketMaker], [toWei(-110), toWei(110)]);
  });
});
