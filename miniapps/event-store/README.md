# 📜 Event Store

> Immutable append-only event log with SHA-256 hash chaining for home.lab

## Overview

The Event Store provides a tamper-proof audit log for all home.lab operations:

- **Append-Only** - Events cannot be modified or deleted (only aged out)
- **Hash Chaining** - Each event links to the previous via SHA-256
- **Integrity Verification** - Detect any tampering in the chain
- **Retention Policies** - Automatic cleanup of old events

## Quick Start

```bash
# Start the event store
docker compose up -d

# Check health
curl http://localhost:5101/health
```

## API Reference

### Append Event

```bash
curl -X POST http://localhost:5101/events \
  -H "Content-Type: application/json" \
  -d '{
    "category": "service",
    "action": "container_started",
    "actor": "docker",
    "target": "ollama",
    "data": {"image": "ollama/ollama:latest"},
    "result": "success"
  }'
```

### Query Events

```bash
# All recent events
curl http://localhost:5101/events?limit=50

# Filter by category
curl "http://localhost:5101/events?category=security&limit=50"

# Filter by actor
curl "http://localhost:5101/events?actor=user&limit=50"

# Filter by time range
curl "http://localhost:5101/events?start_time=2025-12-24T00:00:00Z&end_time=2025-12-24T23:59:59Z"
```

### Get Specific Event

```bash
curl http://localhost:5101/events/abc123def456
```

### Verify Chain Integrity

```bash
curl -X POST http://localhost:5101/verify
```

### Get Status

```bash
curl http://localhost:5101/status
```

## Event Structure

```json
{
  "id": "abc123def456",
  "timestamp": "2025-12-24T10:00:00Z",
  "category": "service",
  "action": "container_started",
  "actor": "docker",
  "target": "ollama",
  "data": {"image": "ollama/ollama:latest"},
  "result": "success",
  "error": null,
  "previous_hash": "a1b2c3...",
  "hash": "d4e5f6..."
}
```

## Event Categories

| Category | Description | Retention |
|----------|-------------|-----------|
| `system` | System-level events | 90 days |
| `service` | Service lifecycle | 30 days |
| `security` | Security events | 365 days |
| `ai` | AI/ML operations | 30 days |
| `user` | User actions | 90 days |
| `config` | Configuration changes | 180 days |
| `error` | Error events | 30 days |

## Hash Chain

Each event contains:

- `previous_hash` - SHA-256 hash of the previous event
- `hash` - SHA-256 hash of this event (excluding the hash field)

The first event links to the genesis hash (64 zeros).

```
GENESIS → Event1 → Event2 → Event3 → ...
  ↓         ↓         ↓         ↓
0000...   a1b2c3    d4e5f6    g7h8i9
```

## Verification

Verify the entire chain:

```bash
curl -X POST http://localhost:5101/verify
```

Response:
```json
{
  "status": "valid",
  "message": "Chain integrity verified"
}
```

If tampered:
```json
{
  "status": "invalid",
  "error": "Chain broken at event abc123: expected a1b2c3, got x9y8z7"
}
```

## File Storage

Events are stored in JSONL files:

```
data/
├── events_20251224_100000.jsonl     # Active file
├── events_20251223_100000.jsonl.gz  # Compressed
└── events_20251222_100000.jsonl.gz  # Compressed
```

Files are rotated when they reach 100MB and compressed automatically.

## Integration

### Python Client

```python
import httpx

async def log_event(action: str, actor: str, target: str, data: dict):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://event-store:5101/events",
            json={
                "category": "service",
                "action": action,
                "actor": actor,
                "target": target,
                "data": data,
                "result": "success"
            }
        )
        return response.json()
```

### Docker Integration

Add to your service's docker-compose:

```yaml
services:
  my-service:
    environment:
      - EVENT_STORE_URL=http://event-store:5101
    depends_on:
      - event-store
```

## Configuration

See `configs/store.yaml` for all configuration options.

## Monitoring

Access status at `/status`:

```json
{
  "total_events": 15247,
  "chain_valid": true,
  "first_event_time": "2025-12-01T00:00:00Z",
  "last_event_time": "2025-12-24T10:00:00Z",
  "last_hash": "d4e5f6...",
  "file_count": 5,
  "total_size_bytes": 52428800
}
```
