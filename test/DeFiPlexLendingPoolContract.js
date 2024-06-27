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
    // Deploy lending pool
    lendingPool = await LendingPool.deploy(owner.address, stakingContract);

    // Mint tokens for testing
    await flexToken2.connect(owner).mint(addr1.address, 500);
    await rewardToken.mint(owner.address, 1000);
    await stakingContract.addStakingToken(flexToken1, 1);
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

  describe("Loan Approval", function () {
    beforeEach(async function () {
      await flexToken2.connect(addr1).approve(lendingPool, 500);
      await flexToken1.connect(owner).mint(addr2.address, 100);
      await flexToken1.connect(addr2).approve(stakingContract, 100);
      await stakingContract.connect(addr2).stake(flexToken1, 100);
      await lendingPool.connect(addr1).requestLoan(
        flexToken1,
        100,
        flexToken2,
        50,
        10,
        1000
      );
    });

    it("Should approve a loan correctly", async function () {
      await lendingPool.approveLoan(0);
      const loan = await lendingPool.getLoan(0);
      expect(loan.collateralized).to.be.true;
    });

    it("Should revert if collateral already collected", async function () {
      await lendingPool.approveLoan(0);
      await expect(lendingPool.approveLoan(0)).to.be.reverted;
    });

    it("Should revert if staking contract has insufficient tokens", async function () {
      await flexToken1.connect(owner).transfer(addr2.address, 1000); // Empty staking contract
      await expect(lendingPool.approveLoan(0)).to.be.reverted;
    });

    it("Should revert if borrower has insufficient collateral tokens", async function () {
      await flexToken2.connect(addr1).transfer(addr2.address, 500); // Empty borrower balance
      await expect(lendingPool.approveLoan(0)).to.be.reverted;
    });
  });

  describe("Loan Repayment", function () {
    beforeEach(async function () {
      await flexToken1.connect(addr1).approve(lendingPool, 1000);
      await flexToken2.connect(addr1).approve(lendingPool, 500);
      await flexToken1.connect(owner).mint(addr2.address, 100);
      await flexToken1.connect(addr2).approve(stakingContract, 100);
      await stakingContract.connect(addr2).stake(flexToken1, 100);
      await lendingPool.connect(addr1).requestLoan(
        flexToken1,
        100,
        flexToken2,
        50,
        10,
        1000
      );

      await lendingPool.approveLoan(0);
    });

    it("Should repay a loan correctly", async function () {
      await ethers.provider.send("evm_increaseTime", [1000]); // Fast-forward time
      await ethers.provider.send("evm_mine", []);

      await flexToken1.connect(addr1).approve(lendingPool, 110); // 100 + 10% interest
      await lendingPool.connect(addr1).repayLoan(0);
      const loan = await lendingPool.getLoan(0);
      expect(loan.repaid).to.be.true;
    });

    it("Should apply penalties for late repayment", async function () {
      await ethers.provider.send("evm_increaseTime", [1000 + 7 * 24 * 60 * 60]); // Fast-forward 1 week late
      await ethers.provider.send("evm_mine", []);

      await flexToken1.connect(addr1).approve(lendingPool, 112); // 100 + 10% interest + 2% penalty
      await lendingPool.connect(addr1).repayLoan(0);
      const loan = await lendingPool.getLoan(0);
      expect(loan.repaid).to.be.true;
    });

    it("Should revert if loan already repaid", async function () {
      await ethers.provider.send("evm_increaseTime", [1000]); // Fast-forward time
      await ethers.provider.send("evm_mine", []);

      await flexToken1.connect(addr1).approve(lendingPool, 110);
      await lendingPool.connect(addr1).repayLoan(0);
      await expect(lendingPool.connect(addr1).repayLoan(0)).to.be.reverted;
    });

    it("Should revert if loan duration not expired", async function () {
      await flexToken1.connect(addr1).approve(lendingPool.address, 110);
      await expect(lendingPool.connect(addr1).repayLoan(0)).to.be.reverted;
    });

    it("Should revert if borrower has insufficient funds", async function () {
      await ethers.provider.send("evm_increaseTime", [1000]); // Fast-forward time
      await ethers.provider.send("evm_mine", []);

      await flexToken1.connect(addr1).transfer(addr2.address, 900); // Reduce borrower balance
      await flexToken1.connect(addr1).approve(lendingPool, 110);
      await expect(lendingPool.connect(addr1).repayLoan(0)).to.be.reverted;
    });
  });

  describe("Penalty Rate", function () {
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

      await lendingPool.approveLoan(0);
    });

    it("Should set penalty rate correctly", async function () {
      await lendingPool.setPenaltyRate(0, 5);
      const loan = await lendingPool.getLoan(0);
      expect(loan.penaltyRate).to.equal(5);
    });

    it("Should revert if penalty rate is negative", async function () {
      await expect(lendingPool.setPenaltyRate(0, -1)).to.be.reverted;
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
});
