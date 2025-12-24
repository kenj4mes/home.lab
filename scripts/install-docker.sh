#!/bin/bash
# ==============================================================================
# 🐳 Docker Installation Script
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Installs Docker Engine on Debian 12 with all dependencies
#
# Usage:
#   chmod +x install-docker.sh
#   sudo ./install-docker.sh
# ==============================================================================

set -e

# Colors (some may be unused but kept for consistency)
# shellcheck disable=SC2034
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                     🐳 Docker Installation Script                             ║"
echo "║                     HomeLab - Self-Hosted Infrastructure                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ==============================================================================
# CHECKS
# ==============================================================================

# Must run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}"
   exit 1
fi

# Check OS
if ! grep -q "debian" /etc/os-release; then
    echo -e "${YELLOW}⚠️  This script is designed for Debian. Your mileage may vary.${NC}"
fi

# ==============================================================================
# REMOVE OLD VERSIONS
# ==============================================================================

echo -e "${BLUE}🧹 Removing old Docker versions (if any)...${NC}"

for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    apt-get remove -y $pkg 2>/dev/null || true
done

# ==============================================================================
# INSTALL DEPENDENCIES
# ==============================================================================

echo -e "${BLUE}📦 Installing dependencies...${NC}"

apt-get update
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https

# ==============================================================================
# ADD DOCKER REPOSITORY
# ==============================================================================

echo -e "${BLUE}🔑 Adding Docker GPG key...${NC}"

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo -e "${BLUE}📋 Adding Docker repository...${NC}"

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# ==============================================================================
# INSTALL DOCKER
# ==============================================================================

echo -e "${BLUE}🐳 Installing Docker Engine...${NC}"

apt-get update
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# ==============================================================================
# CONFIGURE DOCKER
# ==============================================================================

echo -e "${BLUE}⚙️  Configuring Docker...${NC}"

# Enable Docker service
systemctl enable docker
systemctl start docker

# Add current user to docker group (if not root)
# shellcheck disable=SC2034  # SUDO_USER_HOME available for future use
SUDO_USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
if [[ -n "$SUDO_USER" ]]; then
    usermod -aG docker "$SUDO_USER"
    echo -e "${GREEN}✅ Added $SUDO_USER to docker group${NC}"
fi

# Create Docker daemon config for better defaults
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true
}
EOF

# Reload Docker with new config
systemctl restart docker

# ==============================================================================
# INSTALL NVIDIA CONTAINER TOOLKIT (Optional)
# ==============================================================================

read -p "Do you have an NVIDIA GPU and want to install the container toolkit? (y/N): " install_nvidia

if [[ "$install_nvidia" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🎮 Installing NVIDIA Container Toolkit...${NC}"
    
    # Add NVIDIA repository
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    apt-get update
    apt-get install -y nvidia-container-toolkit
    
    # Configure Docker for NVIDIA
    nvidia-ctk runtime configure --runtime=docker
    systemctl restart docker
    
    echo -e "${GREEN}✅ NVIDIA Container Toolkit installed${NC}"
fi

# ==============================================================================
# VERIFY INSTALLATION
# ==============================================================================

echo -e "\n${BLUE}🔍 Verifying installation...${NC}"

docker version
echo ""
docker compose version
echo ""

# Test with hello-world
echo -e "${BLUE}🧪 Running test container...${NC}"
docker run --rm hello-world

# ==============================================================================
# COMPLETE
# ==============================================================================

echo -e "\n${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                     ✅ Docker Installation Complete!                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "  1. Log out and back in for docker group to take effect"
echo "  2. Navigate to your HomeLab docker directory"
echo "  3. Run: docker compose up -d"
echo ""

if [[ -n "$SUDO_USER" ]]; then
    echo -e "${YELLOW}⚠️  Remember to log out and back in as $SUDO_USER for group changes to take effect!${NC}"
fi
