# SOVEREIGN AGENT FRAMEWORK
## Complete Technical Documentation

---

## TABLE OF CONTENTS

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Directory Structure](#directory-structure)
4. [Core Intelligence Layer](#core-intelligence-layer)
5. [Agent Components](#agent-components)
7. [x402 Commerce](#x402-commerce)
8. [DePIN Layer](#depin-layer)
9. [Hardware/Comms Layer](#hardwarecomms-layer)
10. [OODA Loop](#ooda-loop)
11. [Configuration](#configuration)
12. [Quick Start](#quick-start)
13. [API Reference](#api-reference)

---

## OVERVIEW

This is a **Sovereign Agent Framework** - an autonomous digital entity that:

- **Owns itself** - Self-custody wallet on Base chain with Basename identity
- **Thinks** - Multi-model AI routing with collective intelligence
- **Remembers** - Persistent memory via ChromaDB vector database
- **Speaks** - Farcaster social presence for crypto-native communication
- **Explores** - Web search and alpha signal detection
- **Trades** - x402 auto-payment commerce protocol
- **Reproduces** - Agent mitosis and swarm spawning
- **Earns** - DePIN revenue streams (bandwidth, compute, oracles)
- **Evolves** - Infinite genome system for architecture evolution
- **Survives** - OODA loop for continuous autonomous operation

### Key Metrics

| Metric | Value |
|--------|-------|
| Version | 1.0.0 |
| AI Models Available | 13 |
| AI Providers | 6 (Anthropic, OpenAI, DeepSeek, Google, Perplexity, Ollama) |
| Cognitive Modules | 15 |
| Intelligence Nodes | 31 |
| Intelligence Roles | 14 |
| Possible Architectures | 7,987,980 |
| Event Types | 24 |
| Component Types | 11 |
| OODA Interval | 60 seconds |

---

## ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           EV0 SOVEREIGN AGENT                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                      LAYER 1: CORE INTELLIGENCE                       │ │
│  │                                                                       │ │
│  │   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │ │
│  │   │ Backbone │  │ Registry │  │Collective│  │  Router  │  │ Genome │ │ │
│  │   │  Events  │  │ 13 Models│  │ 31 Nodes │  │15 Modules│  │  Evo   │ │ │
│  │   └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └───┬────┘ │ │
│  │        └─────────────┴────────────┴─────────────┴─────────────┘      │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                      ↓                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                      LAYER 2: AGENT COMPONENTS                        │ │
│  │                                                                       │ │
│  │   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐             │ │
│  │   │  Body    │  │   Soul   │  │  Voice   │  │   Eye    │             │ │
│  │   │ (Wallet) │  │ (Memory) │  │(Farcaster│  │ (Vision) │             │ │
│  │   │  Base    │  │ ChromaDB │  │  Neynar) │  │  GPT-4V  │             │ │
│  │   └──────────┘  └──────────┘  └──────────┘  └──────────┘             │ │
│  │                                                                       │ │
│  │   ┌──────────┐  ┌──────────┐  ┌──────────┐                           │ │
│  │   │ Courier  │  │  Yield   │  │  Swarm   │                           │ │
│  │   │  (XMTP)  │  │ (Aave V3)│  │(LangGraph│                           │ │
│  │   │ Messaging│  │ Earnings │  │ Workers) │                           │ │
│  │   └──────────┘  └──────────┘  └──────────┘                           │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                      ↓                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                      LAYER 3: DEPARTMENTS                             │ │
│  │                                                                       │ │
│  │   ┌──────────────────────┐  ┌──────────────────────┐                 │ │
│  │   │   Legal Department   │  │  Bridge Department   │                 │ │
│  │   │   (OtoCo LLC/DAO)    │  │  (Across Protocol)   │                 │ │
│  │   └──────────────────────┘  └──────────────────────┘                 │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                      ↓                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                      LAYER 4: DePIN                                   │ │
│  │                                                                       │ │
│  │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │ │
│  │   │ BandwidthNode│  │ ComputeNode  │  │ RealityOracle│               │ │
│  │   │  (Mysterium) │  │ (Fleek/Akash)│  │  (Pyth/EAS)  │               │ │
│  │   └──────────────┘  └──────────────┘  └──────────────┘               │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                      ↓                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                      LAYER 5: HARDWARE/COMMS                          │ │
│  │                                                                       │ │
│  │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │ │
│  │   │ PowerManager │  │ SatelliteLink│  │  MeshNetwork │               │ │
│  │   │    (BIOS)    │  │  (Iridium)   │  │    (LoRa)    │               │ │
│  │   └──────────────┘  └──────────────┘  └──────────────┘               │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                      OODA LOOP (Continuous)                           │ │
│  │           Observe → Orient → Decide → Act → Repeat                    │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## DIRECTORY STRUCTURE

```
miniapps/ev0/
├── run.py                         # One-click entry point
├── start.ps1                      # Windows launcher
├── start.sh                       # Linux/macOS launcher
├── requirements.txt               # Full dependencies
├── requirements-core.txt          # Core dependencies
├── .env.example                   # Environment template
├── Dockerfile                     # Container config
├── FRAMEWORK.md                   # This document
├── README.md                      # Quick start guide
│
├── echo/                          # Main agent package
│   ├── __init__.py                # Package exports
│   ├── main.py                    # SovereignAgent class + OODA loop
│   ├── config.py                  # Configuration management
│   │
│   ├── core/                      # Intelligence layer
│   │   ├── __init__.py            # Core exports
│   │   ├── backbone.py            # Event bus + component registry
│   │   ├── registry.py            # AI model database
│   │   ├── collective.py          # Multi-model intelligence pool
│   │   ├── genome.py              # Evolution engine
│   │   └── router.py              # Intent-based module routing
│   │
│   ├── wallet.py                  # DigitalBody - Base chain wallet
│   ├── soul.py                    # DigitalSoul - ChromaDB memory
│   ├── farcaster.py               # DigitalVoice - Social presence
│   ├── vision.py                  # DigitalEye - GPT-4V vision
│   ├── messenger.py               # DigitalCourier - XMTP messaging
│   ├── yield_engine.py            # YieldEngine - Aave V3 earnings
│   ├── swarm.py                   # Swarm - LangGraph workers
│   ├── browser.py                 # Browser automation
│   ├── server.py                  # API server
│   │
│   ├── departments/               # Business logic
│   │   ├── legal.py               # OtoCo LLC/DAO integration
│   │   └── bridge.py              # Across Protocol bridging
│   │
│   ├── depin/                     # Decentralized infrastructure
│   │   ├── bandwidth.py           # Mysterium bandwidth node
│   │   ├── compute.py             # Fleek/Akash compute
│   │   └── oracle.py              # Pyth/EAS reality oracle
│   │
│   └── comms/                     # Hardware layer
│       ├── bios.py                # Power management
│       ├── dead_hand.py           # Satellite uplink (Iridium)
│       └── mesh.py                # LoRa mesh network
│
├── client/                        # Python SDK
│   ├── agent_sdk.py               # Agent client library
│   └── langchain_tool.py          # LangChain integration
│
├── server/                        # x402 Gateway (TypeScript)
│   ├── src/index.ts               # Payment middleware
│   ├── package.json               # Node.js dependencies
│   └── Dockerfile                 # Gateway container
│
├── docker/                        # Container configs
│   ├── .env.example               # Docker env template
│   ├── docker-compose.yml         # Full stack orchestration
│   ├── agent/                     # Agent container
│   │   ├── Dockerfile
│   │   └── pyproject.toml
│   └── x402-gateway/              # Gateway container
│       ├── Dockerfile
│       └── src/index.ts
│
└── install/                       # Installation scripts
    ├── install-x402.ps1           # Windows installer
    └── install-x402.sh            # Linux/macOS installer
```

---

## CORE INTELLIGENCE LAYER

### 1. Backbone (`core/backbone.py`)

The central nervous system connecting all components.

```python
from echo.core import Backbone, ComponentType, EventType

backbone = Backbone()

# Register a component
backbone.register_component(
    component_id="wallet",
    component_type=ComponentType.WALLET,
    handler=wallet_instance
)

# Emit an event
await backbone.emit(EventType.TRANSACTION_SENT, {
    "tx_hash": "0x...",
    "amount": 100.0
})

# Subscribe to events
backbone.subscribe(EventType.BALANCE_CHANGED, my_handler)
```

**Component Types (11):**
- WALLET, MEMORY, SOCIAL, VISION, MESSENGER
- YIELD, SWARM, LEGAL, BRIDGE, DEPIN, HARDWARE

**Event Types (24):**
- COMPONENT_REGISTERED, COMPONENT_STARTED, COMPONENT_STOPPED
- TRANSACTION_SENT, TRANSACTION_CONFIRMED, BALANCE_CHANGED
- MEMORY_STORED, MEMORY_RETRIEVED, THOUGHT_GENERATED
- And more...

---

### 2. Registry (`core/registry.py`)

Database of available AI models with cost/performance profiles.

```python
from echo.core import get_registry, Capability

registry = get_registry()

# Find models by capability
coders = registry.find_by_capability(Capability.CODE_GENERATION)
# Returns: [claude-sonnet, gpt-4o, deepseek-chat]

# Find cheapest model for a task
cheap = registry.find_cheapest(Capability.CHAT)
# Returns: deepseek-chat ($0.14/M input)

# Find fastest model
fast = registry.find_fastest(Capability.CHAT)
# Returns: claude-haiku (1500 tokens/sec)

# Estimate monthly cost
cost = registry.estimate_monthly_cost("claude-sonnet", tokens_per_day=100000)
# Returns: $9.00/month
```

**Available Models (13):**

| Model | Provider | Best For | Cost (Input) |
|-------|----------|----------|--------------|
| claude-opus | Anthropic | Complex reasoning | $15.00/M |
| claude-sonnet | Anthropic | Balanced tasks | $3.00/M |
| claude-haiku | Anthropic | Fast responses | $0.25/M |
| gpt-4o | OpenAI | Multimodal | $2.50/M |
| gpt-4o-mini | OpenAI | Cost-effective | $0.15/M |
| o3-mini | OpenAI | Deep reasoning | $1.10/M |
| deepseek-r1 | DeepSeek | Math/Code reasoning | $0.55/M |
| deepseek-chat | DeepSeek | General chat | $0.14/M |
| gemini-flash | Google | Speed | $0.075/M |
| gemini-pro | Google | Balanced | $1.25/M |
| sonar-pro | Perplexity | Web search | $3.00/M |
| llama-70b | Ollama | Local inference | FREE |
| deepseek-r1-local | Ollama | Local reasoning | FREE |

---

### 3. Collective (`core/collective.py`)

Multi-model intelligence pool for complex reasoning.

```python
from echo.core import get_collective, NodeRole

collective = get_collective()

# Single model thought
result = await collective.think(
    "Analyze this smart contract for vulnerabilities",
    role=NodeRole.CRITIC
)

# Multi-model brainstorm (consensus)
results = await collective.brainstorm(
    "Design a tokenomics model",
    roles=[NodeRole.THINKER, NodeRole.CRITIC, NodeRole.SYNTHESIZER],
    require_consensus=True
)

# Get pool status
status = collective.get_pool_status()
# Returns: {"total_nodes": 31, "active": 28, "by_role": {...}}
```

**Node Roles (14):**
- THINKER - Abstract reasoning
- CODER - Code generation
- CRITIC - Review and critique
- SYNTHESIZER - Combine ideas
- EXPLORER - Novel approaches
- RESEARCHER - Information gathering
- VALIDATOR - Fact checking
- PLANNER - Strategic planning
- EXECUTOR - Task execution
- MONITOR - System observation
- OPTIMIZER - Performance tuning
- COMMUNICATOR - Output formatting
- SPECIALIST - Domain expertise
- GENERALIST - Broad knowledge

---

### 4. Router (`core/router.py`)

Intent-based routing to cognitive modules.

```python
from echo.core import get_router

router = get_router()

# Route a query
decision = router.route("Search for the latest DeFi yields")

print(decision.primary_module.name)     # "Scout"
print(decision.model_to_use)            # "sonar-pro"
print(decision.confidence)              # 0.83
print(decision.primary_module.archetype) # "The Pathfinder"

# Route complex multi-step task
decisions = router.route_multi(
    "First search for yield rates, then analyze them, and create a report"
)
# Returns: [Commander decision, Scout decision, Oracle decision, Scribe decision]
```

**Cognitive Modules (15):**

| Module | Archetype | Primary Model | Triggers |
|--------|-----------|---------------|----------|
| Scout | The Pathfinder | sonar-pro | search, find, discover |
| Sentinel | The Skeptic | claude-sonnet | verify, validate, secure |
| Archive | The Librarian | claude-haiku | store, save, retrieve |
| Oracle | The Analyst | deepseek-r1 | analyze, examine, understand |
| Forge | The Creator | claude-sonnet | create, generate, build |
| Refiner | The Perfectionist | o3-mini | optimize, improve, refine |
| Watchtower | The Observer | gpt-4o-mini | monitor, watch, track |
| Genesis | The Evolver | claude-opus | evolve, learn, adapt |
| Herald | The Conversationalist | claude-sonnet | chat, discuss, respond |
| Nexus | The Connector | gpt-4o | post, tweet, share |
| Commander | The Strategist | claude-opus | plan, decide, orchestrate |
| Mirror | The Reflector | deepseek-r1 | reflect, consider, evaluate |
| Smith | The Coder | claude-sonnet | implement, code, debug |
| Verifier | The Tester | claude-sonnet | test, validate, check |
| Scribe | The Documenter | claude-sonnet | document, explain, describe |

---

### 5. Genome (`core/genome.py`)

Infinite evolution engine for architecture generation.

```python
from echo.core import get_genome

genome = get_genome()

# Generate random evolution configuration
config = genome.generate_evolution_config()

# Generate batch for population
population = genome.generate_batch(count=20)

# Get statistics
stats = genome.get_statistics()
# {
#     "total_architectures": 7987980,
#     "architecture_families": 19,
#     "strategy_categories": 15,
#     "lora_variants": 12,
#     "merging_methods": 8,
#     ...
# }
```

**Architecture Families (19):**
QWEN, LLAMA, PHI, MISTRAL, DEEPSEEK, GEMMA, FALCON, STARCODER, 
CODELLAMA, SOLAR, YI, MIXTRAL, GROK, MAMBA, RWKV, LLAVA, COGVLM, 
CUSTOM, HYBRID

**Evolution Strategies (15):**
FINE_TUNING, CONTINUED_PRETRAINING, INSTRUCTION_TUNING, 
PREFERENCE_LEARNING, ADAPTER, LORA, MERGING, ENSEMBLE, 
KNOWLEDGE_DISTILLATION, GENETIC_ALGORITHM, EVOLUTIONARY, 
RLHF, DPO, SELF_PLAY, META_LEARNING

---

## AGENT COMPONENTS

### DigitalBody (`wallet.py`)
Self-custody wallet on Base chain using Coinbase AgentKit.

### DigitalSoul (`soul.py`)
Persistent memory and personality via ChromaDB.

### DigitalVoice (`farcaster.py`)
Social presence on Farcaster via Neynar API.

### DigitalEye (`vision.py`)
Computer vision via GPT-4V and browser automation.

### DigitalCourier (`messenger.py`)
Encrypted messaging via XMTP protocol.

### YieldEngine (`yield_engine.py`)
Passive income via Aave V3 on Base.

### Swarm (`swarm.py`)
Multi-agent task execution via LangGraph.

---

## OODA LOOP

The agent runs a continuous Observe-Orient-Decide-Act loop:

```python
async def _ooda_loop(self):
    """The OODA loop - Observe, Orient, Decide, Act"""
    while self._running:
        try:
            # OBSERVE - Gather information
            await self._observe()
            
            # ORIENT - Analyze situation
            context = await self._orient()
            
            # DECIDE - Choose action
            action = await self._decide(context)
            
            # ACT - Execute
            await self._act(action)
            
            # Wait for next cycle
            await asyncio.sleep(self.settings.ooda_interval)
            
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error("ooda_error", error=str(e))
            await asyncio.sleep(10)
```

---

## QUICK START

### Windows

```powershell
cd miniapps\ev0

# Demo mode (no API keys needed)
.\start.ps1 -demo

# Interactive CLI
.\start.ps1 -cli

# Full agent (requires .env config)
.\start.ps1
```

### Linux/macOS

```bash
cd miniapps/ev0

chmod +x start.sh

# Demo mode
./start.sh --demo

# Interactive CLI
./start.sh --cli

# Full agent
./start.sh
```

### Direct Python

```bash
cd miniapps/ev0
python run.py --demo
python run.py --cli
python run.py --status
python run.py  # Full agent
```

---

## SECURITY CONSIDERATIONS

1. **Private Keys** - Never stored in code, use CDP MPC wallet
2. **API Keys** - Store in `.env`, never commit
3. **Attestations** - Verify via EAS on Base mainnet
4. **Rate Limits** - Respect provider limits (see registry)
5. **Snyk Scanning** - Run on all new code per security rules

---

## LICENSE

MIT License - See LICENSE file

---

*Documentation generated for home.lab*
