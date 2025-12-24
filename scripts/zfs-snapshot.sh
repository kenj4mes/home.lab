#!/bin/bash
# ==============================================================================
# 📸 ZFS Snapshot Script
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Creates timestamped snapshots of ZFS pools for backup/recovery
#
# Usage:
#   chmod +x zfs-snapshot.sh
#   sudo ./zfs-snapshot.sh
#
# For automated daily snapshots, add to crontab:
#   0 2 * * * /path/to/zfs-snapshot.sh
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
TIMESTAMP=$(date +%Y-%m-%d_%H%M)
RETENTION_DAYS=30
# Pool names - customize these to match your setup
POOLS=("fast-pool" "bulk-pool")

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                     📸 ZFS Snapshot Script                                    ║"
echo "║                     HomeLab - Self-Hosted Infrastructure                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Must run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}"
   exit 1
fi

# ==============================================================================
# CREATE SNAPSHOTS
# ==============================================================================

echo -e "${BLUE}📸 Creating snapshots with timestamp: ${TIMESTAMP}${NC}"
echo ""

for pool in "${POOLS[@]}"; do
    if zpool list "$pool" &> /dev/null; then
        # Create recursive snapshot of entire pool
        snapshot_name="${pool}@autosnap-${TIMESTAMP}"
        
        echo -e "  Creating snapshot: ${snapshot_name}"
        zfs snapshot -r "$snapshot_name"
        echo -e "  ${GREEN}✅ ${snapshot_name} created${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Pool $pool not found, skipping${NC}"
    fi
done

# ==============================================================================
# CLEANUP OLD SNAPSHOTS
# ==============================================================================

echo -e "\n${BLUE}🧹 Cleaning up snapshots older than ${RETENTION_DAYS} days...${NC}"

# Calculate cutoff date
cutoff_date=$(date -d "-${RETENTION_DAYS} days" +%Y-%m-%d)

for pool in "${POOLS[@]}"; do
    if zpool list "$pool" &> /dev/null; then
        # List all auto snapshots
        zfs list -t snapshot -o name -H | grep "${pool}@autosnap-" | while read snapshot; do
            # Extract date from snapshot name
            snap_date=$(echo "$snapshot" | sed -n 's/.*autosnap-\([0-9-]*\)_.*/\1/p')
            
            if [[ -n "$snap_date" && "$snap_date" < "$cutoff_date" ]]; then
                echo -e "  Deleting old snapshot: $snapshot"
                zfs destroy "$snapshot"
                echo -e "  ${GREEN}✅ Deleted${NC}"
            fi
        done
    fi
done

# ==============================================================================
# SHOW CURRENT SNAPSHOTS
# ==============================================================================

echo -e "\n${BLUE}📋 Current snapshots:${NC}"
echo ""

zfs list -t snapshot -o name,used,creation | head -50

# Get total count
total=$(zfs list -t snapshot -H | wc -l)
echo ""
echo -e "Total snapshots: ${total}"

# ==============================================================================
# SHOW POOL STATUS
# ==============================================================================

echo -e "\n${BLUE}📊 Pool Status:${NC}"
zpool list

echo -e "\n${GREEN}✅ Snapshot operation complete${NC}"

# ==============================================================================
# USAGE TIPS
# ==============================================================================

echo -e "\n${YELLOW}📋 Useful ZFS Commands:${NC}"
echo "  List snapshots:     zfs list -t snapshot"
echo "  Rollback:           zfs rollback <pool>@<snapshot>"
echo "  Clone snapshot:     zfs clone <pool>@<snapshot> <pool>/clone-name"
echo "  Send to file:       zfs send <pool>@<snapshot> > backup.zfs"
echo "  Destroy snapshot:   zfs destroy <pool>@<snapshot>"
echo ""
