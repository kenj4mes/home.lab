# 📋 Requirements

Before deploying HomeLab, ensure your system meets these requirements.

## Hardware

### Minimum (Single Node)

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 4 cores | 8+ cores |
| **RAM** | 16 GB | 32+ GB |
| **Storage** | 100 GB SSD | 1 TB NVMe |
| **Network** | 1 Gbps | 2.5+ Gbps |

### Recommended (Multi-Node Cluster)

| Component | Per Node | Total (3 nodes) |
|-----------|----------|-----------------|
| **CPU** | 4 cores i5/i7 | 12 cores |
| **RAM** | 32 GB | 96 GB |
| **Storage** | 1 TB NVMe | 3 TB |
| **Network** | 2.5 Gbps | 10 Gbps backbone |

### For GPU Workloads (AI/Creative)

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **GPU** | NVIDIA GTX 1080 (8GB) | NVIDIA RTX 3090/4090 (24GB) |
| **VRAM** | 8 GB | 24+ GB |
| **CUDA** | 11.8+ | 12.x |

## Software

### Required

| Software | Version | Purpose |
|----------|---------|---------|
| **Docker** | 24.x+ | Container runtime |
| **Docker Compose** | 2.20+ | Service orchestration |
| **Git** | 2.x+ | Repository management || **Git LFS** | 3.x+ | Large file storage (models, ZIMs) |
### Optional

| Software | Version | Purpose |
|----------|---------|---------|
| **kubectl** | 1.28+ | Kubernetes CLI |
| **Helm** | 3.x | Kubernetes package manager |
| **aria2c** | 1.36+ | Accelerated downloads |
| **PowerShell** | 7.x | Windows automation |

## Operating Systems

### Supported

| OS | Version | Notes |
|----|---------|-------|
| **Ubuntu** | 22.04 LTS, 24.04 LTS | Recommended for servers |
| **Debian** | 11, 12 | Stable, minimal |
| **Fedora** | 38+ | Cutting edge features |
| **Windows** | 10/11 + WSL2 | Desktop development |
| **Proxmox VE** | 8.x | Hypervisor deployment |

### Docker Desktop vs Native

| Platform | Recommended Setup |
|----------|------------------|
| **Linux** | Native Docker Engine |
| **Windows** | Docker Desktop with WSL2 backend |
| **macOS** | Docker Desktop (Intel/Apple Silicon) |

## Network

### Ports Required

| Port | Service | Protocol |
|------|---------|----------|
| 80 | HTTP | TCP |
| 443 | HTTPS | TCP |
| 3000 | Open WebUI | TCP |
| 8096 | Jellyfin | TCP |
| 9090 | Prometheus | TCP |
| 11434 | Ollama API | TCP |

### Firewall Rules

```bash
# Allow HomeLab ports
sudo ufw allow 80,443,3000,8096,9090,11434/tcp
```

## Storage Requirements

### Data Storage

| Data Set | Size | Status |
|----------|------|--------|
| **Kiwix ZIMs** | ~22 GB | ✅ Included via Git LFS |
| **SDXL + Whisper** | ~6.8 GB | ✅ Included via Git LFS |
| **Superchain Repos** | ~1 GB | ✅ Included via Git LFS |
| Ollama Models | ~26 GB | Optional download |
| Creative Models | ~50 GB | Optional download |

### Persistent Storage

| Volume | Estimated Size | Growth Rate |
|--------|---------------|-------------|
| Media Library | 100+ GB | High |
| Databases | 1-10 GB | Medium |
| Logs | 5-20 GB | Medium |
| Backups | 50+ GB | High |

## Pre-flight Checklist

- [ ] Docker and Docker Compose installed
- [ ] Git LFS installed (`git lfs install`)
- [ ] Sufficient disk space (100GB+ free)
- [ ] Network ports available
- [ ] Git configured with SSH keys (optional)
- [ ] GPU drivers installed (for AI workloads)
