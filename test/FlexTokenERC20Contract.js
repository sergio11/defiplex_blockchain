const { expect } = require("chai");

describe("FlexTokenERC20Contract", function () {

  async function deployContractFixture() {
    const [owner, addr1, addr2, addr3] = await ethers.getSigners()
    // Get the ContractFactory and Signers here.
    const ContractFactory = await ethers.getContractFactory("FlexTokenERC20Contract")
    const instance = await ContractFactory.deploy(owner.address)
    return { ContractFactory, instance, owner, addr1, addr2, addr3 }
  }

  // Test to verify that the contract owner is set correctly
  it("Should set the right owner", async function () {
    const { instance, owner } = await deployContractFixture();
    expect(await instance.owner()).to.equal(owner.address);
  });
})