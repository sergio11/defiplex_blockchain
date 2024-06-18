// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Interface for the DefiFlex Staking contract.
 * @dev This interface defines the functions and events of the DefiFlex Staking contract.
 */
interface IDefiFlexStakingContract {
    /**
     * @dev Emitted when a user stakes tokens.
     * @param user The address of the user who staked tokens.
     * @param amount The amount of tokens staked.
     */
    event Staked(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user withdraws tokens.
     * @param user The address of the user who withdrew tokens.
     * @param amount The amount of tokens withdrawn.
     */
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * @dev Emitted when a user claims rewards.
     * @param user The address of the user who claimed rewards.
     * @param amount The amount of rewards claimed.
     */
    event RewardClaimed(address indexed user, uint256 amount);

    /**
     * @dev Emitted when the reward rate is set.
     * @param newRate The new reward rate.
     */
    event RewardRateSet(uint256 newRate);

    /**
     * @dev Stake tokens to participate in staking.
     * @param amount The amount of tokens to stake.
     */
    function stake(uint256 amount) external;

    /**
     * @dev Withdraw tokens from staking.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(uint256 amount) external;

    /**
     * @dev Claim rewards earned from staking.
     */
    function claimReward() external;

    /**
     * @dev Set the reward rate.
     * @param rewardRate The new reward rate.
     */
    function setRewardRate(uint256 rewardRate) external;

    /**
     * @dev Get the address of the staking token.
     */
    function stakingToken() external view returns (address);

    /**
     * @dev Get the address of the reward token.
     */
    function rewardToken() external view returns (address);

    /**
     * @dev Get the current reward rate.
     */
    function rewardRate() external view returns (uint256);

    /**
     * @dev Get the amount of rewards already paid to a user.
     * @param account The address of the user.
     */
    function userRewardPerTokenPaid(address account) external view returns (uint256);

    /**
     * @dev Get the total amount of staked tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Get the balance of staked tokens for a user.
     * @param account The address of the user.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Get the total amount of rewards earned by a user.
     * @param account The address of the user.
     */
    function getEarnedRewards(address account) external view returns (uint256);
}