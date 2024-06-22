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
     * @dev Add a new staking token.
     * @param stakingTokenAddress The address of the ERC20 token to be staked.
     * @param rewardRate Reward rate for the token (tokens per week).
     */
    function addStakingToken(address stakingTokenAddress, uint256 rewardRate) external;

    /**
     * @dev Stake tokens to participate in staking.
     * @param stakingTokenAddress The address of the ERC20 token to be staked.
     * @param amount The amount of tokens to stake.
     */
    function stake(address stakingTokenAddress, uint256 amount) external;

    /**
     * @dev Withdraw tokens from staking.
     * @param stakingTokenAddress The address of the ERC20 token to be withdrawn.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(address stakingTokenAddress, uint256 amount) external;

    /**
     * @dev Claim rewards earned from staking.
     * @param stakingTokenAddress The address of the ERC20 token for which rewards are claimed.
     */
    function claimReward(address stakingTokenAddress) external;

    /**
     * @dev Set the reward rate.
     * @param stakingTokenAddress The address of the ERC20 token.
     * @param rewardRate The new reward rate.
     */
    function setRewardRate(address stakingTokenAddress, uint256 rewardRate) external;

    /**
     * @dev Get the address of the reward token.
     * @return The address of the reward token.
     */
    function rewardToken() external view returns (address);

    /**
     * @dev Get the current reward rate for a specific staking token.
     * @param stakingTokenAddress The address of the ERC20 token.
     * @return The current reward rate (tokens per week).
     */
    function rewardRate(address stakingTokenAddress) external view returns (uint256);

    /**
     * @dev Get the total amount of staked tokens for a specific staking token.
     * @param stakingTokenAddress The address of the ERC20 token.
     * @return The total amount of staked tokens (in wei).
     */
    function totalSupply(address stakingTokenAddress) external view returns (uint256);

    /**
     * @dev Get the balance of staked tokens for a user.
     * @param stakingTokenAddress The address of the ERC20 token.
     * @param account The address of the user.
     * @return The balance of staked tokens for the user (in wei).
     */
    function balanceOf(address stakingTokenAddress, address account) external view returns (uint256);

    /**
     * @dev Get the total amount of rewards earned by a user for a specific staking token.
     * @param stakingTokenAddress The address of the ERC20 token.
     * @param account The address of the user.
     * @return The total amount of rewards earned by the user (in wei).
     */
    function getEarnedRewards(address stakingTokenAddress, address account) external view returns (uint256);
}
