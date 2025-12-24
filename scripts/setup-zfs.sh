#!/bin/bash
# ==============================================================================
# 🗄️ ZFS Pool Setup Script
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# This script creates ZFS pools for your HomeLab:
#   - fast-pool: Mirror of SSDs for fast VM/config storage
#   - bulk-pool: RAIDZ1 of HDDs for bulk media storage
#
# Usage:
#   chmod +x setup-zfs.sh
#   sudo ./setup-zfs.sh
#
# ⚠️  WARNING: This will DESTROY ALL DATA on the specified disks!
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                     🗄️  ZFS Pool Setup Script                                ║"
echo "║                     HomeLab - Self-Hosted Infrastructure                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ==============================================================================
# CONFIGURATION - MODIFY THESE FOR YOUR SETUP
# ==============================================================================

# SSD devices for fast-pool (fast storage)
SSD_DISK_1="/dev/sda"
SSD_DISK_2="/dev/sdb"

# HDD devices for bulk-pool (bulk storage)
HDD_DISK_1="/dev/sdc"
HDD_DISK_2="/dev/sdd"
# Add more HDDs here if you have them:
# HDD_DISK_3="/dev/sde"

# Pool names (customize these for your environment)
FAST_POOL="fast-pool"
BULK_POOL="bulk-pool"

# ==============================================================================
# SAFETY CHECKS
# ==============================================================================

# Must run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}"
   exit 1
fi

# Check if ZFS is installed
if ! command -v zpool &> /dev/null; then
    echo -e "${RED}❌ ZFS is not installed. Installing...${NC}"
    apt-get update
    apt-get install -y zfsutils-linux
fi

# ==============================================================================
# SHOW CURRENT DISK STATUS
# ==============================================================================

echo -e "${YELLOW}📋 Current disk layout:${NC}"
lsblk -d -o NAME,SIZE,TYPE,MODEL
echo ""

echo -e "${YELLOW}📋 Current ZFS pools:${NC}"
zpool list 2>/dev/null || echo "No pools found"
echo ""

# ==============================================================================
# CONFIRM BEFORE PROCEEDING
# ==============================================================================

echo -e "${RED}⚠️  WARNING: This will DESTROY ALL DATA on the following disks:${NC}"
echo -e "   SSD Pool (${FAST_POOL}): ${SSD_DISK_1}, ${SSD_DISK_2}"
echo -e "   HDD Pool (${BULK_POOL}): ${HDD_DISK_1}, ${HDD_DISK_2}"
echo ""
read -p "Are you ABSOLUTELY sure you want to continue? (type 'YES' to confirm): " confirm

if [[ "$confirm" != "YES" ]]; then
    echo -e "${YELLOW}Aborted. No changes made.${NC}"
    exit 0
fi

# ==============================================================================
# CREATE FAST-POOL (SSD MIRROR)
# ==============================================================================

echo -e "\n${BLUE}🚀 Creating ${FAST_POOL} pool (SSD mirror)...${NC}"

# Check if pool already exists
if zpool list ${FAST_POOL} &> /dev/null; then
    echo -e "${YELLOW}⚠️  Pool ${FAST_POOL} already exists. Skipping.${NC}"
else
    # Wipe partition tables
    wipefs -a ${SSD_DISK_1} 2>/dev/null || true
    wipefs -a ${SSD_DISK_2} 2>/dev/null || true
    
    # Create mirrored pool
    zpool create -f \
        -o ashift=12 \
        -O acltype=posixacl \
        -O compression=lz4 \
        -O dnodesize=auto \
        -O normalization=formD \
        -O relatime=on \
        -O xattr=sa \
        -O mountpoint=/srv/${FAST_POOL} \
        ${FAST_POOL} mirror ${SSD_DISK_1} ${SSD_DISK_2}
    
    echo -e "${GREEN}✅ ${FAST_POOL} pool created successfully${NC}"
fi

# ==============================================================================
# CREATE BULK-POOL (HDD RAIDZ1)
# ==============================================================================

echo -e "\n${BLUE}🚀 Creating ${BULK_POOL} pool (HDD RAIDZ1)...${NC}"

# Check if pool already exists
if zpool list ${BULK_POOL} &> /dev/null; then
    echo -e "${YELLOW}⚠️  Pool ${BULK_POOL} already exists. Skipping.${NC}"
else
    # Wipe partition tables
    wipefs -a ${HDD_DISK_1} 2>/dev/null || true
    wipefs -a ${HDD_DISK_2} 2>/dev/null || true
    
    # Create RAIDZ1 pool (single parity - can lose 1 disk)
    # For 3+ disks, you can use: raidz1 ${HDD_DISK_1} ${HDD_DISK_2} ${HDD_DISK_3}
    # For 4+ disks with double parity: raidz2
    zpool create -f \
        -o ashift=12 \
        -O acltype=posixacl \
        -O compression=lz4 \
        -O dnodesize=auto \
        -O normalization=formD \
        -O relatime=on \
        -O xattr=sa \
        -O recordsize=1M \
        -O mountpoint=/srv/${BULK_POOL} \
        ${BULK_POOL} raidz1 ${HDD_DISK_1} ${HDD_DISK_2}
    
    echo -e "${GREEN}✅ ${BULK_POOL} pool created successfully${NC}"
fi

# ==============================================================================
# CREATE DATASETS (ZFS FILESYSTEMS)
# ==============================================================================

echo -e "\n${BLUE}📁 Creating ZFS datasets...${NC}"

# fast-pool datasets (configs, VMs)
datasets_fast=(
    "${FAST_POOL}/jellyfin"
    "${FAST_POOL}/qbittorrent"
    "${FAST_POOL}/bookstack"
    "${FAST_POOL}/nginx"
    "${FAST_POOL}/ollama"
    "${FAST_POOL}/prowlarr"
    "${FAST_POOL}/radarr"
    "${FAST_POOL}/sonarr"
    "${FAST_POOL}/lidarr"
    "${FAST_POOL}/portainer"
    "${FAST_POOL}/open-webui"
    "${FAST_POOL}/vms"
)

# bulk-pool datasets (media)
datasets_bulk=(
    "${BULK_POOL}/Movies"
    "${BULK_POOL}/Series"
    "${BULK_POOL}/Music"
    "${BULK_POOL}/Photos"
    "${BULK_POOL}/Books"
    "${BULK_POOL}/Downloads"
    "${BULK_POOL}/ZIM"
)

for dataset in "${datasets_fast[@]}"; do
    if zfs list "$dataset" &> /dev/null; then
        echo -e "  ${YELLOW}⚠️  $dataset already exists${NC}"
    else
        zfs create "$dataset"
        echo -e "  ${GREEN}✅ Created $dataset${NC}"
    fi
done

for dataset in "${datasets_bulk[@]}"; do
    if zfs list "$dataset" &> /dev/null; then
        echo -e "  ${YELLOW}⚠️  $dataset already exists${NC}"
    else
        zfs create "$dataset"
        echo -e "  ${GREEN}✅ Created $dataset${NC}"
    fi
done

# ==============================================================================
# SET PERMISSIONS
# ==============================================================================

echo -e "\n${BLUE}🔐 Setting permissions...${NC}"

chown -R 1000:1000 /srv/${FAST_POOL}
chown -R 1000:1000 /srv/${BULK_POOL}

echo -e "${GREEN}✅ Permissions set (UID/GID 1000)${NC}"

# ==============================================================================
# SHOW RESULTS
# ==============================================================================

echo -e "\n${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                     ✅ ZFS Setup Complete!                                    ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}📊 Pool Status:${NC}"
zpool status

echo -e "\n${BLUE}📊 Pool Capacity:${NC}"
zpool list

echo -e "\n${BLUE}📁 Datasets:${NC}"
zfs list

echo -e "\n${YELLOW}📋 Next Steps:${NC}"
echo "  1. Create a Debian 12 VM in Proxmox"
echo "  2. Pass through /srv/\${FAST_POOL} and /srv/\${BULK_POOL} to the VM"
echo "  3. Install Docker in the VM"
echo "  4. Run docker compose up -d"
echo ""
