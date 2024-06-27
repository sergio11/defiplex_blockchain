const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PlexTokenERC20Contract", function () {
  let FlexToken;
  let flexToken;
  let owner;
  let addr1;
  let addr2;
  let addr3;
  let addrs;

  beforeEach(async function () {
    FlexToken = await ethers.getContractFactory("PlexTokenERC20Contract");
    [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    flexToken = await FlexToken.deploy(owner.address);
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await flexToken.owner()).to.equal(owner.address);
    });

    it("Should assign the initial supply to the owner", async function () {
      const ownerBalance = await flexToken.balanceOf(owner.address);
      expect(await flexToken.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe("Minting", function () {
    it("Should allow the owner to mint tokens", async function () {
      await flexToken.mint(addr1.address, 500);
      const addr1Balance = await flexToken.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(500);
    });

    it("Should not allow non-owners to mint tokens", async function () {
      await expect(flexToken.connect(addr1).mint(addr1.address, 500)).to.be.reverted;
    });
  });

  describe("Burning", function () {
    it("Should allow users to burn their tokens", async function () {
      await flexToken.connect(owner).transfer(addr1.address, 500);
      await flexToken.connect(addr1).burn(200);
      const addr1Balance = await flexToken.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(300);
    });
  });

  describe("MultiTransfer", function () {
    it("Should allow the owner to transfer tokens to multiple addresses", async function () {
      const recipients = [addr1.address, addr2.address, addr3.address];
      const amounts = [100, 200, 300];
      await flexToken.multiTransfer(recipients, amounts);
      const addr1Balance = await flexToken.balanceOf(addr1.address);
      const addr2Balance = await flexToken.balanceOf(addr2.address);
      const addr3Balance = await flexToken.balanceOf(addr3.address);
      expect(addr1Balance).to.equal(100);
      expect(addr2Balance).to.equal(200);
      expect(addr3Balance).to.equal(300);
    });

    it("Should not allow non-owners to execute multiTransfer", async function () {
      const recipients = [addr1.address, addr2.address];
      const amounts = [100, 200];
      await expect(flexToken.connect(addr1).multiTransfer(recipients, amounts)).to.be.reverted;
    });

    it("Should revert if arrays length mismatch", async function () {
      const recipients = [addr1.address, addr2.address];
      const amounts = [100];
      await expect(flexToken.multiTransfer(recipients, amounts)).to.be.reverted;
    });
  });
});