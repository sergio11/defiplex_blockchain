// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DefiFlexStakingContract is Ownable {
    using SafeERC20 for IERC20;

    IERC20 private _stakingToken;
    IERC20 private _rewardToken;

    // Reward rate (tokens per week)
    uint256 private rewardRate = 700;

    // Last timestamp when rewards were updated
    uint256 private lastUpdateTime;

    // Reward per token stored
    uint256 private rewardPerTokenStored;

    // Mapping to track user reward per token paid
    mapping(address => uint256) private userRewardPerTokenPaid;

    // Mapping to track user rewards
    mapping(address => uint256) private rewards;

    // Total staked tokens
    uint256 private _totalSupply;

    // Mapping to track staked balances of users
    mapping(address => uint256) private _balances;

    // Array to keep track of all stakers
    address[] private stakers;

    constructor(address stakingToken, address rewardToken) {
        _stakingToken = IERC20(stakingToken);
        _rewardToken = IERC20(rewardToken);
        lastUpdateTime = block.timestamp;
    }

    // Function to update all users' rewards
    function updateAllRewards() public {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        for (uint256 i = 0; i < stakers.length; i++) {
            address account = stakers[i];
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    // Function to stake tokens
    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0 tokens");
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        if (_balances[msg.sender] == amount) {
            stakers.push(msg.sender); // Only add to stakers list if it's a new staker
        }
        _stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    // Function to withdraw staked tokens
    function withdraw(uint256 amount) external {
        require(amount > 0, "Cannot withdraw 0 tokens");
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        if (_balances[msg.sender] == 0) {
            // Remove from stakers array
            for (uint256 i = 0; i < stakers.length; i++) {
                if (stakers[i] == msg.sender) {
                    stakers[i] = stakers[stakers.length - 1];
                    stakers.pop();
                    break;
                }
            }
        }
        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    // Function to claim rewards
    function claimReward() external {
        uint256 reward = earned(msg.sender);
        require(reward > 0, "No reward to claim");
        rewards[msg.sender] = 0;
        userRewardPerTokenPaid[msg.sender] = rewardPerTokenStored;
        _rewardToken.safeTransfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    // Function to set reward rate
    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        updateAllRewards();
        rewardRate = _rewardRate;
        emit RewardRateSet(rewardRate);
    }

    // Function to view total supply
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // Function to view balance of an account
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // Function to calculate reward per token
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + ((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / (_totalSupply * 1 weeks);
    }

    // Function to calculate earned rewards for an account
    function earned(address account) public view returns (uint256) {
        return (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 + rewards[account];
    }
}
