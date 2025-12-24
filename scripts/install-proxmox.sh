#!/bin/bash
# ==============================================================================
# Install Proxmox VE Prerequisites Script
# ==============================================================================
# Run this on Debian 12 to prepare for Proxmox VE installation
# Note: Full Proxmox requires bare-metal installation from ISO
#
# This script installs Proxmox VE on top of existing Debian 12
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║               Proxmox VE Installation on Debian 12                            ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Must run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Check if Debian 12
if ! grep -q "bookworm" /etc/os-release; then
    echo -e "${RED}This script requires Debian 12 (Bookworm)${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  WARNING: Installing Proxmox on existing Debian${NC}"
echo ""
echo "This will convert your Debian installation to Proxmox VE."
echo "Recommended: Fresh Proxmox ISO installation for production use."
echo ""
read -p "Continue? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# ==============================================================================
# Set Hostname
# ==============================================================================

echo -e "${BLUE}Configuring hostname...${NC}"

CURRENT_HOST=$(hostname)
read -p "Enter hostname for Proxmox [${CURRENT_HOST}]: " NEW_HOST
NEW_HOST="${NEW_HOST:-$CURRENT_HOST}"

# Get IP
IP=$(hostname -I | awk '{print $1}')
read -p "Enter IP address [${IP}]: " NEW_IP
NEW_IP="${NEW_IP:-$IP}"

# Set hostname
hostnamectl set-hostname "$NEW_HOST"

# Update /etc/hosts
if ! grep -q "$NEW_HOST" /etc/hosts; then
    echo "${NEW_IP} ${NEW_HOST}.local ${NEW_HOST}" >> /etc/hosts
fi

echo -e "${GREEN}✓ Hostname configured: ${NEW_HOST}${NC}"

# ==============================================================================
# Add Proxmox Repository
# ==============================================================================

echo -e "${BLUE}Adding Proxmox repository...${NC}"

# Add Proxmox GPG key
wget -qO /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg \
    http://download.proxmox.com/debian/proxmox-release-bookworm.gpg

# Add repository
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > \
    /etc/apt/sources.list.d/pve-install-repo.list

apt-get update

echo -e "${GREEN}✓ Repository added${NC}"

# ==============================================================================
# Install Proxmox Kernel
# ==============================================================================

echo -e "${BLUE}Installing Proxmox kernel...${NC}"

apt-get install -y proxmox-default-kernel

echo -e "${GREEN}✓ Proxmox kernel installed${NC}"
echo -e "${YELLOW}A reboot will be required after installation${NC}"

# ==============================================================================
# Install Proxmox VE
# ==============================================================================

echo -e "${BLUE}Installing Proxmox VE packages...${NC}"

DEBIAN_FRONTEND=noninteractive apt-get install -y \
    proxmox-ve \
    postfix \
    open-iscsi \
    chrony

echo -e "${GREEN}✓ Proxmox VE installed${NC}"

# ==============================================================================
# Remove Standard Kernel (Optional)
# ==============================================================================

echo -e "${BLUE}Cleaning up...${NC}"

# Remove the standard Debian kernel
apt-get remove -y linux-image-amd64 'linux-image-6.1*' 2>/dev/null || true
update-grub

echo -e "${GREEN}✓ Cleanup complete${NC}"

# ==============================================================================
# Summary
# ==============================================================================

echo -e "\n${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                     ✓ Proxmox VE Installation Complete                       ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo "Next steps:"
echo "  1. Reboot the system: reboot"
echo "  2. Access Proxmox web UI: https://${NEW_IP}:8006"
echo "  3. Login with root and your system password"
echo ""
echo -e "${YELLOW}⚠️  REBOOT REQUIRED${NC}"
echo ""

read -p "Reboot now? (y/N): " reboot_now
if [[ "$reboot_now" =~ ^[Yy]$ ]]; then
    reboot
fi
