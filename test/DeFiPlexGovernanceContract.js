const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DeFiPlexGovernanceContract", function () {
  let DeFiPlexGovernanceContract;
  let DeFiPlexGovernanceToken;
  let governanceContract;
  let governanceToken;
  let owner;
  let addr1;
  let addr2;
  let addr3;

  beforeEach(async function () {
    DeFiPlexGovernanceContract = await ethers.getContractFactory("DeFiPlexGovernanceContract");
    DeFiPlexGovernanceToken = await ethers.getContractFactory("DeFiPlexGovernanceTokenContract");

    [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();

    // Deploy governance token and governance contract
    governanceToken = await DeFiPlexGovernanceToken.deploy(owner.address);
    governanceContract = await DeFiPlexGovernanceContract.deploy(owner.address, governanceToken, 10);

    // Mint tokens for testing
    await governanceToken.connect(owner).mint(owner, 1000); // Mint 1000 tokens for owner
    await governanceToken.connect(owner).mint(addr1, 500); // Mint 500 tokens for addr1
    await governanceToken.connect(owner).mint(addr2, 300); // Mint 300 tokens for addr2
    await governanceToken.connect(owner).mint(addr3, 200); // Mint 200 tokens for addr3
  });

  it("Should deploy the contract correctly", async function () {
    expect(governanceContract.address).to.not.equal(0);
  });

  it("Should allow setting minimum votes required", async function () {
    await governanceContract.setMinimumVotesRequired(20); // Set minimum votes to 20
    const minimumVotesRequired = await governanceContract.minimumVotesRequired();
    expect(minimumVotesRequired).to.equal(20);
  });

  it("Should allow setting voting period", async function () {
    await governanceContract.setVotingPeriod(86400); // Set voting period to 1 day (86400 seconds)
    const votingPeriod = await governanceContract.votingPeriod();
    expect(votingPeriod).to.equal(86400);
  });

  it("Should propose a loan request", async function () {
    await governanceContract.proposeLoanRequest(1);
    const proposalCount = await governanceContract.proposalCount();
    expect(proposalCount).to.equal(1);
  });

  it("Should vote on a proposal", async function () {
    await governanceContract.setVotingPeriod(86400); // Set voting period to 1 day (86400 seconds)
    await governanceContract.proposeLoanRequest(1);
    // Move time forward to voting period
    await ethers.provider.send("evm_increaseTime", [100]); // Increase time by 100 seconds
    await ethers.provider.send("evm_mine"); // Mine a new block to advance time

    await governanceContract.connect(owner).vote(1, true); // Vote in favor of proposal 1
    const proposal = await governanceContract.loanProposals(1); // Retrieve proposal details
    expect(proposal.forVotes).to.equal(1000); // Check that forVotes match the approved tokens
  });

  it("Should check proposal approval status without minimun votes required", async function () {
    await governanceContract.setVotingPeriod(86400); // Set voting period to 1 day (86400 seconds)
    await governanceContract.proposeLoanRequest(1);
    // Move time forward to voting period
    await ethers.provider.send("evm_increaseTime", [86401]); // Move time forward by 1 day and 1 second
    await ethers.provider.send("evm_mine"); // Mine a new block to advance time

    const isApproved = await governanceContract.checkProposalApprovalStatus(1);
    expect(isApproved).to.be.false;
  });

  it("Should check proposal approval status with minimun votes required", async function () {
    await governanceContract.setVotingPeriod(86400); // Set voting period to 1 day (86400 seconds)
    await governanceContract.setMinimumVotesRequired(999); // Set minimum votes to 999
    await governanceContract.proposeLoanRequest(1);

    await governanceContract.connect(addr1).vote(1, true); // Vote in favor of proposal 1
    await governanceContract.connect(addr2).vote(1, true); // Vote in favor of proposal 1
    await governanceContract.connect(addr3).vote(1, true); // Vote in favor of proposal 1

    // Move time forward to voting period
    await ethers.provider.send("evm_increaseTime", [86401]); // Move time forward by 1 day and 1 second
    await ethers.provider.send("evm_mine"); // Mine a new block to advance time
   
    const proposal = await governanceContract.loanProposals(1); // Retrieve proposal details
    const isApproved = await governanceContract.checkProposalApprovalStatus(1);
    expect(proposal.forVotes).to.equal(1000); // Check that forVotes match the approved tokens
    expect(isApproved).to.be.true;
  });

  it("Should revert on trying to vote on non-existent proposal", async function () {
    await expect(governanceContract.vote(2, true)).to.be.reverted;
  });

  it("Should revert on trying to propose with same ID", async function () {
    await governanceContract.proposeLoanRequest(1);
    await expect(governanceContract.proposeLoanRequest(1)).to.be.reverted;
  });

  it("Should revert when user tries to vote again", async function () {
    await governanceContract.setVotingPeriod(86400); // Set voting period to 1 day (86400 seconds)
    await governanceContract.proposeLoanRequest(1);
    await governanceToken.connect(addr1).approve(governanceContract, 100); // Approve tokens for voting
    await governanceContract.connect(addr1).vote(1, true); // Vote in favor of proposal 1

    // Try to vote again
    await expect(governanceContract.connect(addr1).vote(1, true)).to.be.revertedWith("You have already voted");
  });

  it("Should revert when user tries to vote outside voting period", async function () {
    await governanceContract.proposeLoanRequest(1);
    await ethers.provider.send("evm_increaseTime", [86401]); // Move time forward by 1 day and 1 second
    await ethers.provider.send("evm_mine"); // Mine a new block to advance time

    await governanceToken.connect(addr1).approve(governanceContract, 100); // Approve tokens for voting

    // Try to vote outside voting period
    await expect(governanceContract.connect(addr1).vote(1, true)).to.be.revertedWith("Voting period has not started or has ended");
  });
});
