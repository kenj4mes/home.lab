# 🤖 AI Orchestrator

> Intelligent model routing, ensemble execution, and cognitive orchestration for home.lab

## Overview

The AI Orchestrator provides a unified interface for all AI operations:

- **Model Routing** - Automatically select the best model for each task
- **Ensemble Execution** - Run multiple models with various strategies
- **Caching** - Redis-based response caching
- **Circuit Breakers** - Automatic failover on model failures
- **Event Logging** - All operations logged to event store

## Quick Start

```bash
# Start the orchestrator
docker compose up -d

# Check health
curl http://localhost:5200/health

# List available models
curl http://localhost:5200/models
```

## API Reference

### Generate Completion

```bash
curl -X POST http://localhost:5200/complete \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Explain quantum computing in simple terms",
    "task_type": "chat",
    "temperature": 0.7,
    "max_tokens": 1000
  }'
```

### Specify Model

```bash
curl -X POST http://localhost:5200/complete \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Write a Python function to sort a list",
    "model": "qwen2.5-coder",
    "task_type": "code"
  }'
```

### Use Ensemble

```bash
curl -X POST http://localhost:5200/complete \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Review this code for bugs: ...",
    "ensemble": "code_review"
  }'
```

### Generate Embeddings

```bash
curl -X POST http://localhost:5200/embeddings \
  -H "Content-Type: application/json" \
  -d '{
    "texts": ["Hello world", "How are you?"]
  }'
```

## Task Types

| Type | Description | Primary Model |
|------|-------------|---------------|
| `chat` | General conversation | llama3.2 |
| `code` | Code generation/review | qwen2.5-coder |
| `reasoning` | Complex reasoning | deepseek-r1 |
| `embeddings` | Vector embeddings | nomic-embed-text |
| `vision` | Image understanding | llava |
| `audio` | Speech-to-text | whisper-large |

## Ensemble Strategies

### Consensus
Multiple models vote on the answer:
```json
{
  "ensemble": "fact_check",
  "prompt": "Is the Earth round?"
}
```

### Diverse
Collect multiple perspectives:
```json
{
  "ensemble": "creative_brainstorm",
  "prompt": "Ideas for a new app"
}
```

### Generate-Critique
Iterative improvement:
```json
{
  "ensemble": "code_generation",
  "prompt": "Write a REST API in Python"
}
```

## Available Ensembles

| Ensemble | Strategy | Models | Use Case |
|----------|----------|--------|----------|
| `code_review` | consensus | qwen2.5-coder, llama3.2 | Code review |
| `code_generation` | generate_critique | qwen2.5-coder → llama3.2 | Code writing |
| `fact_check` | consensus | llama3.2, deepseek-r1 | Fact verification |
| `creative_brainstorm` | diverse | llama3.2, gemma2 | Idea generation |
| `deep_analysis` | diverse | llama3.2, deepseek-r1 | Analysis |
| `problem_solver` | specialist | Various | Complex problems |

## Model Routing

The orchestrator automatically selects models based on:

1. **Task Type** - Match task to model capabilities
2. **Complexity** - Simple → fast model, Complex → powerful model
3. **Context Length** - Route to models that can handle the input size
4. **Availability** - Fall back to alternatives if primary is unavailable

## Configuration

All configuration is in `/configs/ai/`:

- `model-router.yaml` - Model registry and routing rules
- `ensembles.yaml` - Ensemble patterns and strategies
- `cognitive-modules.yaml` - Cognitive architecture
- `reasoning-techniques.yaml` - Reasoning strategies

## Integration

### Python Client

```python
import httpx

async def ask_ai(prompt: str, task_type: str = "chat") -> str:
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://ai-orchestrator:5200/complete",
            json={
                "prompt": prompt,
                "task_type": task_type
            }
        )
        return response.json()["content"]
```

### From Other Services

Add to docker-compose:

```yaml
services:
  my-service:
    environment:
      - AI_ORCHESTRATOR_URL=http://ai-orchestrator:5200
    depends_on:
      - ai-orchestrator
```

## Monitoring

Health check returns model availability:

```json
{
  "status": "healthy",
  "models_available": 5
}
```

List detailed model status:

```bash
curl http://localhost:5200/models
```
