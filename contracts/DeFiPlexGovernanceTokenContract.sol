// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DeFiPlexGovernanceTokenContract
 * @dev Implementation of a governance token allowing holders to vote on proposals.
 */
contract DeFiPlexGovernanceTokenContract is ERC20, Ownable {

    /**
     * @dev Constructor that initializes the contract with the token's name and symbol.
     */
    constructor(address initialOwner) ERC20("DeFiPlex Governance Token", "DFXGOV") Ownable(initialOwner) {}

    /**
     * @dev Function for the contract owner to mint new governance tokens.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Function for the contract owner to burn existing governance tokens.
     * @param from The address from which to burn tokens.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
