// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDeFiPlexLendingPoolContract.sol";
import "./IDeFiPlexGovernanceContract.sol";
import "./IDeFiPlexStakingContract.sol";

/**
 * @title DeFiPlexLendingPoolContract
 * @dev This contract handles the lending and borrowing functionalities within the DeFiPlex platform.
 * It allows users to request loans, approve loans, and repay loans. Additionally, it manages collateral and penalties for late repayment.
 */
contract DeFiPlexLendingPoolContract is Ownable, IDeFiPlexLendingPoolContract {
     using SafeERC20 for IERC20;

    // Mapping to store loans for each borrower
    mapping(address => uint256[]) public borrowerLoans;

    uint256 private _loanCount; 

    // Array to store all loan details
    Loan[] public loans;

    // Addresses for the staking and governance contracts
    address private _stakingContract;
    address private _governanceContract;

    /**
     * @dev Constructor to initialize the contract with owner, staking contract, and governance contract addresses.
     * @param initialOwner Address of the initial owner.
     * @param stakingContract Address of the staking contract.
     * @param governanceContract Address of the governance contract.
     */
    constructor(address initialOwner, address stakingContract, address governanceContract) Ownable(initialOwner) {
        _stakingContract = stakingContract;
        _governanceContract = governanceContract;
    }

    /**
     * @dev Request a new loan.
     * @param borrowToken Address of the token to borrow.
     * @param borrowAmount Amount of tokens to borrow.
     * @param collateralToken Address of the collateral token.
     * @param collateralAmount Amount of collateral tokens.
     * @param interestRate Interest rate for the loan.
     * @param duration Duration of the loan in seconds.
     */
    function requestLoan(
        address borrowToken,
        uint256 borrowAmount,
        address collateralToken,
        uint256 collateralAmount,
        uint256 interestRate,
        uint256 duration
    ) external override {
        require(borrowAmount > 0, "Loan amount must be greater than zero");
        require(interestRate > 0, "Interest rate must be greater than zero");
        require(collateralAmount > 0, "Collateral amount must be greater than zero");
        require(duration > 0, "Loan duration must be greater than zero");
        require(borrowToken != address(0), "Invalid borrowToken address");
        // Check if the address is a contract (basic verification)
        uint256 size;
        assembly {
            size := extcodesize(borrowToken)
        }
        require(size > 0, "collateralToken address is not a contract");
        require(collateralToken != address(0), "Invalid collateralToken address");
        assembly {
            size := extcodesize(collateralToken)
        }
        require(size > 0, "collateralToken address is not a contract");

        Loan memory newLoan = Loan({
            borrowToken: borrowToken,
            borrowAmount: borrowAmount,
            collateralToken: collateralToken,
            collateralAmount: collateralAmount,
            interestRate: interestRate,
            duration: duration,
            startTime: block.timestamp,
            borrower: msg.sender,
            collateralized: false,
            repaid: false,
            penaltyRate: 1,
            penaltyStartTime: 0
        });

        loans.push(newLoan);
        uint256 loanIndex = _loanCount++;
        borrowerLoans[msg.sender].push(loanIndex);
        
        IDeFiPlexGovernanceContract(_governanceContract).proposeLoanRequest(loanIndex);

        emit LoanRequested(loanIndex, msg.sender, borrowToken, borrowAmount);
    }

    /**
     * @dev Approve a loan after verifying collateral and governance approval.
     * @param loanIndex Index of the loan to approve.
     */
    function approveLoan(uint256 loanIndex) external override onlyOwner {
        Loan storage loan = loans[loanIndex];
        require(!loan.collateralized, "Collateral already collected");
        require(IERC20(loan.borrowToken).balanceOf(_stakingContract) >= loan.borrowAmount, "Insufficient borrow token amount in lending pool");
        require(IERC20(loan.collateralToken).balanceOf(loan.borrower) >= loan.collateralAmount, "Borrower does not have enough collateral tokens");
        require(IDeFiPlexGovernanceContract(_governanceContract).checkProposalApprovalStatus(loanIndex), "Loan proposal has not been approved by governance");

        IERC20(loan.collateralToken).safeTransferFrom(loan.borrower, address(this), loan.collateralAmount);
        loan.collateralized = true;
        IDeFiPlexStakingContract(_stakingContract).transferTokensTo(loan.borrowToken, loan.borrower, loan.borrowAmount);

        emit CollateralCollected(loanIndex, loan.borrower, loan.collateralToken, loan.collateralAmount);
        emit LoanApproved(loanIndex, loan.borrower, loan.borrowAmount);
    }

    /**
     * @dev Repay a loan with interest and handle late repayment penalties.
     * @param loanIndex Index of the loan to repay.
     */
    function repayLoan(uint256 loanIndex) external override {
        Loan storage loan = loans[loanIndex];
        require(!loan.repaid, "Loan already repaid");
        require(block.timestamp >= loan.startTime + loan.duration, "Loan duration not expired");

        uint256 interestAmount = loan.borrowAmount * loan.interestRate / 100;
        uint256 repaymentAmount = loan.borrowAmount + interestAmount;

        // Apply penalties for late repayment
        if (loan.penaltyStartTime == 0) {
            loan.penaltyStartTime = block.timestamp;
        } else {
            uint256 weeksLate = (block.timestamp - loan.penaltyStartTime) / (7 days);
            uint256 penaltyAmount = weeksLate * loan.penaltyRate * loan.borrowAmount / 100;
            if (penaltyAmount > 0) {
                repaymentAmount += penaltyAmount;
                emit PenaltyApplied(loanIndex, loan.borrower, penaltyAmount);
            }
        }

        require(IERC20(loan.borrowToken).balanceOf(loan.borrower) >= repaymentAmount, "Insufficient borrower funds");
        IERC20(loan.borrowToken).transferFrom(loan.borrower, _stakingContract, repaymentAmount);

        // Return collateral to borrower
        if (loan.collateralized) {
            IERC20(loan.collateralToken).transferFrom(address(this), loan.borrower, loan.collateralAmount);
        }

        loan.repaid = true;

        emit LoanRepaid(loanIndex, loan.borrower, repaymentAmount);
    }

    /**
     * @dev Set the penalty rate for a loan.
     * @param loanIndex Index of the loan to set the penalty rate for.
     * @param newPenaltyRate New penalty rate.
     */
    function setPenaltyRate(uint256 loanIndex, uint256 newPenaltyRate) external override onlyOwner {
        require(newPenaltyRate >= 0, "Penalty rate cannot be negative");
        loans[loanIndex].penaltyRate = newPenaltyRate;
    }

    /**
     * @dev Get the total number of loans.
     * @return Total number of loans.
     */
    function getLoanCount() external override view returns (uint256) {
        return loans.length;
    }

    /**
     * @dev Get the loan indices for a borrower.
     * @param borrower Address of the borrower.
     * @return Array of loan indices.
     */
    function getBorrowerLoans(address borrower) external override view returns (uint256[] memory) {
        require(borrowerLoans[borrower].length > 0, "No loans found for this borrower");
        return borrowerLoans[borrower];
    }

    /**
     * @dev Get details of a specific loan.
     * @param loanIndex Index of the loan to get details for.
     * @return Loan details.
     */
    function getLoan(uint256 loanIndex) external view returns(Loan memory) {
        require(loanIndex < loans.length, "Loan index out of bounds");
        return loans[loanIndex];
    }
}
