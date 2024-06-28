// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDeFiPlexLendingPoolContract.sol";
import "./IDeFiPlexGovernanceContract.sol";

contract DeFiPlexLendingPoolContract is Ownable, IDeFiPlexLendingPoolContract {

    mapping(address => uint256[]) public borrowerLoans;
    Loan[] public loans;

    address private _stakingContract;
    address private _governanceContract;

    constructor(address initialOwner, address stakingContract, address governanceContract) Ownable(initialOwner) {
        _stakingContract = stakingContract;
        _governanceContract = governanceContract;
    }

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
        uint256 loanIndex = loans.length - 1;
        borrowerLoans[msg.sender].push(loanIndex);
        
        IDeFiPlexGovernanceContract(_governanceContract).proposeLoanRequest(loanIndex);

        emit LoanRequested(loanIndex, msg.sender, borrowToken, borrowAmount);
    }

    function approveLoan(uint256 loanIndex) external override onlyOwner {
        Loan storage loan = loans[loanIndex];
        require(!loan.collateralized, "Collateral already collected");
        require(IERC20(loan.borrowToken).balanceOf(_stakingContract) >= loan.borrowAmount, "Insufficient borrow token amount in lending pool");
        require(IERC20(loan.collateralToken).balanceOf(loan.borrower) >= loan.collateralAmount, "Borrower does not have enough collateral tokens");
        require(IDeFiPlexGovernanceContract(_governanceContract).checkProposalApprovalStatus(loanIndex), "Loan has not be approved");

        IERC20(loan.collateralToken).transferFrom(loan.borrower, address(this), loan.collateralAmount);
        loan.collateralized = true;
        IERC20(loan.borrowToken).transferFrom(_stakingContract, loan.borrower, loan.borrowAmount);

        emit CollateralCollected(loanIndex, loan.borrower, loan.collateralToken, loan.collateralAmount);
        emit LoanApproved(loanIndex, loan.borrower, loan.borrowAmount);
    }

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

    function setPenaltyRate(uint256 loanIndex, uint256 newPenaltyRate) external override onlyOwner {
        require(newPenaltyRate >= 0, "Penalty rate cannot be negative");
        loans[loanIndex].penaltyRate = newPenaltyRate;
    }

    function getLoanCount() external override view returns (uint256) {
        return loans.length;
    }

    function getBorrowerLoans(address borrower) external override view returns (uint256[] memory) {
        require(borrowerLoans[borrower].length > 0, "No loans found for this borrower");
        return borrowerLoans[borrower];
    }

    function getLoan(uint256 loanIndex) external view returns(Loan memory) {
        require(loanIndex < loans.length, "Loan index out of bounds");
        return loans[loanIndex];
    }
}