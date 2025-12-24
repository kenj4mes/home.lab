# 🖥️ Proxmox VE Setup Guide

> **HomeLab** - Hypervisor Installation & Configuration

---

## 📋 Table of Contents

- [Overview](#overview)
- [Hardware Requirements](#hardware-requirements)
- [Installation](#installation)
- [Post-Installation Setup](#post-installation-setup)
- [Creating VMs](#creating-vms)
- [GPU Passthrough](#gpu-passthrough)
- [Networking](#networking)
- [Backup & Restore](#backup--restore)

---

## Overview

Proxmox VE (Virtual Environment) is a complete open-source platform for enterprise virtualization that combines:

- **KVM hypervisor** for full virtualization
- **LXC containers** for lightweight Linux containers
- **ZFS** for advanced storage management
- **Web-based management** interface

---

## Hardware Requirements

### Minimum

| Component | Specification |
|-----------|--------------|
| CPU | 64-bit with VT-x/AMD-V |
| RAM | 8 GB |
| Storage | 32 GB SSD |
| Network | 1× Ethernet |

### Recommended for HomeLab

| Component | Specification |
|-----------|--------------|
| CPU | Intel i5/i7 or AMD Ryzen (8+ threads) |
| RAM | 32-64 GB ECC |
| OS Storage | 2× 256 GB SSD (ZFS mirror) |
| VM Storage | 2× 1 TB NVMe (ZFS mirror) |
| Media Storage | 2× 8+ TB HDD (ZFS RAIDZ1) |
| Network | 2.5 GbE or 10 GbE |
| GPU | NVIDIA RTX (for passthrough) |

---

## Installation

### Step 1: Download ISO

1. Visit https://www.proxmox.com/en/downloads
2. Download "Proxmox VE ISO Installer"
3. Verify checksum (optional but recommended)

### Step 2: Create Bootable USB

**Windows (Rufus):**
1. Download Rufus: https://rufus.ie
2. Insert USB drive (8 GB+)
3. Select Proxmox ISO
4. Write in DD mode

**Linux:**
```bash
sudo dd if=proxmox-ve_*.iso of=/dev/sdX bs=4M status=progress
sync
```

### Step 3: Boot and Install

1. Boot from USB
2. Select "Install Proxmox VE"
3. Accept EULA
4. **Target Harddisk:**
   - Click "Options"
   - Select **ZFS (RAID1)** for mirrored SSDs
   - Select both SSDs for the mirror
5. **Country, Time zone, Keyboard**
6. **Password and Email** (for root user)
7. **Network Configuration:**
   - Hostname: `proxmox.local`
   - IP: Static IP (e.g., `192.168.1.10`)
   - Gateway: Your router IP
   - DNS: `1.1.1.1` or your Pi-hole
8. Click Install

### Step 4: First Login

1. Open browser: `https://<IP>:8006`
2. Accept self-signed certificate warning
3. Login: `root` / `<your password>`
4. Realm: `Linux PAM`

---

## Post-Installation Setup

### Remove Subscription Nag

```bash
# SSH into Proxmox
ssh root@<proxmox-ip>

# Disable enterprise repo
sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list

# Add no-subscription repo
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

# Update
apt update && apt full-upgrade -y
```

### Remove Subscription Popup (Web UI)

```bash
# Backup original file
cp /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak

# Remove subscription check
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

# Restart web service
systemctl restart pveproxy
```

### Enable IOMMU (for GPU Passthrough)

Edit GRUB:
```bash
nano /etc/default/grub
```

Find the line `GRUB_CMDLINE_LINUX_DEFAULT` and add:

**Intel CPU:**
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"
```

**AMD CPU:**
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"
```

Update GRUB and reboot:
```bash
update-grub
reboot
```

Verify IOMMU is enabled:
```bash
dmesg | grep -e DMAR -e IOMMU
```

### Add VFIO Modules

```bash
# Add modules
echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
echo "vfio_virqfd" >> /etc/modules

update-initramfs -u
```

---

## Creating VMs

### Debian 12 VM (Docker Host)

#### Via Web UI

1. **Upload ISO:**
   - Datacenter → pve → local → ISO Images
   - Upload Debian 12 netinstall ISO

2. **Create VM:**
   - Click "Create VM"
   - **General:**
     - Name: `docker-host`
     - VM ID: `100`
   - **OS:**
     - ISO image: Debian 12
     - Guest OS: Linux
   - **System:**
     - Machine: q35
     - BIOS: OVMF (UEFI)
     - Add EFI Disk: Yes
   - **Disks:**
     - Storage: homelab
     - Size: 100 GB
     - SSD emulation: Yes
   - **CPU:**
     - Cores: 4-8
     - Type: host
   - **Memory:**
     - 8192 MB (8 GB) minimum
     - 16384 MB (16 GB) for LLM
   - **Network:**
     - Bridge: vmbr0
     - Model: VirtIO

3. **Start and Install Debian**

#### Via CLI

```bash
# Create VM
qm create 100 \
  --name docker-host \
  --memory 16384 \
  --cores 8 \
  --cpu host \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-pci \
  --scsi0 homelab:100,format=raw,ssd=1 \
  --ide2 local:iso/debian-12-netinst.iso,media=cdrom \
  --boot order=ide2

# Start VM
qm start 100
```

---

## GPU Passthrough

### Step 1: Identify GPU

```bash
lspci -nn | grep -i nvidia
# Example output:
# 01:00.0 VGA compatible controller [0300]: NVIDIA Corporation ... [10de:2684]
# 01:00.1 Audio device [0403]: NVIDIA Corporation ... [10de:22ba]
```

Note the device IDs: `10de:2684,10de:22ba`

### Step 2: Blacklist Host Drivers

```bash
# Create blacklist file
cat > /etc/modprobe.d/blacklist-nvidia.conf << EOF
blacklist nouveau
blacklist nvidia
blacklist nvidiafb
blacklist nvidia_drm
EOF

# Bind GPU to VFIO
cat > /etc/modprobe.d/vfio.conf << EOF
options vfio-pci ids=10de:2684,10de:22ba
EOF

update-initramfs -u
reboot
```

### Step 3: Verify VFIO

```bash
lspci -nnk -s 01:00
# Should show: Kernel driver in use: vfio-pci
```

### Step 4: Add GPU to VM

Via Web UI:
1. Select VM → Hardware → Add → PCI Device
2. Select GPU (01:00.0)
3. Check: All Functions, ROM-Bar, PCI-Express
4. Start VM

Via CLI:
```bash
qm set 100 -hostpci0 01:00,pcie=1,x-vga=1
```

### Step 5: Install NVIDIA Drivers in VM

```bash
# Add non-free repos
apt install software-properties-common
add-apt-repository contrib non-free non-free-firmware

# Install drivers
apt update
apt install nvidia-driver firmware-misc-nonfree

reboot
```

Verify:
```bash
nvidia-smi
```

---

## Networking

### Bridge Configuration

Default network file: `/etc/network/interfaces`

```bash
auto lo
iface lo inet loopback

# Physical interface
auto eno1
iface eno1 inet manual

# Main bridge
auto vmbr0
iface vmbr0 inet static
    address 192.168.1.10/24
    gateway 192.168.1.1
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0

# VLAN for IoT (optional)
auto vmbr0.10
iface vmbr0.10 inet static
    address 192.168.10.1/24
```

Apply changes:
```bash
ifreload -a
```

---

## Backup & Restore

### Backup VM

Via Web UI:
1. Select VM → Backup → Backup now
2. Storage: Select backup location
3. Mode: Snapshot (recommended)
4. Compression: ZSTD

Via CLI:
```bash
vzdump 100 --storage homelab --mode snapshot --compress zstd
```

### Scheduled Backups

1. Datacenter → Backup → Add
2. Storage: Select location
3. Schedule: Daily at 2:00 AM
4. Selection mode: All or specific VMs
5. Retention: Keep last 7

### Restore VM

Via Web UI:
1. Datacenter → Storage → Backups
2. Select backup → Restore

Via CLI:
```bash
qmrestore /var/lib/vz/dump/vzdump-qemu-100-*.vma.zst 100
```

---

## Quick Reference

| Task | Command |
|------|---------|
| List VMs | `qm list` |
| Start VM | `qm start <vmid>` |
| Stop VM | `qm stop <vmid>` |
| Shutdown VM | `qm shutdown <vmid>` |
| VM config | `qm config <vmid>` |
| Console access | `qm terminal <vmid>` |
| List containers | `pct list` |
| Start container | `pct start <ctid>` |
| Update Proxmox | `apt update && apt full-upgrade` |
| Check cluster | `pvecm status` |
| ZFS status | `zpool status` |

---

*HomeLab - Self-Hosted Infrastructure*



