// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DeFiPlexGovernanceTokenContract.sol";
import "./IDeFiPlexGovernanceContract.sol";

/**
 * @title DeFiPlexGovernanceContract
 * @dev This contract manages governance proposals for DeFiPlex platform.
 */
contract DeFiPlexGovernanceContract is Ownable, IDeFiPlexGovernanceContract {

    struct LoanProposal {
        uint256 loanProposalId;       // Unique ID of the loan proposal
        address proposer;             // Address of the proposer who created the proposal
        uint256 votingStartTime;      // Start time of the voting period
        uint256 votingEndTime;        // End time of the voting period
        bool executed;                // Flag indicating whether the proposal has been executed
        uint256 forVotes;             // Total number of votes in favor of the proposal
        uint256 againstVotes;         // Total number of votes against the proposal
        mapping(address => bool) hasVoted; // Mapping to track addresses that have voted
    }

    uint256 public proposalCount;               // Total count of proposals created
    mapping(uint256 => LoanProposal) public loanProposals; // Mapping to store all loan proposals
    DeFiPlexGovernanceTokenContract public governanceToken; // Instance of the governance token contract
    uint256 public minimumVotesRequired;        // Minimum number of votes required to approve a proposal
    uint256 public votingPeriod;                // Duration of the voting period for each proposal

    /**
     * @dev Constructor to initialize the contract with initial values.
     * @param initialOwner Address of the initial owner of the contract
     * @param governanceTokenAddress Address of the DeFiPlexGovernanceTokenContract contract
     * @param _minimumVotesRequired Minimum number of votes required to approve a proposal
     */
    constructor(address initialOwner, address governanceTokenAddress, uint256 _minimumVotesRequired) Ownable(initialOwner) {
        governanceToken = DeFiPlexGovernanceTokenContract(governanceTokenAddress);
        minimumVotesRequired = _minimumVotesRequired;
    }

    /**
     * @dev Sets the minimum number of votes required to approve a proposal.
     * @param minimumVotes Minimum number of votes required
     */
    function setMinimumVotesRequired(uint256 minimumVotes) external onlyOwner {
        minimumVotesRequired = minimumVotes;
    }

    /**
     * @dev Sets the duration of the voting period for each proposal.
     * @param period Duration of the voting period in seconds
     */
    function setVotingPeriod(uint256 period) external onlyOwner {
        votingPeriod = period;
    }

    /**
     * @dev Proposes a new loan request.
     * @param loanProposalId Unique ID of the loan proposal
     * @return loanProposalId ID of the created loan proposal
     */
    function proposeLoanRequest(uint256 loanProposalId) external returns (uint256) {
        require(loanProposals[loanProposalId].proposer == address(0), "Proposal ID already exists");

        LoanProposal storage newProposal = loanProposals[loanProposalId];
        newProposal.loanProposalId = loanProposalId;
        newProposal.proposer = msg.sender;
        newProposal.votingStartTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + votingPeriod;
        newProposal.executed = false;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        proposalCount++;

        emit LoanProposalCreated(loanProposalId, msg.sender);
        return loanProposalId;
    }

    /**
     * @dev Votes on a loan proposal.
     * @param proposalId ID of the proposal to vote on
     * @param support Boolean indicating whether to support (true) or oppose (false) the proposal
     */
    function vote(uint256 proposalId, bool support) external {
        LoanProposal storage proposal = loanProposals[proposalId];
        require(proposal.votingStartTime <= block.timestamp && block.timestamp <= proposal.votingEndTime, "Voting period has not started or has ended");
        require(!proposal.hasVoted[msg.sender], "You have already voted");

        if (support) {
            proposal.forVotes += governanceToken.balanceOf(msg.sender);
        } else {
            proposal.againstVotes += governanceToken.balanceOf(msg.sender);
        }

        proposal.hasVoted[msg.sender] = true;

        emit LoanProposalVoted(proposalId, msg.sender, support);
    }

    /**
     * @dev Checks the approval status of a loan proposal.
     * @param proposalId ID of the proposal to check
     * @return Whether the proposal is approved or not
     */
    function checkProposalApprovalStatus(uint256 proposalId) external view returns (bool) {
        LoanProposal storage proposal = loanProposals[proposalId];
        return block.timestamp > proposal.votingEndTime &&
           proposal.forVotes > minimumVotesRequired &&
           proposal.againstVotes == 0;
    }

    /**
     * @dev Retrieves the details of a loan proposal.
     * @param proposalId ID of the proposal to retrieve details for
     * @return loanProposalId ID of the loan proposal
     * @return proposer Address of the proposer
     * @return votingStartTime Start time of the voting period
     * @return votingEndTime End time of the voting period
     * @return executed Whether the proposal has been executed
     * @return forVotes Total votes in favor of the proposal
     * @return againstVotes Total votes against the proposal
     */
    function getProposalDetails(uint256 proposalId) external view returns (
        uint256,
        address,
        uint256,
        uint256,
        bool,
        uint256,
        uint256
    ) {
        LoanProposal storage proposal = loanProposals[proposalId];
        return (
            proposal.loanProposalId,
            proposal.proposer,
            proposal.votingStartTime,
            proposal.votingEndTime,
            proposal.executed,
            proposal.forVotes,
            proposal.againstVotes
        );
    }
}