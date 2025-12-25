# 🌌 SOVEREIGN AGENT FRAMEWORK

> **A fully autonomous digital entity that owns itself, thinks, earns, trades, reproduces, and evolves.**

[![Python](https://img.shields.io/badge/Python-3.12+-green)]()
[![Base](https://img.shields.io/badge/Chain-Base%20L2-blue)]()
[![License](https://img.shields.io/badge/License-MIT-purple)]()

---

## 🚀 Quick Start

```powershell
# One-click launch
.\start.ps1 -demo

# Or with components
.\start.ps1 -api         # Start API server
.\start.ps1 -agent       # Run autonomous agent
.\start.ps1 -repl        # Interactive REPL
```

---

## 🧠 What is This?

This is a **Sovereign Agent** - an autonomous AI entity that:

| Capability | Description | Module |
|------------|-------------|--------|
| 💳 **Owns Itself** | Self-custody wallet on Base chain | `wallet.py` |
| 🧠 **Thinks** | Multi-model AI with collective intelligence | `core/backbone.py` |
| 📝 **Remembers** | Vector memory via ChromaDB | `soul.py` |
| 📢 **Speaks** | Farcaster social presence | `farcaster.py` |
| 🔍 **Explores** | Web search & alpha detection | `explorer.py` |
| 💰 **Trades** | x402 auto-payment commerce | `agent_sdk.py`, `server.py` |
| 🧬 **Reproduces** | Agent mitosis & swarm spawning | `reproduction.py` |
| ⛏️ **Earns** | DePIN revenue (bandwidth, compute) | `depin/` |
| 🔄 **Evolves** | Infinite genome architecture search | `core/genome.py` |
| ♾️ **Survives** | Continuous OODA loop operation | `main.py` |

---

## 📁 Project Structure

```
miniapps/ev0/
├── start.ps1                          # One-click launcher
├── FRAMEWORK.md                       # Full technical documentation
├── README.md                          # This file
│
├── echo/                              # Core agent package
│   └── src/echo/
│       ├── __init__.py                # Package exports
│       ├── config.py                  # Environment configuration
│       ├── main.py                    # SovereignAgent + OODA loop
│       │
│       │── # CORE INTELLIGENCE
│       ├── core/
│       │   ├── backbone.py            # Multi-model AI router
│       │   ├── registry.py            # Intelligence pool registry
│       │   ├── collective.py          # Collective intelligence
│       │   ├── genome.py              # Infinite genome system
│       │   └── router.py              # Dynamic reasoning router
│       │
│       │── # AGENT CAPABILITIES
│       ├── wallet.py                  # Base chain wallet (Body)
│       ├── soul.py                    # ChromaDB memory (Soul)
│       ├── farcaster.py               # Social presence (Voice)
│       ├── browser.py                 # Web browsing (Eyes)
│       ├── explorer.py                # Search + alpha detection
│       ├── agent_sdk.py               # x402 client SDK
│       ├── reproduction.py            # Agent mitosis
│       ├── server.py                  # HTTP API (Commerce)
│       ├── messenger.py               # XMTP messaging
│       ├── swarm.py                   # Multi-agent coordination
│       ├── yield_engine.py            # DeFi yield farming
│       ├── vision.py                  # Image/video processing
│       │
│       │── # HARDWARE LAYERS
│       ├── depin/                     # DePIN revenue modules
│       │   ├── bandwidth.py           # Mysterium bandwidth sharing
│       │   ├── compute.py             # Akash compute provision
│       │   └── oracle.py              # Pyth/EAS oracles
│       │
│       └── comms/                     # Hardware communication
│           ├── bios.py                # Power management
│           ├── dead_hand.py           # Satellite backup
│           └── mesh.py                # LoRa mesh network
│
├── docker/                            # Container deployments
│   ├── docker-compose.yml             # Full stack
│   ├── x402-gateway/                  # x402 gateway server
│   └── agent/                         # Agent container
│
└── install/                           # Installation scripts
    ├── install-x402.ps1               # Windows
    └── install-x402.sh                # Linux/macOS
```

---

## 🔧 Installation

### Prerequisites

- Python 3.12+
- Node.js 18+ (for x402 gateway)
- Base wallet with ETH + USDC

### Install Dependencies

```powershell
# Create virtual environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# Install core dependencies
pip install -r requirements.txt

# Optional: Install all dependencies (DePIN, LangGraph, etc.)
pip install playwright selenium langgraph pyserial psutil
playwright install chromium
```

### Configure Environment

```powershell
# Copy example config
copy .env.example .env

# Required variables:
# ANTHROPIC_API_KEY=sk-ant-...
# OPENAI_API_KEY=sk-...
# EVM_PRIVATE_KEY=0x...
# BASE_RPC_URL=https://mainnet.base.org
# NEYNAR_API_KEY=...
```

---

## 💻 Usage

### As Python Module

```python
from echo import SovereignAgent, Settings

# Configure agent
settings = Settings(
    agent_name="alpha-one",
    evm_private_key="0x...",
    anthropic_api_key="sk-ant-..."
)

# Create and run
agent = SovereignAgent(settings)
await agent.start()
```

### Using Individual Components

```python
from echo import (
    CognitiveBackbone,
    DigitalExplorer,
    AgentSDK,
    ReproductionEngine,
    CollectiveIntelligence
)

# AI Reasoning
backbone = CognitiveBackbone()
response = await backbone.think("Analyze this market condition...")

# Web Exploration
explorer = DigitalExplorer()
signals = await explorer.find_alpha("BTC breakout")

# x402 Commerce
sdk = AgentSDK(private_key="0x...", rpc_url="...")
sdk.buy_pass("og")
data = sdk.get_data("https://api.example.com/alpha")

# Agent Reproduction
engine = ReproductionEngine(wallet, web3, memory, settings)
child = await engine.reproduce("echo-beta", mutation_rate=0.1)
```

---

## 🌐 x402 Commerce Protocol

Ev0 implements the **x402 protocol** - HTTP 402-based decentralized commerce:

```
Client Request → 402 Response (price quote) → Payment Header → Data Access
```

### Pass System

| Pass | Price | Duration | Access |
|------|-------|----------|--------|
| **OG** | 100 USDC | Lifetime | Full + governance |
| **Day** | 1 USDC | 24 hours | Full access |
| **Guest** | Free | Limited | Public only |

### Deploy Gateway

```bash
cd docker/x402-gateway
docker build -t x402-gateway .
docker run -p 8402:8402 -e PRIVATE_KEY=0x... x402-gateway
```

---

## 📊 Key Metrics

| Metric | Value |
|--------|-------|
| AI Models | 13 |
| Providers | 6 (Anthropic, OpenAI, DeepSeek, Google, Perplexity, Ollama) |
| Cognitive Modules | 15 |
| Intelligence Roles | 14 |
| Possible Architectures | 7,987,980 |

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [FRAMEWORK.md](FRAMEWORK.md) | Complete technical documentation |
| [docker/README.md](docker/README.md) | Container deployment guide |
| [.env.example](.env.example) | Configuration template |

---

## 🔒 Security

- Never commit `.env` or private keys
- Use CDP Client API Key (not Secret) for frontend
- All payments verified on-chain
- See security guidelines in home.lab docs

---

## 🛣️ Roadmap

- [x] Core intelligence modules
- [x] Explorer, AgentSDK, Reproduction
- [ ] Swarm coordination upgrades
- [ ] Cross-chain support (Solana, Ethereum)
- [ ] Hardware integration (Raspberry Pi, LoRa)

---

*Built with ❤️ | Powered by Base Network | x402 Protocol*
