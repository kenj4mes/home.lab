# 🏠 home.lab

> Self-hosted infrastructure for the modern homelab enthusiast

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📋 Overview

home.lab is a comprehensive, production-grade self-hosted infrastructure stack featuring:

- 🤖 **AI Orchestration** - Local LLM inference with intelligent model routing
- 📊 **Unified Dashboard** - Real-time monitoring and control
- 🔒 **Security-First Design** - Constitutional AI principles and audit trails
- 📦 **50+ Integrated Services** - Media, databases, monitoring, and more
- 🔄 **Event-Driven Architecture** - Message bus and event sourcing

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose v2+
- 16GB+ RAM recommended
- Linux/macOS/WSL2

### Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd home.lab

# Copy environment template
cp .env.example .env

# Edit with your values
nano .env

# Bootstrap the infrastructure
make bootstrap

# Or run individual service groups
make core    # Core services (Redis, PostgreSQL)
make ai      # AI services (Ollama, orchestrator)
make monitor # Monitoring (Prometheus, Grafana)
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     🎛️ Dashboard (5300)                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────────────────────┐
│                    🚌 Message Bus (5100)                     │
└───┬─────────────┬──────────────┬────────────────────────────┘
    │             │              │
┌───┴───┐   ┌─────┴─────┐   ┌────┴─────┐   ┌──────────────┐
│ Event │   │    AI     │   │ Webhook  │   │   Services   │
│ Store │   │Orchestrator│   │ Handler  │   │   (50+)      │
│(5101) │   │  (5200)   │   │  (5400)  │   │              │
└───────┘   └───────────┘   └──────────┘   └──────────────┘
                │
        ┌───────┴───────┐
        │   🦙 Ollama    │
        │   (11434)     │
        └───────────────┘
```

## 📁 Directory Structure

```
home.lab/
├── configs/
│   ├── services/      # Service registry & priorities
│   ├── ai/            # AI models & ensembles
│   ├── monitoring/    # Dashboards & alerts
│   ├── security/      # Constitution & policies
│   ├── integrations/  # Webhooks & external APIs
│   └── settings.yaml  # Global configuration
├── miniapps/
│   ├── message-bus/   # Pub/sub messaging
│   ├── event-store/   # Immutable event log
│   ├── ai-orchestrator/ # AI routing & ensembles
│   ├── dashboard/     # Unified UI
│   └── webhook-handler/ # External integrations
├── scripts/
│   ├── deploy.sh      # Zero-downtime deployment
│   ├── backup.sh      # Automated backups
│   ├── health-check.sh # Comprehensive health checks
│   └── security/      # Audit scripts
├── docker/            # Docker compose stacks
├── terraform/         # Infrastructure as code
└── docs/              # Documentation
```

## 🔧 Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

| Variable | Description | Required |
|----------|-------------|----------|
| `HOMELAB_ENV` | Environment (development/staging/production) | Yes |
| `POSTGRES_PASSWORD` | PostgreSQL password | Yes |
| `REDIS_PASSWORD` | Redis password | No |
| `SLACK_WEBHOOK_URL` | Slack notifications | No |
| `ENABLE_AI_ORCHESTRATOR` | Enable AI features | No |

### Feature Flags

Enable/disable features in `configs/settings.yaml`:

```yaml
features:
  ai_orchestrator:
    enabled: true
  energy_monitoring:
    enabled: false
  remote_backup:
    enabled: false
```

## 🤖 AI Orchestration

The AI system supports:

- **Model Router** - Automatic task-to-model mapping
- **Ensembles** - Combine multiple models for better results
- **Reasoning Techniques** - Chain-of-thought, tree-of-thought, reflection

### Available Models

| Model | Use Case | Memory |
|-------|----------|--------|
| llama3.2 | General purpose | 4GB |
| qwen2.5-coder | Code generation | 4GB |
| deepseek-r1 | Deep reasoning | 8GB |
| gemma2 | Fast inference | 2GB |

## 📊 Monitoring

Access the dashboards:

- **Main Dashboard**: http://localhost:5300
- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9090

### Alerts

Alerts are configured for:

- High CPU/memory usage
- Service failures
- Security events
- AI inference errors

## 🔒 Security

### Constitutional AI

The system operates under immutable axioms:

1. **Beneficence** - Maximize global utility
2. **Non-Maleficence** - Do no harm
3. **Lawfulness** - Adhere to regulations
4. **Safety** - Operate within boundaries
5. **Transparency** - Document all actions
6. **Deference** - Respect human overrides

### Audit Trail

All actions are logged to the event store with SHA-256 hash chaining for integrity.

## 🚀 Deployment

### Manual Deployment

```bash
./scripts/deploy.sh production
```

### Automated CI/CD

Push to `main` branch triggers automatic deployment via GitHub Actions.

### Rollback

```bash
./scripts/deploy.sh production --rollback
```

## 📚 Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [API Reference](docs/API.md)
- [Runbooks](docs/RUNBOOKS.md)
- [Contributing](CONTRIBUTING.md)

## 🛠️ Maintenance

### Scheduled Tasks

| Task | Schedule | Description |
|------|----------|-------------|
| Backup | Daily 2 AM | Full system backup |
| Prune | Daily 4 AM | Docker cleanup |
| Health Check | Every 5 min | System health |
| Security Audit | Weekly | Security scan |

### Useful Commands

```bash
# View logs
make logs

# Restart all services
make restart

# Run health check
make health

# Security audit
make audit
```

## 📄 License

MIT License - See [LICENSE](LICENSE)

---

**Built with 💜 for the self-hosted community**
