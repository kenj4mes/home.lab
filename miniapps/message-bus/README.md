# 📬 Message Bus

> Async inter-service messaging with priority queuing for home.lab

## Overview

The Message Bus provides a centralized communication layer for all home.lab services, enabling:

- **Pub/Sub Messaging** - Services publish and subscribe to topics
- **Priority Queuing** - Critical messages processed first (1-10 scale)
- **Message History** - Last 1000 messages stored for debugging
- **TTL Expiration** - Automatic cleanup of stale messages

## Quick Start

```bash
# Start the message bus
docker compose up -d

# Check health
curl http://localhost:5100/health
```

## API Reference

### Publish Message

```bash
curl -X POST http://localhost:5100/messages \
  -H "Content-Type: application/json" \
  -d '{
    "source": "ollama",
    "target": "open-webui",
    "action": "model_loaded",
    "payload": {"model": "llama3.2:latest"},
    "priority": 8
  }'
```

### Subscribe to Messages

```bash
curl -X POST http://localhost:5100/subscribe \
  -H "Content-Type: application/json" \
  -d '{
    "subscriber_id": "my-service",
    "topics": ["*"],
    "callback_url": "http://my-service:8080/webhook"
  }'
```

### Get Message History

```bash
# All messages
curl http://localhost:5100/messages?limit=50

# Filtered by source
curl http://localhost:5100/messages?source=ollama&limit=50
```

### Get Stats

```bash
curl http://localhost:5100/stats
```

## Message Structure

```json
{
  "id": "abc123def456",
  "source": "service-name",
  "target": "target-service",
  "type": "event",
  "action": "action_name",
  "payload": {},
  "context": {},
  "priority": 5,
  "ttl": 300,
  "timestamp": "2025-12-24T10:00:00Z",
  "correlation_id": null
}
```

## Priority Levels

| Level | Value | Use Case |
|-------|-------|----------|
| CRITICAL | 10 | System failures, security |
| HIGH | 8 | Service events, alerts |
| NORMAL | 5 | Standard operations |
| LOW | 3 | Background tasks |
| BACKGROUND | 1 | Cleanup, logging |

## Message Types

| Type | Description |
|------|-------------|
| `request` | Ask service to do something |
| `response` | Reply to a request |
| `event` | Notify about state change |
| `error` | Report an error |
| `broadcast` | Notify all services |

## Integration

### Python Client

```python
import httpx

async def publish_event(source: str, action: str, payload: dict):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://message-bus:5100/messages",
            json={
                "source": source,
                "action": action,
                "payload": payload,
                "priority": 5
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
      - MESSAGE_BUS_URL=http://message-bus:5100
    depends_on:
      - message-bus
```

## Configuration

See `configs/bus.yaml` for all configuration options.

## Monitoring

Access stats at `/stats`:

```json
{
  "total_messages": 1247,
  "messages_per_minute": 12.5,
  "active_subscribers": 8,
  "queue_depth": {
    "CRITICAL": 0,
    "HIGH": 2,
    "NORMAL": 15,
    "LOW": 42,
    "BACKGROUND": 100
  },
  "uptime_seconds": 86400
}
```
