const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const secret = require('../../.secret.json');

module.exports = buildModule("DeFiPlex", (m) => {
  const plexTokenERC20Contract = m.contract("PlexTokenERC20Contract", [secret.ownerKey]);
  const deFiPlexStakingContract = m.contract("DeFiPlexStakingContract", [secret.ownerKey, plexTokenERC20Contract]);
  const deFiPlexGovernanceTokenContract = m.contract("DeFiPlexGovernanceTokenContract", [secret.ownerKey]);
  const deFiPlexGovernanceContract = m.contract("DeFiPlexGovernanceContract", [secret.ownerKey, deFiPlexGovernanceTokenContract, 1000]);
  const deFiPlexLendingPoolContract = m.contract("DeFiPlexLendingPoolContract", [secret.ownerKey, deFiPlexStakingContract, deFiPlexGovernanceContract]);
  return { plexTokenERC20Contract, deFiPlexStakingContract, deFiPlexLendingPoolContract, deFiPlexGovernanceTokenContract, deFiPlexGovernanceContract };
});