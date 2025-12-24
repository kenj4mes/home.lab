# AI Agent Framework Guide

HomeLab includes a comprehensive AI agent development and orchestration platform.

## Overview

| Component | Purpose |
|-----------|---------|
| **LangGraph** | Single-agent reasoning with tool use |
| **CrewAI** | Multi-agent team collaboration |
| **AutoGen** | Microsoft's agent framework |
| **MCP Server** | Model Context Protocol for service integration |
| **Ollama** | Local LLM inference (offline-capable) |
| **ChromaDB** | Vector store for RAG |

## Quick Start

### Start Agent Services

```bash
# Linux/WSL
./homelab.sh --action agents

# Windows PowerShell
.\homelab.ps1 -Action start -IncludeAgents

# Docker directly
docker compose -f docker-compose.agents.yml up -d
```

### Run a Query

```bash
# Single agent
curl -X POST http://localhost:5004/agent/run \
  -H "Content-Type: application/json" \
  -d '{"query": "Analyze the current state of Web3"}'

# Multi-agent crew
curl -X POST http://localhost:5004/crew/run \
  -H "Content-Type: application/json" \
  -d '{"task": "Research and design a DeFi protocol", "crew_type": "develop"}'
```

## Agent Types

### LangGraph (Single Agent)

Reasoning agent with step-by-step problem solving and tool access.

**Best for:**
- Complex reasoning tasks
- Tool-augmented queries
- Conversational agents

**Example:**
```python
from langchain_ollama import ChatOllama
from langgraph.graph import StateGraph

llm = ChatOllama(model="mistral", base_url="http://ollama:11434")

# Define tools, nodes, graph...
agent = graph.compile()
result = agent.invoke({"messages": [HumanMessage(content="...")]})
```

### CrewAI (Multi-Agent Teams)

Collaborative agents working together on complex tasks.

**Crew Types:**

| Type | Agents | Use Case |
|------|--------|----------|
| `research` | Analyst → Writer | Information gathering |
| `develop` | Architect → Developer → Reviewer | Code generation |
| `analyze` | Data Analyst | Pattern recognition |

**Example:**
```python
from crewai import Agent, Task, Crew, Process

researcher = Agent(
    role="Research Analyst",
    goal="Gather comprehensive information",
    llm=llm
)

crew = Crew(
    agents=[researcher, writer],
    tasks=[research_task, write_task],
    process=Process.sequential
)

result = crew.kickoff()
```

## API Reference

### Agent Orchestrator (Port 5004)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/agent/run` | POST | Run single agent query |
| `/crew/run` | POST | Run multi-agent team |
| `/jobs/{id}` | GET | Get job status/result |
| `/jobs` | GET | List all jobs |
| `/health` | GET | Health check |

### Request Examples

**Single Agent:**
```json
POST /agent/run
{
  "query": "What are the latest AI developments?",
  "agent_type": "langgraph",
  "model": "mistral",
  "temperature": 0.7,
  "max_iterations": 10
}
```

**Multi-Agent Crew:**
```json
POST /crew/run
{
  "task": "Analyze smart contract security vulnerabilities",
  "crew_type": "analyze",
  "model": "codellama"
}
```

**Response:**
```json
{
  "job_id": "abc-123",
  "status": "queued",
  "created_at": "2024-12-23T10:00:00"
}
```

## MCP Integration

The Model Context Protocol enables agents to access HomeLab services.

### Available Tools

| Tool | Description |
|------|-------------|
| `generate_text` | Generate text with Ollama |
| `get_random` | Quantum RNG bytes |
| `run_quantum_circuit` | Execute quantum circuits |
| `eth_call` | Query Base blockchain |

### Available Resources

| Resource | Description |
|----------|-------------|
| `homelab://services` | Service status |
| `homelab://models` | Available LLM models |
| `homelab://blockchain/status` | Base node sync status |

### Using MCP Client

```python
from mcp import ClientSession

async with ClientSession() as session:
    await session.initialize()
    
    # List available tools
    tools = await session.list_tools()
    
    # Call a tool
    result = await session.call_tool(
        "generate_text",
        {"prompt": "Hello world", "model": "mistral"}
    )
```

## Offline Operation

Agents work fully offline with local Ollama models:

1. **Pull models:**
   ```bash
   ollama pull mistral
   ollama pull codellama
   ```

2. **Configure endpoint:**
   ```bash
   OLLAMA_URL=http://localhost:11434
   ```

3. **Run agents** - No internet required

## Vector Store (ChromaDB)

RAG (Retrieval Augmented Generation) with local vector storage.

### Add Documents

```python
import chromadb

client = chromadb.HttpClient(host="localhost", port=8000)
collection = client.create_collection("docs")

collection.add(
    documents=["HomeLab documentation..."],
    ids=["doc1"]
)
```

### Query

```python
results = collection.query(
    query_texts=["How to deploy?"],
    n_results=5
)
```

## Custom Agents

### Template Location

```
/opt/homelab/agents/templates/
├── langgraph_agent.py
└── crewai_team.py
```

### Create Custom Agent

```python
#!/usr/bin/env python3
"""Custom HomeLab Agent"""

from langchain_ollama import ChatOllama
from langgraph.graph import StateGraph

# Initialize with local Ollama
llm = ChatOllama(
    model="mistral",
    base_url="http://ollama:11434"
)

# Define your tools
def my_tool(query: str) -> str:
    """Custom tool implementation"""
    return f"Result for: {query}"

# Build graph
# ... (see templates for full example)

# Export for CLI
def run(query: str) -> str:
    return agent.invoke({"messages": [HumanMessage(content=query)]})
```

## Docker Services

### All Agent Services

```yaml
# docker-compose.agents.yml
services:
  agent-orchestrator:  # Port 5004
  chromadb:            # Port 8000
  redis:               # Port 6379 (internal)
```

### Start Specific Services

```bash
# Just orchestrator
docker compose -f docker-compose.agents.yml up -d agent-orchestrator

# With automation (n8n)
docker compose -f docker-compose.agents.yml --profile automation up -d
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OLLAMA_URL` | http://ollama:11434 | Ollama API endpoint |
| `OLLAMA_MODEL` | mistral | Default LLM model |
| `BASE_RPC_URL` | http://base-node:8545 | Blockchain RPC |
| `CHROMADB_URL` | http://chromadb:8000 | Vector store |

## Recommended Models

| Model | Size | Use Case |
|-------|------|----------|
| `phi3` | 3.8B | Fast, lightweight |
| `mistral` | 7B | General purpose |
| `codellama` | 7B | Code generation |
| `llama3.2` | 11B | Advanced reasoning |
| `deepseek-coder` | 6.7B | Code specialist |

## Resources

- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [CrewAI Documentation](https://docs.crewai.com/)
- [MCP Specification](https://modelcontextprotocol.io/)
- [Ollama Models](https://ollama.ai/library)
- [ChromaDB Guide](https://docs.trychroma.com/)

## Troubleshooting

### "Model not found"

Pull the model with Ollama:
```bash
ollama pull mistral
```

### "Connection refused"

Check that Ollama is running:
```bash
docker ps | grep ollama
curl http://localhost:11434/api/tags
```

### "Job stuck in processing"

Check agent logs:
```bash
docker logs agent-orchestrator
```
