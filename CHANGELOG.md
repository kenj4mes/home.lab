# Changelog

All notable changes to HomeLab will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
   tar czf backup.tar.gz /srv/FlashBang /srv/Tumadre
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
