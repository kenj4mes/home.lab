# 🔧 Maintenance Guide

> **HomeLab** - Regular Maintenance Procedures

---

## 📋 Table of Contents

- [Maintenance Schedule](#maintenance-schedule)
- [Daily Tasks](#daily-tasks)
- [Weekly Tasks](#weekly-tasks)
- [Monthly Tasks](#monthly-tasks)
- [Updates & Upgrades](#updates--upgrades)
- [Backup Procedures](#backup-procedures)
- [Monitoring](#monitoring)

---

## Maintenance Schedule

| Frequency | Task | Priority |
|-----------|------|----------|
| **Daily** | Check container health | High |
| **Daily** | Review Pi-hole logs | Medium |
| **Weekly** | Update Docker containers | High |
| **Weekly** | Check disk space | High |
| **Monthly** | ZFS scrub | High |
| **Monthly** | Review security logs | Medium |
| **Quarterly** | Test backup restore | High |
| **Yearly** | Review hardware health | Medium |

---

## Daily Tasks

### Container Health Check

```bash
# Check all running containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check for containers that exited unexpectedly
docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Status}}"

# View logs for specific container
docker logs --tail 50 jellyfin
docker logs --since 1h pihole

# Restart unhealthy container
docker restart <container-name>
```

### Automated Health Check Script

Create `$HOME/scripts/daily-health.sh` (or `/opt/homelab/scripts/daily-health.sh`):

```bash
#!/bin/bash

echo "=== HomeLab Daily Health Check ==="
echo "Date: $(date)"
echo ""

echo "=== Container Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}"
echo ""

echo "=== Exited Containers ==="
docker ps -a --filter "status=exited" --format "{{.Names}}: {{.Status}}"
echo ""

echo "=== Disk Usage ==="
df -h | grep -E "^/dev|^Filesystem"
echo ""

echo "=== ZFS Pool Status ==="
zpool list
echo ""

echo "=== Memory Usage ==="
free -h
echo ""

echo "=== Docker Disk Usage ==="
docker system df
```

Add to crontab:
```cron
0 8 * * * $HOME/scripts/daily-health.sh | mail -s "HomeLab Daily Report" you@example.com
```

---

## Weekly Tasks

### Update Docker Containers

```bash
#!/bin/bash
# $HOME/scripts/update-containers.sh

cd $HOME/homelab

echo "=== Pulling latest images ==="
docker compose pull

echo "=== Recreating containers with new images ==="
docker compose up -d

echo "=== Cleaning up old images ==="
docker image prune -f

echo "=== Current running containers ==="
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
```

### Check Disk Space

```bash
# Overall disk usage
df -h

# Find large files
du -sh /srv/Tumadre/* | sort -rh | head -10

# Docker specific
docker system df
docker system df -v  # Detailed

# Clean up Docker
docker system prune -a --volumes  # CAREFUL: Removes unused volumes too!
```

### Pi-hole Maintenance

```bash
# Update Pi-hole blocklists (happens automatically, but can force)
docker exec pihole pihole -g

# Check query statistics
docker exec pihole pihole -c

# View top blocked domains
docker exec pihole pihole -t
```

### Jellyfin Library Scan

Via Web UI:
1. Dashboard → Scheduled Tasks
2. Click "Scan All Libraries" → Run

Or automate via API:
```bash
curl -X POST "http://localhost:8096/Library/Refresh" \
  -H "X-Emby-Token: YOUR_API_KEY"
```

---

## Monthly Tasks

### ZFS Scrub

```bash
# Start scrub on all pools
zpool scrub FlashBang
zpool scrub Tumadre

# Check scrub progress
zpool status

# Expected output during scrub:
#   scan: scrub in progress since Mon Dec 23 02:00:00 2024
#     1.23T scanned at 234M/s, 456G issued at 123M/s, 2.34T total
#     0B repaired, 19.49% done, 04:32:10 to go
```

### Review ZFS Health

```bash
# Check pool status
zpool status -v

# Check for errors
zpool status | grep -E "DEGRADED|FAULTED|OFFLINE|UNAVAIL|errors"

# Check capacity (don't exceed 80%)
zpool list -o name,size,alloc,free,cap
```

### Check System Logs

```bash
# Proxmox system logs
journalctl -p err -b  # Errors since last boot

# Docker container logs
for container in $(docker ps --format "{{.Names}}"); do
  echo "=== $container ==="
  docker logs --since 720h $container 2>&1 | grep -i "error\|warn\|fail" | tail -10
done

# Check authentication failures
grep "Failed password" /var/log/auth.log | tail -20
```

### Security Updates

```bash
# Proxmox host
apt update && apt full-upgrade -y

# Debian VM
sudo apt update && sudo apt full-upgrade -y

# Reboot if kernel updated
[ -f /var/run/reboot-required ] && echo "Reboot required!"
```

---

## Updates & Upgrades

### Updating Individual Services

```bash
cd $HOME/homelab

# Update specific service
docker compose pull jellyfin
docker compose up -d jellyfin

# Verify
docker logs -f jellyfin
```

### Updating All Services

```bash
cd $HOME/homelab

# Pull all images
docker compose pull

# Recreate containers
docker compose up -d

# Verify all running
docker ps

# Clean old images
docker image prune -f
```

### Updating Ollama Models

```bash
# Update specific model
ollama pull mistral

# List installed models
ollama list

# Remove old models
ollama rm <model-name>
```

### Major Version Upgrades

Before upgrading major versions (e.g., Jellyfin 10.8 → 10.9):

1. **Backup configuration:**
   ```bash
   tar -czvf jellyfin-backup-$(date +%Y%m%d).tar.gz /srv/FlashBang/jellyfin
   ```

2. **Create ZFS snapshot:**
   ```bash
   zfs snapshot FlashBang/jellyfin@before-upgrade
   ```

3. **Pull and update:**
   ```bash
   docker compose pull jellyfin
   docker compose up -d jellyfin
   ```

4. **If issues, rollback:**
   ```bash
   docker compose down
   zfs rollback FlashBang/jellyfin@before-upgrade
   # Pin to previous version in docker-compose.yml
   docker compose up -d
   ```

---

## Backup Procedures

### Automated Backup Script

Create `$HOME/scripts/backup.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/srv/Tumadre/Backups"
DATE=$(date +%Y-%m-%d)
RETENTION_DAYS=30

echo "=== Starting Backup: $DATE ==="

# 1. ZFS Snapshots
echo "Creating ZFS snapshots..."
zfs snapshot -r FlashBang@backup-$DATE
zfs snapshot -r Tumadre@backup-$DATE

# 2. Docker volumes backup
echo "Backing up Docker volumes..."
for volume in $(docker volume ls -q); do
  docker run --rm \
    -v $volume:/source:ro \
    -v $BACKUP_DIR/volumes:/backup \
    alpine tar -czf /backup/${volume}-${DATE}.tar.gz -C /source .
done

# 3. Configuration backup
echo "Backing up configurations..."
tar -czf $BACKUP_DIR/configs/homelab-config-$DATE.tar.gz \
  $HOME/homelab \
  $HOME/homeassistant \
  /etc/docker/daemon.json

# 4. Database dumps
echo "Dumping databases..."
docker exec bookstack-db mysqldump -u root -p$MYSQL_ROOT_PASSWORD bookstack > $BACKUP_DIR/databases/bookstack-$DATE.sql

# 5. Cleanup old backups
echo "Cleaning up old backups..."
find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.sql" -mtime +$RETENTION_DAYS -delete

# 6. Cleanup old ZFS snapshots
zfs list -t snapshot -o name -H | grep "backup-" | while read snap; do
  snap_date=$(echo $snap | grep -oP '\d{4}-\d{2}-\d{2}')
  if [[ -n "$snap_date" ]]; then
    if [[ $(date -d "$snap_date" +%s) -lt $(date -d "-$RETENTION_DAYS days" +%s) ]]; then
      echo "Deleting old snapshot: $snap"
      zfs destroy $snap
    fi
  fi
done

echo "=== Backup Complete ==="
```

Add to crontab:
```cron
0 3 * * * $HOME/scripts/backup.sh >> /var/log/homelab-backup.log 2>&1
```

### Testing Restore

**Quarterly**, test restore from backup:

1. Create a test VM
2. Restore configuration files
3. Verify service starts
4. Check data integrity

---

## Monitoring

### Uptime Kuma (Optional)

Add to docker-compose.yml:

```yaml
uptime-kuma:
  image: louislam/uptime-kuma:1
  container_name: uptime-kuma
  volumes:
    - ${CONFIG_PATH}/uptime-kuma:/app/data
  ports:
    - "3001:3001"
  restart: unless-stopped
```

Configure monitors for:
- Each service URL
- DNS resolution (Pi-hole)
- External sites (internet connectivity)

### Grafana + Prometheus (Advanced)

For detailed metrics, add:

```yaml
prometheus:
  image: prom/prometheus:latest
  container_name: prometheus
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
    - prometheus-data:/prometheus
  ports:
    - "9090:9090"
  restart: unless-stopped

grafana:
  image: grafana/grafana:latest
  container_name: grafana
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=changeme
  volumes:
    - grafana-data:/var/lib/grafana
  ports:
    - "3002:3000"
  restart: unless-stopped

node-exporter:
  image: prom/node-exporter:latest
  container_name: node-exporter
  ports:
    - "9100:9100"
  restart: unless-stopped

cadvisor:
  image: gcr.io/cadvisor/cadvisor:latest
  container_name: cadvisor
  volumes:
    - /:/rootfs:ro
    - /var/run:/var/run:ro
    - /sys:/sys:ro
    - /var/lib/docker/:/var/lib/docker:ro
  ports:
    - "8088:8080"
  restart: unless-stopped
```

---

## Maintenance Checklist

### Weekly Checklist

- [ ] Check container health
- [ ] Review error logs
- [ ] Update containers
- [ ] Check disk space
- [ ] Verify backups exist
- [ ] Test one service

### Monthly Checklist

- [ ] Run ZFS scrub
- [ ] Review security logs
- [ ] Apply system updates
- [ ] Check ZFS pool capacity
- [ ] Update Ollama models
- [ ] Review Pi-hole statistics
- [ ] Clean Docker resources

### Quarterly Checklist

- [ ] Test backup restore
- [ ] Review user accounts
- [ ] Check SSL certificates
- [ ] Update documentation
- [ ] Review firewall rules
- [ ] Capacity planning

---

*HomeLab - Self-Hosted Infrastructure*
