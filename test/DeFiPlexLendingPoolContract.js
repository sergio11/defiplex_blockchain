const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DeFiPlexLendingPoolContract", function () {
  let LendingPool;
  let lendingPool;
  let owner;
  let addr1;
  let addr2;
  let flexToken1;
  let flexToken2;
  let stakingContract;
  let governanceContract;

  beforeEach(async function () {
    LendingPool = await ethers.getContractFactory("DeFiPlexLendingPoolContract");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    // Deploy FlexTokenERC20Contract tokens
    const FlexToken = await ethers.getContractFactory("PlexTokenERC20Contract");
    flexToken1 = await FlexToken.deploy(owner.address);
    flexToken2 = await FlexToken.deploy(owner.address);
    rewardToken = await FlexToken.deploy(owner.address);

    // Deploy staking contract
    const StakingContract = await ethers.getContractFactory("DeFiPlexStakingContract");
    stakingContract = await StakingContract.deploy(owner.address, rewardToken);

    DeFiPlexGovernanceContract = await ethers.getContractFactory("DeFiPlexGovernanceContract");
    DeFiPlexGovernanceToken = await ethers.getContractFactory("DeFiPlexGovernanceTokenContract");
    // Deploy governance token and governance contract
    governanceToken = await DeFiPlexGovernanceToken.deploy(owner.address);
    governanceContract = await DeFiPlexGovernanceContract.deploy(owner.address, governanceToken, 10);
    // Deploy lending pool
    lendingPool = await LendingPool.deploy(owner.address, stakingContract, governanceContract);

    // Mint tokens for testing
    await flexToken1.connect(owner).mint(owner.address, 1500);
    await flexToken2.connect(owner).mint(addr1.address, 500);
    await rewardToken.mint(owner.address, 1000);
    await stakingContract.addStakingToken(flexToken1, 1);
    await stakingContract.authorizeTransfer(flexToken1, lendingPool);
    
    await governanceContract.setMinimumVotesRequired(20); // Set minimum votes to 20
    await governanceContract.setVotingPeriod(86400); // Set voting period to 1 day (86400 seconds)
    await governanceToken.connect(owner).mint(owner, 1000); // Mint 1000 tokens for owner
    await governanceToken.connect(owner).mint(addr1, 500); // Mint 500 tokens for addr1
    await governanceToken.connect(owner).mint(addr2, 300); // Mint 300 tokens for addr2
  });

  describe("Loan Requests", function () {
    it("Should allow users to request a loan", async function () {
      await flexToken1.connect(addr1).approve(lendingPool, 1000);
      await flexToken2.connect(addr1).approve(lendingPool, 500);

      await lendingPool.connect(addr1).requestLoan(
        flexToken1,
        100,
        flexToken2,
        50,
        10,
        1000
      );

      const loan = await lendingPool.getLoan(0);
      expect(loan.borrower).to.equal(addr1.address);
      expect(loan.borrowAmount).to.equal(100);
    });

    it("Should revert if loan amount is zero", async function () {
      await expect(
        lendingPool.connect(addr1).requestLoan(
          flexToken1,
          0,
          flexToken2,
          50,
          10,
          1000
        )
      ).to.be.revertedWith("Loan amount must be greater than zero");
    });

    it("Should revert if interest rate is zero", async function () {
      await expect(
        lendingPool.connect(addr1).requestLoan(
          flexToken1,
          100,
          flexToken2,
          50,
          0,
          1000
        )
      ).to.be.reverted;
    });

    it("Should revert if collateral amount is zero", async function () {
      await expect(
        lendingPool.connect(addr1).requestLoan(
          flexToken1,
          100,
          flexToken2,
          0,
          10,
          1000
        )
      ).to.be.reverted;
    });

    it("Should revert if duration is zero", async function () {
      await expect(
        lendingPool.connect(addr1).requestLoan(
          flexToken1,
          100,
          flexToken2,
          50,
          10,
          0
        )
      ).to.be.reverted;
    });
  });

  describe("Loan Queries", function () {
    beforeEach(async function () {
      await flexToken1.connect(addr1).approve(lendingPool, 1000);
      await flexToken2.connect(addr1).approve(lendingPool, 500);

      await lendingPool.connect(addr1).requestLoan(
        flexToken1,
        100,
        flexToken2,
        50,
        10,
        1000
      );
    });

    it("Should return borrower loans correctly", async function () {
      const loans = await lendingPool.getBorrowerLoans(addr1.address);
      expect(loans.length).to.equal(1);
      expect(loans[0]).to.equal(0);
    });

    it("Should revert if no loans found for borrower", async function () {
      await expect(lendingPool.getBorrowerLoans(addr2.address)).to.be.reverted;
    });

    it("Should return loan details correctly", async function () {
      const loan = await lendingPool.getLoan(0);
      expect(loan.borrower).to.equal(addr1.address);
    });

    it("Should revert if loan index is out of bounds", async function () {
      await expect(lendingPool.getLoan(1)).to.be.reverted;
    });
  });

  describe("Loan Approval", function () {

    beforeEach(async function () {
      await lendingPool.connect(addr1).requestLoan(flexToken1, 100, flexToken2, 50, 10, 1000);
    });

    it("Should be rejected because insufficient borrow token amount in lending pool", async function () {
      await governanceContract.connect(addr2).vote(0, true); // Vote in favor of proposal
      // Move time forward to voting period
      await ethers.provider.send("evm_increaseTime", [86401]); // Move time forward by 1 day and 1 second
      await ethers.provider.send("evm_mine"); // Mine a new block to advance time
      await expect(lendingPool.connect(owner).approveLoan(0)).to.be.rejectedWith("Insufficient borrow token amount in lending pool");
    });

    it("Should be rejected because borrower does not have enough collateral tokens", async function () {
      await flexToken1.connect(owner).transfer(stakingContract, 500);
      await governanceContract.connect(addr2).vote(0, true); // Vote in favor of proposal
      // Move time forward to voting period
      await ethers.provider.send("evm_increaseTime", [86401]); // Move time forward by 1 day and 1 second
      await ethers.provider.send("evm_mine"); // Mine a new block to advance time
      await expect(lendingPool.connect(owner).approveLoan(0)).to.be.reverted;
    });

    it("Should be rejected because collateral already collected", async function () {
      await flexToken1.connect(owner).transfer(stakingContract, 500); // Transfer tokens to the staking contract
      await flexToken2.connect(owner).transfer(addr1.address, 50); // Transfer collateral tokens to the borrower
      await flexToken2.connect(addr1).approve(lendingPool, 50); // Approve the lending pool to spend borrower's collateral tokens
  
      await governanceContract.connect(addr2).vote(0, true); // Vote in favor of proposal
      // Move time forward to voting period
      await ethers.provider.send("evm_increaseTime", [86401]); // Move time forward by 1 day and 1 second
      await ethers.provider.send("evm_mine"); // Mine a new block to advance time
      await lendingPool.approveLoan(0);
      expect(await flexToken1.balanceOf(addr1)).to.equal(100);
      await expect(lendingPool.approveLoan(0)).to.be.rejectedWith("Collateral already collected");
    });

    it("Should be rejected because the loan proposal has not been approved by governance", async function () {
      await flexToken1.connect(owner).transfer(stakingContract, 500); // Transfer tokens to the staking contract
      await flexToken2.connect(owner).transfer(addr1.address, 50); // Transfer collateral tokens to the borrower
      await flexToken2.connect(addr1).approve(lendingPool, 50); // Approve the lending pool to spend borrower's collateral tokens
  
      await governanceContract.connect(addr2).vote(0, false);
      // Move time forward to voting period
      await ethers.provider.send("evm_increaseTime", [86401]); // Move time forward by 1 day and 1 second
      await ethers.provider.send("evm_mine"); // Mine a new block to advance time
      await expect(lendingPool.approveLoan(0)).to.be.rejectedWith("Loan proposal has not been approved by governance");
      expect(await flexToken1.balanceOf(addr1)).to.equal(0);
    });
  });

});
