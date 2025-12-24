# HomeLab Hardhat Development Environment

Smart contract development environment pre-configured for Base L2 blockchain.

## Features

- **Hardhat 3.x** - Latest Ethereum development environment
- **Foundry Integration** - forge, cast, anvil, chisel
- **Base Networks** - Mainnet, Sepolia testnet, local node
- **OpenZeppelin** - Secure contract libraries
- **TypeScript** - Type-safe development

## Quick Start

### Using Docker

```bash
# Build and start
cd docker
docker compose -f docker-compose.dev.yml up hardhat-dev -d

# Access container
docker exec -it hardhat-dev sh

# Inside container
pnpm compile
pnpm test
```

### Using Local Node

```bash
# Start local Ethereum node
pnpm node         # Hardhat node
# or
pnpm anvil        # Foundry's Anvil (faster)
```

### Deploy Contracts

```bash
# Local deployment
pnpm deploy

# Base Sepolia (testnet)
pnpm deploy:sepolia

# Base Mainnet
pnpm deploy:base
```

## Network Configuration

| Network | Chain ID | RPC URL |
|---------|----------|---------|
| Localhost | 31337 | http://localhost:8545 |
| HomeLab Base | 8453 | http://base-node:8545 |
| Base Mainnet | 8453 | https://mainnet.base.org |
| Base Sepolia | 84532 | https://sepolia.base.org |

## Environment Variables

Create a `.env` file:

```env
# Private key for deployment (DO NOT COMMIT!)
DEPLOYER_PRIVATE_KEY=0x...

# API keys for verification (optional)
BASESCAN_API_KEY=your_key
ETHERSCAN_API_KEY=your_key

# Custom RPC endpoints
BASE_RPC_URL=http://base-node:8545
BASE_MAINNET_RPC=https://mainnet.base.org
```

## Example Contract

The included `HomelabToken.sol` demonstrates:

- ERC20 token implementation
- OpenZeppelin integration
- Mint/burn functionality
- Owner access control

## Offline Development

This environment supports fully offline development:

1. Use `pnpm anvil` for local blockchain
2. Dependencies are cached in container
3. No external RPC calls needed

## Foundry Integration

Foundry tools are also available:

```bash
# Compile with Forge
forge build

# Test with Forge
forge test

# Deploy with Forge
forge create --rpc-url http://localhost:8545 \
  --private-key 0xac0974... \
  contracts/HomelabToken.sol:HomelabToken

# Interact with Cast
cast call <address> "name()" --rpc-url http://localhost:8545
```

## Security Notes

⚠️ **Never commit private keys or `.env` files!**

The default private key in `hardhat.config.ts` is Anvil's first test account - only use for local development.

## Documentation

- [Hardhat Docs](https://hardhat.org/docs)
- [Foundry Book](https://book.getfoundry.sh/)
- [Base Docs](https://docs.base.org/)
- [OpenZeppelin](https://docs.openzeppelin.com/contracts/)
