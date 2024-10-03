const { loadFixture, time } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("OrderSwapContract", function() {
  async function deployOrderBasedSwapFixture() {
    const [owner, signer1, signer2, signer3] = await ethers.getSigners();

    // Pass the contract name
    const OrderBasedSwap = await ethers.getContractFactory("OrderSwapContract");

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const tokenA = await MockERC20.deploy();

    const MockERC21 = await ethers.getContractFactory("MockERC21");
    const tokenB = await MockERC21.deploy();

    // Deploy the contract passing the NFT contract address
    const orderBasedSwap = await OrderBasedSwap.deploy(owner);

    return { orderBasedSwap, tokenA, tokenB, owner, signer1, signer2, signer3 };
  }

  describe("Create Order and Deposit", function() {
    it("Should revert if zero address detected", async function() {
      const { orderBasedSwap, tokenA,tokenB, owner } = await loadFixture(deployOrderBasedSwapFixture);

      const zeroAddressSigner = await ethers.getImpersonatedSigner(ethers.ZeroAddress);

      await owner.sendTransaction({
        to: ethers.ZeroAddress,
        value: ethers.parseEther("1.0") // Send 1 ETH
      });

      const amountForSale = ethers.parseEther("1001");
      const amountWanted = ethers.parseUnits("100");

      await expect(orderBasedSwap.connect(zeroAddressSigner).createOrderAndDeposit(
        tokenA,
        amountForSale,
        tokenB,
        amountWanted
      )).to.be.revertedWith("Address zero detected");
    });

    it("Should revert if tokenForSale is equal to tokenWanted", async function() {
      const { orderBasedSwap, signer1, tokenA } = await loadFixture(deployOrderBasedSwapFixture);

      const amountForSale = ethers.parseEther("1001");
      const amountWanted = ethers.parseUnits("100");

      await expect(orderBasedSwap.connect(signer1).createOrderAndDeposit(
        tokenA,
        amountForSale,
        tokenA,
        amountWanted
      )).to.be.revertedWith("Cannot swap a token for itself");
    });

    it("Should revert if tokenForSale and tokenWanted equal zero address", async function() {
      const { orderBasedSwap, owner } = await loadFixture(deployOrderBasedSwapFixture);

      const zeroAddressSigner = await ethers.getImpersonatedSigner(ethers.ZeroAddress);

      await owner.sendTransaction({
        to: ethers.ZeroAddress,
        value: ethers.parseEther("1.0") // Send 1 ETH
      });

      const amountForSale = ethers.parseEther("1001");
      const amountWanted = ethers.parseUnits("100");

      await expect(orderBasedSwap.connect(zeroAddressSigner).createOrderAndDeposit(
        ethers.ZeroAddress,
        amountForSale,
        ethers.ZeroAddress,
        amountWanted
      )).to.be.revertedWith("Address zero detected");
    });

    it("Should revert if amountForSale and amountWanted", async function() {
      const { orderBasedSwap, signer1, tokenA, tokenB } = await loadFixture(deployOrderBasedSwapFixture);

      const amountForSale = ethers.parseEther("0");
      const amountWanted = ethers.parseUnits("0");

      await expect(orderBasedSwap.connect(signer1).createOrderAndDeposit(
        tokenA,
        amountForSale,
        tokenB,
        amountWanted
      )).to.be.revertedWith("Amounts must be greater than zero");
    });

    it("Should revert if  seller has sufficient balance of tokenForSale", async function() {
      const { orderBasedSwap, signer1, tokenA, tokenB } = await loadFixture(deployOrderBasedSwapFixture);

      await tokenA.transfer(signer1, ethers.parseUnits("10", 18))

      const amountForSale = ethers.parseEther("100");
      const amountWanted = ethers.parseUnits("100");

      await expect(orderBasedSwap.connect(signer1).createOrderAndDeposit(
        tokenA,
        amountForSale,
        tokenB,
        amountWanted
      )).to.be.revertedWith("Insufficient balance of token for sale")
    });

    it("Should revert create order and deposit", async function() {
      const { orderBasedSwap, signer1, tokenA, tokenB } = await loadFixture(deployOrderBasedSwapFixture);

      await tokenA.transfer(signer1, ethers.parseUnits("1000", 18))

      const amountForSale = ethers.parseEther("100");
      const amountWanted = ethers.parseUnits("100");

      await tokenA.connect(signer1).approve(orderBasedSwap, amountForSale);

      await expect(orderBasedSwap.connect(signer1).createOrderAndDeposit(
        tokenA,
        amountForSale,
        tokenB,
        amountWanted
      )).to.emit(orderBasedSwap, "OrderCreated")
      .withArgs(1, signer1, tokenA, amountForSale, tokenB, amountWanted);

    });
  });
});