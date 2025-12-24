# Quantum RNG Service

Quantum Random Number Generator service providing cryptographically secure random bytes via REST API.

## Features

- **Multiple Entropy Sources**: Hardware QRNG → Public QRNG APIs → OS CSPRNG
- **Thread-Safe Pool**: Cached entropy pool for high-performance
- **REST API**: Simple JSON endpoints
- **Docker Ready**: Production-ready container

## Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/random/<bytes>` | GET | Get N random bytes (1-1024) |
| `/uuid` | GET | Generate random UUID v4 |
| `/password/<length>` | GET | Generate random password |
| `/health` | GET | Health check |
| `/info` | GET | Service information |
| `/entropy` | GET | Entropy pool status |

## Usage

### Docker

```bash
# Build
docker build -t homelab/quantum-rng .

# Run
docker run -p 5001:5000 homelab/quantum-rng

# Test
curl http://localhost:5001/random/32
```

### API Examples

```bash
# Get 32 random bytes
curl http://localhost:5001/random/32
# {"hex": "a1b2c3...", "bytes": 32, "source": "os_csprng"}

# Generate UUID
curl http://localhost:5001/uuid
# {"uuid": "550e8400-e29b-41d4-a716-446655440000"}

# Generate password
curl http://localhost:5001/password/24
# {"password": "xK9#mP2$...", "length": 24}
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `QRNG_MAX_BYTES` | 1024 | Maximum bytes per request |
| `QRNG_CACHE_SIZE` | 4096 | Entropy pool cache size |
| `QRNG_ENABLE_REMOTE` | true | Enable remote QRNG sources |

## Integration

### With HomeLab Scripts

```bash
# Use in shell scripts
RANDOM_HEX=$(curl -s http://quantum-rng:5000/random/32 | jq -r .hex)

# Generate password
PASSWORD=$(curl -s http://quantum-rng:5000/password/24 | jq -r .password)
```

### With Python

```python
import requests

def get_quantum_random(num_bytes: int) -> bytes:
    resp = requests.get(f"http://quantum-rng:5000/random/{num_bytes}")
    return bytes.fromhex(resp.json()["hex"])
```
