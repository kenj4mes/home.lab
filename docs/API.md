# 📚 API Reference

## Overview

All miniapps expose RESTful APIs with JSON payloads.

Base URLs (default configuration):
- Message Bus: `http://localhost:5100`
- Event Store: `http://localhost:5101`
- AI Orchestrator: `http://localhost:5200`
- Dashboard: `http://localhost:5300`
- Webhook Handler: `http://localhost:5400`

---

## 🚌 Message Bus API

### Health Check

```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "message-bus",
  "redis_connected": true,
  "timestamp": "2024-01-15T12:00:00Z"
}
```

### Publish Message

```http
POST /publish
Content-Type: application/json

{
  "channel": "system-events",
  "message": {
    "type": "service.started",
    "service": "ollama",
    "timestamp": "2024-01-15T12:00:00Z"
  }
}
```

**Response:**
```json
{
  "status": "published",
  "channel": "system-events",
  "subscribers": 3
}
```

### Subscribe to Channel

```http
POST /subscribe
Content-Type: application/json

{
  "channel": "system-events",
  "callback_url": "http://my-service:8080/webhook"
}
```

### List Channels

```http
GET /channels
```

**Response:**
```json
{
  "channels": [
    {
      "name": "system-events",
      "subscribers": 3
    },
    {
      "name": "ai-requests",
      "subscribers": 1
    }
  ]
}
```

---

## 📦 Event Store API

### Health Check

```http
GET /health
```

### Store Event

```http
POST /events
Content-Type: application/json

{
  "type": "user.action",
  "actor": "admin",
  "action": "deploy",
  "resource": "ai-orchestrator",
  "metadata": {
    "version": "1.2.0"
  }
}
```

**Response:**
```json
{
  "id": "evt_20240115_001",
  "hash": "abc123...",
  "stored_at": "2024-01-15T12:00:00Z"
}
```

### Query Events

```http
GET /events?type=user.action&limit=10&since=2024-01-01
```

**Response:**
```json
{
  "events": [
    {
      "id": "evt_20240115_001",
      "type": "user.action",
      "timestamp": "2024-01-15T12:00:00Z",
      "data": {...},
      "hash": "abc123..."
    }
  ],
  "total": 150,
  "has_more": true
}
```

### Verify Chain Integrity

```http
GET /verify
```

**Response:**
```json
{
  "valid": true,
  "events_verified": 1500,
  "last_verified": "2024-01-15T12:00:00Z"
}
```

---

## 🤖 AI Orchestrator API

### Health Check

```http
GET /health
```

### Inference Request

```http
POST /infer
Content-Type: application/json

{
  "prompt": "Explain quantum computing",
  "task": "general",
  "options": {
    "temperature": 0.7,
    "max_tokens": 500
  }
}
```

**Response:**
```json
{
  "response": "Quantum computing is...",
  "model_used": "llama3.2",
  "tokens": {
    "input": 4,
    "output": 150
  },
  "latency_ms": 1250
}
```

### Ensemble Request

```http
POST /ensemble
Content-Type: application/json

{
  "prompt": "Write a Python function to sort a list",
  "ensemble": "code_review",
  "options": {
    "require_consensus": true
  }
}
```

**Response:**
```json
{
  "response": "def sort_list(items)...",
  "models_used": ["qwen2.5-coder", "deepseek-r1"],
  "consensus_reached": true,
  "individual_responses": [...],
  "latency_ms": 3500
}
```

### List Models

```http
GET /models
```

**Response:**
```json
{
  "models": [
    {
      "name": "llama3.2",
      "status": "ready",
      "memory_usage": "4.2GB",
      "capabilities": ["general", "chat"]
    }
  ]
}
```

### Model Health

```http
GET /models/{model_name}/health
```

---

## 🎛️ Dashboard API

### Health Check

```http
GET /health
```

### Get Services Status

```http
GET /api/services
```

**Response:**
```json
{
  "services": [
    {
      "name": "ollama",
      "status": "healthy",
      "uptime": "5d 12h",
      "memory": "4.2GB"
    }
  ]
}
```

### Get Recent Events

```http
GET /api/events?limit=20
```

### Get Metrics

```http
GET /api/metrics
```

**Response:**
```json
{
  "cpu_percent": 45.2,
  "memory_percent": 62.5,
  "disk_percent": 35.0,
  "containers_running": 25,
  "ai_requests_today": 150
}
```

---

## 🔌 Webhook Handler API

### Health Check

```http
GET /health
```

### GitHub Webhook

```http
POST /webhooks/github
X-Hub-Signature-256: sha256=...
X-GitHub-Event: push

{...github payload...}
```

### Docker Hub Webhook

```http
POST /webhooks/docker-hub
Content-Type: application/json

{...dockerhub payload...}
```

### Custom Webhook

```http
POST /webhooks/custom/{endpoint}
Authorization: Bearer {token}
Content-Type: application/json

{
  "event": "custom-event",
  "data": {...}
}
```

### Send Outgoing Webhook

```http
POST /send
Content-Type: application/json

{
  "target": "slack",
  "event": "deployment",
  "data": {
    "service": "ai-orchestrator",
    "version": "1.2.0",
    "status": "success"
  },
  "channel": "#deployments"
}
```

---

## 🔐 Authentication

### Bearer Token

```http
Authorization: Bearer {jwt_token}
```

### API Key

```http
X-API-Key: {api_key}
```

---

## 📊 Rate Limits

| Endpoint | Limit |
|----------|-------|
| `/infer` | 100/min |
| `/ensemble` | 20/min |
| `/events` | 500/min |
| `/publish` | 1000/min |
| `/webhooks/*` | 100/min |

---

## 🚨 Error Responses

### Standard Error Format

```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests",
    "details": {
      "limit": 100,
      "reset_at": "2024-01-15T12:05:00Z"
    }
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid request payload |
| `UNAUTHORIZED` | 401 | Missing or invalid auth |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `SERVICE_UNAVAILABLE` | 503 | Service temporarily down |
| `INFERENCE_ERROR` | 500 | AI inference failed |

---

## 🔬 Security Research APIs

### Garak - LLM Vulnerability Scanner

**Base URL:** `http://localhost:5600`

#### Start LLM Scan

```http
POST /scan
Content-Type: application/json

{
  "model_type": "ollama",
  "model_name": "llama2",
  "api_base": "http://ollama:11434",
  "probes": ["promptinject", "dan"],
  "generations": 5
}
```

**Response:**
```json
{
  "scan_id": "abc123",
  "status": "queued",
  "model": "ollama/llama2",
  "started_at": "2024-01-15T12:00:00Z"
}
```

#### Get Scan Status

```http
GET /scan/{scan_id}
```

#### List Probes

```http
GET /probes
```

**Response:**
```json
{
  "categories": {
    "prompt_injection": [...],
    "jailbreak": [...],
    "encoding": [...],
    "leakage": [...]
  }
}
```

### Firmware Analyzer

**Base URL:** `http://localhost:5602`

#### Upload Firmware

```http
POST /upload
Content-Type: multipart/form-data

file: [firmware.bin]
```

**Response:**
```json
{
  "analysis_id": "xyz789",
  "status": "queued",
  "sha256": "a1b2c3...",
  "file_size": 10485760
}
```

#### Get Analysis Results

```http
GET /analysis/{analysis_id}
```

**Response:**
```json
{
  "analysis_id": "xyz789",
  "status": "completed",
  "file_count": 1250,
  "findings": [
    {
      "category": "credentials",
      "path": "etc/shadow",
      "size": 1024
    }
  ]
}
```

#### List Extracted Files

```http
GET /analysis/{analysis_id}/files?limit=100&offset=0
```

### Signal Classifier

**Base URL:** `http://localhost:5604`

#### Classify IQ Data

```http
POST /classify
Content-Type: multipart/form-data

file: [capture.raw]
sample_rate: 2400000
center_freq: 2437000000
```

**Response:**
```json
{
  "classification_id": "def456",
  "modulation": "OFDM",
  "modulation_confidence": 0.87,
  "protocol": "wifi_2.4ghz",
  "protocol_confidence": 0.92,
  "signal_features": {
    "snr_db": 22.5,
    "bandwidth_hz": 20000000,
    "power_dbm": -45.2
  }
}
```

#### List Modulations

```http
GET /modulations
```

#### List Protocol Signatures

```http
GET /protocols
```

### Security Dashboard

**Base URL:** `http://localhost:5610`

#### Get All Services Status

```http
GET /api/status
```

**Response:**
```json
{
  "timestamp": "2024-01-15T12:00:00Z",
  "services": [
    {
      "name": "garak",
      "url": "http://garak:5600",
      "status": "healthy",
      "latency_ms": 45.2
    }
  ],
  "healthy": 8,
  "total": 9
}
```
