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
| **homelab** | Mirror | 2× SSD | VM/Config storage |
| **media** | RAIDZ1 | 2+ HDD | Bulk media storage |

---

## Pool Architecture

### homelab (Fast Storage)

```
homelab (mirror)
├── /srv/homelab/jellyfin     # Jellyfin config
├── /srv/homelab/qbittorrent  # qBittorrent config
├── /srv/homelab/bookstack    # BookStack config
├── /srv/homelab/nginx        # Nginx Proxy Manager
├── /srv/homelab/ollama       # LLM models (~10GB+)
├── /srv/homelab/prowlarr     # Indexer config
├── /srv/homelab/radarr       # Movie manager config
├── /srv/homelab/sonarr       # TV manager config
├── /srv/homelab/lidarr       # Music manager config
├── /srv/homelab/portainer    # Docker manager
└── /srv/homelab/vms          # VM disk images
```

### media (Bulk Storage)

```
media (raidz1)
├── /srv/media/Movies         # Movie files
├── /srv/media/Series         # TV series
├── /srv/media/Music          # Music library
├── /srv/media/Photos         # Photo library
├── /srv/media/Books          # Ebooks/Audiobooks
├── /srv/media/Downloads      # Download staging
└── /srv/media/ZIM            # Wikipedia ZIM files
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
zpool get all homelab

# Check pool I/O stats
zpool iostat -v 1

# Import a pool (after reboot or move)
zpool import homelab

# Export a pool (before moving drives)
zpool export media
```

### Dataset Management

```bash
# List all datasets
zfs list

# Create a new dataset
zfs create homelab/newdataset

# Create nested dataset
zfs create -p homelab/apps/myapp

# Destroy a dataset (CAREFUL!)
zfs destroy homelab/olddataset

# Set mountpoint
zfs set mountpoint=/custom/path homelab/data

# Enable compression
zfs set compression=lz4 media

# Check compression ratio
zfs get compressratio media
```

### Properties

```bash
# View all properties
zfs get all homelab

# Set property
zfs set quota=100G homelab/jellyfin

# Set reservation (guaranteed space)
zfs set reservation=50G homelab/ollama

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
zfs snapshot homelab@before-upgrade

# Create recursive snapshot (all child datasets)
zfs snapshot -r media@weekly-backup

# Create timestamped snapshot
zfs snapshot media@$(date +%Y-%m-%d_%H%M)

# List snapshots
zfs list -t snapshot

# List snapshots for specific dataset
zfs list -t snapshot -r homelab
```

### Using Snapshots

```bash
# Access snapshot data (hidden .zfs directory)
ls /srv/homelab/.zfs/snapshot/before-upgrade/

# Rollback to snapshot (DESTRUCTIVE - loses newer data)
zfs rollback homelab@before-upgrade

# Rollback with force (destroy intermediate snapshots)
zfs rollback -r homelab@before-upgrade
```

### Cloning Snapshots

```bash
# Clone a snapshot (writable copy)
zfs clone media/Movies@backup media/Movies-copy

# Promote clone to independent dataset
zfs promote media/Movies-copy
```

### Sending/Receiving (Backup & Replication)

```bash
# Send snapshot to file
zfs send homelab@backup > /backup/homelab.zfs

# Send compressed
zfs send homelab@backup | gzip > /backup/homelab.zfs.gz

# Receive snapshot
zfs receive BackupPool/homelab < /backup/homelab.zfs

# Incremental send (faster for updates)
zfs send -i @snap1 homelab@snap2 | zfs receive BackupPool/homelab

# Send to remote server
zfs send homelab@backup | ssh user@remote "zfs receive BackupPool/homelab"
```

### Automated Snapshots

Add to crontab (`sudo crontab -e`):

```cron
# Daily snapshot at 2 AM
0 2 * * * /path/to/scripts/zfs-snapshot.sh

# Weekly snapshot on Sunday at 3 AM
0 3 * * 0 zfs snapshot -r media@weekly-$(date +\%Y-\%m-\%d)

# Monthly snapshot on 1st at 4 AM
0 4 1 * * zfs snapshot -r media@monthly-$(date +\%Y-\%m)
```

---

## Maintenance

### Health Checks

```bash
# Check pool status
zpool status

# Run scrub (integrity check) - do monthly
zpool scrub homelab
zpool scrub media

# Check scrub progress
zpool status | grep -A 5 "scan:"

# View errors
zpool status -v
```

### Adding/Replacing Disks

```bash
# Add a disk to existing pool (NOT recommended for mirrors/raidz)
zpool add media /dev/sde

# Replace a failed disk
zpool replace media /dev/sdc /dev/sde

# Resilver status (after replace)
zpool status

# Add a mirror to existing vdev
zpool attach homelab /dev/sda /dev/sdc
```

### Expansion

```bash
# After replacing all disks with larger ones
zpool online -e homelab

# Check new size
zpool list
```

### Performance Tuning

```bash
# Add SSD cache (L2ARC)
zpool add media cache /dev/nvme0n1p1

# Add SSD log device (SLOG)
zpool add media log mirror /dev/nvme0n1p2 /dev/nvme0n2p2

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
zpool import homelab

# Import with different mountpoint
zpool import -R /mnt homelab

# Force import (use with caution)
zpool import -f homelab
```

#### Degraded Pool

```bash
# Check status
zpool status

# Replace failed disk
zpool replace media /dev/sdc /dev/sde

# Clear errors after fix
zpool clear media
```

#### Pool is Full

```bash
# Check usage
zfs list

# Delete old snapshots
zfs destroy homelab@old-snapshot

# List largest files
du -sh /srv/media/* | sort -rh | head -20
```

#### Slow Performance

```bash
# Check I/O stats
zpool iostat -v 1

# Check ARC hit ratio (should be >90%)
arc_summary | grep "Hit Ratio"

# Disable atime
zfs set atime=off media

# Check compression
zfs get compressratio media
```

---

## Advanced Topics

### Encryption

```bash
# Create encrypted dataset
zfs create -o encryption=on -o keyformat=passphrase homelab/secrets

# Load key at boot
zfs load-key homelab/secrets
zfs mount homelab/secrets

# Unload key (unmount and lock)
zfs unmount homelab/secrets
zfs unload-key homelab/secrets
```

### Send/Receive Over Network

```bash
# Continuous replication to backup server
while true; do
    zfs send -i @last media@$(date +%Y%m%d) | \
        ssh backup-server "zfs receive BackupPool/media"
    sleep 3600
done
```

### Sharing

```bash
# NFS share
zfs set sharenfs=on homelab/share

# SMB share (requires Samba)
zfs set sharesmb=on homelab/share
```

### Docker on ZFS

For best Docker performance on ZFS:

```bash
# Create dedicated dataset for Docker
zfs create -o mountpoint=/var/lib/docker homelab/docker

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



