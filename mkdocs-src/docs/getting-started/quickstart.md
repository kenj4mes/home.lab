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
    curl -sSL https://raw.githubusercontent.com/kenj4mes/home.lab/main/bootstrap.sh | bash
    ```

=== "Windows (PowerShell)"

    ```powershell
    irm https://raw.githubusercontent.com/kenj4mes/home.lab/main/install/setup-windows.ps1 | iex
    ```

## Manual Installation

### Step 1: Clone Repository

```bash
git clone https://github.com/kenj4mes/home.lab.git
cd home.lab
```

### Step 2: Configure Environment

```bash
cp CREDENTIALS.example.txt .env
# Edit .env with your settings
```

!!! warning "Security"
    Change ALL `CHANGEME_*` placeholders before starting services!

### Step 3: Download Offline Data

```bash
# Download AI models (~26GB)
./scripts/download-models.sh

# Download Kiwix ZIMs (~22GB)
./scripts/download-all.sh
```

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
