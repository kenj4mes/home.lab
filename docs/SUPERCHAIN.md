# 🔗 Superchain Ecosystem

> **One-Folder Build-Out** - All 31 OP-Stack L2 node repositories in a single directory.

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║   ███████╗██╗   ██╗██████╗ ███████╗██████╗  ██████╗██╗  ██╗ █████╗ ██╗███╗   ██╗║
║   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗██╔════╝██║  ██║██╔══██╗██║████╗  ██║║
║   ███████╗██║   ██║██████╔╝█████╗  ██████╔╝██║     ███████║███████║██║██╔██╗ ██║║
║   ╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗██║     ██╔══██║██╔══██║██║██║╚██╗██║║
║   ███████║╚██████╔╝██║     ███████╗██║  ██║╚██████╗██║  ██║██║  ██║██║██║ ╚████║║
║   ╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

## 📋 Overview

The Superchain is a network of OP-Stack L2 chains that share security, communication layers, and a common development stack. This integration provides:

- **31 Ecosystem Repositories** - All major OP-Stack L2 node implementations
- **Docker Compose Orchestration** - Profile-based multi-chain deployment
- **Unified Dashboard** - Real-time node status monitoring
- **Offline Operation** - Clone once, run anywhere

## 🌐 Ecosystem Table

### Finance Category

| # | Ecosystem | Chain ID | GitHub Repo | Notes |
|---|-----------|----------|-------------|-------|
| 1 | **Ink** | - | [inkonchain/node](https://github.com/inkonchain/node) | Full node (Docker-compose) |
| 2 | **Unichain** | 130 | [Uniswap/unichain-node](https://github.com/Uniswap/unichain-node) | Uniswap L2 node |
| 3 | **Mode** | 34443 | [mode-network/rollup-node](https://github.com/mode-network/rollup-node) | Conduit rollup node |
| 4 | **Base** | 8453 | [base/node](https://github.com/base/node) | Coinbase L2 (geth, reth) |
| 5 | **Superseed** | - | [superseed-xyz/node](https://github.com/superseed-xyz/node) | Fork of simple-optimism-node |
| 6 | **Epic Chain** | - | [epicchainlabs/epicchain-node](https://github.com/epicchainlabs/epicchain-node) | Epic Chain rollup |
| 7 | **Metal L2** | - | [MetalPay/metal-l2-docs](https://github.com/MetalPay/metal-l2-docs) | Config only - use OP-Stack |
| 8 | **Swell** | - | [SwellNetwork/v3-core-public](https://github.com/SwellNetwork/v3-core-public) | Contracts/config - use OP-Stack |
| 9 | **BOB** | - | [gobobofficial/bob](https://github.com/gobobofficial/bob) | Hybrid Bitcoin-Ethereum |
| 10 | **Silent Data** | - | [appliedblockchain/silentdata-node](https://github.com/appliedblockchain/silentdata-node) | Archived node library |
| 11 | **Polynomial** | - | *(generic OP-Stack)* | Use Superchain Registry |
| 12 | **Derive Chain** | - | *(generic OP-Stack)* | Use Derive docs for config |
| 13 | **Orderly** | - | *(generic OP-Stack)* | SDKs in Orderly GitHub org |
| 14 | **Boba** | - | [bobanetwork/boba-node](https://github.com/bobanetwork/boba-node) | Optional - Boba implementation |
| 15 | **Fraxtal** | - | [fraxtal/fraxtal-node](https://github.com/fraxtal/fraxtal-node) | Optional - OP-Stack fork |

### General Category

| # | Ecosystem | Chain ID | GitHub Repo | Notes |
|---|-----------|----------|-------------|-------|
| 16 | **OP Mainnet** | 10 | [ethereum-optimism/optimism](https://github.com/ethereum-optimism/optimism) | Core OP-Stack implementation |
| 17 | **World Chain** | 480 | [worldcoin/world-chain](https://github.com/worldcoin/world-chain) | Worldcoin L2 monorepo |
| 18 | **Lisk** | 1135 | [LiskHQ/lisk-node](https://github.com/LiskHQ/lisk-node) | Lisk OP-Stack node |
| 19 | **HashKey Chain** | - | [hashkey-chain/hashkey-chain](https://github.com/hashkey-chain/hashkey-chain) | Full Go implementation |
| 20 | **Binary** | - | *(generic OP-Stack)* | No public node source |
| 21 | **Automata** | - | *(generic OP-Stack)* | See Automata docs for config |
| 22 | **Celo** | - | [celo-org/celo-node](https://github.com/celo-org/celo-node) | Separate L1-compatible client |

### Creator Category

| # | Ecosystem | Chain ID | GitHub Repo | Notes |
|---|-----------|----------|-------------|-------|
| 23 | **Mint** | - | [Mint-Blockchain/mint-node](https://github.com/Mint-Blockchain/mint-node) | Mint rollup (Docker) |
| 24 | **Shape** | - | [shape-network/mcp-server](https://github.com/shape-network/mcp-server) | Shape L2 MCP server |
| 25 | **Soneium** | - | *(generic OP-Stack)* | Config in Soneium docs |
| 26 | **Zora** | - | [himanii33/zora-node](https://github.com/himanii33/zora-node) | Community Zora node |
| 27 | **Cyber** | - | *(generic OP-Stack)* | See Cyber docs |
| 28 | **Funki** | - | [funkichain/funki-superchain-registry](https://github.com/funkichain/funki-superchain-registry) | Superchain config only |
| 29 | **Settlus** | - | *(generic OP-Stack)* | Config in Superchain Registry |

### Gaming Category

| # | Ecosystem | Chain ID | GitHub Repo | Notes |
|---|-----------|----------|-------------|-------|
| 30 | **Redstone** | - | [redstone-network/redstone-node](https://github.com/redstone-network/redstone-node) | Rust/Substrate-style |
| 31 | **Xterio Chain** | - | [XeChain/xe-core](https://github.com/XeChain/xe-core) | Go implementation |

## 🚀 Quick Start

### Clone All Repositories

```powershell
# Run the clone script (creates superchain/ folder)
.\scripts\clone-superchain.ps1

# With options
.\scripts\clone-superchain.ps1 -DestinationPath "C:\chains" -ShallowClone -SkipExisting

# Include optional repos (Celo, Boba, Fraxtal)
.\scripts\clone-superchain.ps1 -IncludeOptional
```

### Start a Node

```powershell
# Using HomeLab CLI
.\homelab.ps1 -Action superchain

# Or directly with Docker Compose
docker compose -f docker/docker-compose.superchain.yml --profile base up -d
```

### Available Profiles

| Profile | Chains | Ports | Notes |
|---------|--------|-------|-------|
| `base` | Base L2 | 8545/8546/9222 | Coinbase L2 |
| `op-mainnet` | OP Mainnet | 8555/8556/9232 | Optimism |
| `unichain` | Unichain | 8565/8566/9242 | Uniswap L2 |
| `mode` | Mode | 8575/8576/9252 | Mode Network |
| `world` | World Chain | 8585/8586/9262 | Worldcoin |
| `lisk` | Lisk | 8595/8596/9272 | Lisk L2 |
| `multi` | All above | Various | Resource intensive |
| `explorer` | Blockscout | 4010 | Block explorer |
| `monitoring` | Prometheus/Grafana | 9190/3200 | Metrics |

## 🔧 Configuration

### Environment Variables

Create a `.env` file with your L1 RPC endpoints:

```bash
# Required: L1 Ethereum RPC
L1_RPC_URL=https://eth.llamarpc.com
L1_BEACON_URL=https://ethereum-beacon-api.publicnode.com

# Optional: Custom ports
BASE_RPC_PORT=8545
BASE_WS_PORT=8546
BASE_P2P_PORT=9222

# Explorer
BLOCKSCOUT_DB_PASS=your_secure_password

# Monitoring
GRAFANA_ADMIN_PASSWORD=admin
```

### L1 RPC Providers

For production use, you'll need a reliable L1 RPC. Options:

| Provider | URL | Notes |
|----------|-----|-------|
| **LlamaRPC** | `https://eth.llamarpc.com` | Free, rate-limited |
| **PublicNode** | `https://ethereum-rpc.publicnode.com` | Free, rate-limited |
| **Alchemy** | `https://eth-mainnet.g.alchemy.com/v2/KEY` | Free tier available |
| **Infura** | `https://mainnet.infura.io/v3/KEY` | Free tier available |
| **Self-hosted** | `http://localhost:8545` | Run your own geth/reth |

## 📊 Node Operations

### Check Sync Status

```bash
# Base L2
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'

# OP Mainnet
curl -X POST http://localhost:8555 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'
```

### Get Latest Block

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### Get Chain ID

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
```

## 🌐 Dashboard

Access the Superchain Dashboard at **http://localhost:8600**

Features:
- Real-time node status monitoring
- Sync progress visualization
- Quick access to RPC endpoints
- Command reference

## 📁 Repository Structure

After cloning, the `superchain/` folder contains:

```
superchain/
├── optimism/               # Core OP-Stack (fallback for many chains)
├── superchain-registry/    # Chain configs for all OP-Stack L2s
│
├── ink-node/              # Ink (Finance)
├── unichain-node/         # Unichain (Finance)
├── mode-rollup-node/      # Mode (Finance)
├── base-node/             # Base (Finance)
├── superseed-node/        # Superseed (Finance)
├── epicchain-node/        # Epic Chain (Finance)
├── metal-l2-docs/         # Metal L2 config (Finance)
├── swell-v3-core/         # Swell config (Finance)
├── bob/                   # BOB hybrid (Finance)
├── silentdata-node/       # Silent Data (Finance)
│
├── world-chain/           # World Chain (General)
├── lisk-node/             # Lisk (General)
├── hashkey-chain/         # HashKey Chain (General)
│
├── mint-node/             # Mint (Creator)
├── shape-mcp-server/      # Shape (Creator)
├── zora-node/             # Zora community (Creator)
├── funki-registry/        # Funki config (Creator)
│
├── redstone-node/         # Redstone (Gaming)
├── xe-core/               # Xterio Chain (Gaming)
│
├── celo-node/             # Celo (Optional)
├── boba-node/             # Boba (Optional)
├── fraxtal-node/          # Fraxtal (Optional)
│
└── SUPERCHAIN_INDEX.md    # Auto-generated index
```

## 🔗 Superchain Registry

The `superchain-registry/` contains chain configurations for all OP-Stack L2s:

```bash
# View all chains
cat superchain/superchain-registry/chainList.toml

# Use a chain config with generic OP-Stack
cd superchain/optimism
./op-node --network <chain-name>
```

## 💾 Disk Requirements

| Component | Size | Notes |
|-----------|------|-------|
| **All Repos** | ~50GB | With git history |
| **Shallow Clone** | ~5GB | `--depth 1` |
| **Base Node Data** | ~500GB | Full archive |
| **Base Node Data** | ~100GB | Snap sync |
| **Multi-chain** | ~2TB+ | Multiple nodes |

## 🔒 Security Considerations

1. **JWT Secrets** - Each node needs a unique JWT secret for auth RPC
2. **Firewall** - Only expose P2P ports publicly if needed
3. **RPC Access** - Consider rate limiting and authentication
4. **Private Keys** - Never store wallet keys on node machines

## 📚 References

- [Optimism Documentation](https://docs.optimism.io/)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry)
- [OP-Stack Specification](https://specs.optimism.io/)
- [Base Documentation](https://docs.base.org/)

## 🛠️ Troubleshooting

### Node Won't Start

```bash
# Check Docker logs
docker logs base-geth -f
docker logs base-node -f

# Verify L1 RPC is accessible
curl $L1_RPC_URL -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### Slow Sync

- Use a dedicated L1 RPC (not free/public endpoints)
- Enable snap sync (default)
- Ensure sufficient disk I/O (SSD recommended)
- Check network bandwidth

### Out of Memory

- Reduce `GETH_CACHE` in environment
- Run fewer chains simultaneously
- Use `--profile base` instead of `--profile multi`

---

*Part of the HomeLab Infrastructure Stack*
