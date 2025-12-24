"""
═══════════════════════════════════════════════════════════════
🤖 home.lab - AI Orchestrator
Intelligent model routing, ensemble execution, and cognitive modules
═══════════════════════════════════════════════════════════════
"""

import os
import asyncio
import json
from datetime import datetime, timezone
from typing import Optional, Dict, List, Any, Literal
from contextlib import asynccontextmanager
from enum import Enum
from pathlib import Path

import httpx
import yaml
import redis.asyncio as redis
from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
import structlog
import uvicorn
from tenacity import retry, stop_after_attempt, wait_exponential

# ───────────────────────────────────────────────────────────────
# Configuration
# ───────────────────────────────────────────────────────────────
ORCHESTRATOR_HOST = os.getenv("ORCHESTRATOR_HOST", "0.0.0.0")
ORCHESTRATOR_PORT = int(os.getenv("ORCHESTRATOR_PORT", "5200"))
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://ollama:11434")
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/2")
EVENT_STORE_URL = os.getenv("EVENT_STORE_URL", "http://event-store:5101")
MESSAGE_BUS_URL = os.getenv("MESSAGE_BUS_URL", "http://message-bus:5100")
CONFIG_DIR = Path(os.getenv("CONFIG_DIR", "/app/configs"))
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

# Configure logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer()
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
)
logger = structlog.get_logger()


# ───────────────────────────────────────────────────────────────
# Models
# ───────────────────────────────────────────────────────────────
class TaskType(str, Enum):
    CHAT = "chat"
    CODE = "code"
    REASONING = "reasoning"
    EMBEDDINGS = "embeddings"
    VISION = "vision"
    AUDIO = "audio"


class Priority(int, Enum):
    CRITICAL = 1
    HIGH = 2
    NORMAL = 5
    LOW = 8
    BACKGROUND = 10


class CompletionRequest(BaseModel):
    """Request for AI completion"""
    prompt: str = Field(..., description="The prompt to send")
    system: Optional[str] = Field(default=None, description="System prompt")
    task_type: TaskType = Field(default=TaskType.CHAT)
    model: Optional[str] = Field(default=None, description="Specific model to use")
    ensemble: Optional[str] = Field(default=None, description="Ensemble to use")
    temperature: float = Field(default=0.7, ge=0, le=2)
    max_tokens: int = Field(default=4096, ge=1, le=128000)
    stream: bool = Field(default=False)
    priority: Priority = Field(default=Priority.NORMAL)
    metadata: Dict[str, Any] = Field(default_factory=dict)


class CompletionResponse(BaseModel):
    """Response from AI completion"""
    id: str
    model: str
    content: str
    tokens_used: int
    latency_ms: int
    confidence: Optional[float] = None
    ensemble_results: Optional[List[Dict]] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)


class ModelInfo(BaseModel):
    """Model information"""
    name: str
    provider: str
    type: str
    status: str
    capabilities: List[str]
    loaded: bool


class EmbeddingRequest(BaseModel):
    """Request for embeddings"""
    texts: List[str]
    model: Optional[str] = None


class EmbeddingResponse(BaseModel):
    """Response with embeddings"""
    model: str
    embeddings: List[List[float]]
    dimensions: int


# ───────────────────────────────────────────────────────────────
# Configuration Loader
# ───────────────────────────────────────────────────────────────
class ConfigLoader:
    """Load and manage configuration files"""
    
    def __init__(self, config_dir: Path):
        self.config_dir = config_dir
        self.configs: Dict[str, Any] = {}
        
    def load_all(self):
        """Load all configuration files"""
        config_files = [
            "model-router.yaml",
            "ensembles.yaml",
            "cognitive-modules.yaml",
            "reasoning-techniques.yaml"
        ]
        
        for filename in config_files:
            filepath = self.config_dir / filename
            if filepath.exists():
                with open(filepath) as f:
                    key = filename.replace(".yaml", "").replace("-", "_")
                    self.configs[key] = yaml.safe_load(f)
                    logger.info(f"Loaded config: {filename}")
                    
    def get(self, key: str) -> Dict:
        """Get configuration by key"""
        return self.configs.get(key, {})
        
    def get_models(self) -> Dict:
        """Get model registry"""
        return self.get("model_router").get("models", {})
        
    def get_routing(self) -> Dict:
        """Get routing configuration"""
        return self.get("model_router").get("routing", {})
        
    def get_ensembles(self) -> Dict:
        """Get ensemble definitions"""
        return self.get("ensembles").get("ensembles", {})


# ───────────────────────────────────────────────────────────────
# Model Router
# ───────────────────────────────────────────────────────────────
class ModelRouter:
    """Route requests to appropriate models"""
    
    def __init__(self, config: ConfigLoader, http_client: httpx.AsyncClient):
        self.config = config
        self.http = http_client
        self.model_status: Dict[str, str] = {}
        
    async def health_check_models(self):
        """Check health of all models"""
        models = self.config.get_models()
        
        for name, model_config in models.items():
            try:
                if model_config.get("provider") == "ollama":
                    response = await self.http.get(f"{OLLAMA_URL}/api/tags")
                    if response.status_code == 200:
                        tags = response.json().get("models", [])
                        model_names = [m.get("name", "").split(":")[0] for m in tags]
                        self.model_status[name] = "available" if name in model_names else "not_loaded"
                    else:
                        self.model_status[name] = "unavailable"
            except Exception as e:
                self.model_status[name] = "error"
                logger.error(f"Health check failed for {name}", error=str(e))
                
    def select_model(self, task_type: TaskType, complexity: str = "medium") -> str:
        """Select best model for task"""
        routing = self.config.get_routing()
        
        # Try task-based routing
        task_routing = routing.get("task_routing", {})
        if task_type.value in task_routing:
            primary = task_routing[task_type.value].get("primary")
            if self.model_status.get(primary) == "available":
                return primary
            # Try fallbacks
            for fallback in task_routing[task_type.value].get("fallback", []):
                if self.model_status.get(fallback) == "available":
                    return fallback
                    
        # Fall back to complexity routing
        complexity_routing = routing.get("complexity_routing", {})
        if complexity in complexity_routing:
            preferred = complexity_routing[complexity].get("prefer")
            if self.model_status.get(preferred) == "available":
                return preferred
                
        # Last resort: any available model
        for name, status in self.model_status.items():
            if status == "available":
                return name
                
        raise HTTPException(status_code=503, detail="No models available")
        
    def get_model_info(self) -> List[ModelInfo]:
        """Get information about all models"""
        models = self.config.get_models()
        result = []
        
        for name, config in models.items():
            result.append(ModelInfo(
                name=name,
                provider=config.get("provider", "unknown"),
                type=config.get("type", "unknown"),
                status=self.model_status.get(name, "unknown"),
                capabilities=config.get("capabilities", []),
                loaded=self.model_status.get(name) == "available"
            ))
            
        return result


# ───────────────────────────────────────────────────────────────
# Ollama Client
# ───────────────────────────────────────────────────────────────
class OllamaClient:
    """Client for Ollama API"""
    
    def __init__(self, http_client: httpx.AsyncClient):
        self.http = http_client
        
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=10))
    async def generate(
        self,
        model: str,
        prompt: str,
        system: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 4096
    ) -> Dict:
        """Generate completion"""
        
        payload = {
            "model": model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": temperature,
                "num_predict": max_tokens
            }
        }
        
        if system:
            payload["system"] = system
            
        response = await self.http.post(
            f"{OLLAMA_URL}/api/generate",
            json=payload,
            timeout=300.0
        )
        
        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Ollama error: {response.text}"
            )
            
        return response.json()
        
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=10))
    async def chat(
        self,
        model: str,
        messages: List[Dict],
        temperature: float = 0.7,
        max_tokens: int = 4096
    ) -> Dict:
        """Chat completion"""
        
        payload = {
            "model": model,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": temperature,
                "num_predict": max_tokens
            }
        }
            
        response = await self.http.post(
            f"{OLLAMA_URL}/api/chat",
            json=payload,
            timeout=300.0
        )
        
        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Ollama error: {response.text}"
            )
            
        return response.json()
        
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=10))
    async def embeddings(self, model: str, texts: List[str]) -> List[List[float]]:
        """Generate embeddings"""
        
        embeddings = []
        for text in texts:
            response = await self.http.post(
                f"{OLLAMA_URL}/api/embeddings",
                json={"model": model, "prompt": text},
                timeout=60.0
            )
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Ollama error: {response.text}"
                )
                
            embeddings.append(response.json().get("embedding", []))
            
        return embeddings


# ───────────────────────────────────────────────────────────────
# Ensemble Executor
# ───────────────────────────────────────────────────────────────
class EnsembleExecutor:
    """Execute ensemble patterns"""
    
    def __init__(
        self,
        config: ConfigLoader,
        ollama: OllamaClient,
        router: ModelRouter
    ):
        self.config = config
        self.ollama = ollama
        self.router = router
        
    async def execute(
        self,
        ensemble_name: str,
        prompt: str,
        system: Optional[str] = None
    ) -> Dict:
        """Execute an ensemble pattern"""
        
        ensembles = self.config.get_ensembles()
        if ensemble_name not in ensembles:
            raise HTTPException(
                status_code=404,
                detail=f"Ensemble not found: {ensemble_name}"
            )
            
        ensemble = ensembles[ensemble_name]
        strategy = ensemble.get("strategy", "consensus")
        
        if strategy == "consensus":
            return await self._execute_consensus(ensemble, prompt, system)
        elif strategy == "diverse":
            return await self._execute_diverse(ensemble, prompt, system)
        elif strategy == "generate_critique":
            return await self._execute_generate_critique(ensemble, prompt, system)
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Unknown strategy: {strategy}"
            )
            
    async def _execute_consensus(
        self,
        ensemble: Dict,
        prompt: str,
        system: Optional[str]
    ) -> Dict:
        """Execute consensus strategy"""
        
        models = ensemble.get("models", [])
        tasks = []
        
        for model in models:
            tasks.append(self.ollama.generate(model, prompt, system))
            
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        responses = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                logger.error(f"Model {models[i]} failed", error=str(result))
            else:
                responses.append({
                    "model": models[i],
                    "content": result.get("response", ""),
                    "tokens": result.get("eval_count", 0)
                })
                
        # Simple aggregation: pick most common or first
        if not responses:
            raise HTTPException(status_code=500, detail="All models failed")
            
        return {
            "strategy": "consensus",
            "content": responses[0]["content"],
            "ensemble_results": responses,
            "agreement": len(responses) / len(models)
        }
        
    async def _execute_diverse(
        self,
        ensemble: Dict,
        prompt: str,
        system: Optional[str]
    ) -> Dict:
        """Execute diverse strategy"""
        
        models = ensemble.get("models", [])
        tasks = []
        
        for model in models:
            tasks.append(self.ollama.generate(model, prompt, system))
            
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        responses = []
        for i, result in enumerate(results):
            if not isinstance(result, Exception):
                responses.append({
                    "model": models[i],
                    "content": result.get("response", "")
                })
                
        # Combine diverse perspectives
        combined = "\n\n---\n\n".join([
            f"**{r['model']}**: {r['content']}" for r in responses
        ])
        
        return {
            "strategy": "diverse",
            "content": combined,
            "ensemble_results": responses
        }
        
    async def _execute_generate_critique(
        self,
        ensemble: Dict,
        prompt: str,
        system: Optional[str]
    ) -> Dict:
        """Execute generate-critique strategy"""
        
        models = ensemble.get("models", {})
        generator = models.get("generator")
        critic = models.get("critic")
        max_iterations = ensemble.get("config", {}).get("max_iterations", 2)
        
        # Generate initial response
        gen_result = await self.ollama.generate(generator, prompt, system)
        current_response = gen_result.get("response", "")
        
        iterations = [{
            "phase": "generate",
            "model": generator,
            "content": current_response
        }]
        
        for i in range(max_iterations):
            # Critique
            critique_prompt = f"Review this response and suggest improvements:\n\n{current_response}"
            critique_result = await self.ollama.generate(critic, critique_prompt)
            critique = critique_result.get("response", "")
            
            iterations.append({
                "phase": "critique",
                "model": critic,
                "content": critique
            })
            
            if "APPROVED" in critique or "no issues" in critique.lower():
                break
                
            # Refine
            refine_prompt = f"Improve this based on feedback:\n\nOriginal: {current_response}\n\nFeedback: {critique}"
            refine_result = await self.ollama.generate(generator, refine_prompt, system)
            current_response = refine_result.get("response", "")
            
            iterations.append({
                "phase": "refine",
                "model": generator,
                "content": current_response
            })
            
        return {
            "strategy": "generate_critique",
            "content": current_response,
            "iterations": len(iterations),
            "ensemble_results": iterations
        }


# ───────────────────────────────────────────────────────────────
# Event Logger
# ───────────────────────────────────────────────────────────────
class EventLogger:
    """Log events to event store"""
    
    def __init__(self, http_client: httpx.AsyncClient):
        self.http = http_client
        
    async def log(
        self,
        action: str,
        actor: str,
        target: Optional[str] = None,
        data: Optional[Dict] = None,
        result: str = "success"
    ):
        """Log an event"""
        try:
            await self.http.post(
                f"{EVENT_STORE_URL}/events",
                json={
                    "category": "ai",
                    "action": action,
                    "actor": actor,
                    "target": target,
                    "data": data or {},
                    "result": result
                },
                timeout=5.0
            )
        except Exception as e:
            logger.warning("Failed to log event", error=str(e))


# ───────────────────────────────────────────────────────────────
# FastAPI Application
# ───────────────────────────────────────────────────────────────
config_loader = ConfigLoader(CONFIG_DIR)
http_client: Optional[httpx.AsyncClient] = None
redis_client: Optional[redis.Redis] = None
router: Optional[ModelRouter] = None
ollama: Optional[OllamaClient] = None
ensemble_executor: Optional[EnsembleExecutor] = None
event_logger: Optional[EventLogger] = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    global http_client, redis_client, router, ollama, ensemble_executor, event_logger
    
    # Initialize
    http_client = httpx.AsyncClient()
    redis_client = redis.from_url(REDIS_URL)
    
    config_loader.load_all()
    
    router = ModelRouter(config_loader, http_client)
    ollama = OllamaClient(http_client)
    ensemble_executor = EnsembleExecutor(config_loader, ollama, router)
    event_logger = EventLogger(http_client)
    
    # Initial health check
    await router.health_check_models()
    
    logger.info("AI Orchestrator initialized")
    
    yield
    
    # Cleanup
    await http_client.aclose()
    await redis_client.close()


app = FastAPI(
    title="home.lab AI Orchestrator",
    description="Intelligent model routing and ensemble execution",
    version="1.0.0",
    lifespan=lifespan
)


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "models_available": sum(1 for s in router.model_status.values() if s == "available")
    }


@app.get("/models", response_model=List[ModelInfo])
async def list_models():
    """List all available models"""
    return router.get_model_info()


@app.post("/models/refresh")
async def refresh_models(background_tasks: BackgroundTasks):
    """Refresh model status"""
    background_tasks.add_task(router.health_check_models)
    return {"status": "refreshing"}


@app.post("/complete", response_model=CompletionResponse)
async def complete(request: CompletionRequest):
    """Generate AI completion"""
    
    start_time = datetime.now(timezone.utc)
    request_id = f"req_{start_time.timestamp()}"
    
    # Select model
    if request.model:
        model = request.model
    else:
        model = router.select_model(request.task_type)
        
    # Execute
    if request.ensemble:
        result = await ensemble_executor.execute(
            request.ensemble,
            request.prompt,
            request.system
        )
        content = result["content"]
        ensemble_results = result.get("ensemble_results")
    else:
        ollama_result = await ollama.generate(
            model,
            request.prompt,
            request.system,
            request.temperature,
            request.max_tokens
        )
        content = ollama_result.get("response", "")
        ensemble_results = None
        
    # Calculate latency
    latency_ms = int((datetime.now(timezone.utc) - start_time).total_seconds() * 1000)
    
    # Log event
    await event_logger.log(
        action="completion",
        actor="orchestrator",
        target=model,
        data={
            "task_type": request.task_type.value,
            "tokens": len(content.split()),
            "latency_ms": latency_ms
        }
    )
    
    return CompletionResponse(
        id=request_id,
        model=model,
        content=content,
        tokens_used=len(content.split()),
        latency_ms=latency_ms,
        ensemble_results=ensemble_results,
        metadata=request.metadata
    )


@app.post("/embeddings", response_model=EmbeddingResponse)
async def generate_embeddings(request: EmbeddingRequest):
    """Generate embeddings"""
    
    model = request.model or router.select_model(TaskType.EMBEDDINGS)
    embeddings = await ollama.embeddings(model, request.texts)
    
    return EmbeddingResponse(
        model=model,
        embeddings=embeddings,
        dimensions=len(embeddings[0]) if embeddings else 0
    )


@app.get("/ensembles")
async def list_ensembles():
    """List available ensembles"""
    return config_loader.get_ensembles()


@app.get("/config/{config_name}")
async def get_config(config_name: str):
    """Get configuration by name"""
    config = config_loader.get(config_name)
    if not config:
        raise HTTPException(status_code=404, detail="Config not found")
    return config


# ───────────────────────────────────────────────────────────────
# Main Entry Point
# ───────────────────────────────────────────────────────────────
if __name__ == "__main__":
    uvicorn.run(
        "orchestrator:app",
        host=ORCHESTRATOR_HOST,
        port=ORCHESTRATOR_PORT,
        reload=False,
        log_level=LOG_LEVEL.lower()
    )
