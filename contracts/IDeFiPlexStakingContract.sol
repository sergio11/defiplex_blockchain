// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Interface for the DeFiPlex Staking contract.
 * @dev This interface defines the functions and events of the DeFiPlex Staking contract.
 */
interface IDeFiPlexStakingContract {

    event StakingTokenAdded(address stakingTokenAddress, uint256 rewardRate);

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
     * @param _newRate The new reward rate.
     */
    event RewardRateSet(uint256 _newRate);

    /**
     * @dev Add a new staking token.
     * @param _stakingTokenAddress The address of the ERC20 token to be staked.
     * @param _rewardRate Reward rate for the token (tokens per week).
     */
    function addStakingToken(address _stakingTokenAddress, uint256 _rewardRate) external;

    /**
     * @dev Stake tokens to participate in staking.
     * @param _stakingTokenAddress The address of the ERC20 token to be staked.
     * @param _amount The amount of tokens to stake.
     */
    function stake(address _stakingTokenAddress, uint256 _amount) external;

    /**
     * @dev Withdraw tokens from staking.
     * @param _stakingTokenAddress The address of the ERC20 token to be withdrawn.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdraw(address _stakingTokenAddress, uint256 _amount) external;

    /**
     * @dev Claim rewards earned from staking.
     * @param _stakingTokenAddress The address of the ERC20 token for which rewards are claimed.
     */
    function claimReward(address _stakingTokenAddress) external;

    /**
     * @dev Set the reward rate.
     * @param _stakingTokenAddress The address of the ERC20 token.
     * @param _rewardRate The new reward rate.
     */
    function setRewardRate(address _stakingTokenAddress, uint256 _rewardRate) external;

    /**
     * @dev Get the address of the reward token.
     * @return The address of the reward token.
     */
    function rewardToken() external view returns (address);

    /**
     * @dev Get the current reward rate for a specific staking token.
     * @param _stakingTokenAddress The address of the ERC20 token.
     * @return The current reward rate (tokens per week).
     */
    function rewardRate(address _stakingTokenAddress) external view returns (uint256);

    /**
     * @dev Get the total amount of staked tokens for a specific staking token.
     * @param _stakingTokenAddress The address of the ERC20 token.
     * @return The total amount of staked tokens (in wei).
     */
    function totalSupply(address _stakingTokenAddress) external view returns (uint256);

    /**
     * @dev Get the balance of staked tokens for a user.
     * @param _stakingTokenAddress The address of the ERC20 token.
     * @param _account The address of the user.
     * @return The balance of staked tokens for the user (in wei).
     */
    function balanceOf(address _stakingTokenAddress, address _account) external view returns (uint256);

    /**
     * @dev Get the pending rewards for a user for a specific staking token
     * @param _stakingTokenAddress Address of the ERC20 token
     * @param _account Address of the user
     * @return Total amount of pending rewards for the user (in wei)
     */
    function getPendingRewards(address _stakingTokenAddress, address _account) external view returns (uint256);

    /**
     * @dev Get the consolidated rewards for a user for a specific staking token
     * @param _stakingTokenAddress Address of the ERC20 token
     * @param _account Address of the user
     * @return Total consolidated rewards for the user (in wei)
     */
    function getConsolidatedRewards(address _stakingTokenAddress, address _account) external view returns (uint256);

    /**
     * @dev Authorize an address to perform token transfers on behalf of the staking contract
     * @param token Address of the ERC20 token
     * @param target Address to authorize
     */
    function authorizeTransfer(address token, address target) external;

    /**
     * @dev Revoke authorization from an address to perform token transfers
     * @param token Address of the ERC20 token
     * @param target Address to revoke authorization from
     */
    function revokeAuthorization(address token, address target) external;


    /**
     * @dev Check if an address is authorized to perform token transfers
     * @param token Address of the ERC20 token
     * @param target Address to check
     * @return True if authorized, false otherwise
     */
    function isAuthorizedTransfer(address token, address target) external view returns (bool);

    /**
     * @dev Transfer ERC20 tokens from the staking contract to a target address
     * @param token Address of the ERC20 token
     * @param target Address to which tokens will be transferred
     * @param amount Amount of tokens to transfer
     */
    function transferTokensTo(address token, address target, uint256 amount) external;
}
