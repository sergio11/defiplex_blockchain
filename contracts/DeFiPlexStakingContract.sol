// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDeFiPlexStakingContract.sol";

/**
 * @title DeFiPlex Staking Contract
 * @dev A contract that allows users to stake multiple ERC20 tokens and earn rewards over time.
 */
contract DeFiPlexStakingContract is Ownable, IDeFiPlexStakingContract {
    using SafeERC20 for IERC20;

    struct StakingInfo {
        IERC20 stakingToken;
        uint256 totalSupply;
        uint256 rewardRate;
        mapping(address => uint256) userStakedAmount;
        mapping(address => uint256) userLastStakedTime;
        mapping(address => uint256) userRewards;
    }

    // Reward token instance 
    IERC20 private _rewardToken;

    // Maximum reward rate allowed (e.g., 100 tokens per week)
    uint256 private constant MAX_REWARD_RATE = 100;

    // Mapping from token address to staking info
    mapping(address => StakingInfo) private _stakingInfos;

    /**
     * @dev Constructor function
     * @param rewardTokenAddress Address of the ERC20 token used as rewards
     */
    constructor(address initialOwner, address rewardTokenAddress) Ownable(initialOwner) {
        _rewardToken = IERC20(rewardTokenAddress);
    }

    /**
     * @dev Modifier to update the user's rewards before executing a function
     * @param stakingTokenAddress Address of the staking token
     * @param account Address of the user whose rewards will be updated
     */
    modifier updateReward(address stakingTokenAddress, address account) {
        _updateReward(stakingTokenAddress, account);
        _;
    }

    /**
     * @dev Add a new staking token
     * @param _stakingTokenAddress Address of the ERC20 token to be staked
     * @param _rewardRate Reward rate for the token (tokens per week)
     */
    function addStakingToken(address _stakingTokenAddress, uint256 _rewardRate) external override onlyOwner {
        require(_rewardRate > 0, "Cannot add staking token with 0 reward rate");
        require(_rewardRate <= MAX_REWARD_RATE, "Reward rate exceeds maximum allowed");
        require(_stakingTokenAddress != address(0), "Invalid token address");
        // Check if the address is a contract (basic verification)
        uint256 size;
        assembly {
            size := extcodesize(_stakingTokenAddress)
        }
        require(size > 0, "Address is not a contract");
        StakingInfo storage info = _stakingInfos[_stakingTokenAddress];
        require(address(info.stakingToken) == address(0), "Staking token already added");

        info.stakingToken = IERC20(_stakingTokenAddress);
        info.rewardRate = _rewardRate;

        emit StakingTokenAdded(_stakingTokenAddress, _rewardRate);
    }

    /**
     * @dev Stake ERC20 tokens into the contract
     * @param _stakingTokenAddress Address of the ERC20 token to be staked
     * @param _amount The amount of tokens to stake
     */
    function stake(address _stakingTokenAddress, uint256 _amount) external override updateReward(_stakingTokenAddress, msg.sender) {
        require(_amount > 0, "Cannot stake 0 tokens");
        StakingInfo storage info = _stakingInfos[_stakingTokenAddress];
        // Check if the user has enough balance to stake
        uint256 userBalance = info.stakingToken.balanceOf(msg.sender);
        require(userBalance >= _amount, "Insufficient funds to stake");

        info.totalSupply += _amount;
        info.userStakedAmount[msg.sender] += _amount;

        if (info.userLastStakedTime[msg.sender] == 0) {
            info.userLastStakedTime[msg.sender] = block.timestamp;
        }

        info.stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    /**
     * @dev Withdraw ERC20 tokens from the contract
     * @param _stakingTokenAddress Address of the ERC20 token to be withdrawn
     * @param _amount The amount of tokens to withdraw
     */
    function withdraw(address _stakingTokenAddress, uint256 _amount) external override updateReward(_stakingTokenAddress, msg.sender) {
        require(_amount > 0, "Cannot withdraw 0 tokens");
        StakingInfo storage info = _stakingInfos[_stakingTokenAddress];
        require(info.userStakedAmount[msg.sender] >= _amount, "Insufficient staked amount");

        uint256 contractBalance = info.stakingToken.balanceOf(address(this));
        require(contractBalance >= _amount, "Insufficient funds in the contract");

        info.totalSupply -= _amount;
        info.userStakedAmount[msg.sender] -= _amount;

        info.stakingToken.safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    /**
     * @dev Claim accumulated rewards
     * @param _stakingTokenAddress Address of the ERC20 token for which rewards are claimed
     */
    function claimReward(address _stakingTokenAddress) external updateReward(_stakingTokenAddress, msg.sender) {
        StakingInfo storage info = _stakingInfos[_stakingTokenAddress];
        uint256 stakedAmount = info.userStakedAmount[msg.sender];
        require(stakedAmount > 0, "No staked tokens to claim reward");

        uint256 reward = info.userRewards[msg.sender];
        require(reward > 0, "No reward to claim");

        info.userRewards[msg.sender] = 0;
        info.userLastStakedTime[msg.sender] = block.timestamp;

        _rewardToken.safeTransfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    /**
     * @dev Set the reward rate for a specific staking token
     * @param _stakingTokenAddress Address of the ERC20 token
     * @param _rewardRate The new reward rate (tokens per week)
     */
    function setRewardRate(address _stakingTokenAddress, uint256 _rewardRate) external override onlyOwner {
        StakingInfo storage info = _stakingInfos[_stakingTokenAddress];
        require(address(info.stakingToken) != address(0), "Staking token not found");

        info.rewardRate = _rewardRate;
        emit RewardRateSet(_rewardRate);
    }

    /**
     * @dev Get the address of the reward token
     * @return Address of the reward token
     */
    function rewardToken() external view override returns (address) {
        return address(_rewardToken);
    }

    /**
     * @dev Get the current reward rate for a specific staking token
     * @param _stakingTokenAddress Address of the ERC20 token
     * @return Current reward rate (tokens per week)
     */
    function rewardRate(address _stakingTokenAddress) external view override returns (uint256) {
        return _stakingInfos[_stakingTokenAddress].rewardRate;
    }

    /**
     * @dev Get the total amount of staked tokens for a specific staking token
     * @param _stakingTokenAddress Address of the ERC20 token
     * @return Total amount of staked tokens (in wei)
     */
    function totalSupply(address _stakingTokenAddress) external view override returns (uint256) {
        return _stakingInfos[_stakingTokenAddress].totalSupply;
    }

    /**
     * @dev Get the balance of staked tokens for a user
     * @param _stakingTokenAddress Address of the ERC20 token
     * @param _account Address of the user
     * @return Balance of staked tokens for the user (in wei)
     */
    function balanceOf(address _stakingTokenAddress, address _account) external view override returns (uint256) {
        return _stakingInfos[_stakingTokenAddress].userStakedAmount[_account];
    }

    /**
     * @dev Get the pending rewards for a user for a specific staking token
     * @param _stakingTokenAddress Address of the ERC20 token
     * @param _account Address of the user
     * @return Total amount of pending rewards for the user (in wei)
     */
    function getPendingRewards(address _stakingTokenAddress, address _account) external view returns (uint256) {
        StakingInfo storage info = _stakingInfos[_stakingTokenAddress];
        uint256 timeElapsed = block.timestamp - info.userLastStakedTime[_account];
        return (info.userStakedAmount[_account] * info.rewardRate * timeElapsed) / (1 weeks);
    }

    /**
     * @dev Get the consolidated rewards for a user for a specific staking token
     * @param _stakingTokenAddress Address of the ERC20 token
     * @param _account Address of the user
     * @return Total consolidated rewards for the user (in wei)
     */
    function getConsolidatedRewards(address _stakingTokenAddress, address _account) external view returns (uint256) {
        StakingInfo storage info = _stakingInfos[_stakingTokenAddress];
        return info.userRewards[_account];
    }

    /**
     * @dev Internal function to update rewards for a user
     * @param stakingTokenAddress Address of the ERC20 token
     * @param account Address of the user
     */
    function _updateReward(address stakingTokenAddress, address account) private {
        StakingInfo storage info = _stakingInfos[stakingTokenAddress];
        if (info.totalSupply == 0) {
            return;
        }

        uint256 reward = this.getPendingRewards(stakingTokenAddress, account);
        info.userRewards[account] += reward;
        info.userLastStakedTime[account] = block.timestamp;
    }
}