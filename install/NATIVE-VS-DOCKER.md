# 🔧 Native vs Docker Installation Guide

> Choose the right installation method for your use case.

---

## Quick Comparison

| Aspect | Native | Docker | Recommendation |
|--------|--------|--------|----------------|
| **Resource Usage** | Lower (~10-20% less RAM) | Higher (container overhead) | Native for low-spec |
| **Isolation** | Shared system | Fully isolated | Docker for security |
| **Updates** | Manual per-service | `docker compose pull` | Docker for ease |
| **Portability** | OS-specific | Runs anywhere | Docker for flexibility |
| **Debugging** | Direct system access | Container logs | Native for learning |
| **Backup** | Complex | Simple volume backup | Docker for data safety |
| **Services Available** | Limited (~10) | Full (~75+) | Docker for all features |

---

## 🖥️ When to Use Native Installation

### ✅ Good For:
- **Raspberry Pi / Low-spec hardware** - Every MB of RAM counts
- **Learning Linux** - See how services work directly
- **Single-service setup** - Just want Ollama + AI chat
- **Air-gapped systems** - Where Docker can't be installed
- **Development** - Quick iteration without container rebuilds

### ❌ Limitations:
- Fewer services available natively
- More complex updates
- Dependency conflicts possible
- Harder to backup/migrate

---

## 🐳 When to Use Docker Installation

### ✅ Good For:
- **Full HomeLab setup** - 75+ services available
- **Production stability** - Isolated, reproducible
- **Easy management** - `docker compose up -d`
- **Multi-service stacks** - Media server, monitoring, etc.
- **Team environments** - Same setup everywhere

### ❌ Limitations:
- ~10-20% RAM overhead
- Requires Docker knowledge
- Larger disk footprint

---

## 📊 Service Availability by Method

### Native Installation (install-native.sh)

| Service | Available | Notes |
|---------|-----------|-------|
| **Ollama** | ✅ Yes | Full native support |
| **Open WebUI** | ✅ Yes | Python-based |
| **Kiwix** | ✅ Yes | Native binary |
| **Redis** | ✅ Yes | System package |
| **Nginx** | ✅ Yes | Reverse proxy |
| BookStack | ⚠️ Manual | Requires PHP/MySQL setup |
| Jellyfin | ⚠️ Manual | Complex dependencies |
| Prometheus | ⚠️ Manual | Go binary available |
| Grafana | ⚠️ Manual | Complex setup |

### Docker Installation (bootstrap.sh)

| Service | Available | Notes |
|---------|-----------|-------|
| **Everything above** | ✅ Yes | Plus... |
| Jellyfin | ✅ Yes | Full media server |
| Plex | ✅ Yes | Alternative media |
| Sonarr/Radarr | ✅ Yes | Media automation |
| Home Assistant | ✅ Yes | Smart home |
| Prometheus/Grafana | ✅ Yes | Full monitoring |
| BookStack | ✅ Yes | Documentation wiki |
| Portainer | ✅ Yes | Docker management UI |
| Authentik | ✅ Yes | SSO/Identity |
| +60 more | ✅ Yes | See services/ |

---

## 🚀 Installation Commands

### Native (No Docker)
```bash
# Download and run
curl -fsSL https://raw.githubusercontent.com/yourusername/home.lab/main/install/install-native.sh | sudo bash

# Or with profile
sudo ./install/install-native.sh --minimal  # Ollama only
sudo ./install/install-native.sh --standard # + WebUI, Kiwix
sudo ./install/install-native.sh --full     # + All models
```

### Docker (Full Features)
```bash
# Linux/macOS
./bootstrap.sh

# Windows
.\homelab.ps1
```

---

## 🔄 Hybrid Approach

You can mix both approaches:

```bash
# Install Ollama natively (better performance)
curl -fsSL https://ollama.ai/install.sh | sh

# Run other services in Docker
docker compose -f docker/compose.media.yml up -d
```

**Benefits:**
- AI runs at native speed
- Media services isolated
- Best of both worlds

---

## 📦 Native Installation Details

### Supported Operating Systems

| OS | Status | Notes |
|----|--------|-------|
| Ubuntu 22.04+ | ✅ Full | Recommended |
| Debian 12+ | ✅ Full | Stable choice |
| Fedora 38+ | ✅ Full | Cutting edge |
| Arch Linux | ✅ Full | Rolling release |
| Raspberry Pi OS | ✅ Full | ARM optimized |
| CentOS/RHEL 9+ | ⚠️ Partial | May need EPEL |
| Alpine | ❌ No | Use Docker instead |

### What Gets Installed

```
/opt/homelab/              # Application files
├── open-webui/            # AI chat interface
│   └── venv/              # Python virtual env
├── kiwix/                 # Offline wiki tools
├── config/                # Configuration
└── logs/                  # Log files

/srv/homelab/              # Data files
├── ZIM/                   # Wikipedia archives
├── Movies/                # Media (optional)
├── Books/                 # eBooks (optional)
└── models/                # AI models

/usr/local/bin/homelab     # Management script
```

### Systemd Services

```bash
# Services created
systemctl status ollama        # AI model server
systemctl status open-webui    # Chat interface
systemctl status kiwix         # Wikipedia server
systemctl status nginx         # Reverse proxy

# Management
homelab status    # Check all
homelab start     # Start all
homelab stop      # Stop web services
homelab logs      # View logs
```

---

## 🔧 Manual Native Installation

For services not covered by the script:

### Jellyfin (Native)
```bash
# Ubuntu/Debian
curl -fsSL https://repo.jellyfin.org/install-debuntu.sh | sudo bash
```

### Prometheus (Native)
```bash
# Download and extract
wget https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz
cd prometheus-*
./prometheus --config.file=prometheus.yml
```

### Grafana (Native)
```bash
# Ubuntu/Debian
sudo apt-get install -y grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

---

## 🆘 Troubleshooting

### Native Issues

**Service won't start:**
```bash
# Check logs
journalctl -u <service-name> -f

# Check port conflicts
sudo lsof -i :<port>

# Fix permissions
sudo chown -R $USER:$USER /opt/homelab /srv/homelab
```

**Dependency conflicts:**
```bash
# Use virtual environments
python3 -m venv /opt/homelab/venv
source /opt/homelab/venv/bin/activate
pip install <package>
```

### Docker Issues

**Container won't start:**
```bash
# Check logs
docker compose logs <service>

# Rebuild
docker compose up -d --build

# Full reset
docker compose down -v
docker compose up -d
```

---

## 📈 Resource Comparison

### Minimal HomeLab (AI Chat Only)

| Resource | Native | Docker |
|----------|--------|--------|
| RAM | 2GB | 2.5GB |
| Disk | 10GB | 15GB |
| CPU | 5-10% | 8-12% |

### Standard HomeLab (AI + Media + Wiki)

| Resource | Native | Docker |
|----------|--------|--------|
| RAM | 4GB | 6GB |
| Disk | 30GB | 40GB |
| CPU | 10-20% | 15-25% |

### Full HomeLab (Everything)

| Resource | Docker Only |
|----------|-------------|
| RAM | 16GB+ |
| Disk | 100GB+ |
| CPU | Variable |

*Note: Full setup only available via Docker*

---

## 🎯 My Recommendation

| Scenario | Recommendation |
|----------|----------------|
| Raspberry Pi 4 (4GB) | Native - minimal |
| Old laptop (8GB) | Native - standard |
| Desktop (16GB+) | Docker - full |
| NAS/Server | Docker - full |
| Learning Linux | Native - educational |
| Production use | Docker - reliable |
| Air-gapped | Native - required |

---

*Happy homelabbing! Choose what works for YOU.* 🏠
