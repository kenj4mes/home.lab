# 🔐 Post-Quantum TLS Security

> **Future-proof cryptographic protection for your HomeLab**

This guide covers the Post-Quantum TLS (PQ-TLS) implementation using OpenQuantumSafe NGINX, providing hybrid classical + post-quantum key exchange to protect against future quantum computer attacks.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Why Post-Quantum?](#why-post-quantum)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Certificate Management](#certificate-management)
- [Vault Integration](#vault-integration)
- [Configuration Reference](#configuration-reference)
- [Testing PQ-TLS](#testing-pq-tls)
- [Troubleshooting](#troubleshooting)

---

## Overview

| Component | Purpose | Port |
|-----------|---------|------|
| **pq-nginx** | Post-Quantum TLS reverse proxy | 443, 80 |
| **vault** | Secrets management | 8200 |
| **pq-cert-gen** | Certificate generator (one-time) | - |

---

## Why Post-Quantum?

Quantum computers pose a threat to current cryptographic systems:

| Algorithm | Threat Level | Timeline |
|-----------|--------------|----------|
| RSA-2048 | HIGH | 10-15 years |
| ECDH (P-256) | HIGH | 10-15 years |
| AES-256 | MEDIUM | Grover's algorithm (√N speedup) |

**Hybrid Mode** combines classical + post-quantum algorithms:
- If quantum computers arrive early → PQ algorithm protects
- If PQ algorithm has vulnerabilities → Classical algorithm protects

---

## Quick Start

### 1. Generate Certificates

```powershell
# Generate self-signed PQ certificates (development)
docker compose -f docker-compose.pqtls.yml --profile setup up pq-cert-gen

# Or manually with openssl (OQS)
docker run --rm -v ./configs/pq-nginx/certs:/certs openquantumsafe/curl \
  openssl req -x509 -new -newkey dilithium3 \
    -keyout /certs/privkey.pem \
    -out /certs/fullchain.pem \
    -nodes -days 365 \
    -subj "/CN=homelab.local/O=HomeLab/C=US"
```

### 2. Start PQ-TLS Stack

```powershell
# Using homelab.ps1
.\homelab.ps1 -Action pqtls

# Using docker compose
docker compose -f docker-compose.pqtls.yml --profile pqtls up -d
```

### 3. Access via HTTPS

```powershell
# Browser (accept self-signed cert warning)
https://localhost

# Curl with insecure flag (self-signed)
curl -k https://localhost/health
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     INTERNET / LAN                               │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   PQ-NGINX      │  Port 443 (HTTPS)
                    │   Reverse Proxy │  X25519 + Kyber768
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼────┐         ┌────▼────┐         ┌────▼────┐
   │ Jellyfin │         │Open-WebUI│         │ Grafana │
   │  :8096   │         │  :8080   │         │  :3000  │
   └──────────┘         └──────────┘         └──────────┘
```

### Key Exchange Algorithms

| Algorithm | Type | Security Level | Status |
|-----------|------|----------------|--------|
| X25519-Kyber768 | Hybrid | 192-bit | Default |
| P256-Kyber768 | Hybrid | 128-bit | Fallback |
| Kyber768 | PQ Only | 192-bit | Available |
| X25519 | Classical | 128-bit | Fallback |

### Signature Algorithms

| Algorithm | Type | Key Size | Use Case |
|-----------|------|----------|----------|
| Dilithium3 | PQ | ~2.4 KB | Certificates |
| Falcon-512 | PQ | ~897 B | Compact certs |
| SPHINCS+-128 | PQ | ~16 KB | Stateless |

---

## Certificate Management

### Development (Self-Signed)

```bash
# Generate with Dilithium (PQ signature)
openssl req -x509 -new -newkey dilithium3 \
  -keyout privkey.pem \
  -out fullchain.pem \
  -nodes -days 365 \
  -subj "/CN=homelab.local"
```

### Production (Let's Encrypt)

Let's Encrypt doesn't yet support PQ algorithms, but you can use hybrid mode:

```bash
# Classical certificate from Let's Encrypt
certbot certonly --webroot -w /var/www/html -d yourdomain.com

# NGINX uses classical cert with PQ key exchange
# Key exchange is still quantum-resistant
```

### Certificate Locations

```
configs/pq-nginx/
├── certs/
│   ├── fullchain.pem    # Certificate chain
│   └── privkey.pem      # Private key
└── conf.d/
    └── default.conf     # NGINX configuration
```

---

## Vault Integration

HashiCorp Vault provides secure secrets management.

### Initialize Vault

```bash
# First-time setup
docker exec -it vault vault operator init

# Save the unseal keys and root token!
# Store in a secure location (not in version control)
```

### Store Secrets

```bash
# Set Vault address
export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=<your-root-token>

# Store database credentials
docker exec vault vault kv put secret/homelab/database \
  username=homelab \
  password=<generated-password>

# Store API keys
docker exec vault vault kv put secret/homelab/api \
  ollama_key=<key> \
  openai_key=<key>
```

### Read Secrets in Applications

```python
import hvac

client = hvac.Client(url='http://vault:8200', token='<token>')

# Read secret
secret = client.secrets.kv.v2.read_secret_version(
    path='homelab/database'
)
db_password = secret['data']['data']['password']
```

### Docker Secrets Integration

```yaml
# In docker-compose
secrets:
  db_password:
    external: true

services:
  myapp:
    secrets:
      - db_password
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password
```

---

## Configuration Reference

### NGINX SSL Configuration

```nginx
# TLS 1.3 only (required for PQ)
ssl_protocols TLSv1.3;

# Post-Quantum + Classical Hybrid Key Exchange
ssl_conf_command CurvesPreferences x25519_kyber768:p256_kyber768:kyber768:x25519:p256;

# Security headers
add_header Strict-Transport-Security "max-age=63072000" always;
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
```

### Environment Variables

```bash
# .env file
PQNGINX_CONFIG_PATH=./configs/pq-nginx
PQNGINX_CERTS_PATH=./configs/pq-nginx/certs
VAULT_DEV_TOKEN=root-token
VAULT_CONFIG_PATH=./configs/vault
```

---

## Testing PQ-TLS

### Verify PQ Key Exchange

```bash
# Using OQS curl
docker run --rm openquantumsafe/curl \
  curl -k --curves x25519_kyber768 \
  https://host.docker.internal/health

# Check negotiated cipher
docker run --rm openquantumsafe/curl \
  openssl s_client -connect host.docker.internal:443 \
  -curves x25519_kyber768 2>/dev/null | grep "Server Temp Key"
```

### Test with Standard Browsers

Modern browsers (Chrome 116+, Firefox 118+) support Kyber:

1. Navigate to `https://localhost`
2. Click lock icon → Connection is secure
3. Check certificate details

### Verify in Chrome

1. Open DevTools (F12)
2. Security tab
3. Look for "Key exchange group: X25519Kyber768"

---

## Troubleshooting

### Certificate Issues

```bash
# Check certificate validity
docker exec pq-nginx openssl x509 -in /opt/nginx/certs/fullchain.pem -text -noout

# Verify private key matches
docker exec pq-nginx openssl x509 -noout -modulus -in /opt/nginx/certs/fullchain.pem | openssl md5
docker exec pq-nginx openssl rsa -noout -modulus -in /opt/nginx/certs/privkey.pem | openssl md5
```

### NGINX Not Starting

```bash
# Check configuration
docker exec pq-nginx nginx -t

# View logs
docker logs pq-nginx
```

### Vault Sealed

```bash
# Check status
docker exec vault vault status

# Unseal (need 3 of 5 keys)
docker exec vault vault operator unseal <key1>
docker exec vault vault operator unseal <key2>
docker exec vault vault operator unseal <key3>
```

### Client Compatibility

Not all clients support PQ-TLS yet. Configure fallback:

```nginx
# Allow classical fallback for older clients
ssl_conf_command CurvesPreferences x25519_kyber768:p256_kyber768:x25519:p256;
```

---

## Security Checklist

- [ ] PQ-TLS certificates generated and installed
- [ ] Vault initialized and unsealed
- [ ] Root token stored securely (offline)
- [ ] HTTP to HTTPS redirect enabled
- [ ] Security headers configured
- [ ] Services accessible only through reverse proxy
- [ ] Logs monitored for suspicious activity
- [ ] Regular certificate rotation scheduled

---

## Resources

- [Open Quantum Safe Project](https://openquantumsafe.org/)
- [OQS-OpenSSL Provider](https://github.com/open-quantum-safe/oqs-provider)
- [NIST PQC Standards](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [HashiCorp Vault](https://www.vaultproject.io/)
- [Kyber Specification](https://pq-crystals.org/kyber/)
