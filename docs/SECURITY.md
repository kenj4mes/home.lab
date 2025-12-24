# HomeLab Security Guide

This guide covers security best practices for your HomeLab deployment.

## Post-Installation Checklist

- [ ] Change all default passwords
- [ ] Generate secure `.env` secrets with `./scripts/env-generator.sh`
- [ ] Enable firewall and restrict ports
- [ ] Configure HTTPS via Nginx Proxy Manager
- [ ] Set up backup schedule
- [ ] Review container security settings

## Secret Management

### Generating Secure Secrets

**Recommended:** Use the environment generator:
```bash
./scripts/env-generator.sh
```

**Manual generation:**
```bash
# Generate a 32-character random password
openssl rand -base64 32 | tr -d '/+=' | head -c 32

# Generate a hex secret
openssl rand -hex 24
```

### Never Commit Secrets

Ensure these files are in `.gitignore`:
```gitignore
.env
*.key
*.pem
docker/.env
```

## Default Credentials to Change

| Service | Default Credentials | How to Change |
|---------|---------------------|---------------|
| BookStack | admin@admin.com / password | Settings → Users |
| Nginx Proxy Manager | admin@example.com / changeme | First login forces change |
| Portainer | Create on first visit | N/A |
| qBittorrent | admin / (see logs) | Settings → Web UI |

## Network Security

### Firewall Configuration

**Linux (UFW):**
```bash
# Default deny incoming
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (if needed)
sudo ufw allow 22/tcp

# Allow HomeLab services (internal network only)
sudo ufw allow from 192.168.0.0/16 to any port 80,443,3000,8080,8081,8082,8096,9000 proto tcp

# Enable firewall
sudo ufw enable
```

**Windows Firewall:**
```powershell
# Block external access to sensitive ports
New-NetFirewallRule -DisplayName "Block External 9000" -Direction Inbound -LocalPort 9000 -Protocol TCP -Action Block -Profile Public
```

### Recommended Port Exposure

| Port | Service | Exposure |
|------|---------|----------|
| 80/443 | Nginx Proxy Manager | Public (for HTTPS) |
| 3000 | Open-WebUI | LAN only |
| 8080 | qBittorrent | LAN only |
| 8081 | Kiwix | LAN only |
| 8082 | BookStack | LAN only |
| 8096 | Jellyfin | LAN only |
| 9000 | Portainer | LAN only |
| 11434 | Ollama | Internal only |

## Container Hardening

The updated `docker-compose.yml` includes these security measures:

### No New Privileges
```yaml
security_opt:
  - no-new-privileges:true
```

### Read-Only Mounts (where possible)
```yaml
volumes:
  - ./content:/data:ro  # Read-only
```

### Separate Networks
```yaml
networks:
  homelab:    # Public-facing services
  internal:   # Database connections only
```

## HTTPS Setup

### Using Nginx Proxy Manager

1. Access NPM at `http://localhost:81`
2. Add a new Proxy Host
3. Enable SSL with Let's Encrypt
4. Set "Force SSL" to redirect HTTP

### Environment for DNS Challenge

```env
# In .env for Cloudflare
CF_API_TOKEN=your_cloudflare_token
```

## Backup Strategy

### Recommended Backup Targets

| Data | Location | Priority |
|------|----------|----------|
| Docker volumes | `/var/lib/docker/volumes/` | Critical |
| Config directory | `${CONFIG_PATH}` | Critical |
| ZIM files | `${MEDIA_PATH}/ZIM` | High |
| Media files | `${MEDIA_PATH}` | Medium |

### Automated Backup Script

```bash
#!/bin/bash
BACKUP_DIR="/backup/homelab/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Stop services for consistent backup
docker compose down

# Backup volumes
tar czf "$BACKUP_DIR/config.tar.gz" /srv/FlashBang/
tar czf "$BACKUP_DIR/volumes.tar.gz" /var/lib/docker/volumes/

# Restart services
docker compose up -d

echo "Backup complete: $BACKUP_DIR"
```

### ZFS Snapshots (if using ZFS)

```bash
# Create snapshot
zfs snapshot homelab@backup-$(date +%Y%m%d)

# List snapshots
zfs list -t snapshot

# Rollback (WARNING: destructive)
zfs rollback homelab@backup-20241220
```

## Secret Rotation

### Rotating Database Passwords

1. Generate new password:
   ```bash
   NEW_PASS=$(openssl rand -base64 24)
   echo "New password: $NEW_PASS"
   ```

2. Update MySQL user:
   ```bash
   docker exec -it bookstack-db mysql -u root -p
   ALTER USER 'bookstack'@'%' IDENTIFIED BY 'NEW_PASSWORD';
   FLUSH PRIVILEGES;
   ```

3. Update `.env`:
   ```env
   BOOKSTACK_DB_PASSWORD=NEW_PASSWORD
   ```

4. Restart containers:
   ```bash
   docker compose restart bookstack
   ```

## Security Monitoring

### Log Locations

| Service | Log Command |
|---------|-------------|
| All services | `docker compose logs -f` |
| Specific service | `docker logs -f jellyfin` |
| Host system | `journalctl -f` |

### Suspicious Activity Indicators

- Multiple failed login attempts
- Unusual outbound connections
- High CPU/memory on unexpected containers
- New processes inside containers

### Using Docker Bench

Run the Docker security benchmark:

```bash
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc:/etc:ro \
  docker/docker-bench-security
```

## Additional Hardening

### Disable Root SSH
```bash
# /etc/ssh/sshd_config
PermitRootLogin no
```

### Enable Automatic Updates (Ubuntu/Debian)
```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

### Use Docker Rootless Mode
```bash
# Run as non-root user
dockerd-rootless-setuptool.sh install
```
