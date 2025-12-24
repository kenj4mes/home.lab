# 💬 Matrix Synapse - Secure Communications

> Self-hosted end-to-end encrypted messaging with Matrix protocol

## Overview

HomeLab includes a complete Matrix Synapse deployment for self-hosted secure communications, based on the GrapheneOS Matrix server patterns.

```
╔════════════════════════════════════════════════════════════════════════════╗
║                    💬 Matrix Communication Stack                           ║
╠════════════════════════════════════════════════════════════════════════════╣
║  Synapse          → Matrix homeserver (federation-capable)                 ║
║  Element Web      → Modern web client for Matrix                          ║
║  PostgreSQL       → Database backend                                       ║
║  Valkey           → Redis-compatible cache for workers                    ║
║  Coturn           → TURN server for voice/video NAT traversal             ║
╚════════════════════════════════════════════════════════════════════════════╝
```

## Quick Start

### Start Matrix Stack

```powershell
# Windows
.\homelab.ps1 -Action matrix

# Or manually
docker compose -f docker/docker-compose.matrix.yml up -d
```

### Access Services

| Service | URL | Description |
|---------|-----|-------------|
| **Element Web** | http://localhost:8480 | Matrix web client |
| **Synapse API** | http://localhost:8008 | Client-Server API |
| **Federation** | http://localhost:8448 | Server-to-server |

## Initial Setup

### 1. Generate Synapse Configuration

```bash
# Generate initial config
docker run --rm \
    -v homelab_synapse-data:/data \
    matrixdotorg/synapse:latest \
    generate --server-name=homelab.local --report-stats=no

# Copy to configs folder
docker cp synapse:/data/homeserver.yaml ./configs/synapse/
```

### 2. Create Admin User

```bash
# Register admin user
docker exec -it synapse register_new_matrix_user \
    -c /config/homeserver.yaml \
    -u admin \
    -p YOUR_PASSWORD \
    -a http://localhost:8008
```

### 3. Configure TURN Server

Edit `configs/synapse/turnserver.conf`:
```conf
# Generate secret
static-auth-secret=$(openssl rand -hex 32)
realm=homelab.local
```

Add to `homeserver.yaml`:
```yaml
turn_uris:
  - "turn:localhost:3478?transport=udp"
  - "turn:localhost:3478?transport=tcp"
turn_shared_secret: "YOUR_TURN_SECRET"
turn_user_lifetime: "1h"
```

## Features

### End-to-End Encryption

Matrix provides device-verified E2EE for all messages:
- Cross-signing for device verification
- Secure key backup
- Message key sharing

### Federation

Connect to other Matrix servers:
```yaml
# homeserver.yaml
federation_domain_whitelist:
  - matrix.org
  - grapheneos.org
```

### Voice & Video

WebRTC-based calls with TURN support:
- One-on-one calls
- Group calls (Jitsi integration optional)
- Screen sharing

### Bridges

Connect to other platforms:
- Telegram
- Discord  
- Slack
- IRC
- WhatsApp (via mautrix)

## Security Hardening

### Database Encryption

```yaml
# homeserver.yaml
database:
  name: psycopg2
  args:
    host: matrix-postgres
    database: synapse
    user: synapse
    password: ${MATRIX_DB_PASSWORD}
    sslmode: require
```

### Rate Limiting

```yaml
# homeserver.yaml
rc_message:
  per_second: 0.2
  burst_count: 10

rc_registration:
  per_second: 0.17
  burst_count: 3
```

### Federation Security

```yaml
# homeserver.yaml
# Require valid TLS certificates
federation_verify_certificates: true

# Block problematic servers
federation_domain_whitelist: null  # Allow all
# OR
federation_domain_blacklist:
  - evil-server.example
```

## Backup & Restore

### Backup

```bash
# Backup database
docker exec matrix-postgres pg_dump -U synapse synapse > backup.sql

# Backup media
docker cp synapse:/data/media_store ./backup/media/

# Backup signing keys
docker cp synapse:/data/homelab.local.signing.key ./backup/
```

### Restore

```bash
# Restore database
docker exec -i matrix-postgres psql -U synapse synapse < backup.sql

# Restore media
docker cp ./backup/media/ synapse:/data/media_store/
```

## Monitoring

### Health Check

```bash
curl http://localhost:8008/health
# {"status": "OK"}
```

### Metrics (Prometheus)

```yaml
# homeserver.yaml
enable_metrics: true
metrics_port: 9000
```

Add to Prometheus:
```yaml
- job_name: 'synapse'
  static_configs:
    - targets: ['synapse:9000']
```

## Troubleshooting

### Federation Issues

```bash
# Check federation status
curl https://federationtester.matrix.org/api/report?server_name=homelab.local

# View federation logs
docker logs synapse 2>&1 | grep -i federation
```

### Database Connection

```bash
# Check PostgreSQL
docker exec matrix-postgres pg_isready -U synapse

# View connection info
docker exec synapse python -c "import psycopg2; print('OK')"
```

### Memory Issues

For larger deployments, enable workers:
```yaml
# homeserver.yaml
worker_app: synapse.app.generic_worker
worker_name: synapse_worker1
```

## CLI Reference

```powershell
# Start Matrix services
.\homelab.ps1 -Action matrix

# View logs
docker compose -f docker/docker-compose.matrix.yml logs -f synapse

# Create user
docker exec synapse register_new_matrix_user -c /config/homeserver.yaml

# Stop services
docker compose -f docker/docker-compose.matrix.yml down
```

## Resources

- [Matrix Specification](https://spec.matrix.org/)
- [Synapse Documentation](https://matrix-org.github.io/synapse/latest/)
- [Element Web](https://element.io/)
- [GrapheneOS Matrix](https://grapheneos.org/articles/matrix)
