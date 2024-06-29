# 🌐 DeFiPlex - Decentralized Finance Platform on Polygon

🌐 DeFiPlex is a comprehensive decentralized finance (DeFi) platform built on the Polygon blockchain, a Layer 2 scaling solution for Ethereum. It aims to facilitate a wide array of decentralized financial activities, making it accessible and efficient for users across the globe. Whether users are looking to stake their assets to earn rewards, participate in decentralized lending and borrowing markets, or engage in community-driven governance decisions, DeFiPlex provides a seamless and secure environment.

🔗 Powered by smart contracts, DeFiPlex ensures unparalleled transparency by executing transactions in a trustless manner, thereby eliminating the need for intermediaries. Security is paramount, with robust protocols and audits in place to safeguard user funds and maintain the integrity of the platform.

<p align="center">
  <img src="https://img.shields.io/badge/Solidity-2E8B57?style=for-the-badge&logo=solidity&logoColor=white" />
  <img src="https://img.shields.io/badge/Alchemy-039BE5?style=for-the-badge&logo=alchemy&logoColor=white" />
  <img src="https://img.shields.io/badge/Remix IDE-3e5f8a?style=for-the-badge&logo=remix&logoColor=white" />
  <img src="https://img.shields.io/badge/Hardhat-E6522C?style=for-the-badge&logo=hardhat&logoColor=white" />
  <img src="https://img.shields.io/badge/Ethereum-3C3C3D?style=for-the-badge&logo=Ethereum&logoColor=white" />
  <img src="https://img.shields.io/badge/Smart%20Contracts-8B0000?style=for-the-badge&logo=Ethereum&logoColor=white" />
</p>

### Key Features

- 🔐 **Staking**: Users can stake their tokens in DeFiPlex to earn rewards, securing the network and earning passive income based on their stake amount and duration.

- 💰 **Reward Distribution**: DeFiPlex distributes rewards to users who stake their tokens. Rewards are calculated based on the staked amount and duration, available for periodic claiming.

- 💸 **Lending and Borrowing**: The platform allows users to lend and borrow assets directly, earning interest by lending assets or paying interest to borrow assets, thereby creating a decentralized money market.

- 🗳️ **Governance**: DeFiPlex incorporates a robust decentralized governance framework empowering token holders to actively participate in decision-making, including loan approval processes. The community votes on key proposals related to loan approvals, ensuring transparent and democratic decision-making reflecting the collective interests of platform users.

### Smart Contracts

- 📜 **Staking Contract**: Manages token deposits, tracks user balances, calculates staking rewards, and facilitates reward claims.

- 📜 **Lending Pool Contract**: Enables lending and borrowing functionalities, manages loan requests, and ensures loan repayment mechanisms.

- 📜 **Governance Token (FlexTokenERC20Contract)**: Implements the governance token used for voting and decision-making within the platform.

- 📜 **Governance Contract (DefiFlexGovernanceContract)**: Facilitates governance processes by managing proposals and ensuring transparent voting mechanisms. It requires a minimum threshold of votes over a specified voting period for loan approvals, ensuring community consensus.

## UML Design Diagram
Complete UML diagram of decentralized application design.

<img width="auto" src="./doc/diagram.svg" />

### Governance Mechanism for Loan Approval 📜🗳️
The DeFiPlex governance system plays a crucial role in loan approval processes. Here are its key components:

* **Proposal Creation: 📝** Users can create loan proposals detailing loan conditions, terms, and collateral requirements.

* **Voting: 🗳️** Token holders participate in governance by voting on submitted loan proposals. Each token represents one vote, encouraging active participation and stakeholder engagement.

* **Threshold Requirements: 📊** Loan proposals must meet a minimum threshold of votes during a specified voting period to be approved. This ensures robust community backing and consensus before final approval.

* **Execution: 🚀** Once a loan proposal meets the voting requirements, it is automatically executed via smart contracts. This includes disbursing loan funds and implementing agreed-upon terms.

### Security Considerations

- 🔍 **Auditing**: All smart contracts undergo rigorous audits conducted by reputable security firms to ensure robustness and protection against vulnerabilities.

- 🔒 **Access Control**: Critical parameters such as reward rates are securely controlled, with restricted access limited to authorized entities only.

- 🧪 **Testing**: Comprehensive testing is conducted on testnets prior to mainnet deployment to validate contract functionality and security measures.

DeFiPlex is committed to providing a secure and versatile platform for decentralized financial activities. By leveraging smart contracts and the Polygon blockchain, DeFiPlex offers a transparent and efficient way to engage in staking, lending, borrowing, and governance processes.

### Technology Stack

DeFiPlex leverages a robust technology stack to ensure scalability, security, and efficiency across its decentralized finance platform:

- 🛠️ **Polygon Blockchain**: DeFiPlex is built on the Polygon blockchain, benefiting from its high throughput, low transaction fees, and interoperability with Ethereum.

- 💻 **Solidity**: Smart contracts in DeFiPlex are written in Solidity, the predominant programming language for Ethereum-compatible blockchains, ensuring compatibility and reliability.

- 📦 **OpenZeppelin**: OpenZeppelin's library is extensively used for secure and standardized smart contract components. It provides tested and audited implementations of ERC standards and contract functionalities, enhancing security and reliability.

- ⚙️ **Hardhat**: Hardhat serves as the development environment for DeFiPlex, facilitating tasks such as compiling, testing, and deploying smart contracts. It supports a wide range of plugins and tools essential for robust contract development and deployment.

### Key Technologies Explained 🛠️📚

#### Polygon Blockchain 🔷

Polygon provides a scalable and Ethereum-compatible platform that enhances transaction speeds and reduces costs compared to the Ethereum mainnet. DeFiPlex leverages Polygon’s Layer 2 solutions to ensure fast transaction finality and a seamless user experience.

#### Solidity 🖋️

Solidity is the programming language of choice for developing smart contracts on Ethereum and compatible blockchains. It enables developers to write secure and efficient contracts, ensuring compatibility with the broader Ethereum ecosystem and facilitating seamless integration with decentralized applications (dApps).

#### OpenZeppelin 🔒

OpenZeppelin is a library of reusable and secure smart contract components widely adopted within the blockchain community. DeFiPlex utilizes OpenZeppelin's tested implementations of ERC standards and contract functionalities to enhance security and mitigate potential vulnerabilities.

#### Hardhat 🎩

Hardhat is a popular development environment tailored for Ethereum smart contract development. It offers built-in support for tasks such as compiling, testing, debugging, and deploying smart contracts, streamlining the development lifecycle and ensuring the reliability of deployed contracts.

The technology stack behind DeFiPlex underscores its commitment to delivering a secure, scalable, and efficient decentralized finance platform. By leveraging Polygon's blockchain, Solidity smart contracts, OpenZeppelin's library, and the Hardhat development environment, DeFiPlex ensures robustness, security, and interoperability while offering a seamless user experience for staking, lending, borrowing, and governance activities.

## 🛠️ Installation
First, clone the repository:

```bash
git clone https://github.com/sergio11/defiplex_blockchain.git
cd defiplex_blockchain
```

Install the necessary dependencies:

```bash
npm install
```

## 🚀 Usage

### 📜 Deploying Contracts
Deploying the DeFiPlex smart contracts is a straightforward process using **Hardhat Ignition***. This tool simplifies the deployment process, allowing you to deploy your contracts with ease and confidence. Below is a step-by-step guide to deploying the DeFiPlex contracts to your specified network.

Use the following command to deploy the contracts to the specified network (in this case, Polygon amoy):

```shell
npx hardhat ignition deploy ignition/modules/DefiPlex.js --network amoy   
```

Deploying your DeFiPlex contracts with Hardhat Ignition ensures a smooth, efficient, and error-free process, paving the way for a robust and transparent DeFi system.

## 🧪 Testing
Testing is a critical part of the development process for ensuring that our smart contracts function correctly and securely. The DeFiPlex project includes comprehensive test suites for all the contracts. These tests cover a wide range of scenarios to ensure robustness and reliability.

### Running the Tests
To run the tests, use the following command:

```shell
npx hardhat test
```

This command will execute all the test scripts located in the test directory, and you should see output similar to the following:

```shell
DeFiPlexGovernanceContract
    ✔ Should deploy the contract correctly
    ✔ Should allow setting minimum votes required
    ✔ Should allow setting voting period
    ✔ Should propose a loan request
    ✔ Should vote on a proposal
    ✔ Should not approve a proposal if criteria are not met
    ✔ Should approve a proposal if criteria are met
    ✔ Should not approve a proposal if there are votes against it
    ✔ Should revert on trying to vote on non-existent proposal (38ms)
    ✔ Should revert on trying to propose with same ID
    ✔ Should revert when user tries to vote again
    ✔ Should revert when user tries to vote outside voting period
    ✔ Should retrieve correct details of a loan proposal

  DeFiPlexLendingPoolContract
    Loan Requests
      ✔ Should allow users to request a loan
      ✔ Should revert if loan amount is zero
      ✔ Should revert if interest rate is zero
      ✔ Should revert if collateral amount is zero
      ✔ Should revert if duration is zero
    Loan Queries
      ✔ Should return borrower loans correctly
      ✔ Should revert if no loans found for borrower
      ✔ Should return loan details correctly
      ✔ Should revert if loan index is out of bounds
    Loan Approval
      ✔ Should be rejected because insufficient borrow token amount in lending pool
      ✔ Should be rejected because borrower does not have enough collateral tokens
      ✔ Should be rejected because collateral already collected
      ✔ Should be rejected because the loan proposal has not been approved by governance
      ✔ Should be approved successfully
    Loan Repayment
      ✔ Should be rejected because the loan duration not expired yet
      ✔ Should be repay successfuly
      ✔ Should be rejected because loan is already repaid
      ✔ Should be rejected because Only the borrower can repay the loan
      ✔ Should be repay successfuly penalty (45ms)

  DeFiPlexStakingContract
    ✔ Should set the right owner
    Adding Staking Tokens
      ✔ Should allow the owner to add staking tokens
      ✔ Should not allow non-owners to add staking tokens
      ✔ Should not allow adding the same staking token more than once
      ✔ Should revert when adding a staking token with a reward rate of zero
      ✔ Should correctly store staking token info after adding
      ✔ Should emit StakingTokenAdded event when a new staking token is added
      ✔ Should revert if trying to add a staking token with a non-contract address
      ✔ Should not allow adding staking tokens with extremely high reward rates
    Staking Tokens
      ✔ Should allow users to stake tokens
      ✔ Should not allow staking zero tokens
      ✔ Should allow multiple users to stake tokens
      ✔ Should not allow staking more tokens than available
      ✔ Should allow stake and withdraw tokens
      ✔ Should revert if user tries to withdraw more than staked
      ✔ Should revert if contract has insufficient funds for withdrawal
    Withdrawing Tokens
      ✔ Should allow users to withdraw all staked tokens
      ✔ Should not allow withdrawing more tokens than staked
      ✔ Should allow withdrawing tokens and update rewards
      ✔ Should allow withdrawing tokens and update rewards 2
    Claiming Rewards
      ✔ Should allow users to claim rewards
      ✔ Should update user reward after claiming
      ✔ Should not allow claiming zero rewards
      ✔ Should not affect staked balance after claiming rewards
      ✔ Should revert if user tries to claim rewards with no staked tokens
      ✔ Should revert if user tries to claim rewards with no rewards available
    Setting Reward Rate
      ✔ Should allow the owner to set the reward rate
      ✔ Should not allow non-owners to set the reward rate
    Getting Information
      ✔ Should return the correct total supply
      ✔ Should return the correct balance of user
      ✔ Should return the correct earned rewards
      ✔ Should return the correct total rewards accumulated

  PlexTokenERC20Contract
    Deployment
      ✔ Should set the right owner
      ✔ Should assign the initial supply to the owner
    Minting
      ✔ Should allow the owner to mint tokens
      ✔ Should not allow non-owners to mint tokens
    Burning
      ✔ Should allow users to burn their tokens
    MultiTransfer
      ✔ Should allow the owner to transfer tokens to multiple addresses
      ✔ Should not allow non-owners to execute multiTransfer
      ✔ Should revert if arrays length mismatch


  72 passing (9s)
```

You can also use ganache to carry out the tests, for this it is only necessary to use the network option

```shell
npx hardhat --network ganache test
```

Tests provide comprehensive coverage of all smart contract functionalities.
