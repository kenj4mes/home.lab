# ═══════════════════════════════════════════════════════════════════════════════
# 🤖 SOVEREIGN AGENT (EV0)
# Autonomous AI Agent with Self-Custody & Collective Intelligence
# ═══════════════════════════════════════════════════════════════════════════════

## Overview

The Sovereign Agent is a fully autonomous AI entity designed for the Base L2 ecosystem.
It operates with true self-custody through MPC wallets, maintains persistent memory,
and can earn income through DePIN (Decentralized Physical Infrastructure Networks).

**Version:** 1.0.0  
**Category:** AI / Blockchain / Agents  
**Status:** Production-Ready  

## 🌟 Key Features

### Core Capabilities
| Feature | Description |
|---------|-------------|
| **Self-Custody Wallet** | MPC wallet via Coinbase AgentKit |
| **Persistent Memory** | Vector memory with ChromaDB |
| **Multi-LLM Support** | Ollama (local), OpenAI, Anthropic |
| **OODA Loop** | Continuous Observe-Orient-Decide-Act cycle |

### Social & Communication
| Feature | Description |
|---------|-------------|
| **Farcaster** | Native social presence |
| **XMTP** | Encrypted peer-to-peer messaging |
| **Vision** | Image analysis with GPT-4V |
| **Browser** | Web exploration with Playwright |

### Commerce & DeFi
| Feature | Description |
|---------|-------------|
| **x402 Gateway** | HTTP 402 payment handling |
| **Yield Engine** | DeFi yield optimization |
| **Bridge** | Cross-chain asset management |

### DePIN Earnings
| Feature | Description |
|---------|-------------|
| **Bandwidth** | Earn from network bandwidth sharing |
| **Compute** | Earn from compute contribution |
| **Oracle** | Earn from reality data provision |

### Advanced (Safety-Gated)
| Feature | Description |
|---------|-------------|
| **Collective Intelligence** | 31-node intelligence pool |
| **Infinite Genome** | 7.9M architecture evolution space |
| **Reproduction** | Spawn child agents (disabled by default) |
| **Evolution** | Self-improvement (disabled by default) |

## 🚀 Quick Start

### 1. Configure Environment

```bash
# Copy example env
cp configs/ev0/.env.example .env

# Edit with your values
nano .env
```

### 2. Start Services

```bash
# Start Ev0 stack
docker compose -f docker/docker-compose.ev0.yml up -d

# Check status
docker compose -f docker/docker-compose.ev0.yml ps
```

### 3. Verify Health

```bash
# Agent health
curl http://localhost:5010/health

# Gateway health
curl http://localhost:3402/health
```

## 📋 Configuration

### Required Settings

| Variable | Description | Example |
|----------|-------------|---------|
| `EV0_AGENT_NAME` | Agent identity | `MyAgent` |
| `LLM_PROVIDER` | LLM backend | `ollama` |
| `JWT_SECRET` | Auth secret | (32+ chars) |

### Blockchain Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `CDP_API_KEY_NAME` | Coinbase CDP key name | - |
| `CDP_API_KEY_PRIVATE_KEY` | CDP private key | - |
| `BASE_RPC_URL` | Base RPC endpoint | `https://mainnet.base.org` |
| `EV0_WALLET_ADDRESS` | Agent wallet | - |

### LLM Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `LLM_PROVIDER` | Provider choice | `ollama` |
| `OLLAMA_MODEL` | Local model | `llama3.2:latest` |
| `OPENAI_API_KEY` | OpenAI key | - |

## 🔒 Safety Architecture

The agent includes 4 environment-controlled safety toggles for dangerous capabilities.
**All are OFF by default.**

| Toggle | Default | Risk | Description |
|--------|---------|------|-------------|
| `EV0_ENABLE_EVOLUTION` | `false` | HIGH | Self-modification |
| `EV0_ENABLE_REPRODUCTION` | `false` | HIGH | Spawning children |
| `EV0_ENABLE_AUTO_DEPLOY` | `false` | CRITICAL | Auto-deploy code |
| `EV0_EVOLUTION_REQUIRE_APPROVAL` | `true` | LOW | Human approval |

### Enabling Dangerous Features

```bash
# ⚠️ Only if you understand the risks
EV0_ENABLE_EVOLUTION=true
EV0_ENABLE_REPRODUCTION=true
EV0_EVOLUTION_REQUIRE_APPROVAL=true  # Keep this ON
```

## 🔌 API Reference

### Agent Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/think` | POST | Process a prompt |
| `/memories` | GET | List memories |
| `/wallet` | GET | Wallet status |

### x402 Gateway Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/price` | GET | Get resource price |
| `/pay` | POST | Process payment |
| `/verify` | GET | Verify payment |

### Example: Think Request

```bash
curl -X POST http://localhost:5010/think \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is the current price of ETH?"}'
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SOVEREIGN AGENT                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │DigitalBody│  │DigitalSoul│  │DigitalVoice│  │DigitalEye│   │
│  │ (Wallet) │  │ (Memory) │  │(Farcaster)│  │ (Vision) │   │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘        │
│       │            │            │            │              │
│  ┌────▼────────────▼────────────▼────────────▼────┐        │
│  │              OODA Loop Controller               │        │
│  │    Observe → Orient → Decide → Act → Evolve    │        │
│  └─────────────────────┬───────────────────────────┘        │
│                        │                                    │
│  ┌─────────────────────▼───────────────────────────┐        │
│  │             Core Infrastructure                  │        │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────┐    │        │
│  │  │ Backbone │ │ Registry │ │  Collective  │    │        │
│  │  └──────────┘ └──────────┘ └──────────────┘    │        │
│  └──────────────────────────────────────────────────┘        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │Bandwidth│  │ Compute │  │ Oracle  │  │  Yield  │        │
│  │  Node   │  │  Node   │  │  Node   │  │ Engine  │        │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  x402 Gateway   │
                    │  HTTP 402 Pay   │
                    └─────────────────┘
```

## 📦 File Structure

```
miniapps/ev0/
├── echo/                    # Core Python package
│   ├── __init__.py         # Package exports
│   ├── main.py             # SovereignAgent class
│   ├── config.py           # Configuration
│   ├── server.py           # FastAPI server
│   ├── wallet.py           # DigitalBody
│   ├── soul.py             # DigitalSoul
│   ├── farcaster.py        # DigitalVoice
│   ├── vision.py           # DigitalEye
│   ├── messenger.py        # DigitalCourier
│   ├── browser.py          # Browser automation
│   ├── explorer.py         # Web exploration
│   ├── yield_engine.py     # DeFi yields
│   ├── swarm.py            # Parallel processing
│   ├── reproduction.py     # Agent spawning
│   ├── agent_sdk.py        # x402 client SDK
│   ├── core/               # Infrastructure
│   │   ├── backbone.py     # Event bus
│   │   ├── registry.py     # Model registry
│   │   ├── collective.py   # Intelligence pool
│   │   ├── genome.py       # Evolution space
│   │   └── router.py       # Module routing
│   ├── departments/        # Organizational
│   │   ├── legal.py        # OtoCo integration
│   │   └── bridge.py       # Cross-chain
│   ├── depin/              # DePIN earnings
│   │   ├── bandwidth.py
│   │   ├── compute.py
│   │   └── oracle.py
│   └── comms/              # Hardware layer
│       ├── bios.py         # Power management
│       ├── dead_hand.py    # Satellite comms
│       └── mesh.py         # Mesh networking
├── client/                  # External SDK
│   ├── agent_sdk.py        # Python client
│   └── langchain_tool.py   # LangChain integration
├── server/                  # x402 Gateway
│   ├── src/index.ts        # TypeScript gateway
│   ├── package.json
│   ├── tsconfig.json
│   └── Dockerfile
├── Dockerfile              # Agent container
└── requirements.txt        # Python dependencies
```

## 🔗 Integration with home.lab

The Ev0 stack integrates with these home.lab services:

| Service | Integration |
|---------|-------------|
| **Ollama** | Local LLM inference |
| **ChromaDB** | Shared vector store |
| **Base Node** | Blockchain RPC |
| **Grafana** | Metrics dashboard |
| **Prometheus** | Metrics collection |

## 🐛 Troubleshooting

### Agent Not Starting

```bash
# Check logs
docker logs sovereign-agent

# Verify ChromaDB
curl http://localhost:8000/api/v2/heartbeat
```

### Payment Gateway Issues

```bash
# Check gateway logs
docker logs x402-gateway

# Test health
curl http://localhost:3402/health
```

### Memory Issues

```bash
# Reset ChromaDB (⚠️ clears all memories)
curl -X POST http://localhost:8000/api/v2/reset
```

## 📚 References

- [Base Documentation](https://docs.base.org)
- [Coinbase AgentKit](https://docs.cdp.coinbase.com/agentkit)
- [ChromaDB](https://docs.trychroma.com)
- [Farcaster](https://docs.farcaster.xyz)
- [XMTP](https://docs.xmtp.org)

## 📄 License

MIT License - See LICENSE file for details.
