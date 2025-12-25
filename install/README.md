# 🚀 HomeLab Complete Auto-Install System

> **One-click deployment - Choose your target platform**

## 🎯 Choose Your Platform

| Platform | Installer | Best For |
|----------|-----------|----------|
| **🖥️ Windows** | `install-wizard.ps1` | Local PC, Windows Server |
| **🐧 Linux** | `bootstrap.sh` | Debian, Ubuntu, Fedora, Arch |
| **🍎 macOS** | `install-macos.sh` | Mac Mini, MacBook, Mac Studio |
| **📱 Android** | `install-android.sh` | Termux on phones/tablets |
| **📱 iOS/iPad** | `INSTALL-IOS.md` | Access guide (no native install) |
| **🏠 Proxmox** | `orchestrator.ps1` | Dedicated bare-metal server |
| **🔧 Native** | `install-native.sh` | No Docker, bare-metal Linux |

> **New!** Want to run services directly on your OS without Docker? See **[Native vs Docker Guide](NATIVE-VS-DOCKER.md)**

---

## 🖥️ Windows (Recommended for Beginners)

Interactive wizard with GUI folder picker and component selection.

```powershell
# Open PowerShell as Administrator
cd C:\path\to\home.lab
.\install\install-wizard.ps1
```

**Features:**
- ✅ GUI folder browser
- ✅ 22 selectable components
- ✅ Automatic Docker Desktop detection
- ✅ Ollama model downloads
- ✅ Progress tracking

**Requirements:** Windows 10/11, 16GB+ RAM, 50GB+ disk

---

## 🐧 Linux (One-Liner)

```bash
# Debian, Ubuntu, Fedora, or Arch
curl -sSL https://raw.githubusercontent.com/kenj4mes/home.lab/main/bootstrap.sh | sudo bash

# Or with profile selection
sudo ./bootstrap.sh --full  # minimal | standard | full
```

**Features:**
- ✅ Automatic distro detection
- ✅ Docker + Ollama installation
- ✅ ZIM/model downloads
- ✅ Service auto-start

---

## 🍎 macOS

```bash
# Download and run
chmod +x install/install-macos.sh
./install/install-macos.sh --standard
```

**Features:**
- ✅ Homebrew auto-install
- ✅ Docker Desktop integration
- ✅ Apple Silicon (M1/M2/M3) optimized
- ✅ Native Ollama

**Requirements:** macOS 12+, Docker Desktop for Mac

---

## 📱 Android (Termux)

```bash
# 1. Install Termux from F-Droid (NOT Play Store)
# 2. Run setup storage
termux-setup-storage

# 3. Install HomeLab
pkg install curl
curl -sSL https://raw.githubusercontent.com/kenj4mes/home.lab/main/install/install-android.sh | bash
```

**Features:**
- ✅ AI chat client (connects to Ollama server)
- ✅ SSH server for remote access
- ✅ Python AI packages
- ✅ Offline knowledge tools

**Note:** Android runs a client/lite version. Full server requires proper hardware.

---

## 📱 iOS / iPadOS

iOS cannot run servers directly. See **[INSTALL-IOS.md](INSTALL-IOS.md)** for:

- ✅ Accessing HomeLab via web browser
- ✅ Native apps (Jellyfin, Kiwix, Grafana)
- ✅ SSH access via Termius
- ✅ Tailscale/VPN for remote access
- ✅ Siri Shortcuts integration

---

## 🏠 Proxmox (Bare Metal Server)

Full enterprise setup with ZFS and GPU passthrough.

```powershell
# From Windows orchestrator
.\install\orchestrator.ps1 -ProxmoxIP "192.168.1.10"
```

See detailed phases below.

---

## 🔧 Native Linux (No Docker)

For users who prefer running services directly on the OS without containers.

```bash
# Download and run
curl -sSL https://raw.githubusercontent.com/kenj4mes/home.lab/main/install/install-native.sh | sudo bash

# Or with profile selection
sudo ./install/install-native.sh --minimal   # Ollama only
sudo ./install/install-native.sh --standard  # + WebUI, Kiwix
sudo ./install/install-native.sh --full      # + All models
```

**Features:**
- ✅ No Docker required
- ✅ Native Ollama + Open WebUI
- ✅ Kiwix for offline Wikipedia
- ✅ Nginx reverse proxy
- ✅ Systemd service management

**Best For:**
- 🥧 Raspberry Pi / low-spec hardware
- 📚 Learning Linux administration
- 🔒 Air-gapped systems
- 🎯 Simple AI-only setup

**Trade-offs:**
- ⚠️ Fewer services available (~10 vs 75+)
- ⚠️ Manual updates per-service
- ⚠️ More complex troubleshooting

**See:** [NATIVE-VS-DOCKER.md](NATIVE-VS-DOCKER.md) for detailed comparison

---

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
- Creates ZFS pools (fast-pool, bulk-pool)
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
