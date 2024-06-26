// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DefiFlexGovernanceToken.sol";
import "./IDefiFlexLendingPoolContract.sol";

contract DefiFlexGovernanceContract is Ownable {

    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        address borrowerAddress;
        uint256 borrowingAmount;
        uint256 collateralAmount;
        uint256 interestRate;
        uint256 duration;
        uint256 votingStartTime;
        uint256 votingEndTime;
        bool executed;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted;
    }

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string title,
        string description
    );

    event Voted(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 votes
    );

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    DefiFlexGovernanceToken public governanceToken;
    uint256 public minimumVotesRequired;
    uint256 public votingPeriod;

    constructor(address initialOwner, address governanceTokenAddress, uint256 _minimumVotesRequired) Ownable(initialOwner) {
        governanceToken = DefiFlexGovernanceToken(governanceTokenAddress);
        minimumVotesRequired = _minimumVotesRequired;
    }

    function setMinimumVotesRequired(uint256 minimumVotes) external onlyOwner {
        minimumVotesRequired = minimumVotes;
    }

    function setVotingPeriod(uint256 period) external onlyOwner {
        votingPeriod = period;
    }

    function proposeLoanRequest(
        uint256 proposalId,
        string memory title,
        string memory description,
        address borrowerAddress,
        uint256 borrowingAmount,
        uint256 collateralAmount,
        uint256 interestRate,
        uint256 duration
    ) external returns (uint256) {
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.title = title;
        newProposal.description = description;
        newProposal.borrowerAddress = borrowerAddress;
        newProposal.borrowingAmount = borrowingAmount;
        newProposal.collateralAmount = collateralAmount;
        newProposal.interestRate = interestRate;
        newProposal.duration = duration;
        newProposal.votingStartTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + votingPeriod;
        newProposal.executed = false;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;

        emit ProposalCreated(proposalId, msg.sender, title, description);
        return proposalId;
    }

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

    function checkProposalApprovalStatus(uint256 proposalId) external view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        return block.timestamp > proposal.votingEndTime &&
           proposal.forVotes > minimumVotesRequired &&
           proposal.againstVotes == 0;
    }
}
