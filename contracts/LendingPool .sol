// contracts/LendingPool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LendingPool is Ownable {
    IERC20 public stakingToken;

    struct Loan {
        uint256 amount;
        uint256 interestRate; // Interest rate in percentage (e.g., 10 for 10%)
        uint256 duration; // Duration in blocks
        uint256 startTime; // Start time of the loan
        address borrower;
        bool repaid;
    }

    Loan[] public loans;
    mapping(address => uint256) public borrowerLoanIndex;

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }

    function requestLoan(uint256 amount, uint256 interestRate, uint256 duration) external {
        require(borrowerLoanIndex[msg.sender] == 0, "Borrower already has a loan");
        loans.push(Loan(amount, interestRate, duration, block.timestamp, msg.sender, false));
        borrowerLoanIndex[msg.sender] = loans.length;
    }

    function approveLoan(uint256 loanIndex) external onlyOwner {
        Loan storage loan = loans[loanIndex];
        require(!loan.repaid, "Loan already repaid");
        require(stakingToken.balanceOf(address(this)) >= loan.amount, "Insufficient funds");
        stakingToken.transfer(loan.borrower, loan.amount);
    }

    function repayLoan() external {
        uint256 loanIndex = borrowerLoanIndex[msg.sender];
        Loan storage loan = loans[loanIndex];
        require(!loan.repaid, "Loan already repaid");
        uint256 interestAmount = loan.amount * loan.interestRate * (block.timestamp - loan.startTime) / 100 / loan.duration;
        uint256 repaymentAmount = loan.amount + interestAmount;
        stakingToken.transferFrom(msg.sender, address(this), repaymentAmount);
        loan.repaid = true;
    }
}