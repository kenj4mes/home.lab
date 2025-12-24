"""
═══════════════════════════════════════════════════════════════
🎛️ home.lab - Dashboard Server
Web dashboard for system monitoring and control
═══════════════════════════════════════════════════════════════
"""

import os
from pathlib import Path
from contextlib import asynccontextmanager

import httpx
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse
import uvicorn

# Configuration
DASHBOARD_HOST = os.getenv("DASHBOARD_HOST", "0.0.0.0")
DASHBOARD_PORT = int(os.getenv("DASHBOARD_PORT", "5300"))
MESSAGE_BUS_URL = os.getenv("MESSAGE_BUS_URL", "http://message-bus:5100")
EVENT_STORE_URL = os.getenv("EVENT_STORE_URL", "http://event-store:5101")
AI_ORCHESTRATOR_URL = os.getenv("AI_ORCHESTRATOR_URL", "http://ai-orchestrator:5200")

# Paths
BASE_DIR = Path(__file__).parent.parent
TEMPLATES_DIR = BASE_DIR / "templates"
STATIC_DIR = BASE_DIR / "static"

# HTTP Client
http_client = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    global http_client
    http_client = httpx.AsyncClient(timeout=10.0)
    yield
    await http_client.aclose()


# Create app
app = FastAPI(
    title="home.lab Dashboard",
    description="Web dashboard for home.lab",
    version="1.0.0",
    lifespan=lifespan
)

# Mount static files
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

# Templates
templates = Jinja2Templates(directory=str(TEMPLATES_DIR))


@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request):
    """Main dashboard page"""
    return templates.TemplateResponse("index.html", {"request": request})


@app.get("/health")
async def health():
    """Health check"""
    return {"status": "healthy"}


@app.get("/api/services")
async def get_services():
    """Get service status from message bus"""
    try:
        response = await http_client.get(f"{MESSAGE_BUS_URL}/health")
        message_bus = response.json() if response.status_code == 200 else None
    except:
        message_bus = None
        
    try:
        response = await http_client.get(f"{EVENT_STORE_URL}/status")
        event_store = response.json() if response.status_code == 200 else None
    except:
        event_store = None
        
    try:
        response = await http_client.get(f"{AI_ORCHESTRATOR_URL}/models")
        ai_models = response.json() if response.status_code == 200 else None
    except:
        ai_models = None
        
    return {
        "message_bus": message_bus,
        "event_store": event_store,
        "ai_models": ai_models
    }


@app.get("/api/events")
async def get_events(limit: int = 50):
    """Get recent events"""
    try:
        response = await http_client.get(
            f"{EVENT_STORE_URL}/events",
            params={"limit": limit}
        )
        if response.status_code == 200:
            return response.json()
    except:
        pass
    return []


@app.get("/api/metrics")
async def get_metrics():
    """Get system metrics"""
    # Would connect to Prometheus
    return {
        "cpu_usage": 35,
        "memory_usage": 52,
        "disk_usage": 45,
        "container_count": 12
    }


if __name__ == "__main__":
    uvicorn.run(
        "app:app",
        host=DASHBOARD_HOST,
        port=DASHBOARD_PORT,
        reload=True
    )
