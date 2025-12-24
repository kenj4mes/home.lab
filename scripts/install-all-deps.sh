#!/bin/bash
# ==============================================================================
# Complete System Setup - All Dependencies
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Installs ALL dependencies on a fresh Debian/Ubuntu system:
#   - Essential build tools
#   - Docker & Docker Compose
#   - Ollama (LLM runtime)
#   - NVIDIA drivers & container toolkit (if GPU detected)
#   - System utilities
#
# Usage:
#   sudo ./install-all-deps.sh
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
echo "║                 Complete Dependency Installation                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Must run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# System Update
# ==============================================================================

echo -e "${BLUE}[1/7] Updating system packages...${NC}"
apt-get update
apt-get upgrade -y
echo -e "${GREEN}✓ System updated${NC}"

# ==============================================================================
# Essential Packages
# ==============================================================================

echo -e "${BLUE}[2/7] Installing essential packages...${NC}"
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    vim \
    htop \
    iotop \
    tmux \
    net-tools \
    dnsutils \
    jq \
    tree \
    unzip \
    rsync \
    ncdu \
    pv \
    lm-sensors \
    smartmontools

echo -e "${GREEN}✓ Essential packages installed${NC}"

# ==============================================================================
# Docker
# ==============================================================================

echo -e "${BLUE}[3/7] Installing Docker...${NC}"

if command -v docker &> /dev/null; then
    echo -e "${YELLOW}○ Docker already installed: $(docker --version)${NC}"
else
    # Use the dedicated script if available
    if [[ -f "${SCRIPT_DIR}/install-docker.sh" ]]; then
        "${SCRIPT_DIR}/install-docker.sh"
    else
        # Inline installation
        curl -fsSL https://get.docker.com | sh
        
        # Add current user to docker group
        if [[ -n "${SUDO_USER}" ]]; then
            usermod -aG docker "${SUDO_USER}"
        fi
        
        # Enable and start
        systemctl enable docker
        systemctl start docker
    fi
    echo -e "${GREEN}✓ Docker installed${NC}"
fi

# Install Docker Compose plugin
if ! docker compose version &> /dev/null; then
    echo -e "${BLUE}Installing Docker Compose...${NC}"
    apt-get install -y docker-compose-plugin
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${YELLOW}○ Docker Compose already installed${NC}"
fi

# ==============================================================================
# NVIDIA Detection and Setup
# ==============================================================================

echo -e "${BLUE}[4/7] Checking for NVIDIA GPU...${NC}"

if lspci | grep -i nvidia &> /dev/null; then
    echo -e "${GREEN}NVIDIA GPU detected!${NC}"
    
    # Install NVIDIA drivers if not present
    if ! command -v nvidia-smi &> /dev/null; then
        echo -e "${BLUE}Installing NVIDIA drivers...${NC}"
        
        # Add NVIDIA repository
        distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
            gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        
        curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
        
        apt-get update
        apt-get install -y nvidia-driver nvidia-container-toolkit
        
        # Configure Docker for NVIDIA
        nvidia-ctk runtime configure --runtime=docker
        systemctl restart docker
        
        echo -e "${GREEN}✓ NVIDIA drivers and container toolkit installed${NC}"
        echo -e "${YELLOW}⚠️  Reboot required for full GPU support${NC}"
    else
        echo -e "${YELLOW}○ NVIDIA drivers already installed${NC}"
        nvidia-smi --query-gpu=name --format=csv,noheader
    fi
else
    echo -e "${YELLOW}○ No NVIDIA GPU detected, skipping GPU setup${NC}"
fi

# ==============================================================================
# Ollama
# ==============================================================================

echo -e "${BLUE}[5/7] Installing Ollama...${NC}"

if command -v ollama &> /dev/null; then
    echo -e "${YELLOW}○ Ollama already installed: $(ollama --version)${NC}"
else
    if [[ -f "${SCRIPT_DIR}/install-ollama.sh" ]]; then
        "${SCRIPT_DIR}/install-ollama.sh"
    else
        curl -fsSL https://ollama.ai/install.sh | sh
    fi
    echo -e "${GREEN}✓ Ollama installed${NC}"
fi

# ==============================================================================
# ZFS Utilities (Optional)
# ==============================================================================

echo -e "${BLUE}[6/7] Installing ZFS utilities...${NC}"

if command -v zfs &> /dev/null; then
    echo -e "${YELLOW}○ ZFS already installed${NC}"
else
    apt-get install -y zfsutils-linux 2>/dev/null || \
        echo -e "${YELLOW}○ ZFS not available (may need backports or Proxmox)${NC}"
fi

# ==============================================================================
# Final Configuration
# ==============================================================================

echo -e "${BLUE}[7/7] Final configuration...${NC}"

# Enable swap if not present
if [[ $(swapon --show | wc -l) -eq 0 ]]; then
    echo -e "${BLUE}Creating swap file...${NC}"
    if [[ ! -f /swapfile ]]; then
        fallocate -l 4G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        echo -e "${GREEN}✓ 4GB swap created${NC}"
    fi
fi

# Set timezone if not configured
if [[ "$(timedatectl show --property=Timezone --value)" == "Etc/UTC" ]]; then
    echo -e "${BLUE}Setting timezone...${NC}"
    read -p "Enter timezone [America/New_York]: " TZ
    TZ="${TZ:-America/New_York}"
    timedatectl set-timezone "$TZ"
    echo -e "${GREEN}✓ Timezone set to $TZ${NC}"
fi

# Enable automatic security updates
echo -e "${BLUE}Configuring automatic updates...${NC}"
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades 2>/dev/null || true

# ==============================================================================
# Summary
# ==============================================================================

echo -e "\n${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                 ✓ All Dependencies Installed                                  ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo "Installed:"
echo "  ✓ Essential system packages"
echo "  ✓ Docker $(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')"
echo "  ✓ Docker Compose $(docker compose version 2>/dev/null | awk '{print $4}')"
echo "  ✓ Ollama $(ollama --version 2>/dev/null)"
if command -v nvidia-smi &> /dev/null; then
    echo "  ✓ NVIDIA Container Toolkit"
fi
echo ""

# Check if reboot needed
if [[ -f /var/run/reboot-required ]]; then
    echo -e "${YELLOW}⚠️  System reboot recommended${NC}"
fi

echo -e "${BLUE}Next step: Run ./init-homelab.sh --standard${NC}"
