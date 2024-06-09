// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FlexTokenERC20Contract is ERC20Burnable, Ownable {
    uint256 private constant INITIAL_SUPPLY = 1000000 * 10 ** 18; // 1,000,000 tokens with 18 decimals

    constructor() ERC20("Flex Token", "FLEX") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Function to allow transfer of tokens from owner to multiple addresses
    function multiTransfer(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(owner(), recipients[i], amounts[i]);
            totalAmount += amounts[i];
        }
        require(balanceOf(owner()) >= totalAmount, "Insufficient balance");
    }
}
