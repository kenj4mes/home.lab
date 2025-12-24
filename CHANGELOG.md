# Changelog

All notable changes to HomeLab will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### Git LFS Data Inclusion 📦
- **Git LFS Configuration** - Large files now tracked and included in repository
  - `.gitattributes` with 13 tracked extensions (*.zim, *.safetensors, *.gguf, etc.)
  - ~29 GB of data files now clone with the repository
  
- **Included Data (via Git LFS)**
  - `data/zim/` - Kiwix offline encyclopedias (~22 GB)
    - Wikipedia, Wiktionary, WikiHow, Stack Overflow offline
  - `data/models/` - AI models (~6.8 GB)
    - SDXL base + VAE, Whisper large-v3
  - `superchain/` - Blockchain development repositories (~1 GB)
    - ethereum-optimism/op-geth, paradigmxyz/reth, etc.

#### Hugging Face Ecosystem 🤗
- **Install Scripts**
  - `scripts/install-huggingface.ps1` - Windows PowerShell installer
  - `scripts/install-huggingface.sh` - Linux/macOS installer
  - Installs: transformers, diffusers, accelerate, huggingface_hub, safetensors
  - Supports: minimal, standard, full installation profiles
  - Configurable cache directory and offline mode

- **Install Wizard Integration**
  - Added "HuggingFace" component to install wizard
  - Auto-installs Python dependencies for Creative AI

- **Documentation Updates**
  - Updated README.md with "Included Data (Git LFS)" section
  - Updated DATA_SOURCES.md with HuggingFace tooling section
  - Updated portable installation instructions for LFS workflow

### Changed
- `data/` and `superchain/` removed from .gitignore (now LFS-tracked)
- Kept `data/ollama/` and `data/volumes/` ignored (runtime data)
- Moved CREDENTIALS.example.txt to templates/ folder

### Removed
- 31 empty directories (orphaned from cloned repos)
- Python __pycache__ folders
- Temporary backup files

## [2.3.0] - 2025-01-20

### Added

#### GitHub Profile Analytics - Expert-Tier S+ Configuration 📊
Complete GitHub profile optimization system for achieving S+ rank status:

- **GitHub Actions Workflows** (`.github/workflows/`)
  - `profile-metrics.yml` - Full lowlighter/metrics with 8 generation steps
    - Header card, isocalendar full-year, languages indepth mode
    - Habits analysis (facts/charts), achievements (S+ rank)
    - Stars distribution, WakaTime integration, full dashboard
  - `profile-snake.yml` - Platane/snk contribution animation
    - Light/dark/ocean theme variants
    - Outputs to dedicated `output` branch
  - `profile-waka-readme.yml` - WakaTime IDE time tracking
    - 6-hour schedule for coding stats injection
  - `profile-blog-posts.yml` - RSS feed blog post updates

- **Documentation**
  - `docs/GITHUB_PROFILE.md` - Comprehensive expert setup guide
    - S+ rank algorithm breakdown (Stars 33.33%, PRs 25%, Commits 16.67%)
    - Critical flags: `include_all_commits=true`, `count_private=true`
    - PAT generation with required scopes
    - Trophy SECRET rank achievement guide

- **Templates & Scripts**
  - `templates/PROFILE_README.md` - Expert-tier profile template
    - Typing SVG animation
    - GitHub stats cards (S+ optimized)
    - Trophy shelf with SECRET ranks
    - Snake contribution animation
    - WakaTime coding time stats
    - Skill badges with Simple Icons
  - `scripts/setup-github-profile.sh` - Linux/macOS setup script
  - `scripts/setup-github-profile.ps1` - Windows PowerShell setup

- **Install Wizard Integration**
  - Added "GitHub Profile" component to install wizard
  - Automated PAT validation and secret setup

### S+ Rank Optimization Reference
```
┌──────────────────────────────────────────────────────────┐
│                  S+ RANK ALGORITHM                       │
├──────────────────────────────────────────────────────────┤
│ Stars Earned:      33.33%  → Get repos starred           │
│ Pull Requests:     25.00%  → Contribute to open source   │
│ Commits:           16.67%  → include_all_commits=true    │
│ Issues:             8.33%  → Open quality issues         │
│ Code Reviews:       8.33%  → Review PRs                  │
│ Followers:          8.33%  → Build community             │
└──────────────────────────────────────────────────────────┘

Critical Flags:
  &include_all_commits=true  ← Count private commits
  &count_private=true        ← Include private contributions
  &rank_icon=github          ← Clean rank display
```

## [2.2.0] - 2025-01-15

### Added

#### Experimental Stack - Cybernetic Evolution 🧪
Five pillars transforming the homelab into a cognitive cybernetic ecosystem:

- **LangFlow** (`k8s/experimental/langflow.yaml`) - Agentic AI orchestration
  - Visual LangChain IDE with drag-and-drop workflows
  - PostgreSQL backend for flow persistence
  - Ollama integration for local LLM inference
  - NetworkPolicy isolation and secure secrets management

- **Chaos Mesh** (`k8s/experimental/chaos-mesh.yaml`) - CNCF fault injection
  - Kernel-level chaos via eBPF (no sidecar required)
  - Controller, Dashboard, and DaemonSet deployment
  - Pre-built experiments: network-latency, pod-failure, stress-test, io-chaos
  - Chaos Daemon runs privileged for ptrace capabilities

- **Kepler** (`k8s/experimental/kepler.yaml`) - eBPF energy monitoring
  - Joules-per-container metrics via RAPL and eBPF
  - ServiceMonitor and PrometheusRules for alerting
  - Grafana Dashboard #17701 integration
  - Sustainability scoring per workload

- **Kratix** (`k8s/experimental/kratix.yaml`) - Platform engineering
  - Internal Developer Platform via Promises
  - DevEnvironment Promise for on-demand workspaces
  - AIModel Promise template for ML deployments
  - Reconciliation with State Stores

- **Rotki** (`k8s/experimental/rotki.yaml`) - Sovereign finance
  - Local-first DeFi portfolio analytics
  - Zero API keys required (chain RPC only)
  - Automated snapshot CronJob
  - NetworkPolicy restricting to Base/Ethereum RPC only

#### Docker Experimental Stack
- **docker-compose.experimental.yml** - Docker version of experimental services
  - LangFlow with PostgreSQL backend
  - Rotki portfolio tracker
  - Scaphandre energy monitoring (Docker alternative to Kepler)
  - n8n workflow automation
  - Dozzle real-time log viewer

#### Cybernetic Loop Architecture
- **SENSE** → Kepler eBPF probes collect energy/latency metrics
- **ANALYZE** → Prometheus aggregates, Grafana visualizes, Rotki tracks DeFi
- **DECIDE** → LangFlow agents process data, invoke tools, make decisions
- **ACT** → Kratix provisions resources, Chaos Mesh injects experiments

#### Documentation
- **docs/EXPERIMENTAL.md** - Comprehensive guide for all 5 pillars
- Updated **docs/ARCHITECTURE.md** with cybernetic evolution section
- Updated **README.md** with experimental stack features

### Changed
- Standardized paths: `/srv/FlashBang` → `/srv/homelab/config`
- Standardized paths: `/srv/Tumadre` → `/srv/homelab/data`
- ZFS pool names: `FlashBang` → `fast-pool`, `Tumadre` → `bulk-pool`
- Placeholder pattern: `YOUR_USERNAME` → `<your-github-username>` with CUSTOMIZE markers

### Fixed
- Removed personal path references throughout codebase
- Cleaned sensitive placeholders for public release
- Updated all documentation for production polish

## [2.1.0] - 2024-12-23

### Added

#### Post-Quantum Cryptography
- **Quantum Installer** (`install-quantum.sh`) - Installs liboqs, OpenSSL OQS provider, Notary v2, oqs-tools
- **PQ TLS Generator** (`generate-pq-tls.sh`) - Creates hybrid Kyber-768/Dilithium-5 TLS certificates
- **Docker Secrets** (`create-docker-secrets.sh`) - Generates cryptographically secure Docker secrets
- **Notary Setup** (`create-notary-secret.sh`) - Creates Dilithium-5 signing keys for DCT
- **Nginx PQ-SSL** (`configs/nginx-proxy/99-pq-ssl.conf`) - Hybrid TLS 1.3 configuration

#### Quantum Computing Services
- **Quantum RNG** (`miniapps/quantum-rng/`) - Quantum random number generator with REST API
- **Quantum Simulator** (`miniapps/quantum-simulator/`) - Circuit simulator with Qiskit, Cirq, PennyLane
- **Docker Compose Quantum** (`docker-compose.quantum.yml`) - Quantum services stack
- **Pre-built Circuits** - Bell state, GHZ, W state, QFT, Grover, QAOA templates

#### Security Enhancements
- **Quantum-Safe Backups** - Updated `backup.sh` with oqsenc support for PQ encryption
- **Hybrid Key Exchange** - X25519Kyber768 when OQS provider is active
- **QRNG Integration** - Scripts can use quantum entropy for secret generation

#### Documentation
- **QUANTUM.md** - Complete post-quantum and quantum computing guide
- Updated README with quantum features section
- Updated architecture diagram

#### CI/CD
- **Quantum Validation Job** - Validates quantum Python files and configs
- Validates `docker-compose.quantum.yml`

## [2.0.0] - 2024-12-23

### Added

#### Infrastructure
- **Unified CLI** (`homelab.ps1`) - Single PowerShell command for all operations with `-WhatIf` support
- **Makefile** - Cross-platform task runner for Linux/macOS
- **Docker Compose Profiles** - Separate compose files for core, blockchain, monitoring, arr stack, pihole

#### Security
- **Environment Generator** (`env-generator.sh`) - Automatic secure secret generation using `openssl rand`
- **Health Checks** - All services now include Docker health checks
- **Container Hardening** - `no-new-privileges`, separate internal networks
- **Security Documentation** - Comprehensive hardening guide in `docs/SECURITY.md`

#### Model Management
- **Model Catalog** (`scripts/models/catalog.json`) - JSON catalog of available Ollama models
- **Model Downloader** (`download-models.sh`) - Profile-based and group-based model downloading
- **Model Groups** - foundation, code, reasoning, multilingual, vision, compact, uncensored
- **Download Library** (`lib/download.sh`) - Robust downloads with retry, resume, and checksum verification

#### Blockchain Integration
- **Base L2 Node** - Self-hosted Base blockchain node (light/snap/full sync)
- **Blockscout Explorer** - Local block explorer at port 4000
- **Wallet CLI API** - REST API for wallet operations (generate, balance, send, query)
- **Web3.py Integration** - Python-based wallet management

#### Monitoring
- **Prometheus** - Metrics collection with pre-configured scrape targets
- **Grafana** - Dashboards and visualization with auto-provisioned datasources
- **Loki** - Log aggregation for centralized logging
- **Promtail** - Log collection from Docker containers and system logs
- **cAdvisor** - Container resource metrics
- **Node Exporter** - Host system metrics

#### Infrastructure as Code
- **Terraform** - Proxmox VM provisioning with telmate/proxmox provider
- **Cloud-Init** - Automated VM configuration

#### CI/CD
- **GitHub Actions** - Comprehensive linting and validation workflow
  - ShellCheck for bash scripts
  - PSScriptAnalyzer for PowerShell
  - Docker Compose validation
  - YAML/JSON linting
  - Terraform validation
  - Security scanning

#### Documentation
- Updated README with architecture diagram, feature list, and quick start
- BASE.md - Blockchain integration guide
- SECURITY.md - Security hardening checklist
- MAINTENANCE.md - Operations and backup guide
- TROUBLESHOOTING.md - Common issues and solutions

### Changed
- Replaced individual helper scripts with unified CLI
- Standardized logging across all bash scripts using `lib/common.sh`
- Improved error handling with stack traces
- Made all scripts idempotent (safe to run multiple times)

### Security
- All default passwords are now placeholders (`CHANGEME_*`)
- `.env` file is auto-generated and excluded from git
- Added comprehensive `.gitignore`

## [1.0.0] - 2024-12-01

### Added
- Initial release
- Core services: Jellyfin, qBittorrent, Kiwix, BookStack, Nginx Proxy Manager
- Ollama + Open WebUI for local AI
- Portainer for container management
- Basic Windows setup script
- Linux bootstrap script
- ZIM file downloader

---

## Quick Reference

### Upgrade from 1.x to 2.x

1. Backup your data:
   ```bash
   tar czf backup.tar.gz /srv/homelab/config /srv/homelab/data
   ```

2. Pull the latest changes:
   ```bash
   git pull origin main
   ```

3. Generate new secure secrets:
   ```bash
   ./scripts/env-generator.sh --force
   ```

4. Restart services:
   ```bash
   make update
   ```

### Links

- [GitHub Repository](https://github.com/YOUR_USERNAME/homelab)
- [Security Guide](docs/SECURITY.md)
- [Blockchain Guide](docs/BASE.md)
- [Issue Tracker](https://github.com/YOUR_USERNAME/homelab/issues)
