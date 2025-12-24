# Web3 Development Guide

HomeLab includes a complete Web3/Blockchain development environment pre-configured for Base L2.

## Overview

| Component | Purpose |
|-----------|---------|
| **Hardhat** | Smart contract development, testing, deployment |
| **Foundry** | High-performance Solidity toolkit (forge, cast, anvil) |
| **Base Node** | Local Base L2 blockchain |
| **Blockscout** | Blockchain explorer |
| **OpenZeppelin** | Secure contract libraries |

## Quick Start

### Start Development Environment

```bash
# Linux/WSL
./homelab.sh --action web3

# Windows PowerShell
.\homelab.ps1 -Action start -IncludeWeb3
```

### Create New Project

```bash
# From template
new-web3-project my-dapp
cd my-dapp
pnpm install
```

### Compile & Test

```bash
pnpm compile          # Compile contracts
pnpm test             # Run tests
pnpm test:gas         # Test with gas report
```

### Deploy

```bash
# Local (Anvil)
pnpm anvil &          # Start local node
pnpm deploy           # Deploy to localhost

# Base Sepolia (testnet)
pnpm deploy:sepolia

# Base Mainnet
pnpm deploy:base
```

## Network Configuration

### Available Networks

| Network | Chain ID | RPC URL | Use Case |
|---------|----------|---------|----------|
| localhost | 31337 | http://localhost:8545 | Development |
| anvil | 31337 | http://localhost:8547 | Fast testing |
| homelab-base | 8453 | http://base-node:8545 | Local Base node |
| base | 8453 | https://mainnet.base.org | Production |
| base-sepolia | 84532 | https://sepolia.base.org | Testnet |

### Environment Variables

Create `.env` in your project:

```env
# NEVER commit real private keys!
DEPLOYER_PRIVATE_KEY=0x...

# API Keys for contract verification
BASESCAN_API_KEY=your_key
ETHERSCAN_API_KEY=your_key

# RPC Endpoints (optional overrides)
BASE_MAINNET_RPC=https://mainnet.base.org
BASE_SEPOLIA_RPC=https://sepolia.base.org
```

## Foundry Tools

### Forge (Compiler/Tester)

```bash
forge build                    # Compile
forge test                     # Run tests
forge test -vvvv               # Verbose output
forge coverage                 # Code coverage
```

### Cast (CLI for Ethereum)

```bash
cast balance 0x...             # Get ETH balance
cast call <addr> "method()"    # Call view function
cast send <addr> "method()"    # Send transaction
cast abi-encode "method(uint)" 123
```

### Anvil (Local Node)

```bash
anvil                          # Start with defaults
anvil --fork-url $RPC          # Fork mainnet
anvil --block-time 1           # Auto-mine every second
```

### Chisel (Solidity REPL)

```bash
chisel                         # Interactive Solidity
```

## Example Contracts

### ERC20 Token

```solidity
// contracts/MyToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("My Token", "MTK") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}
```

### NFT Collection

```solidity
// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721URIStorage, Ownable {
    uint256 private _tokenIds;

    constructor() ERC721("My NFT", "MNFT") Ownable(msg.sender) {}

    function mint(address to, string memory tokenURI) external onlyOwner returns (uint256) {
        _tokenIds++;
        _mint(to, _tokenIds);
        _setTokenURI(_tokenIds, tokenURI);
        return _tokenIds;
    }
}
```

## Docker Services

### Start All Web3 Services

```bash
docker compose -f docker-compose.dev.yml up -d
```

### Individual Services

```bash
# Anvil only (fast local node)
docker compose -f docker-compose.dev.yml up -d anvil

# With Base fork (requires internet)
docker compose -f docker-compose.dev.yml --profile online up -d anvil-base-fork

# Full dev environment with explorer
docker compose -f docker-compose.dev.yml --profile full up -d
```

## Offline Development

The Web3 stack is designed for offline-first development:

1. **Anvil**: Runs locally, no RPC needed
2. **Cached Dependencies**: Pre-installed in container
3. **OpenZeppelin**: Bundled in project

```bash
# Cache everything for offline
./scripts/offline-sync.sh --full

# Work completely offline
docker compose -f docker-compose.dev.yml up -d anvil
pnpm compile
pnpm test
pnpm deploy  # Deploys to local Anvil
```

## Security Best Practices

1. **Never commit private keys** - Use environment variables
2. **Audit contracts** - Run slither analysis:
   ```bash
   slither contracts/
   ```
3. **Test thoroughly** - Aim for 100% coverage:
   ```bash
   forge coverage
   ```
4. **Use OpenZeppelin** - Battle-tested implementations
5. **Verify on Basescan** - After deployment:
   ```bash
   pnpm verify --network base
   ```

## Resources

- [Hardhat Documentation](https://hardhat.org/docs)
- [Foundry Book](https://book.getfoundry.sh/)
- [Base Documentation](https://docs.base.org/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Solidity by Example](https://solidity-by-example.org/)

## Troubleshooting

### "Cannot connect to network"

Check that Anvil or Hardhat node is running:
```bash
docker ps | grep anvil
curl http://localhost:8547
```

### "Insufficient funds"

Anvil provides 10 test accounts with 10,000 ETH each. Use the first account:
```
Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### "Contract verification failed"

Ensure API key is set and network is correct:
```bash
BASESCAN_API_KEY=... pnpm verify --network base <address>
```
