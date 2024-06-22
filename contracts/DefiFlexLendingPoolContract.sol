// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDefiFlexLendingPool.sol";

contract DefiFlexLendingPoolContract is Ownable, IDefiFlexLendingPool {
    struct Loan {
        address borrowToken;         // Token being borrowed
        uint256 borrowAmount;        // Amount being borrowed
        address collateralToken;     // Token used as collateral
        uint256 collateralAmount;    // Amount of collateral in tokens
        uint256 interestRate;        // Interest rate in percentage (e.g., 10 for 10%)
        uint256 duration;            // Duration of the loan in blocks
        uint256 startTime;           // Start time of the loan
        address borrower;            // Address of the borrower
        bool collateralized;         // Flag to track if collateral has been collected
        bool repaid;                 // Flag to track if the loan has been repaid
        bool approved;               // Flag to track if the loan has been approved
        uint256 penaltyRate;         // Penalty rate for late repayment per week
        uint256 penaltyStartTime;    // Start time to calculate penalties
    }

    mapping(address => uint256[]) public borrowerLoans;
    Loan[] public loans;

    address private _defiFlexStakingContract;

    constructor(address initialOwner, address defiFlexStakingContract) Ownable(initialOwner) {
        _defiFlexStakingContract = defiFlexStakingContract;
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
            approved: false,
            penaltyRate: 1,
            penaltyStartTime: 0
        });

        loans.push(newLoan);
        borrowerLoans[msg.sender].push(loans.length - 1);

        emit LoanRequested(loans.length - 1, msg.sender, borrowToken, borrowAmount);
    }

    function approveLoan(uint256 loanIndex) external override onlyOwner {
        Loan storage loan = loans[loanIndex];
        require(!loan.approved, "Loan already approved");
        require(!loan.collateralized, "Collateral already collected");
        require(IERC20(loan.borrowToken).balanceOf(_defiFlexStakingContract) >= loan.borrowAmount, "Insufficient borrow token amount in lending pool");
        require(IERC20(loan.collateralToken).balanceOf(loan.borrower) >= loan.collateralAmount, "Borrower does not have enough collateral tokens");

        IERC20(loan.collateralToken).transferFrom(loan.borrower, address(this), loan.collateralAmount);
        loan.collateralized = true;
        IERC20(loan.borrowToken).transferFrom(_defiFlexStakingContract, loan.borrower, loan.borrowAmount);
        loan.approved = true;

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
        IERC20(loan.borrowToken).transferFrom(loan.borrower, _defiFlexStakingContract, repaymentAmount);

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
        return borrowerLoans[borrower];
    }
}
