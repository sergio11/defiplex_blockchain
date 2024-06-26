// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DefiFlexGovernanceToken.sol";
import "./IDefiFlexLendingPoolContract.sol";

/**
 * @title DefiFlexGovernanceContract
 * @dev Contract for governance management allowing token holders to vote on proposals.
 */
contract DefiFlexGovernanceContract is Ownable {

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 votingStartTime;
        uint256 votingEndTime;
        bool executed;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    DefiFlexGovernanceToken public governanceToken;
    IDefiFlexLendingPool public lendingPoolContract;

    /**
     * @dev Constructor that initializes the contract with the addresses of the governance token and lending pool contract.
     * @param governanceTokenAddress Address of the governance token contract.
     * @param lendingPoolAddress Address of the lending pool contract.
     */
    constructor(address initialOwner, address governanceTokenAddress, address lendingPoolAddress) Ownable(initialOwner) {
        governanceToken = DefiFlexGovernanceToken(governanceTokenAddress);
        lendingPoolContract = IDefiFlexLendingPool(lendingPoolAddress);
    }

    /**
     * @dev Function to set the lending pool contract address.
     * @param lendingPoolAddress Address of the new lending pool contract.
     */
    function setLendingPoolContract(address lendingPoolAddress) external onlyOwner {
        lendingPoolContract = IDefiFlexLendingPool(lendingPoolAddress);
    }

    /**
     * @dev Function to propose a new governance proposal.
     * @param title Title of the proposal.
     * @param description Detailed description of the proposal.
     */
    function propose(string memory title, string memory description) external {
        uint256 proposalId = proposalCount++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.title = title;
        newProposal.description = description;
        newProposal.votingStartTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + 7 days; // 7-day voting period
        newProposal.executed = false;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
    }

    /**
     * @dev Function for governance token holders to vote in favor or against a proposal.
     * @param proposalId ID of the proposal to vote on.
     * @param support Boolean indicating whether the vote is in favor (`true`) or against (`false`).
     */
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.votingStartTime <= block.timestamp && block.timestamp <= proposal.votingEndTime, "Voting period has not started or has ended");
        require(!proposal.hasVoted[msg.sender], "You have already voted");

        if (support) {
            proposal.forVotes += governanceToken.balanceOf(msg.sender);
        } else {
            proposal.againstVotes += governanceToken.balanceOf(msg.sender);
        }

        proposal.hasVoted[msg.sender] = true;
    }

    /**
     * @dev Function to execute a proposal approved by majority vote.
     * @param proposalId ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended yet");
        require(!proposal.executed, "Proposal has already been executed");

        // Determine if proposal is approved based on votes
        if (proposal.forVotes > proposal.againstVotes) {
            // Execute the action of the approved proposal through the lending pool contract
            lendingPoolContract.approveLoan(proposalId); // Example of specific action in lending pool contract
            // You can add more specific actions here based on the proposal
            proposal.executed = true;
        }
    }
}