#!/usr/bin/env python3
"""
Agent Orchestrator Server
REST API for managing and running AI agents.

Supports:
- LangGraph agents (single-agent reasoning)
- CrewAI teams (multi-agent collaboration)
- MCP integration (HomeLab services)
"""

import os
import json
import uuid
import asyncio
import logging
from datetime import datetime
from typing import Optional, Dict, Any, List
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Agent frameworks
from langchain_ollama import ChatOllama
from langchain_core.messages import HumanMessage
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from typing_extensions import TypedDict
from typing import Annotated

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ==============================================================================
# Configuration
# ==============================================================================

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://ollama:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "mistral")
BASE_RPC_URL = os.getenv("BASE_RPC_URL", "http://base-node:8545")

# Job storage
jobs: Dict[str, Dict[str, Any]] = {}

# ==============================================================================
# Pydantic Models
# ==============================================================================

class AgentRequest(BaseModel):
    """Request to run an agent."""
    query: str = Field(..., description="The task or query for the agent")
    agent_type: str = Field(default="langgraph", description="Agent type: langgraph, crewai")
    model: str = Field(default=OLLAMA_MODEL, description="LLM model to use")
    temperature: float = Field(default=0.7, ge=0, le=2)
    max_iterations: int = Field(default=10, ge=1, le=50)


class CrewRequest(BaseModel):
    """Request to run a CrewAI team."""
    task: str = Field(..., description="The task for the team")
    crew_type: str = Field(default="research", description="Crew type: research, develop, analyze")
    model: str = Field(default=OLLAMA_MODEL)


class JobResponse(BaseModel):
    """Job status response."""
    job_id: str
    status: str
    result: Optional[str] = None
    error: Optional[str] = None
    created_at: str
    completed_at: Optional[str] = None


# ==============================================================================
# LangGraph Agent
# ==============================================================================

class AgentState(TypedDict):
    messages: Annotated[list, add_messages]


def create_langgraph_agent(model: str = OLLAMA_MODEL, temperature: float = 0.7):
    """Create a LangGraph reasoning agent."""
    
    llm = ChatOllama(
        model=model,
        base_url=OLLAMA_URL,
        temperature=temperature,
    )
    
    # Define tools
    async def search_web(query: str) -> str:
        """Search the web for information."""
        try:
            from duckduckgo_search import DDGS
            with DDGS() as ddgs:
                results = list(ddgs.text(query, max_results=3))
                return json.dumps(results, indent=2)
        except Exception as e:
            return f"Search failed: {e}"
    
    async def query_blockchain(method: str, params: list = None) -> str:
        """Query Base blockchain."""
        import httpx
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.post(
                    BASE_RPC_URL,
                    json={"jsonrpc": "2.0", "method": method, "params": params or [], "id": 1}
                )
                return resp.text
        except Exception as e:
            return f"Blockchain query failed: {e}"
    
    tools = [search_web, query_blockchain]
    llm_with_tools = llm.bind_tools(tools)
    
    def agent_node(state: AgentState):
        """Main agent node."""
        return {"messages": [llm_with_tools.invoke(state["messages"])]}
    
    # Build graph
    graph = StateGraph(AgentState)
    graph.add_node("agent", agent_node)
    graph.add_edge(START, "agent")
    graph.add_edge("agent", END)
    
    return graph.compile()


# ==============================================================================
# CrewAI Team
# ==============================================================================

def create_crew(task: str, crew_type: str = "research", model: str = OLLAMA_MODEL):
    """Create and run a CrewAI team."""
    from crewai import Agent, Task, Crew, Process
    
    llm = ChatOllama(
        model=model,
        base_url=OLLAMA_URL,
    )
    
    if crew_type == "research":
        agents = [
            Agent(
                role="Research Analyst",
                goal="Gather comprehensive information on the topic",
                backstory="Expert researcher with deep analytical skills",
                llm=llm,
                verbose=True,
            ),
            Agent(
                role="Report Writer",
                goal="Synthesize research into clear, actionable insights",
                backstory="Technical writer specializing in clear communication",
                llm=llm,
                verbose=True,
            ),
        ]
        tasks = [
            Task(
                description=f"Research the following topic thoroughly: {task}",
                expected_output="Comprehensive research findings with sources",
                agent=agents[0],
            ),
            Task(
                description="Create a summary report from the research",
                expected_output="Clear, well-structured report",
                agent=agents[1],
            ),
        ]
    
    elif crew_type == "develop":
        agents = [
            Agent(
                role="Software Architect",
                goal="Design robust technical solutions",
                backstory="Senior architect with Web3 and AI expertise",
                llm=llm,
                verbose=True,
            ),
            Agent(
                role="Developer",
                goal="Implement high-quality code",
                backstory="Full-stack developer with attention to detail",
                llm=llm,
                verbose=True,
            ),
            Agent(
                role="Code Reviewer",
                goal="Ensure code quality and best practices",
                backstory="Security-focused engineer",
                llm=llm,
                verbose=True,
            ),
        ]
        tasks = [
            Task(
                description=f"Design a solution for: {task}",
                expected_output="Technical design document",
                agent=agents[0],
            ),
            Task(
                description="Implement the designed solution",
                expected_output="Working code implementation",
                agent=agents[1],
            ),
            Task(
                description="Review and improve the implementation",
                expected_output="Reviewed and improved code",
                agent=agents[2],
            ),
        ]
    
    else:  # analyze
        agents = [
            Agent(
                role="Data Analyst",
                goal="Analyze data and identify patterns",
                backstory="Expert in data analysis and visualization",
                llm=llm,
                verbose=True,
            ),
        ]
        tasks = [
            Task(
                description=f"Analyze the following: {task}",
                expected_output="Detailed analysis with insights",
                agent=agents[0],
            ),
        ]
    
    crew = Crew(
        agents=agents,
        tasks=tasks,
        process=Process.sequential,
        verbose=True,
    )
    
    return crew.kickoff()


# ==============================================================================
# Background Job Runner
# ==============================================================================

async def run_agent_job(job_id: str, request: AgentRequest):
    """Run agent in background."""
    try:
        jobs[job_id]["status"] = "running"
        
        if request.agent_type == "langgraph":
            agent = create_langgraph_agent(request.model, request.temperature)
            result = await asyncio.to_thread(
                lambda: agent.invoke({"messages": [HumanMessage(content=request.query)]})
            )
            output = result["messages"][-1].content
        
        elif request.agent_type == "crewai":
            output = await asyncio.to_thread(
                lambda: str(create_crew(request.query, "research", request.model))
            )
        
        else:
            raise ValueError(f"Unknown agent type: {request.agent_type}")
        
        jobs[job_id]["status"] = "completed"
        jobs[job_id]["result"] = output
        jobs[job_id]["completed_at"] = datetime.now().isoformat()
        
    except Exception as e:
        logger.error(f"Job {job_id} failed: {e}")
        jobs[job_id]["status"] = "failed"
        jobs[job_id]["error"] = str(e)


async def run_crew_job(job_id: str, request: CrewRequest):
    """Run CrewAI team in background."""
    try:
        jobs[job_id]["status"] = "running"
        
        result = await asyncio.to_thread(
            lambda: str(create_crew(request.task, request.crew_type, request.model))
        )
        
        jobs[job_id]["status"] = "completed"
        jobs[job_id]["result"] = result
        jobs[job_id]["completed_at"] = datetime.now().isoformat()
        
    except Exception as e:
        logger.error(f"Job {job_id} failed: {e}")
        jobs[job_id]["status"] = "failed"
        jobs[job_id]["error"] = str(e)


# ==============================================================================
# FastAPI Application
# ==============================================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events."""
    logger.info("Agent Orchestrator starting...")
    yield
    logger.info("Agent Orchestrator shutting down...")


app = FastAPI(
    title="Agent Orchestrator",
    description="Multi-agent runtime with LangGraph, CrewAI, and MCP support",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    """Health check."""
    return {
        "status": "healthy",
        "service": "agent-orchestrator",
        "version": "1.0.0",
        "ollama_url": OLLAMA_URL,
        "model": OLLAMA_MODEL,
        "active_jobs": sum(1 for j in jobs.values() if j["status"] == "running"),
    }


@app.post("/agent/run", response_model=JobResponse)
async def run_agent(request: AgentRequest, background_tasks: BackgroundTasks):
    """Run a single agent with a query."""
    job_id = str(uuid.uuid4())
    
    jobs[job_id] = {
        "job_id": job_id,
        "status": "queued",
        "created_at": datetime.now().isoformat(),
        "agent_type": request.agent_type,
        "query": request.query,
    }
    
    background_tasks.add_task(run_agent_job, job_id, request)
    
    return JobResponse(
        job_id=job_id,
        status="queued",
        created_at=jobs[job_id]["created_at"],
    )


@app.post("/crew/run", response_model=JobResponse)
async def run_crew(request: CrewRequest, background_tasks: BackgroundTasks):
    """Run a CrewAI team on a task."""
    job_id = str(uuid.uuid4())
    
    jobs[job_id] = {
        "job_id": job_id,
        "status": "queued",
        "created_at": datetime.now().isoformat(),
        "crew_type": request.crew_type,
        "task": request.task,
    }
    
    background_tasks.add_task(run_crew_job, job_id, request)
    
    return JobResponse(
        job_id=job_id,
        status="queued",
        created_at=jobs[job_id]["created_at"],
    )


@app.get("/jobs/{job_id}", response_model=JobResponse)
async def get_job(job_id: str):
    """Get job status."""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    
    job = jobs[job_id]
    return JobResponse(
        job_id=job_id,
        status=job["status"],
        result=job.get("result"),
        error=job.get("error"),
        created_at=job["created_at"],
        completed_at=job.get("completed_at"),
    )


@app.get("/jobs")
async def list_jobs():
    """List all jobs."""
    return {
        "total": len(jobs),
        "jobs": [
            JobResponse(
                job_id=j["job_id"],
                status=j["status"],
                created_at=j["created_at"],
                completed_at=j.get("completed_at"),
            )
            for j in jobs.values()
        ],
    }


@app.get("/")
async def root():
    """API documentation."""
    return {
        "service": "Agent Orchestrator",
        "version": "1.0.0",
        "endpoints": {
            "POST /agent/run": "Run single LangGraph/CrewAI agent",
            "POST /crew/run": "Run multi-agent CrewAI team",
            "GET /jobs/{id}": "Get job status and result",
            "GET /jobs": "List all jobs",
            "GET /health": "Health check",
        },
        "agent_types": ["langgraph", "crewai"],
        "crew_types": ["research", "develop", "analyze"],
    }


if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("PORT", 5004))
    uvicorn.run(app, host="0.0.0.0", port=port)
