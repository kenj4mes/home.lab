// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title HomeLab Token - Example ERC20 for Base L2
/// @notice Demonstration token with mint/burn capabilities
/// @dev Uses OpenZeppelin contracts for security
contract HomelabToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1 billion

    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

    constructor() ERC20("HomeLab Token", "HOME") Ownable(msg.sender) {
        // Mint initial supply to deployer
        _mint(msg.sender, 100_000_000 * 10**18); // 100 million
    }

    /// @notice Mint new tokens (owner only)
    /// @param to Recipient address
    /// @param amount Amount to mint (in wei)
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "HomelabToken: max supply exceeded");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /// @notice Burn tokens from caller
    /// @param amount Amount to burn (in wei)
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /// @notice Get remaining mintable supply
    /// @return Amount that can still be minted
    function remainingSupply() external view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }
}
