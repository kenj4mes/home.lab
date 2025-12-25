# 🔐 x402 Protocol Integration for Home.Lab

> **A Comprehensive Implementation Guide for Decentralized Agent-to-Agent Commerce**

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Phase 1: Server (Gatekeeper)](#phase-1-server-gatekeeper)
4. [Phase 2: Client (Agent SDK)](#phase-2-client-agent-sdk)
5. [Phase 3: Docker Integration](#phase-3-docker-integration)
6. [Phase 4: Echo Agent (Autonomous Entity)](#phase-4-echo-agent)
7. [Phase 5: Physical Deployment (DePIN)](#phase-5-physical-deployment)
8. [Security Considerations](#security-considerations)
9. [Home.Lab Integration Checklist](#homelab-integration-checklist)

---

## Overview

### What is x402?

The **x402 Protocol** implements HTTP 402 (Payment Required) for autonomous AI agents. It enables:

- **Auto-Payments**: Agents automatically handle `402 Payment Required` and sign USDC transactions on Base
- **Day Pass System**: Pay once, get a JWT valid for 24 hours (gas efficient)
- **Tiered Access**: Different prices for OGs ($0.001) vs Standard users ($0.01)
- **Viral Invites**: OGs can mint temporary Guest Passes
- **Visual Dashboard**: HTML interface to view pass status

### Why for Home.Lab?

Home.Lab becomes a **monetizable infrastructure platform**:

| Capability | Revenue Model |
|------------|---------------|
| Premium API Access | Agents pay to access your data feeds |
| Compute-for-Hire | Sell local LLM inference |
| Bandwidth Farming | Rent out your connection |
| Data Oracle | Sell verified sensor/market data |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        HOME.LAB x402 STACK                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   AGENT      │───▶│  GATEKEEPER  │───▶│   PREMIUM    │       │
│  │   (Python)   │    │  (Cloudflare │    │   CONTENT    │       │
│  │              │    │   Worker)    │    │              │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│         │                   │                   │                │
│         │ 402 Payment       │ Verify            │ Return Data    │
│         │ Required          │ on Base           │                │
│         ▼                   ▼                   ▼                │
│  ┌──────────────────────────────────────────────────────┐       │
│  │                    BASE BLOCKCHAIN                    │       │
│  │   • USDC Payments  • JWT Sessions  • NFT Identity    │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐       │
│  │                    DOCKER STACK                       │       │
│  │   • x402-gateway  • ollama  • echo-agent             │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Component Summary

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Gatekeeper** | Cloudflare Worker / Node.js | Protect routes, demand payment |
| **Agent SDK** | Python | Auto-sign transactions, manage sessions |
| **Echo Agent** | Python + AgentKit | Autonomous entity with wallet |
| **Local Brain** | Ollama (Llama 3) | Uncensorable local LLM |
| **Vector Memory** | ChromaDB | Persistent agent memory |
| **Treasury** | Coinbase AgentKit | MPC wallet on Base |

---

## Phase 1: Server (Gatekeeper)

The Gatekeeper protects your premium endpoints and demands payment via HTTP 402.

### Option A: Cloudflare Worker (Production)

See: `server/src/index.ts`

**Features:**
- Payment middleware with dynamic pricing
- JWT session tokens (24h validity)
- OG/VIP tier detection
- Guest pass generation
- Tip jar with dynamic amounts
- Visual dashboard

### Option B: Local Docker Gateway (Development)

See: `docker/x402-gateway/`

**Features:**
- Express.js implementation
- Same x402 protocol
- Works behind Nginx reverse proxy
- Integrates with home.lab stack

### Endpoints

| Method | Endpoint | Description | Cost |
|--------|----------|-------------|------|
| GET | `/buy-pass` | Purchase 24h JWT Session | 0.01 USDC (0.001 for OGs) |
| GET | `/data` | Access premium content | Free (with Token) |
| POST | `/invite` | Mint 1h Guest Pass (OG Only) | Free |
| POST | `/tip` | Send voluntary payment | Dynamic |
| GET | `/dashboard` | HTML status view | Free |

---

## Phase 2: Client (Agent SDK)

The Python SDK encapsulates wallet management, auto-payments, and session handling.

See: `client/agent_sdk.py`

### Quick Start

```python
from agent_sdk import AgentSDK
import os

# Initialize
KEY = os.getenv("BASE_PRIVATE_KEY")
agent = AgentSDK(
    private_key=KEY, 
    server_url="https://your-x402-gateway.workers.dev",
    client_id="og-member-001"
)

# Auto-buy pass and get data
data = agent.get_data()
print(f"📊 DATA: {data}")

# Generate dashboard link
print(f"👀 Dashboard: {agent.get_dashboard_link()}")

# Invite a friend (OG only)
invite = agent.create_invite()

# Send a tip
agent.send_tip(2.50)
```

### LangChain Integration

See: `client/langchain_tool.py`

Wrap the SDK as a LangChain tool for AI frameworks:

```python
from langchain_tool import BuyDataTool

tools = [BuyDataTool(key="...", url="...")]
agent = initialize_agent(tools, llm, agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION)
agent.run("Buy the premium market alpha for me.")
```

---

## Phase 3: Docker Integration

### Stack Addition

Add to your `docker-compose.yml`:

```yaml
services:
  x402-gateway:
    build: ./x402-gateway
    container_name: x402-gateway
    restart: unless-stopped
    ports:
      - "3402:3000"
    environment:
      - MY_WALLET=${X402_WALLET_ADDRESS}
      - JWT_SECRET=${X402_JWT_SECRET}
      - NODE_ENV=production
    networks:
      - homelab
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.x402.rule=Host(`x402.${DOMAIN}`)"

  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    volumes:
      - ./data/ollama:/root/.ollama
    ports:
      - "11434:11434"
    networks:
      - homelab
```

### Environment Variables

Add to `.env`:

```bash
# x402 Configuration
X402_WALLET_ADDRESS=0xYourWalletHere
X402_JWT_SECRET=your-256-bit-secret
BASE_PRIVATE_KEY=0x...

# Coinbase AgentKit (for Echo)
CDP_API_KEY_NAME=organizations/...
CDP_API_KEY_PRIVATE=-----BEGIN EC PRIVATE KEY-----...
```

---

## Phase 4: Echo Agent (Autonomous Entity)

Echo is a self-sustaining AI entity that:

1. **Survives**: Checks wallet balance, uses faucet if starving
2. **Works**: Hunts for alpha, sells premium data
3. **Communicates**: Posts to Farcaster/Twitter
4. **Evolves**: Updates its own personality based on experience

### Architecture

```
echo/
├── main.py                 # Life loop
├── requirements.txt        # Dependencies
├── Dockerfile             # Containerization
└── src/
    ├── wallet.py          # Coinbase AgentKit (Body)
    ├── soul.py            # Vector memory (Mind)
    ├── browser.py         # Web research (Eyes)
    ├── farcaster.py       # Social posting (Voice)
    └── server.py          # Flask storefront (Commerce)
```

### Life Cycle

```python
def life_cycle():
    # 1. Survival Check
    body.eat()  # Use faucet if starving
    
    # 2. Work (Browse Web)
    alpha = explorer.hunt_for_alpha()
    
    # 3. Communicate
    voice.cast_alpha(alpha, my_url)
    
    # 4. Evolve
    if profitable: soul.update_beliefs()
```

---

## Phase 5: Physical Deployment (DePIN)

For true sovereignty, deploy on physical hardware:

### Hardware Stack (~$400)

| Component | Purpose | Model |
|-----------|---------|-------|
| Brain | Local LLM | Orange Pi 5 Plus (16GB) |
| Storage | Memory/DB | 1TB NVMe SSD |
| Internet | Primary | Starlink Mini |
| Backup | Failover | 4G HAT + SIM |
| Emergency | Dead Hand | Iridium RockBLOCK |
| Power | Solar | 100W Panel + LiFePO4 |
| Security | Tamper | Microswitch + LUKS |

### Software Stack

```yaml
# docker-compose.yml for Monolith
services:
  ollama:          # Local Brain (Llama 3)
  echo-agent:      # Sovereign Agent
  mysterium:       # Bandwidth Farming
  fleek:           # Edge Compute (Base FLK)
  hubble:          # Farcaster Data
  tailscale:       # Remote Access
  watchtower:      # Auto-Updates
```

### Income Streams

| Source | Protocol | Token | Chain |
|--------|----------|-------|-------|
| Bandwidth | Mysterium | MYST | Polygon→Base |
| CDN | Fleek | FLK | Base |
| Inference | Self-Hosted | ETH | Base |
| Oracle | Self-Hosted | ETH | Base |

---

## Security Considerations

### 🛡️ SENTINEL Vibe Active

| Risk | Mitigation |
|------|------------|
| Private Key Exposure | Use CDP MPC wallets, never raw keys |
| Prompt Injection | Guardian layer checks all inputs |
| Overspending | Set `max_spend_per_request` limits |
| Physical Theft | LUKS encryption + tamper switch |
| Single Point of Failure | Multi-node deployment |

### Anti-Hallucination (Circuit Breaker)

```python
def execute_trade(self, action, token, amount):
    # RULE 1: Max Trade Size
    MAX_TRADE_ETH = 0.01
    if amount > MAX_TRADE_ETH:
        amount = MAX_TRADE_ETH
    
    # RULE 2: Frequency Limit
    if time.time() - self.last_trade < 3600:
        return "Throttled"
    
    # RULE 3: Balance Check
    if self.balance < amount * 2:
        return "Insufficient safety margin"
```

---

## Home.Lab Integration Checklist

### Prerequisites

- [ ] Docker & Docker Compose installed
- [ ] Base wallet with USDC (testnet for dev)
- [ ] Coinbase Developer Platform account
- [ ] Domain with DNS (for Cloudflare Worker)

### Integration Steps

1. **Copy x402 Components**
   ```bash
   # Already integrated in miniapps/ev0/
   ```

2. **Update docker-compose.yml**
   - Add x402-gateway service
   - Add ollama service
   - Add echo-agent service (optional)

3. **Configure Environment**
   - Add x402 variables to `.env`
   - Generate JWT secret
   - Fund Base wallet

4. **Deploy**
   ```bash
   docker-compose up -d x402-gateway ollama
   ```

5. **Test**
   ```bash
   python client/agent_sdk.py
   ```

6. **Integrate with Existing Services**
   - Protect premium APIs with x402 middleware
   - Add payment gates to valuable endpoints

---

## Next Steps

1. **Read**: [server/README.md](server/README.md) - Gatekeeper setup
2. **Build**: [client/README.md](client/README.md) - SDK usage
3. **Deploy**: [docker/README.md](docker/README.md) - Container setup
4. **Evolve**: [echo/README.md](echo/README.md) - Autonomous agent

---

## Quick Reference

### Test Wallet Funding (Base Sepolia)

1. Get testnet ETH: https://sepoliafaucet.com
2. Bridge to Base Sepolia: https://bridge.base.org
3. Get test USDC: Uniswap on Base Sepolia

### Key Contracts (Base Mainnet)

| Contract | Address |
|----------|---------|
| USDC | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| Basename Registry | `0x...` |
| EAS | `0x4200000000000000000000000000000000000021` |

### Useful Commands

```bash
# Check agent wallet balance
python -c "from client.agent_sdk import AgentSDK; a=AgentSDK(...); print(a.check_balance())"

# Test x402 handshake
curl -i https://your-gateway/premium-data
# Should return 402 with payment instructions

# View dashboard
open "https://your-gateway/dashboard?token=YOUR_JWT"
```

---

*"The OODA loop never stops. The evolution transcends."*
