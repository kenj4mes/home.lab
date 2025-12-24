# 🚀 HomeLab Complete Auto-Install System

> **One-click deployment - Choose your target platform**

## 🎯 Choose Your Setup

| Option | Best For | What You Need |
|--------|----------|---------------|
| **🖥️ Windows PC** | Run on your current machine | Windows 10/11 Pro |
| **🏠 Proxmox Server** | Dedicated home server | Spare PC/server hardware |

---

## 🖥️ Option A: Run on Your Windows PC

**Easiest option!** Run everything locally using Docker Desktop + WSL2.

```powershell
# Open PowerShell as Administrator
cd C:\Lab\install
.\setup-windows.ps1
```

This will automatically:
- ✅ Enable WSL2 (Windows Subsystem for Linux)
- ✅ Install Docker Desktop
- ✅ Install Ollama (local AI)
- ✅ Create data directories
- ✅ Download Wikipedia/LLMs (optional)
- ✅ Start all services

**Requirements:**
- Windows 10/11 Pro (or Education/Enterprise)
- 16GB+ RAM recommended
- 50GB+ free disk space

---

## 🏠 Option B: Dedicated Proxmox Server

Full virtualized setup with ZFS, GPU passthrough, and enterprise features.

### 📋 Installation Phases

| Phase | What Happens | Where It Runs |
|-------|--------------|---------------|
| **Phase 0** | Download Proxmox ISO, create bootable USB | Windows |
| **Phase 1** | Install Proxmox on bare metal | Server (manual) |
| **Phase 2** | Configure Proxmox, create ZFS pools | Proxmox host |
| **Phase 3** | Create & configure Debian VM | Proxmox host |
| **Phase 4** | Install Docker, download content, start services | Debian VM |

---

## 🖥️ Quick Start (From Windows)

### Automated Orchestrator

```powershell
# Run the Windows orchestrator
.\install\orchestrator.ps1
```

This will guide you through each phase with automated scripts.

---

## 📦 Phase 0: Prepare Installation Media (Windows)

```powershell
# Download Proxmox ISO and create bootable USB
.\install\phase0-prepare.ps1
```

**What it does:**
- Downloads latest Proxmox VE ISO
- Downloads Rufus (USB creator)
- Guides you through creating bootable USB

---

## 🔧 Phase 1: Install Proxmox (Manual - At Server)

1. Boot server from USB
2. Follow installer prompts
3. **IMPORTANT:** Select ZFS RAID1 for OS disk
4. Note the IP address shown at end

---

## ⚙️ Phase 2: Configure Proxmox Host

```bash
# SSH into Proxmox and run:
curl -sSL https://raw.githubusercontent.com/your-repo/main/install/phase2-proxmox.sh | bash
```

Or from Windows:
```powershell
.\install\phase2-deploy.ps1 -ProxmoxIP "192.168.1.10"
```

**What it does:**
- Removes subscription nag
- Enables IOMMU for GPU passthrough
- Creates ZFS pools (FlashBang, Tumadre)
- Configures networking

---

## 🖥️ Phase 3: Create Debian VM

```powershell
# From Windows:
.\install\phase3-create-vm.ps1 -ProxmoxIP "192.168.1.10"
```

**What it does:**
- Downloads Debian 12 cloud image
- Creates VM with optimal settings
- Configures GPU passthrough (if available)
- Starts VM and waits for boot

---

## 🐳 Phase 4: Deploy Services

```powershell
# From Windows:
.\install\phase4-deploy.ps1 -VMIP "192.168.1.100" -Profile "standard"
```

**What it does:**
- Installs Docker
- Installs Ollama
- Downloads Wikipedia ZIM files
- Downloads LLM models
- Starts all containers

---

## 🎯 One-Line Full Deploy (After Proxmox Install)

```powershell
# Replace IPs with your actual values
.\install\orchestrator.ps1 -ProxmoxIP "192.168.1.10" -SkipPhase0 -SkipPhase1 -Profile "standard"
```

---

## 📊 Download Profiles

| Profile | Download Size | Disk Usage | Content |
|---------|---------------|------------|---------|
| `minimal` | ~5 GB | ~10 GB | phi3, Simple Wikipedia |
| `standard` | ~35 GB | ~60 GB | Mistral, CodeLlama, Wikipedia, StackOverflow |
| `full` | ~150 GB | ~300 GB | All LLMs, Full Wikipedia, Gutenberg, etc. |

---

## 🔑 Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| Proxmox | root | (set during install) |
| Debian VM | homelab | homelab (change!) |
| Jellyfin | (create on first run) | |
| BookStack | admin@admin.com | password |
| qBittorrent | admin | adminadmin |
| Nginx Proxy | admin@example.com | changeme |

**⚠️ CHANGE ALL PASSWORDS AFTER INSTALL!**
