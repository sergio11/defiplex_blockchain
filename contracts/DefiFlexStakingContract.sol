// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDefiFlexStakingContract.sol";

/**
 * @title DefiFlex Staking Contract
 * @dev A contract that allows users to stake ERC20 tokens and earn rewards over time.
 */
contract DefiFlexStakingContract is Ownable, IDefiFlexStakingContract {
    using SafeERC20 for IERC20;

    // ERC20 token instances for staking and rewards
    IERC20 private _stakingToken;
    IERC20 private _rewardToken;

    // Reward rate in tokens per week
    uint256 private _rewardRate = 100;

    // Total amount of tokens staked
    uint256 private _totalSupply;

    // Mapping to track each user's last staked time
    mapping(address => uint256) private _userLastStakedTime;

    // Mapping to track each user's staked amount
    mapping(address => uint256) private _userStakedAmount;

    // Mapping to track each user's accumulated rewards
    mapping(address => uint256) private _userRewards;

    /**
     * @dev Constructor function
     * @param stakingTokenAddress Address of the ERC20 token to be staked
     * @param rewardTokenAddress Address of the ERC20 token used as rewards
     */
    constructor(address initialOwner, address stakingTokenAddress, address rewardTokenAddress) Ownable(initialOwner) {
        _stakingToken = IERC20(stakingTokenAddress);
        _rewardToken = IERC20(rewardTokenAddress);
    }

    /**
     * @dev Modifier to update the user's rewards before executing a function
     * @param account Address of the user whose rewards will be updated
     */
    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }

    /**
     * @dev Stake ERC20 tokens into the contract
     * @param amount The amount of tokens to stake
     */
    function stake(uint256 amount) external override updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0 tokens");
        _totalSupply += amount;
        _userStakedAmount[msg.sender] += amount;
        if (_userLastStakedTime[msg.sender] == 0) {
            _userLastStakedTime[msg.sender] = block.timestamp;
        }
        _stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Withdraw ERC20 tokens from the contract
     * @param amount The amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external override updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0 tokens");
        _totalSupply -= amount;
        _userStakedAmount[msg.sender] -= amount;
        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Claim accumulated rewards
     */
    function claimReward() external override updateReward(msg.sender) {
        uint256 reward = _userRewards[msg.sender];
        require(reward > 0, "No reward to claim");
        _userRewards[msg.sender] = 0;
        _userLastStakedTime[msg.sender] = block.timestamp;
        _rewardToken.safeTransfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    /**
     * @dev Set the reward rate
     * @param rewardRate The new reward rate (tokens per week)
     */
    function setRewardRate(uint256 rewardRate) external override onlyOwner {
        _rewardRate = rewardRate;
        emit RewardRateSet(rewardRate);
    }

    /**
     * @dev Get the address of the staking token
     * @return Address of the staking token
     */
    function stakingToken() external view override returns (address) {
        return address(_stakingToken);
    }

    /**
     * @dev Get the address of the reward token
     * @return Address of the reward token
     */
    function rewardToken() external view override returns (address) {
        return address(_rewardToken);
    }

    /**
     * @dev Get the current reward rate
     * @return Current reward rate (tokens per week)
     */
    function rewardRate() external view override returns (uint256) {
        return _rewardRate;
    }

    /**
     * @dev Get the amount of rewards already paid to a user
     * @param account Address of the user
     * @return Amount of rewards already paid (in wei)
     */
    function userRewardPerTokenPaid(address account) external view override returns (uint256) {
        return _userRewards[account];
    }

    /**
     * @dev Get the total amount of staked tokens
     * @return Total amount of staked tokens (in wei)
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Get the balance of staked tokens for a user
     * @param account Address of the user
     * @return Balance of staked tokens for the user (in wei)
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _userStakedAmount[account];
    }

    /**
     * @dev Get the total amount of rewards earned by a user
     * @param account Address of the user
     * @return Total amount of rewards earned by the user (in wei)
     */
    function getEarnedRewards(address account) external view override returns (uint256) {
        uint256 timeElapsed = block.timestamp - _userLastStakedTime[account];
        return _userStakedAmount[account] * _rewardRate * timeElapsed / (1 weeks);
    }

    /**
     * @dev Internal function to update rewards for a user
     * @param account Address of the user
     */
    function _updateReward(address account) private {
        if (_totalSupply == 0) {
            return;
        }
        uint256 reward = this.getEarnedRewards(account);
        _userRewards[account] += reward;
        _userLastStakedTime[account] = block.timestamp;
    }
}
