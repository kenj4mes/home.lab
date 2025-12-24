#!/usr/bin/env bash
# ==============================================================================
# 🤖 AI Agent Framework Installation
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Installs comprehensive AI Agent development environment:
#   - LangChain & LangGraph (agent orchestration)
#   - CrewAI (multi-agent collaboration)
#   - AutoGen (Microsoft agent framework)
#   - Ollama integration (local LLMs)
#   - MCP Server support (Model Context Protocol)
#   - Offline-capable operation
#
# Usage:
#   chmod +x install-agents.sh
#   sudo ./install-agents.sh [--offline-cache]
# ==============================================================================

set -e

# Colors (some may be unused but kept for consistency)
# shellcheck disable=SC2034
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
OFFLINE_CACHE="${1:-false}"
[[ "$1" == "--offline-cache" ]] && OFFLINE_CACHE="true"

AGENT_DIR="${AGENT_DIR:-/opt/homelab/agents}"
CACHE_DIR="${CACHE_DIR:-/opt/homelab/cache/agents}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
MCP_DIR="${MCP_DIR:-/opt/homelab/mcp-servers}"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                      🤖 AI Agent Framework                                    ║"
echo "║            LangChain + CrewAI + AutoGen + MCP                                 ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get install user
if [[ $EUID -eq 0 ]]; then
    INSTALL_USER="${SUDO_USER:-root}"
    USER_HOME=$(eval echo ~${INSTALL_USER})
else
    INSTALL_USER="$(whoami)"
    USER_HOME="$HOME"
fi

echo -e "${BLUE}Installing for user: ${INSTALL_USER}${NC}"
echo ""

# ==============================================================================
# 1. Python Environment
# ==============================================================================

echo -e "${BLUE}[1/7] Setting up Python environment...${NC}"

# Ensure Python and venv
if ! command -v python3 &> /dev/null; then
    apt-get update
    apt-get install -y python3 python3-pip python3-venv
fi

# Create virtual environment
VENV_DIR="${AGENT_DIR}/venv"
mkdir -p "${AGENT_DIR}"

if [[ ! -d "${VENV_DIR}" ]]; then
    python3 -m venv "${VENV_DIR}"
fi

source "${VENV_DIR}/bin/activate"
pip install --upgrade pip wheel setuptools

echo -e "${GREEN}✓ Python environment ready${NC}"

# ==============================================================================
# 2. Core Agent Frameworks
# ==============================================================================

echo -e "${BLUE}[2/7] Installing core agent frameworks...${NC}"

# Core dependencies
pip install "langchain>=0.3.0" \
    "langchain-core>=0.3.0" \
    "langchain-community>=0.3.0" \
    "langchain-openai>=0.2.0" \
    "langchain-anthropic>=0.3.0" \
    "langchain-ollama>=0.2.0" \
    "langgraph>=0.2.0" \
    "langsmith>=0.2.0"

echo -e "${GREEN}✓ LangChain + LangGraph installed${NC}"

# CrewAI
pip install crewai crewai-tools

echo -e "${GREEN}✓ CrewAI installed${NC}"

# AutoGen
pip install autogen-agentchat~=0.4 autogen-ext~=0.4

echo -e "${GREEN}✓ AutoGen installed${NC}"

# ==============================================================================
# 3. LLM Integrations
# ==============================================================================

echo -e "${BLUE}[3/7] Installing LLM integrations...${NC}"

pip install \
    ollama \
    openai \
    anthropic \
    transformers \
    sentence-transformers \
    tiktoken \
    bitsandbytes

echo -e "${GREEN}✓ LLM integrations installed${NC}"

# ==============================================================================
# 4. Agent Tools & Utilities
# ==============================================================================

echo -e "${BLUE}[4/7] Installing agent tools...${NC}"

pip install \
    duckduckgo-search \
    wikipedia \
    arxiv \
    tavily-python \
    playwright \
    beautifulsoup4 \
    httpx \
    aiohttp \
    pydantic>=2.0 \
    pydantic-settings \
    python-dotenv \
    rich \
    typer \
    click

# Install Playwright browsers
playwright install chromium 2>/dev/null || echo -e "${YELLOW}○ Playwright browsers can be installed later${NC}"

echo -e "${GREEN}✓ Agent tools installed${NC}"

# ==============================================================================
# 5. Vector Stores & Memory
# ==============================================================================

echo -e "${BLUE}[5/7] Installing vector stores & memory...${NC}"

pip install \
    chromadb \
    faiss-cpu \
    qdrant-client \
    redis \
    sqlalchemy \
    asyncpg \
    psycopg2-binary

echo -e "${GREEN}✓ Vector stores installed${NC}"

# ==============================================================================
# 6. MCP (Model Context Protocol) Server
# ==============================================================================

echo -e "${BLUE}[6/7] Setting up MCP Server support...${NC}"

mkdir -p "${MCP_DIR}"

# Install MCP SDK
pip install mcp

# Create MCP server template
cat > "${MCP_DIR}/homelab-mcp-server.py" << 'EOF'
#!/usr/bin/env python3
"""
HomeLab MCP Server - Model Context Protocol implementation
Provides tools and resources for AI agents to interact with HomeLab services.
"""

import asyncio
import json
import httpx
from mcp.server import Server, NotificationOptions
from mcp.server.models import InitializationOptions
from mcp.types import (
    Resource,
    Tool,
    TextContent,
    ImageContent,
    EmbeddedResource,
)
import mcp.server.stdio

# Initialize server
app = Server("homelab-mcp")

# HomeLab service endpoints
SERVICES = {
    "ollama": "http://localhost:11434",
    "base_rpc": "http://localhost:8545",
    "quantum_rng": "http://localhost:5001",
    "quantum_sim": "http://localhost:5002",
    "jellyfin": "http://localhost:8096",
    "bookstack": "http://localhost:8082",
}


@app.list_resources()
async def list_resources() -> list[Resource]:
    """List available HomeLab resources."""
    return [
        Resource(
            uri="homelab://services",
            name="HomeLab Services",
            description="List of all HomeLab services and their status",
            mimeType="application/json",
        ),
        Resource(
            uri="homelab://models",
            name="Ollama Models",
            description="Available local LLM models",
            mimeType="application/json",
        ),
        Resource(
            uri="homelab://blockchain/status",
            name="Base Blockchain Status",
            description="Current Base L2 node status",
            mimeType="application/json",
        ),
    ]


@app.read_resource()
async def read_resource(uri: str) -> str:
    """Read a HomeLab resource."""
    async with httpx.AsyncClient() as client:
        if uri == "homelab://services":
            status = {}
            for name, url in SERVICES.items():
                try:
                    resp = await client.get(f"{url}/health", timeout=2)
                    status[name] = {"status": "online", "url": url}
                except:
                    status[name] = {"status": "offline", "url": url}
            return json.dumps(status, indent=2)
        
        elif uri == "homelab://models":
            try:
                resp = await client.get(f"{SERVICES['ollama']}/api/tags")
                return resp.text
            except Exception as e:
                return json.dumps({"error": str(e)})
        
        elif uri == "homelab://blockchain/status":
            try:
                resp = await client.post(
                    SERVICES["base_rpc"],
                    json={"jsonrpc": "2.0", "method": "eth_syncing", "params": [], "id": 1}
                )
                return resp.text
            except Exception as e:
                return json.dumps({"error": str(e)})
    
    return json.dumps({"error": f"Unknown resource: {uri}"})


@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available HomeLab tools."""
    return [
        Tool(
            name="generate_text",
            description="Generate text using a local Ollama model",
            inputSchema={
                "type": "object",
                "properties": {
                    "prompt": {"type": "string", "description": "The prompt to send"},
                    "model": {"type": "string", "default": "mistral"},
                },
                "required": ["prompt"],
            },
        ),
        Tool(
            name="get_random",
            description="Get cryptographically secure random bytes from Quantum RNG",
            inputSchema={
                "type": "object",
                "properties": {
                    "bytes": {"type": "integer", "default": 32},
                },
            },
        ),
        Tool(
            name="run_quantum_circuit",
            description="Execute a quantum circuit on the simulator",
            inputSchema={
                "type": "object",
                "properties": {
                    "circuit_type": {
                        "type": "string",
                        "enum": ["bell", "ghz", "qft", "grover"],
                    },
                    "qubits": {"type": "integer", "default": 2},
                },
                "required": ["circuit_type"],
            },
        ),
        Tool(
            name="eth_call",
            description="Make an Ethereum JSON-RPC call to Base node",
            inputSchema={
                "type": "object",
                "properties": {
                    "method": {"type": "string"},
                    "params": {"type": "array", "default": []},
                },
                "required": ["method"],
            },
        ),
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Execute a HomeLab tool."""
    async with httpx.AsyncClient(timeout=30) as client:
        try:
            if name == "generate_text":
                resp = await client.post(
                    f"{SERVICES['ollama']}/api/generate",
                    json={
                        "model": arguments.get("model", "mistral"),
                        "prompt": arguments["prompt"],
                        "stream": False,
                    }
                )
                result = resp.json()
                return [TextContent(type="text", text=result.get("response", ""))]
            
            elif name == "get_random":
                bytes_count = arguments.get("bytes", 32)
                resp = await client.get(f"{SERVICES['quantum_rng']}/random/{bytes_count}")
                return [TextContent(type="text", text=resp.text)]
            
            elif name == "run_quantum_circuit":
                resp = await client.post(
                    f"{SERVICES['quantum_sim']}/run",
                    json={
                        "circuit_type": arguments["circuit_type"],
                        "qubits": arguments.get("qubits", 2),
                    }
                )
                return [TextContent(type="text", text=resp.text)]
            
            elif name == "eth_call":
                resp = await client.post(
                    SERVICES["base_rpc"],
                    json={
                        "jsonrpc": "2.0",
                        "method": arguments["method"],
                        "params": arguments.get("params", []),
                        "id": 1,
                    }
                )
                return [TextContent(type="text", text=resp.text)]
            
            return [TextContent(type="text", text=f"Unknown tool: {name}")]
        
        except Exception as e:
            return [TextContent(type="text", text=f"Error: {str(e)}")]


async def main():
    """Run the MCP server."""
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await app.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="homelab-mcp",
                server_version="1.0.0",
                capabilities=app.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )


if __name__ == "__main__":
    asyncio.run(main())
EOF

chmod +x "${MCP_DIR}/homelab-mcp-server.py"

# Create MCP config for Claude Desktop / other clients
mkdir -p "${USER_HOME}/.config/mcp"
cat > "${USER_HOME}/.config/mcp/homelab.json" << EOF
{
  "mcpServers": {
    "homelab": {
      "command": "python",
      "args": ["${MCP_DIR}/homelab-mcp-server.py"],
      "env": {
        "PYTHONPATH": "${VENV_DIR}/lib/python${PYTHON_VERSION}/site-packages"
      }
    }
  }
}
EOF

echo -e "${GREEN}✓ MCP Server configured${NC}"

# ==============================================================================
# 7. Agent Templates & Examples
# ==============================================================================

echo -e "${BLUE}[7/7] Creating agent templates...${NC}"

mkdir -p "${AGENT_DIR}/templates"

# LangGraph agent template
cat > "${AGENT_DIR}/templates/langgraph_agent.py" << 'EOF'
"""
LangGraph Agent Template - HomeLab
Multi-step reasoning agent with tool use.
"""

import os
from typing import Annotated, Literal
from typing_extensions import TypedDict

from langchain_ollama import ChatOllama
from langchain_core.messages import HumanMessage, AIMessage
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langgraph.prebuilt import ToolNode, tools_condition


class State(TypedDict):
    messages: Annotated[list, add_messages]


# Initialize Ollama LLM (offline-capable)
llm = ChatOllama(
    model=os.getenv("OLLAMA_MODEL", "mistral"),
    base_url=os.getenv("OLLAMA_URL", "http://localhost:11434"),
    temperature=0.7,
)


# Define tools
def search_docs(query: str) -> str:
    """Search HomeLab documentation."""
    # Placeholder - integrate with actual search
    return f"Documentation results for: {query}"


def execute_code(code: str, language: str = "python") -> str:
    """Execute code in a sandbox."""
    # Placeholder - integrate with code executor
    return f"Executed {language} code"


def query_blockchain(method: str, params: list = None) -> str:
    """Query Base blockchain via RPC."""
    import httpx
    resp = httpx.post(
        os.getenv("BASE_RPC_URL", "http://localhost:8545"),
        json={"jsonrpc": "2.0", "method": method, "params": params or [], "id": 1}
    )
    return resp.text


tools = [search_docs, execute_code, query_blockchain]
llm_with_tools = llm.bind_tools(tools)


def agent(state: State):
    """The main agent node."""
    return {"messages": [llm_with_tools.invoke(state["messages"])]}


# Build graph
graph = StateGraph(State)
graph.add_node("agent", agent)
graph.add_node("tools", ToolNode(tools))
graph.add_edge(START, "agent")
graph.add_conditional_edges("agent", tools_condition)
graph.add_edge("tools", "agent")

# Compile
app = graph.compile()


def run(query: str) -> str:
    """Run the agent with a query."""
    result = app.invoke({"messages": [HumanMessage(content=query)]})
    return result["messages"][-1].content


if __name__ == "__main__":
    import sys
    query = sys.argv[1] if len(sys.argv) > 1 else "What can you help me with?"
    print(run(query))
EOF

# CrewAI template
cat > "${AGENT_DIR}/templates/crewai_team.py" << 'EOF'
"""
CrewAI Team Template - HomeLab
Multi-agent collaboration for complex tasks.
"""

import os
from crewai import Agent, Task, Crew, Process
from langchain_ollama import ChatOllama


# Local LLM (offline-capable)
llm = ChatOllama(
    model=os.getenv("OLLAMA_MODEL", "mistral"),
    base_url=os.getenv("OLLAMA_URL", "http://localhost:11434"),
)


# Define agents
researcher = Agent(
    role="Research Analyst",
    goal="Gather and analyze information on the given topic",
    backstory="Expert researcher with access to HomeLab knowledge base",
    llm=llm,
    verbose=True,
)

developer = Agent(
    role="Software Developer",
    goal="Write clean, efficient code to solve problems",
    backstory="Full-stack developer specializing in Web3 and AI",
    llm=llm,
    verbose=True,
)

reviewer = Agent(
    role="Quality Reviewer",
    goal="Review and improve the work of other agents",
    backstory="Senior engineer focused on code quality and best practices",
    llm=llm,
    verbose=True,
)


def run_crew(task_description: str) -> str:
    """Run the crew on a task."""
    
    research_task = Task(
        description=f"Research the following: {task_description}",
        expected_output="Comprehensive research findings",
        agent=researcher,
    )
    
    develop_task = Task(
        description="Based on the research, develop a solution or implementation",
        expected_output="Working code or detailed implementation plan",
        agent=developer,
    )
    
    review_task = Task(
        description="Review the solution and provide improvements",
        expected_output="Final reviewed and improved solution",
        agent=reviewer,
    )
    
    crew = Crew(
        agents=[researcher, developer, reviewer],
        tasks=[research_task, develop_task, review_task],
        process=Process.sequential,
        verbose=True,
    )
    
    return crew.kickoff()


if __name__ == "__main__":
    import sys
    task = sys.argv[1] if len(sys.argv) > 1 else "Create a simple smart contract"
    print(run_crew(task))
EOF

# Create helper scripts
cat > /usr/local/bin/homelab-agent << EOF
#!/bin/bash
# Run HomeLab agent templates

source "${VENV_DIR}/bin/activate"
cd "${AGENT_DIR}/templates"

case "\${1:-help}" in
    langgraph)
        python langgraph_agent.py "\${@:2}"
        ;;
    crewai)
        python crewai_team.py "\${@:2}"
        ;;
    mcp)
        python "${MCP_DIR}/homelab-mcp-server.py"
        ;;
    *)
        echo "HomeLab Agent CLI"
        echo ""
        echo "Usage: homelab-agent <command> [args]"
        echo ""
        echo "Commands:"
        echo "  langgraph <query>  - Run LangGraph reasoning agent"
        echo "  crewai <task>      - Run CrewAI multi-agent team"
        echo "  mcp                - Start MCP server"
        ;;
esac
EOF
chmod +x /usr/local/bin/homelab-agent

# Set permissions
chown -R "${INSTALL_USER}:${INSTALL_USER}" "${AGENT_DIR}" "${MCP_DIR}"

# Offline cache
if [[ "$OFFLINE_CACHE" == "true" ]]; then
    echo "Caching packages for offline use..."
    pip download -d "${CACHE_DIR}" \
        langchain langchain-core langchain-community langchain-ollama \
        langgraph crewai autogen-agentchat mcp 2>/dev/null || true
    echo -e "${GREEN}✓ Packages cached for offline use${NC}"
fi

# ==============================================================================
# Summary
# ==============================================================================

echo -e "\n${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                  ✓ Agent Framework Installation Complete                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo "Installed Frameworks:"
echo "  ✓ LangChain + LangGraph (orchestration)"
echo "  ✓ CrewAI (multi-agent teams)"
echo "  ✓ AutoGen (Microsoft agents)"
echo "  ✓ MCP Server (Model Context Protocol)"
echo ""
echo "LLM Integrations:"
echo "  ✓ Ollama (local, offline)"
echo "  ✓ OpenAI (when online)"
echo "  ✓ Anthropic (when online)"
echo ""
echo "Commands:"
echo "  homelab-agent langgraph \"query\"  - Reasoning agent"
echo "  homelab-agent crewai \"task\"      - Multi-agent team"
echo "  homelab-agent mcp                - Start MCP server"
echo ""
echo "Directories:"
echo "  Templates: ${AGENT_DIR}/templates"
echo "  MCP Server: ${MCP_DIR}"
echo "  Venv: ${VENV_DIR}"
echo ""

echo -e "${BLUE}Documentation: docs/AGENTS.md${NC}"
