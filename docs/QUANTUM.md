# Quantum-Ready Features

HomeLab includes post-quantum cryptography protection and quantum computing capabilities for future-proofing your infrastructure.

## 🔐 Post-Quantum Security

### Overview

Post-quantum cryptography (PQC) protects against attacks from future quantum computers. HomeLab implements hybrid cryptography that combines:

- **Classical**: ECDSA, X25519 (current security)
- **Post-Quantum**: Kyber (key encapsulation), Dilithium (signatures)

### Components

| Component | Purpose | Status |
|-----------|---------|--------|
| Hybrid TLS | Quantum-safe HTTPS | Ready |
| Docker Content Trust | PQ-signed images | Ready |
| Backup Encryption | Quantum-safe at rest | Ready |
| QRNG | Quantum entropy source | Ready |

## 🛠️ Installation

### 1. Install Post-Quantum Dependencies

```bash
# Install liboqs, OpenSSL OQS provider, and tools
sudo ./scripts/install-quantum.sh
```

This installs:
- **liboqs**: Open Quantum Safe library
- **OQS-OpenSSL Provider**: PQ algorithms for OpenSSL
- **Notation CLI**: Docker image signing (Notary v2)
- **oqsenc/oqsdec**: Quantum-safe encryption tools

### 2. Generate Hybrid TLS Certificates

```bash
# Create hybrid certificates for Nginx Proxy Manager
sudo ./scripts/generate-pq-tls.sh --domain proxy.local

# Certificates created in /opt/homelab/config/nginx/ssl/
#   - hybrid.crt      (server certificate)
#   - hybrid.key      (private key)
#   - hybrid-chain.crt (full chain)
#   - ca.crt          (CA for browser trust)
```

### 3. Create Docker Secrets

```bash
# Generate cryptographically secure secrets
sudo ./scripts/create-docker-secrets.sh

# Create Notary signing key for DCT
sudo ./scripts/create-notary-secret.sh
```

### 4. Start Quantum Services

```bash
cd /opt/homelab/docker
docker compose -f docker-compose.yml \
               -f docker-compose.base.yml \
               -f docker-compose.quantum.yml up -d
```

## 🎲 Quantum Random Number Generator

### Overview

The QRNG service provides quantum-derived entropy for:
- Secret generation
- Cryptographic operations
- Secure password creation

### Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /random/<bytes>` | Get N random bytes (hex) |
| `GET /uuid` | Generate UUID v4 |
| `GET /password/<length>` | Generate secure password |
| `GET /entropy` | Pool status |
| `GET /health` | Health check |

### Usage

```bash
# Get 32 random bytes
curl http://localhost:5001/random/32
# {"hex": "a1b2c3...", "bytes": 32, "source": "os_csprng"}

# Generate UUID
curl http://localhost:5001/uuid
# {"uuid": "550e8400-e29b-41d4-a716-446655440000"}

# Generate password
curl http://localhost:5001/password/24
# {"password": "xK9#mP2$vL7...", "length": 24}
```

### Integration with Scripts

```bash
# Use QRNG for secret generation
SECRET=$(curl -s http://quantum-rng:5000/random/32 | jq -r .hex)

# Generate password
PASSWORD=$(curl -s http://quantum-rng:5000/password/32 | jq -r .password)
```

## ⚛️ Quantum Circuit Simulator

### Overview

Local quantum computing simulator supporting multiple backends:
- **Qiskit** (IBM)
- **Cirq** (Google)
- **PennyLane** (Xanadu)

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/run` | POST | Execute quantum circuit |
| `/backends` | GET | List available backends |
| `/examples` | GET | Example circuits |
| `/health` | GET | Health check |

### Usage

#### Execute Bell State

```bash
curl -X POST http://localhost:5002/run \
  -H "Content-Type: application/json" \
  -d '{
    "shots": 1024,
    "backend": "qiskit",
    "circuit": [
      {"gate": "h", "qubit": 0},
      {"gate": "cx", "control": 0, "target": 1}
    ]
  }'
```

Response:
```json
{
  "counts": {"00": 512, "11": 512},
  "shots": 1024,
  "backend": "qiskit_aer"
}
```

### Supported Gates

| Gate | Parameters | Description |
|------|------------|-------------|
| `h` | qubit | Hadamard |
| `x`, `y`, `z` | qubit | Pauli gates |
| `cx`/`cnot` | control, target | Controlled-NOT |
| `cz` | control, target | Controlled-Z |
| `swap` | qubit1, qubit2 | SWAP |
| `rx`, `ry`, `rz` | qubit, angle | Rotation gates |
| `t`, `s` | qubit | Phase gates |

### Integration with Open-WebUI

Create a custom tool:

```python
import requests

def run_quantum_circuit(circuit: list, shots: int = 1024) -> dict:
    """Execute a quantum circuit on the local simulator."""
    resp = requests.post(
        "http://quantum-simulator:5000/run",
        json={"circuit": circuit, "shots": shots}
    )
    return resp.json()
```

### Integration with Home Assistant

```yaml
# configuration.yaml
rest_command:
  run_quantum_circuit:
    url: "http://quantum-simulator:5000/run"
    method: POST
    content_type: "application/json"
    payload: '{"shots": 1024, "circuit": [{"gate":"h","qubit":0}]}'
```

## 🔒 Post-Quantum TLS

### Configuration

The `99-pq-ssl.conf` enables hybrid TLS:

```nginx
# TLS 1.3 only
ssl_protocols TLSv1.3;

# Hybrid key exchange (when OQS available)
# ssl_conf_command Curves X25519Kyber768Draft00:X25519:P-256;

# Security headers
add_header Strict-Transport-Security "max-age=63072000" always;
```

### Verification

```bash
# Check if PQ is negotiated
openssl s_client -connect proxy.local:443 -servername proxy.local 2>&1 | \
  grep -i "kyber\|dilithium"

# Show TLS details
openssl s_client -connect proxy.local:443 -brief
```

### Browser Support

| Browser | Kyber Support |
|---------|--------------|
| Chrome 124+ | ✅ Yes |
| Firefox 124+ | ✅ Yes |
| Edge 124+ | ✅ Yes |
| Safari | ❌ Not yet |

## 💾 Quantum-Safe Backups

### Encrypted Backups

```bash
# Standard backup
sudo ./scripts/backup.sh

# Encrypted backup (AES-256-GCM)
sudo ./scripts/backup.sh --encrypt

# Post-quantum encrypted backup
sudo ./scripts/backup.sh --pq
```

### Restore

```bash
# Decrypt PQ backup
oqsdec -in backup.tar.gz.enc -out backup.tar.gz

# Standard decrypt
openssl enc -d -aes-256-gcm -pbkdf2 -in backup.tar.gz.enc -out backup.tar.gz
```

## 🔑 Docker Content Trust

### Enable DCT

```bash
# Set environment variable
export DOCKER_CONTENT_TRUST=1

# Sign an image
notation sign myregistry/myimage:latest

# Verify an image
notation verify myregistry/myimage:latest
```

### Configuration

Add to `daemon.json`:

```json
{
  "content-trust": {
    "mode": "enforced"
  }
}
```

## 📊 Security Checklist

- [ ] Run `install-quantum.sh`
- [ ] Generate hybrid TLS certificates
- [ ] Create Docker secrets
- [ ] Enable encrypted backups
- [ ] Configure NPM with PQ SSL
- [ ] Start quantum services
- [ ] Test QRNG integration
- [ ] Verify TLS negotiation

## 🔧 Troubleshooting

### OQS Provider Not Loading

```bash
# Check OpenSSL providers
openssl list -providers

# Verify liboqs installation
ls -la /usr/local/lib/liboqs*
```

### QRNG Service Not Starting

```bash
# Check logs
docker logs quantum-rng

# Test endpoint
curl http://localhost:5001/health
```

### Simulator Out of Memory

```bash
# Reduce max qubits
docker run -e QUANTUM_MAX_QUBITS=16 homelab/quantum-simulator
```

## 📚 References

- [Open Quantum Safe](https://openquantumsafe.org/)
- [NIST PQC Standards](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [Qiskit Documentation](https://qiskit.org/documentation/)
- [Cirq Documentation](https://quantumai.google/cirq)
- [PennyLane Documentation](https://pennylane.ai/qml/)
