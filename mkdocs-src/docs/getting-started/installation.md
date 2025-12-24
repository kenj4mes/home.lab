# 📦 Installation Guide

Detailed installation instructions for all platforms.

## Quick Install

### Linux (One-liner)

```bash
# CUSTOMIZE: Replace <your-github-username> with your GitHub username
curl -sSL https://raw.githubusercontent.com/<your-github-username>/home.lab/main/bootstrap.sh | bash
```

### Windows (PowerShell)

```powershell
# Run as Administrator
.\install\install-wizard.ps1
```

## Manual Installation

### Step 1: Clone Repository (with Git LFS)

```bash
# Install Git LFS first
git lfs install

# CUSTOMIZE: Replace <your-github-username> with your GitHub username
# Includes ~29GB of data via LFS (ZIMs, models, Superchain)
git clone https://github.com/<your-github-username>/home.lab.git
cd home.lab
```

!!! info "About Git LFS"
    Large data files are tracked with Git LFS and download automatically.
    This includes offline encyclopedias, AI models, and blockchain repos.

### Step 2: Configure Environment

```bash
# Copy example credentials
cp CREDENTIALS.example.txt .env

# Edit with your values
nano .env
```

!!! danger "Security"
    Replace ALL `CHANGEME_*` values with secure passwords before starting!

### Step 3: Download Optional Data

```bash
# ZIM files and SDXL models already included via Git LFS!

# Optional: Download Ollama LLM models (~26GB)
./scripts/download-models.sh

# Optional: Creative AI models (Bark, MusicGen, etc.)
./scripts/download-all.sh --creative
```

### Step 4: Start Services

```bash
# Start core services
docker compose up -d

# Check status
docker compose ps
```

## Platform-Specific Instructions

### Ubuntu/Debian

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Relogin, then run setup
./bootstrap.sh
```

### Fedora

```bash
# Install Docker
sudo dnf install -y docker docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# Run setup
./bootstrap.sh
```

### Windows + WSL2

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
2. Enable WSL2 backend in settings
3. Open PowerShell as Administrator:

```powershell
.\install\setup-windows.ps1
```

### Proxmox VE

```bash
# On Proxmox host, create VM
./terraform/apply.sh

# Inside VM
./bootstrap.sh
```

## Post-Installation

### Verify Services

| Service | URL | Check |
|---------|-----|-------|
| Portainer | http://localhost:9000 | Create admin account |
| Ollama | http://localhost:11434 | API responds |
| Open WebUI | http://localhost:3000 | Login page loads |
| Jellyfin | http://localhost:8096 | Setup wizard |

### First-Time Setup

1. **Portainer**: Create admin user on first visit
2. **Open WebUI**: First signup becomes admin
3. **Jellyfin**: Run through setup wizard
4. **Grafana**: Login with admin/admin, change password

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Port already in use | Change port in `.env` or stop conflicting service |
| Permission denied | Run with `sudo` or add user to docker group |
| Out of memory | Reduce services or increase RAM |
| Slow downloads | Use `aria2c` with `--connections=16` |

See [Troubleshooting Guide](../operations/troubleshooting.md) for more help.
