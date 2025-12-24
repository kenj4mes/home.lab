# 🚀 Quick Start Guide

Get HomeLab running in 10 minutes.

## Prerequisites

- Docker & Docker Compose installed
- 16GB+ RAM recommended
- 100GB+ free disk space
- Linux, macOS, or Windows with WSL2

## One-Command Install

=== "Linux/macOS"

    ```bash
    # CUSTOMIZE: Replace <your-github-username> with your GitHub username
    curl -sSL https://raw.githubusercontent.com/<your-github-username>/home.lab/main/bootstrap.sh | bash
    ```

=== "Windows (PowerShell)"

    ```powershell
    # CUSTOMIZE: Replace <your-github-username> with your GitHub username
    irm https://raw.githubusercontent.com/<your-github-username>/home.lab/main/install/setup-windows.ps1 | iex
    ```

## Manual Installation

### Step 1: Clone Repository (with LFS Data)

```bash
# Install Git LFS if not already installed
git lfs install

# CUSTOMIZE: Replace <your-github-username> with your GitHub username
# This includes ~29GB of data via LFS (ZIM files, AI models, Superchain)
git clone https://github.com/<your-github-username>/home.lab.git
cd home.lab
```

!!! info "Git LFS"
    The repository includes ~29GB of offline data tracked via Git LFS.
    ZIM encyclopedias, SDXL models, and Superchain repos download automatically.

### Step 2: Configure Environment

```bash
cp CREDENTIALS.example.txt .env
# Edit .env with your settings
```

!!! warning "Security"
    Change ALL `CHANGEME_*` placeholders before starting services!

### Step 3: Download Optional Extras

```bash
# Core data (ZIM + SDXL + Superchain) already included via Git LFS!

# Optional: Download Ollama LLM models (~26GB)
./scripts/download-models.sh

# Optional: Download Creative AI models (Bark, MusicGen)
./scripts/download-all.sh --creative
```

!!! success "Already Included via Git LFS"
    ✅ Kiwix ZIM files (~22GB) - Wikipedia, StackOverflow offline  
    ✅ SDXL + Whisper models (~6.8GB)  
    ✅ Superchain repositories (~1GB)

### Step 4: Start Services

```bash
# Start core services
docker compose up -d

# Start monitoring
docker compose -f docker-compose.monitoring.yml up -d
```

## Verify Installation

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Jellyfin | http://localhost:8096 | Create on first visit |
| Open WebUI | http://localhost:3000 | Create on first visit |
| Portainer | http://localhost:9000 | Create on first visit |
| Grafana | http://localhost:3100 | admin / admin |
| Kiwix | http://localhost:8081 | None required |

## Next Steps

- [Configure network settings](../architecture/network.md)
- [Set up monitoring](../operations/monitoring.md)
- [Enable Kubernetes](../kubernetes/setup.md)
- [Configure backups](../operations/backup.md)
