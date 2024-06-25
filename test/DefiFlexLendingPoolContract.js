const { expect } = require("chai");

describe("DefiFlexLendingPoolContract", function () {

  async function deployContractFixture() {
    const [owner, addr1, addr2, addr3] = await ethers.getSigners()
    // Get the ContractFactory and Signers here.
    const flexTokenERC20ContractFactory = await ethers.getContractFactory("FlexTokenERC20Contract")
    const flexTokenERC20Contract = await flexTokenERC20ContractFactory.deploy(owner.address)
    const defiFlexStakingContractFactory = await ethers.getContractFactory("DefiFlexStakingContract")
    const defiFlexStakingContract = await defiFlexStakingContractFactory.deploy(owner.address, flexTokenERC20Contract)
    const defiFlexLendingPoolContractFactory = await ethers.getContractFactory("DefiFlexLendingPoolContract")
    const instance = await defiFlexLendingPoolContractFactory.deploy(owner.address, defiFlexStakingContract)
    return { instance,  owner, addr1, addr2, addr3 }
  }

  // Test to verify that the contract owner is set correctly
  it("Should set the right owner", async function () {
    const { instance, owner } = await deployContractFixture();
    expect(await instance.owner()).to.equal(owner.address);
  });
})