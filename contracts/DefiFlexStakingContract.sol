// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDefiFlexStakingContract.sol";

/**
 * @title DefiFlex Staking Contract
 * @dev A contract that allows users to stake multiple ERC20 tokens and earn rewards over time.
 */
contract DefiFlexStakingContract is Ownable, IDefiFlexStakingContract {
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
     * @param stakingTokenAddress Address of the ERC20 token to be staked
     * @param rewardRate Reward rate for the token (tokens per week)
     */
    function addStakingToken(address stakingTokenAddress, uint256 rewardRate) external onlyOwner {
        StakingInfo storage info = _stakingInfos[stakingTokenAddress];
        require(address(info.stakingToken) == address(0), "Staking token already added");

        info.stakingToken = IERC20(stakingTokenAddress);
        info.rewardRate = rewardRate;
    }

    /**
     * @dev Stake ERC20 tokens into the contract
     * @param stakingTokenAddress Address of the ERC20 token to be staked
     * @param amount The amount of tokens to stake
     */
    function stake(address stakingTokenAddress, uint256 amount) external override updateReward(stakingTokenAddress, msg.sender) {
        require(amount > 0, "Cannot stake 0 tokens");
        StakingInfo storage info = _stakingInfos[stakingTokenAddress];

        info.totalSupply += amount;
        info.userStakedAmount[msg.sender] += amount;

        if (info.userLastStakedTime[msg.sender] == 0) {
            info.userLastStakedTime[msg.sender] = block.timestamp;
        }

        info.stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Withdraw ERC20 tokens from the contract
     * @param stakingTokenAddress Address of the ERC20 token to be withdrawn
     * @param amount The amount of tokens to withdraw
     */
    function withdraw(address stakingTokenAddress, uint256 amount) external override updateReward(stakingTokenAddress, msg.sender) {
        require(amount > 0, "Cannot withdraw 0 tokens");
        StakingInfo storage info = _stakingInfos[stakingTokenAddress];

        info.totalSupply -= amount;
        info.userStakedAmount[msg.sender] -= amount;

        info.stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Claim accumulated rewards
     * @param stakingTokenAddress Address of the ERC20 token for which rewards are claimed
     */
    function claimReward(address stakingTokenAddress) external override updateReward(stakingTokenAddress, msg.sender) {
        StakingInfo storage info = _stakingInfos[stakingTokenAddress];
        uint256 reward = info.userRewards[msg.sender];
        require(reward > 0, "No reward to claim");

        info.userRewards[msg.sender] = 0;
        info.userLastStakedTime[msg.sender] = block.timestamp;

        _rewardToken.safeTransfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    /**
     * @dev Set the reward rate for a specific staking token
     * @param stakingTokenAddress Address of the ERC20 token
     * @param rewardRate The new reward rate (tokens per week)
     */
    function setRewardRate(address stakingTokenAddress, uint256 rewardRate) external override onlyOwner {
        StakingInfo storage info = _stakingInfos[stakingTokenAddress];
        require(address(info.stakingToken) != address(0), "Staking token not found");

        info.rewardRate = rewardRate;
        emit RewardRateSet(rewardRate);
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
     * @param stakingTokenAddress Address of the ERC20 token
     * @return Current reward rate (tokens per week)
     */
    function rewardRate(address stakingTokenAddress) external view override returns (uint256) {
        return _stakingInfos[stakingTokenAddress].rewardRate;
    }

    /**
     * @dev Get the total amount of staked tokens for a specific staking token
     * @param stakingTokenAddress Address of the ERC20 token
     * @return Total amount of staked tokens (in wei)
     */
    function totalSupply(address stakingTokenAddress) external view override returns (uint256) {
        return _stakingInfos[stakingTokenAddress].totalSupply;
    }

    /**
     * @dev Get the balance of staked tokens for a user
     * @param stakingTokenAddress Address of the ERC20 token
     * @param account Address of the user
     * @return Balance of staked tokens for the user (in wei)
     */
    function balanceOf(address stakingTokenAddress, address account) external view override returns (uint256) {
        return _stakingInfos[stakingTokenAddress].userStakedAmount[account];
    }

    /**
     * @dev Get the total amount of rewards earned by a user for a specific staking token
     * @param stakingTokenAddress Address of the ERC20 token
     * @param account Address of the user
     * @return Total amount of rewards earned by the user (in wei)
     */
    function getEarnedRewards(address stakingTokenAddress, address account) external view override returns (uint256) {
        StakingInfo storage info = _stakingInfos[stakingTokenAddress];
        uint256 timeElapsed = block.timestamp - info.userLastStakedTime[account];
        return (info.userStakedAmount[account] * info.rewardRate * timeElapsed) / (1 weeks);
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

        uint256 reward = this.getEarnedRewards(stakingTokenAddress, account);
        info.userRewards[account] += reward;
        info.userLastStakedTime[account] = block.timestamp;
    }
}
