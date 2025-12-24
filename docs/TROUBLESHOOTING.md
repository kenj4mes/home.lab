# 🔧 Troubleshooting Guide

> **HomeLab** - Common Issues & Solutions

---

## 📋 Table of Contents

- [Docker Issues](#docker-issues)
- [Network Issues](#network-issues)
- [Storage Issues](#storage-issues)
- [Service-Specific Issues](#service-specific-issues)
- [Performance Issues](#performance-issues)
- [GPU Passthrough Issues](#gpu-passthrough-issues)

---

## Docker Issues

### Container Won't Start

**Symptoms:** Container immediately exits or fails to start.

```bash
# Check container logs
docker logs <container-name>

# Check for port conflicts
sudo lsof -i :<port>
netstat -tulpn | grep <port>

# Check container status
docker inspect <container-name> | grep -A 10 "State"
```

**Common causes:**
1. **Port already in use:** Change port in docker-compose.yml
2. **Volume permissions:** Fix with `chown -R 1000:1000 <path>`
3. **Missing config:** Check if config directory exists
4. **Out of memory:** Increase Docker memory limit

### Permission Denied Errors

```bash
# Fix volume ownership
sudo chown -R 1000:1000 /srv/homelab/<service>

# Docker socket permission
sudo chmod 666 /var/run/docker.sock

# Add user to docker group
sudo usermod -aG docker $USER
# Then log out and back in
```

### Docker Network Issues

```bash
# List networks
docker network ls

# Inspect network
docker network inspect homelab

# Remove orphan networks
docker network prune

# Recreate network
docker compose down
docker network rm homelab
docker compose up -d
```

### Container Can't Reach Internet

```bash
# Check DNS resolution in container
docker exec <container> nslookup google.com

# Check Docker DNS settings
cat /etc/docker/daemon.json

# Add custom DNS
cat > /etc/docker/daemon.json << EOF
{
  "dns": ["1.1.1.1", "8.8.8.8"]
}
EOF
systemctl restart docker
```

### Docker Disk Full

```bash
# Check Docker disk usage
docker system df

# Clean everything unused
docker system prune -a --volumes

# Remove specific resources
docker image prune -a          # Remove unused images
docker container prune         # Remove stopped containers
docker volume prune            # Remove unused volumes (CAREFUL!)

# Find largest images
docker images --format "{{.Size}}\t{{.Repository}}:{{.Tag}}" | sort -rh | head -10
```

---

## Network Issues

### Can't Access Service from Browser

1. **Check container is running:**
   ```bash
   docker ps | grep <service>
   ```

2. **Check port is exposed:**
   ```bash
   docker port <container>
   ```

3. **Check firewall:**
   ```bash
   # List firewall rules
   sudo iptables -L -n
   
   # Allow port
   sudo iptables -A INPUT -p tcp --dport 8096 -j ACCEPT
   ```

4. **Check service is listening:**
   ```bash
   ss -tulpn | grep <port>
   ```

### DNS Not Resolving (Pi-hole)

```bash
# Check Pi-hole is running
docker logs pihole

# Test DNS directly
nslookup google.com <pihole-ip>

# Check Pi-hole gravity database
docker exec pihole pihole -g

# Restart Pi-hole
docker restart pihole
```

### Local Domains Not Working

1. **Check Pi-hole custom DNS:**
   ```bash
   cat /path/to/pihole/etc-pihole/custom.list
   ```

2. **Add entries:**
   ```
   192.168.1.100 media.local
   192.168.1.100 docs.local
   ```

3. **Restart Pi-hole:**
   ```bash
   docker restart pihole
   ```

### Nginx Proxy Manager 502 Bad Gateway

1. **Check backend service is running:**
   ```bash
   docker ps | grep <service>
   curl http://localhost:<port>
   ```

2. **Use correct internal hostname:**
   - Use container name, not `localhost`
   - Example: `http://jellyfin:8096`

3. **Check Docker network:**
   - Ensure all services on same network

---

## Storage Issues

### ZFS Pool Degraded

```bash
# Check status
zpool status

# Identify failed disk
zpool status -v

# Replace disk (if spare available)
zpool replace <pool> <old-disk> <new-disk>

# Clear errors after fix
zpool clear <pool>
```

### ZFS Pool Full

```bash
# Check usage
zfs list

# Delete old snapshots
zfs list -t snapshot -o name,used -s used | tail -20
zfs destroy <pool>@<snapshot>

# Find large files
du -sh /srv/media/* | sort -rh | head -20

# Check for snapshot usage
zfs list -o space
```

### Can't Write to Volume

```bash
# Check permissions
ls -la /srv/homelab/<service>

# Fix ownership
sudo chown -R 1000:1000 /srv/homelab/<service>

# Check if read-only
mount | grep /srv/homelab

# Check ZFS dataset
zfs get readonly <dataset>
```

### Slow Disk Performance

```bash
# Check I/O stats
zpool iostat -v 1

# Check for degraded state
zpool status

# Run scrub if errors detected
zpool scrub <pool>

# Check ARC hit ratio
arc_summary | grep "Hit Ratio"
```

---

## Service-Specific Issues

### Jellyfin

**Library not scanning:**
```bash
# Check permissions on media folder
ls -la /srv/media/Movies

# Fix permissions
sudo chown -R 1000:1000 /srv/media/Movies

# Restart Jellyfin
docker restart jellyfin
```

**Transcoding not working (GPU):**
```bash
# Check GPU is visible
docker exec jellyfin nvidia-smi

# Check Jellyfin settings
# Dashboard → Playback → Transcoding → Hardware Acceleration: NVIDIA NVENC
```

### BookStack

**Can't login / 500 error:**
```bash
# Check database connection
docker logs bookstack-db
docker logs bookstack

# Reset database
docker exec -it bookstack-db mysql -u root -p
# Then: DROP DATABASE bookstack; CREATE DATABASE bookstack;

# Restart BookStack
docker restart bookstack
```

### Ollama

**Model not loading:**
```bash
# Check disk space
df -h /srv/homelab/ollama

# Check Ollama logs
journalctl -u ollama -f

# Re-pull model
ollama rm mistral
ollama pull mistral
```

**Out of memory:**
```bash
# Check memory usage
free -h

# Use smaller model
ollama pull phi3  # Instead of larger models

# Adjust context window
ollama run mistral --context 2048  # Smaller context
```

### Home Assistant

**Integration not working:**
```bash
# Check logs
docker logs homeassistant | grep ERROR

# Restart HA
docker restart homeassistant

# Check config validity
docker exec homeassistant python -m homeassistant --script check_config -c /config
```

---

## Performance Issues

### High CPU Usage

```bash
# Find culprit container
docker stats

# Check specific container
docker top <container>

# Limit container resources in docker-compose.yml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 4G
```

### High Memory Usage

```bash
# Check memory usage
free -h
docker stats

# Identify memory hogs
ps aux --sort=-%mem | head -10

# ZFS ARC is supposed to use RAM - this is normal
cat /proc/spl/kstat/zfs/arcstats | grep c_max
```

### Slow Network

```bash
# Check network speed
speedtest-cli

# Check for network errors
ip -s link show

# Check container network
docker exec <container> ping -c 5 google.com
```

---

## GPU Passthrough Issues

### GPU Not Visible in VM

1. **Check IOMMU enabled:**
   ```bash
   dmesg | grep -e DMAR -e IOMMU
   ```

2. **Check VFIO binding:**
   ```bash
   lspci -nnk -s 01:00
   # Should show: Kernel driver in use: vfio-pci
   ```

3. **Check VM config:**
   ```bash
   qm config 100 | grep hostpci
   ```

### nvidia-smi Not Working in Container

```bash
# Install NVIDIA Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Configure Docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Test
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

### "CUDA out of memory"

```bash
# Check GPU memory usage
nvidia-smi

# Kill processes using GPU
nvidia-smi --query-compute-apps=pid --format=csv,noheader | xargs -r kill

# Reduce batch size in application settings
```

---

## Quick Diagnostic Commands

```bash
# Overall system status
htop

# Docker overview
docker ps
docker stats --no-stream

# ZFS status
zpool status
zfs list

# Network
ip addr
ss -tulpn

# Disk
df -h
lsblk

# GPU
nvidia-smi

# Logs
journalctl -xe --since "1 hour ago"
docker logs --tail 100 <container>
```

---

## Emergency Procedures

### Service Down - Quick Recovery

```bash
# 1. Check status
docker ps

# 2. Check logs
docker logs --tail 50 <container>

# 3. Restart container
docker restart <container>

# 4. If still failing, recreate
docker compose up -d --force-recreate <service>

# 5. If storage issue, check ZFS
zpool status
```

### Roll Back to Snapshot

```bash
# 1. Stop service
docker stop <container>

# 2. Rollback ZFS
zfs rollback homelab/<service>@last-good

# 3. Start service
docker start <container>
```

---

*HomeLab - Self-Hosted Infrastructure*



