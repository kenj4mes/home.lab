#!/bin/bash
# ==============================================================================
# Proxmox VE Post-Installation Script
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Run this on the Proxmox host after installation to configure:
#   - Remove subscription nag
#   - Add no-subscription repository
#   - Enable IOMMU for GPU passthrough
#   - Configure basic security
#
# Usage:
#   chmod +x proxmox-post-install.sh
#   ./proxmox-post-install.sh
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
echo "║                     Proxmox VE Post-Installation                              ║"
echo "║                     HomeLab - Self-Hosted Infrastructure                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Must run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# ==============================================================================
# Disable Enterprise Repository
# ==============================================================================

echo -e "${BLUE}Disabling enterprise repository...${NC}"

if [[ -f /etc/apt/sources.list.d/pve-enterprise.list ]]; then
    sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list
    echo -e "${GREEN}✓ Enterprise repository disabled${NC}"
else
    echo -e "${YELLOW}○ Enterprise repository file not found${NC}"
fi

# Also handle ceph enterprise repo if it exists
if [[ -f /etc/apt/sources.list.d/ceph.list ]]; then
    sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/ceph.list
    echo -e "${GREEN}✓ Ceph enterprise repository disabled${NC}"
fi

# ==============================================================================
# Add No-Subscription Repository
# ==============================================================================

echo -e "${BLUE}Adding no-subscription repository...${NC}"

REPO_FILE="/etc/apt/sources.list.d/pve-no-subscription.list"
if [[ ! -f $REPO_FILE ]]; then
    echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > $REPO_FILE
    echo -e "${GREEN}✓ No-subscription repository added${NC}"
else
    echo -e "${YELLOW}○ Repository already exists${NC}"
fi

# ==============================================================================
# Remove Subscription Nag
# ==============================================================================

echo -e "${BLUE}Removing subscription nag from web UI...${NC}"

JS_FILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"
if [[ -f $JS_FILE ]]; then
    # Backup original
    if [[ ! -f "${JS_FILE}.bak" ]]; then
        cp "$JS_FILE" "${JS_FILE}.bak"
    fi
    
    # Remove the subscription check
    sed -Ezi.bak "s/(Ext\.Msg\.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" "$JS_FILE"
    
    # Restart web service
    systemctl restart pveproxy.service
    
    echo -e "${GREEN}✓ Subscription nag removed${NC}"
else
    echo -e "${YELLOW}○ JS file not found (older Proxmox version?)${NC}"
fi

# ==============================================================================
# Enable IOMMU
# ==============================================================================

echo -e "${BLUE}Enabling IOMMU for GPU passthrough...${NC}"

# Detect CPU vendor
if grep -q "Intel" /proc/cpuinfo; then
    IOMMU_PARAM="intel_iommu=on"
    echo -e "  Detected Intel CPU"
elif grep -q "AMD" /proc/cpuinfo; then
    IOMMU_PARAM="amd_iommu=on"
    echo -e "  Detected AMD CPU"
else
    IOMMU_PARAM="iommu=pt"
    echo -e "  Unknown CPU, using generic IOMMU"
fi

GRUB_FILE="/etc/default/grub"
if [[ -f $GRUB_FILE ]]; then
    # Backup
    if [[ ! -f "${GRUB_FILE}.bak" ]]; then
        cp "$GRUB_FILE" "${GRUB_FILE}.bak"
    fi
    
    # Check if already configured
    if grep -q "$IOMMU_PARAM" "$GRUB_FILE"; then
        echo -e "${YELLOW}○ IOMMU already configured${NC}"
    else
        # Add IOMMU parameters
        sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet ${IOMMU_PARAM} iommu=pt\"/" "$GRUB_FILE"
        update-grub
        echo -e "${GREEN}✓ IOMMU enabled (reboot required)${NC}"
    fi
fi

# ==============================================================================
# Add VFIO Modules
# ==============================================================================

echo -e "${BLUE}Adding VFIO modules for GPU passthrough...${NC}"

MODULES_FILE="/etc/modules"
VFIO_MODULES=("vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd")

for module in "${VFIO_MODULES[@]}"; do
    if ! grep -q "^${module}$" "$MODULES_FILE"; then
        echo "$module" >> "$MODULES_FILE"
        echo -e "  Added: $module"
    fi
done

update-initramfs -u -k all
echo -e "${GREEN}✓ VFIO modules configured${NC}"

# ==============================================================================
# Update System
# ==============================================================================

echo -e "${BLUE}Updating system packages...${NC}"

apt-get update
apt-get dist-upgrade -y

echo -e "${GREEN}✓ System updated${NC}"

# ==============================================================================
# Install Useful Packages
# ==============================================================================

echo -e "${BLUE}Installing useful packages...${NC}"

apt-get install -y \
    vim \
    htop \
    iotop \
    tmux \
    curl \
    wget \
    git \
    net-tools \
    iperf3

echo -e "${GREEN}✓ Packages installed${NC}"

# ==============================================================================
# Summary
# ==============================================================================

echo -e "\n${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                     ✓ Post-Installation Complete                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}Changes made:${NC}"
echo "  ✓ Disabled enterprise repository"
echo "  ✓ Added no-subscription repository"
echo "  ✓ Removed subscription nag"
echo "  ✓ Enabled IOMMU for GPU passthrough"
echo "  ✓ Added VFIO modules"
echo "  ✓ Updated system packages"
echo ""

# Check if reboot needed
if [[ -f /var/run/reboot-required ]] || ! dmesg | grep -q "IOMMU enabled"; then
    echo -e "${RED}⚠️  REBOOT REQUIRED for IOMMU changes to take effect${NC}"
    echo ""
    read -p "Reboot now? (y/N): " reboot_now
    if [[ "$reboot_now" =~ ^[Yy]$ ]]; then
        reboot
    fi
fi
