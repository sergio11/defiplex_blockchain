const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DefiFlexStakingContract", function () {
  let owner, addr1, addr2, addr3;
  let rewardToken, stakingToken1, stakingToken2;
  let stakingContract;

  async function deployContractFixture() {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    // Deploy reward token
    const FlexToken = await ethers.getContractFactory("FlexTokenERC20Contract");
    rewardToken = await FlexToken.deploy(owner.address);

    // Deploy staking tokens
    stakingToken1 = await FlexToken.deploy(owner.address);
    stakingToken2 = await FlexToken.deploy(owner.address);

    // Deploy staking contract
    const StakingContract = await ethers.getContractFactory("DefiFlexStakingContract");
    stakingContract = await StakingContract.deploy(owner.address, rewardToken);

    return { stakingContract, rewardToken, stakingToken1, stakingToken2, owner, addr1, addr2, addr3 };
  }

  beforeEach(async function () {
    await deployContractFixture();
  });

  // Test to verify that the contract owner is set correctly
  it("Should set the right owner", async function () {
    expect(await stakingContract.owner()).to.equal(owner.address);
  });

  describe("Adding Staking Tokens", function () {
 
    it("Should allow the owner to add staking tokens", async function () {
      await stakingContract.addStakingToken(stakingToken1, 1);
      const rewardRate = await stakingContract.rewardRate(stakingToken1);
      expect(rewardRate).to.equal(1);
    });
  
    it("Should not allow non-owners to add staking tokens", async function () {
      await expect(
        stakingContract.connect(addr1).addStakingToken(stakingToken1, 1)
      ).to.be.reverted;
    });
  
    it("Should not allow adding the same staking token more than once", async function () {
      await stakingContract.addStakingToken(stakingToken1, 1);
      await expect(
        stakingContract.addStakingToken(stakingToken1, 1)
      ).to.be.reverted;
    });
  
    it("Should revert when adding a staking token with a reward rate of zero", async function () {
      await expect(
        stakingContract.addStakingToken(stakingToken1, 0)
      ).to.be.reverted;
    });
  
    it("Should correctly store staking token info after adding", async function () {
      await stakingContract.addStakingToken(stakingToken1, 1);
      const stakingInfo = await stakingContract.totalSupply(stakingToken1);
      expect(stakingInfo).to.equal(0); // Initially, no tokens are staked
    });
  
    it("Should emit StakingTokenAdded event when a new staking token is added", async function () {
      await expect(stakingContract.addStakingToken(stakingToken1, 1))
        .to.emit(stakingContract, "StakingTokenAdded")
        .withArgs(stakingToken1, 1);
    });
  
    it("Should revert if trying to add a staking token with a non-contract address", async function () {
      await expect(
        stakingContract.addStakingToken(addr1.address, 1)
      ).to.be.reverted;
    });
  
    it("Should not allow adding staking tokens with extremely high reward rates", async function () {
      await expect(
        stakingContract.addStakingToken(stakingToken1, 1000000 * 18)
      ).to.be.reverted;
    });
  });

  describe("Staking Tokens", function () {
    beforeEach(async function () {
      await stakingContract.addStakingToken(stakingToken1, 10);
      await stakingToken1.connect(owner).mint(addr1.address, 100);
      await stakingToken1.connect(addr1).approve(stakingContract, 100);
    });

    it("Should allow users to stake tokens", async function () {
      await stakingContract.connect(addr1).stake(stakingToken1, 50);
      const balance = await stakingContract.balanceOf(stakingToken1, addr1.address);
      expect(balance).to.equal(50);
    });

    it("Should not allow staking zero tokens", async function () {
      await expect(stakingContract.connect(addr1).stake(stakingToken1, 0)).to.be.reverted;
    });

    it("Should allow multiple users to stake tokens", async function () {
      await stakingToken1.connect(owner).mint(addr2.address, 200);
      await stakingToken1.connect(addr2).approve(stakingContract, 200);

      await stakingContract.connect(addr1).stake(stakingToken1, 30);
      await stakingContract.connect(addr2).stake(stakingToken1, 70);

      const balanceAddr1 = await stakingContract.balanceOf(stakingToken1, addr1.address);
      const balanceAddr2 = await stakingContract.balanceOf(stakingToken1, addr2.address);

      expect(balanceAddr1).to.equal(30);
      expect(balanceAddr2).to.equal(70);
    });

    it("Should not allow staking more tokens than available", async function () {
      await expect(stakingContract.connect(addr1).stake(stakingToken1, 150)).to.be.reverted;
    });

    it("Should allow stake and withdraw tokens", async function () {
      await stakingContract.connect(addr1).stake(stakingToken1, 50);
      let balance = await stakingContract.balanceOf(stakingToken1, addr1.address);
      expect(balance).to.equal(50);

      await stakingContract.connect(addr1).withdraw(stakingToken1, 30);
      balance = await stakingContract.balanceOf(stakingToken1, addr1.address);
      expect(balance).to.equal(20);
    });
  });

  describe("Withdrawing Tokens", function () {
    beforeEach(async function () {
      await stakingContract.addStakingToken(stakingToken1, 1);
      await stakingToken1.connect(owner).mint(addr1.address, 100);
      await stakingToken1.connect(addr1).approve(stakingContract, 100);
      await stakingContract.connect(addr1).stake(stakingToken1, 50);
      await rewardToken.connect(owner).mint(stakingContract, 1000);
    });

    it("Should allow users to withdraw all staked tokens", async function () {
      await stakingContract.connect(addr1).withdraw(stakingToken1, 50);
      const balance = await stakingContract.balanceOf(stakingToken1, addr1.address);
      expect(balance).to.equal(0);
    });

    it("Should not allow withdrawing more tokens than staked", async function () {
      await expect(stakingContract.connect(addr1).withdraw(stakingToken1, 60)).to.be.reverted;
    });

    it("Should allow withdrawing tokens and update rewards", async function () {
      // Fast-forward time by 1 week
      await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
      await ethers.provider.send("evm_mine", []);

      const initialRewardBalance = await rewardToken.balanceOf(addr1.address);
      await stakingContract.connect(addr1).withdraw(stakingToken1, 20);
      const earnedRewards = await stakingContract.connect(addr1).getTotalRewards(stakingToken1, addr1.address);
      await stakingContract.connect(addr1).claimReward(stakingToken1)
      const balance = await stakingContract.balanceOf(stakingToken1, addr1.address);
      const finalRewardBalance = await rewardToken.balanceOf(addr1.address);
      
      expect(balance).to.equal(30);
      expect(earnedRewards).to.equal(50);
      expect(finalRewardBalance).to.equal(50);
      expect(finalRewardBalance).to.be.gt(initialRewardBalance);
    });

    it("Should allow withdrawing tokens and update rewards 2", async function () {
      // Fast-forward time by 1 week
      await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
      await ethers.provider.send("evm_mine", []);

      const initialRewardBalance = await rewardToken.balanceOf(addr1.address);
      await stakingContract.connect(addr1).withdraw(stakingToken1, 20);
      const earnedRewardsAfterWithDraw = await stakingContract.connect(addr1).getTotalRewards(stakingToken1, addr1.address);
      
      // Fast-forward time by 1 week
      await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
      await ethers.provider.send("evm_mine", []);

      const earnedRewardsBeforeClaim = await stakingContract.connect(addr1).getEarnedRewards(stakingToken1, addr1.address);

      await stakingContract.connect(addr1).claimReward(stakingToken1)
      const balance = await stakingContract.balanceOf(stakingToken1, addr1.address);
      const finalRewardBalance = await rewardToken.balanceOf(addr1.address);
      
      expect(balance).to.equal(30);
      expect(earnedRewardsAfterWithDraw).to.equal(50);
      expect(earnedRewardsBeforeClaim).to.equal(30);
      expect(finalRewardBalance).to.equal(80);
      expect(finalRewardBalance).to.be.gt(initialRewardBalance);
    });
  });


  describe("Claiming Rewards", function () {
    beforeEach(async function () {
      await stakingContract.addStakingToken(stakingToken1, 1);
      await stakingToken1.connect(owner).mint(addr1.address, 100);
      await stakingToken1.connect(addr1).approve(stakingContract, 100);
      await rewardToken.connect(owner).mint(stakingContract, 1000);
      await stakingContract.connect(addr1).stake(stakingToken1, 50);
    });
  
    it("Should allow users to claim rewards", async function () {
      // Fast-forward time by 1 week
      await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
      await ethers.provider.send("evm_mine", []);
  
      const initialRewardBalance = await rewardToken.balanceOf(addr1.address);
      const earnedRewards = await stakingContract.getEarnedRewards(stakingToken1, addr1.address);
  
      await stakingContract.connect(addr1).claimReward(stakingToken1);
      const finalRewardBalance = await rewardToken.balanceOf(addr1.address);
      
      expect(finalRewardBalance - initialRewardBalance).to.equal(earnedRewards);
    });
  
    it("Should update user reward after claiming", async function () {
      // Fast-forward time by 1 week
      await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
      await ethers.provider.send("evm_mine", []);
  
      await stakingContract.connect(addr1).claimReward(stakingToken1);
      const userRewards = await stakingContract.getEarnedRewards(stakingToken1, addr1.address);
  
      expect(userRewards).to.equal(0);
    });
  
    it("Should not allow claiming zero rewards", async function () {
      await expect(stakingContract.connect(addr1).claimReward(stakingToken1)).to.be.reverted;
    });
  
    it("Should not affect staked balance after claiming rewards", async function () {
      // Fast-forward time by 1 week
      await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
      await ethers.provider.send("evm_mine", []);
  
      const stakedBalanceBefore = await stakingContract.balanceOf(stakingToken1, addr1.address);
      await stakingContract.connect(addr1).claimReward(stakingToken1);
      const stakedBalanceAfter = await stakingContract.balanceOf(stakingToken1, addr1.address);
  
      expect(stakedBalanceBefore).to.equal(stakedBalanceAfter);
    });
  });

  describe("Setting Reward Rate", function () {
    beforeEach(async function () {
      await stakingContract.addStakingToken(stakingToken1, 1);
    });

    it("Should allow the owner to set the reward rate", async function () {
      await stakingContract.setRewardRate(stakingToken1, 2);
      const rewardRate = await stakingContract.rewardRate(stakingToken1);
      expect(rewardRate).to.equal(2);
    });

    it("Should not allow non-owners to set the reward rate", async function () {
      await expect(stakingContract.connect(addr1).setRewardRate(stakingToken1, 2))
        .to.be.reverted;
    });
  });

  describe("Getting Information", function () {
    beforeEach(async function () {
      await stakingContract.addStakingToken(stakingToken1, 1);
      await stakingToken1.connect(owner).mint(addr1.address, 100);
      await stakingToken1.connect(addr1).approve(stakingContract, 100);
      await stakingContract.connect(addr1).stake(stakingToken1, 50);
      await rewardToken.connect(owner).mint(stakingContract, 1000);
    });

    it("Should return the correct total supply", async function () {
      const totalSupply = await stakingContract.totalSupply(stakingToken1);
      expect(totalSupply).to.equal(50);
    });

    it("Should return the correct balance of user", async function () {
      const balance = await stakingContract.balanceOf(stakingToken1, addr1.address);
      expect(balance).to.equal(50);
    });

    it("Should return the correct earned rewards", async function () {
      // Fast-forward time by 1 week
      await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
      await ethers.provider.send("evm_mine", []);

      const rewards = await stakingContract.getEarnedRewards(stakingToken1, addr1.address);
      expect(rewards).to.be.gt(0);
    });

    it("Should return the correct total rewards accumulated", async function () {
      // Fast-forward time by 1 week
      await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
      await ethers.provider.send("evm_mine", []);

      await stakingContract.connect(addr1).claimReward(stakingToken1);
      const totalRewards = await stakingContract.getEarnedRewards(stakingToken1, addr1.address);
      expect(totalRewards).to.equal(0);

      // Fast-forward time by another week
      await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]);
      await ethers.provider.send("evm_mine", []);

      const newTotalRewards = await stakingContract.getEarnedRewards(stakingToken1, addr1.address);
      expect(newTotalRewards).to.be.gt(0);
    });
  });
});
