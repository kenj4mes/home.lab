# Agent Orchestrator

Multi-agent runtime providing REST API access to AI agent frameworks.

## Features

- **LangGraph** - Single-agent reasoning with tool use
- **CrewAI** - Multi-agent team collaboration
- **MCP Integration** - Access HomeLab services
- **Ollama Backend** - Local LLM inference (offline-capable)

## Quick Start

### Docker

```bash
cd docker
docker compose -f docker-compose.agents.yml up -d

# Check health
curl http://localhost:5004/health
```

### Run Agent

```bash
# Single agent query
curl -X POST http://localhost:5004/agent/run \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Analyze the current Base blockchain status",
    "agent_type": "langgraph",
    "model": "mistral"
  }'
```

### Run Crew

```bash
# Multi-agent team
curl -X POST http://localhost:5004/crew/run \
  -H "Content-Type: application/json" \
  -d '{
    "task": "Research and design a smart contract for NFT minting",
    "crew_type": "develop"
  }'
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/agent/run` | POST | Run single agent |
| `/crew/run` | POST | Run multi-agent crew |
| `/jobs/{id}` | GET | Get job status/result |
| `/jobs` | GET | List all jobs |
| `/health` | GET | Health check |

## Agent Types

### LangGraph (Single Agent)

Best for:
- Reasoning tasks
- Tool-augmented queries
- Step-by-step problem solving

```json
{
  "query": "What's the current ETH gas price and how does it compare to last week?",
  "agent_type": "langgraph",
  "model": "mistral",
  "temperature": 0.7
}
```

### CrewAI (Multi-Agent Teams)

#### Research Crew
- Research Analyst → Report Writer
- Best for: Information gathering, analysis

#### Develop Crew
- Software Architect → Developer → Code Reviewer
- Best for: Technical solutions, code generation

#### Analyze Crew
- Data Analyst
- Best for: Data analysis, pattern recognition

```json
{
  "task": "Analyze the security of this smart contract...",
  "crew_type": "analyze",
  "model": "codellama"
}
```

## Offline Operation

The orchestrator uses Ollama for local inference:

1. Ensure Ollama is running with models pulled
2. Set `OLLAMA_URL` environment variable
3. Agents work without internet connection

```bash
# Pull models for offline use
ollama pull mistral
ollama pull codellama
ollama pull llama3.2
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OLLAMA_URL` | http://ollama:11434 | Ollama API endpoint |
| `OLLAMA_MODEL` | mistral | Default LLM model |
| `BASE_RPC_URL` | http://base-node:8545 | Base blockchain RPC |
| `PORT` | 5004 | API server port |

## Integration Examples

### Python

```python
import httpx

# Run agent
response = httpx.post(
    "http://localhost:5004/agent/run",
    json={
        "query": "Explain quantum computing in simple terms",
        "agent_type": "langgraph"
    }
)
job_id = response.json()["job_id"]

# Poll for result
import time
while True:
    status = httpx.get(f"http://localhost:5004/jobs/{job_id}").json()
    if status["status"] == "completed":
        print(status["result"])
        break
    time.sleep(2)
```

### JavaScript

```javascript
const response = await fetch('http://localhost:5004/agent/run', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    query: 'What are the latest developments in AI?',
    agent_type: 'langgraph'
  })
});

const { job_id } = await response.json();
```

## MCP Integration

The orchestrator can connect to the HomeLab MCP server for access to:

- Ollama models
- Quantum RNG
- Base blockchain
- Knowledge base

See `miniapps/agent-orchestrator/mcp_client.py` for integration.

## Documentation

- [LangGraph Docs](https://langchain-ai.github.io/langgraph/)
- [CrewAI Docs](https://docs.crewai.com/)
- [MCP Specification](https://modelcontextprotocol.io/)
