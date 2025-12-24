# 🗄️ ZFS Administration Guide

> **HomeLab** - ZFS Storage Management

---

## 📋 Table of Contents

- [Overview](#overview)
- [Pool Architecture](#pool-architecture)
- [Common Commands](#common-commands)
- [Snapshots & Backups](#snapshots--backups)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)
- [Advanced Topics](#advanced-topics)

---

## Overview

ZFS (Zettabyte File System) provides:

| Feature | Benefit |
|---------|---------|
| **Copy-on-Write** | Data integrity, instant snapshots |
| **RAID-Z** | Software RAID with better reliability |
| **Compression** | LZ4 compression reduces storage usage |
| **Snapshots** | Instant, space-efficient backups |
| **Self-Healing** | Automatic corruption detection/repair |

### HomeLab Pool Structure

| Pool | Type | Disks | Purpose |
|------|------|-------|---------|
| **rpool** | Mirror | 2× SSD | Proxmox OS |
| **FlashBang** | Mirror | 2× SSD | VM/Config storage |
| **Tumadre** | RAIDZ1 | 2+ HDD | Bulk media storage |

---

## Pool Architecture

### FlashBang (Fast Storage)

```
FlashBang (mirror)
├── /srv/FlashBang/jellyfin     # Jellyfin config
├── /srv/FlashBang/qbittorrent  # qBittorrent config
├── /srv/FlashBang/bookstack    # BookStack config
├── /srv/FlashBang/nginx        # Nginx Proxy Manager
├── /srv/FlashBang/ollama       # LLM models (~10GB+)
├── /srv/FlashBang/prowlarr     # Indexer config
├── /srv/FlashBang/radarr       # Movie manager config
├── /srv/FlashBang/sonarr       # TV manager config
├── /srv/FlashBang/lidarr       # Music manager config
├── /srv/FlashBang/portainer    # Docker manager
└── /srv/FlashBang/vms          # VM disk images
```

### Tumadre (Bulk Storage)

```
Tumadre (raidz1)
├── /srv/Tumadre/Movies         # Movie files
├── /srv/Tumadre/Series         # TV series
├── /srv/Tumadre/Music          # Music library
├── /srv/Tumadre/Photos         # Photo library
├── /srv/Tumadre/Books          # Ebooks/Audiobooks
├── /srv/Tumadre/Downloads      # Download staging
└── /srv/Tumadre/ZIM            # Wikipedia ZIM files
```

---

## Common Commands

### Pool Management

```bash
# List all pools
zpool list

# Show pool status and health
zpool status

# Detailed pool information
zpool get all FlashBang

# Check pool I/O stats
zpool iostat -v 1

# Import a pool (after reboot or move)
zpool import FlashBang

# Export a pool (before moving drives)
zpool export Tumadre
```

### Dataset Management

```bash
# List all datasets
zfs list

# Create a new dataset
zfs create FlashBang/newdataset

# Create nested dataset
zfs create -p FlashBang/apps/myapp

# Destroy a dataset (CAREFUL!)
zfs destroy FlashBang/olddataset

# Set mountpoint
zfs set mountpoint=/custom/path FlashBang/data

# Enable compression
zfs set compression=lz4 Tumadre

# Check compression ratio
zfs get compressratio Tumadre
```

### Properties

```bash
# View all properties
zfs get all FlashBang

# Set property
zfs set quota=100G FlashBang/jellyfin

# Set reservation (guaranteed space)
zfs set reservation=50G FlashBang/ollama

# Common properties
zfs set compression=lz4 <dataset>      # Enable compression
zfs set atime=off <dataset>            # Disable access time (performance)
zfs set recordsize=1M <dataset>        # Large files (media)
zfs set recordsize=16K <dataset>       # Small files (databases)
```

---

## Snapshots & Backups

### Creating Snapshots

```bash
# Create a snapshot
zfs snapshot FlashBang@before-upgrade

# Create recursive snapshot (all child datasets)
zfs snapshot -r Tumadre@weekly-backup

# Create timestamped snapshot
zfs snapshot Tumadre@$(date +%Y-%m-%d_%H%M)

# List snapshots
zfs list -t snapshot

# List snapshots for specific dataset
zfs list -t snapshot -r FlashBang
```

### Using Snapshots

```bash
# Access snapshot data (hidden .zfs directory)
ls /srv/FlashBang/.zfs/snapshot/before-upgrade/

# Rollback to snapshot (DESTRUCTIVE - loses newer data)
zfs rollback FlashBang@before-upgrade

# Rollback with force (destroy intermediate snapshots)
zfs rollback -r FlashBang@before-upgrade
```

### Cloning Snapshots

```bash
# Clone a snapshot (writable copy)
zfs clone Tumadre/Movies@backup Tumadre/Movies-copy

# Promote clone to independent dataset
zfs promote Tumadre/Movies-copy
```

### Sending/Receiving (Backup & Replication)

```bash
# Send snapshot to file
zfs send FlashBang@backup > /backup/flashbang.zfs

# Send compressed
zfs send FlashBang@backup | gzip > /backup/flashbang.zfs.gz

# Receive snapshot
zfs receive BackupPool/FlashBang < /backup/flashbang.zfs

# Incremental send (faster for updates)
zfs send -i @snap1 FlashBang@snap2 | zfs receive BackupPool/FlashBang

# Send to remote server
zfs send FlashBang@backup | ssh user@remote "zfs receive BackupPool/FlashBang"
```

### Automated Snapshots

Add to crontab (`sudo crontab -e`):

```cron
# Daily snapshot at 2 AM
0 2 * * * /path/to/scripts/zfs-snapshot.sh

# Weekly snapshot on Sunday at 3 AM
0 3 * * 0 zfs snapshot -r Tumadre@weekly-$(date +\%Y-\%m-\%d)

# Monthly snapshot on 1st at 4 AM
0 4 1 * * zfs snapshot -r Tumadre@monthly-$(date +\%Y-\%m)
```

---

## Maintenance

### Health Checks

```bash
# Check pool status
zpool status

# Run scrub (integrity check) - do monthly
zpool scrub FlashBang
zpool scrub Tumadre

# Check scrub progress
zpool status | grep -A 5 "scan:"

# View errors
zpool status -v
```

### Adding/Replacing Disks

```bash
# Add a disk to existing pool (NOT recommended for mirrors/raidz)
zpool add Tumadre /dev/sde

# Replace a failed disk
zpool replace Tumadre /dev/sdc /dev/sde

# Resilver status (after replace)
zpool status

# Add a mirror to existing vdev
zpool attach FlashBang /dev/sda /dev/sdc
```

### Expansion

```bash
# After replacing all disks with larger ones
zpool online -e FlashBang

# Check new size
zpool list
```

### Performance Tuning

```bash
# Add SSD cache (L2ARC)
zpool add Tumadre cache /dev/nvme0n1p1

# Add SSD log device (SLOG)
zpool add Tumadre log mirror /dev/nvme0n1p2 /dev/nvme0n2p2

# Check ARC stats
arc_summary
# or
cat /proc/spl/kstat/zfs/arcstats
```

---

## Troubleshooting

### Common Issues

#### Pool Not Importing After Reboot

```bash
# List available pools
zpool import

# Import by name
zpool import FlashBang

# Import with different mountpoint
zpool import -R /mnt FlashBang

# Force import (use with caution)
zpool import -f FlashBang
```

#### Degraded Pool

```bash
# Check status
zpool status

# Replace failed disk
zpool replace Tumadre /dev/sdc /dev/sde

# Clear errors after fix
zpool clear Tumadre
```

#### Pool is Full

```bash
# Check usage
zfs list

# Delete old snapshots
zfs destroy FlashBang@old-snapshot

# List largest files
du -sh /srv/Tumadre/* | sort -rh | head -20
```

#### Slow Performance

```bash
# Check I/O stats
zpool iostat -v 1

# Check ARC hit ratio (should be >90%)
arc_summary | grep "Hit Ratio"

# Disable atime
zfs set atime=off Tumadre

# Check compression
zfs get compressratio Tumadre
```

---

## Advanced Topics

### Encryption

```bash
# Create encrypted dataset
zfs create -o encryption=on -o keyformat=passphrase FlashBang/secrets

# Load key at boot
zfs load-key FlashBang/secrets
zfs mount FlashBang/secrets

# Unload key (unmount and lock)
zfs unmount FlashBang/secrets
zfs unload-key FlashBang/secrets
```

### Send/Receive Over Network

```bash
# Continuous replication to backup server
while true; do
    zfs send -i @last Tumadre@$(date +%Y%m%d) | \
        ssh backup-server "zfs receive BackupPool/Tumadre"
    sleep 3600
done
```

### Sharing

```bash
# NFS share
zfs set sharenfs=on FlashBang/share

# SMB share (requires Samba)
zfs set sharesmb=on FlashBang/share
```

### Docker on ZFS

For best Docker performance on ZFS:

```bash
# Create dedicated dataset for Docker
zfs create -o mountpoint=/var/lib/docker FlashBang/docker

# Configure Docker to use ZFS driver
cat > /etc/docker/daemon.json << EOF
{
  "storage-driver": "zfs"
}
EOF

systemctl restart docker
```

---

## Quick Reference Card

| Task | Command |
|------|---------|
| List pools | `zpool list` |
| Pool health | `zpool status` |
| List datasets | `zfs list` |
| Create snapshot | `zfs snapshot pool@name` |
| List snapshots | `zfs list -t snapshot` |
| Rollback | `zfs rollback pool@name` |
| Create dataset | `zfs create pool/name` |
| Destroy dataset | `zfs destroy pool/name` |
| Run scrub | `zpool scrub pool` |
| Check I/O | `zpool iostat -v 1` |
| Send backup | `zfs send pool@snap > file` |
| Receive backup | `zfs receive pool < file` |

---

*HomeLab - Self-Hosted Infrastructure*
