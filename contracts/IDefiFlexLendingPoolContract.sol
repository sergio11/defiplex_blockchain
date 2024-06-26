// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDefiFlexLendingPoolContract {
    /**
     * @dev Event emitted when a new loan request is made.
     * @param loanIndex Index of the new loan in the loans array.
     * @param borrower Address of the borrower.
     * @param borrowToken Address of the token being borrowed.
     * @param borrowAmount Amount of tokens being borrowed.
     */
    event LoanRequested(uint256 indexed loanIndex, address indexed borrower, address indexed borrowToken, uint256 borrowAmount);

    /**
     * @dev Event emitted when a loan is approved.
     * @param loanIndex Index of the approved loan in the loans array.
     * @param borrower Address of the borrower.
     * @param collateralAmount Amount of collateral tokens collected.
     */
    event LoanApproved(uint256 indexed loanIndex, address indexed borrower, uint256 indexed collateralAmount);

    /**
     * @dev Event emitted when a loan is repaid.
     * @param loanIndex Index of the repaid loan in the loans array.
     * @param borrower Address of the borrower.
     * @param amount Amount of tokens repaid, including interest and penalties.
     */
    event LoanRepaid(uint256 indexed loanIndex, address indexed borrower, uint256 amount);

    /**
     * @dev Event emitted when collateral is collected.
     * @param loanIndex Index of the loan in the loans array.
     * @param borrower Address of the borrower.
     * @param collateralToken Address of the token used as collateral.
     * @param collateralAmount Amount of collateral tokens collected.
     */
    event CollateralCollected(uint256 indexed loanIndex, address indexed borrower, address indexed collateralToken, uint256 collateralAmount);

    /**
     * @dev Event emitted when a penalty is applied for late repayment.
     * @param loanIndex Index of the loan in the loans array.
     * @param borrower Address of the borrower.
     * @param penaltyAmount Amount of penalty tokens applied.
     */
    event PenaltyApplied(uint256 indexed loanIndex, address indexed borrower, uint256 penaltyAmount);

    /**
     * @dev Request a new loan.
     * @param borrowToken Address of the token to be borrowed.
     * @param borrowAmount Amount of tokens to be borrowed.
     * @param collateralToken Address of the token to be used as collateral.
     * @param collateralAmount Amount of collateral tokens to be provided.
     * @param interestRate Interest rate of the loan in percentage (e.g., 10 for 10%).
     * @param duration Duration of the loan in blocks.
     */
    function requestLoan(
        address borrowToken,
        uint256 borrowAmount,
        address collateralToken,
        uint256 collateralAmount,
        uint256 interestRate,
        uint256 duration
    ) external;

    /**
     * @dev Approve a loan request.
     * @param loanIndex Index of the loan to be approved.
     */
    function approveLoan(uint256 loanIndex) external;

    /**
     * @dev Repay a loan.
     * @param loanIndex Index of the loan to be repaid.
     */
    function repayLoan(uint256 loanIndex) external;

    /**
     * @dev Set the penalty rate for late repayment.
     * @param loanIndex Index of the loan for which to set the penalty rate.
     * @param newPenaltyRate New penalty rate in percentage per week (e.g., 1 for 1% per week).
     */
    function setPenaltyRate(uint256 loanIndex, uint256 newPenaltyRate) external;

    /**
     * @dev Get the total number of loans.
     * @return Total number of loans.
     */
    function getLoanCount() external view returns (uint256);

    /**
     * @dev Get the list of loan indices for a borrower.
     * @param borrower Address of the borrower.
     * @return Array of loan indices.
     */
    function getBorrowerLoans(address borrower) external view returns (uint256[] memory);


    function getLoan(uint256 loanIndex) external view returns(Loan memory);


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
        uint256 penaltyRate;         // Penalty rate for late repayment per week
        uint256 penaltyStartTime;    // Start time to calculate penalties
    }
}
