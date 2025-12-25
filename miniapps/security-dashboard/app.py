"""
Security Research Dashboard - Unified Interface for All Security Tools
Port: 5610
"""

import asyncio
import json
import logging
import os
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

import httpx
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Security Research Dashboard",
    description="Unified interface for security research tools",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Service URLs from environment
SERVICES = {
    "garak": os.getenv("GARAK_URL", "http://garak:5600"),
    "counterfit": os.getenv("COUNTERFIT_URL", "http://counterfit:5601"),
    "firmware_analyzer": os.getenv("FIRMWARE_ANALYZER_URL", "http://firmware-analyzer:5602"),
    "fissure": os.getenv("FISSURE_URL", "http://fissure-api:5603"),
    "signal_classifier": os.getenv("SIGNAL_CLASSIFIER_URL", "http://signal-classifier:5604"),
    "ics_fuzzer": os.getenv("ICS_FUZZER_URL", "http://ics-fuzzer:5605"),
    "automotive": os.getenv("AUTOMOTIVE_URL", "http://automotive-analyzer:5606"),
    "sca_analyzer": os.getenv("SCA_ANALYZER_URL", "http://sca-analyzer:5607"),
}


class ServiceStatus(BaseModel):
    name: str
    url: str
    status: str
    latency_ms: float = 0
    version: Optional[str] = None
    error: Optional[str] = None


async def check_service(name: str, url: str) -> ServiceStatus:
    """Check health of a service"""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            start = datetime.now()
            response = await client.get(f"{url}/health")
            latency = (datetime.now() - start).total_seconds() * 1000
            
            if response.status_code == 200:
                data = response.json()
                return ServiceStatus(
                    name=name,
                    url=url,
                    status="healthy",
                    latency_ms=round(latency, 2),
                    version=data.get("version"),
                )
            else:
                return ServiceStatus(
                    name=name,
                    url=url,
                    status="unhealthy",
                    error=f"HTTP {response.status_code}",
                )
    except httpx.ConnectError:
        return ServiceStatus(name=name, url=url, status="offline", error="Connection refused")
    except httpx.TimeoutException:
        return ServiceStatus(name=name, url=url, status="timeout", error="Request timed out")
    except Exception as e:
        return ServiceStatus(name=name, url=url, status="error", error=str(e))


DASHBOARD_HTML = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Research Dashboard</title>
    <style>
        :root {
            --bg-primary: #0a0a0f;
            --bg-secondary: #12121a;
            --bg-card: #1a1a24;
            --text-primary: #e4e4e7;
            --text-secondary: #a1a1aa;
            --accent-red: #ef4444;
            --accent-green: #22c55e;
            --accent-yellow: #eab308;
            --accent-blue: #3b82f6;
            --accent-purple: #a855f7;
            --border-color: #27272a;
        }
        
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Segoe UI', system-ui, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            min-height: 100vh;
        }
        
        .header {
            background: linear-gradient(180deg, var(--bg-secondary) 0%, var(--bg-primary) 100%);
            border-bottom: 1px solid var(--border-color);
            padding: 24px 48px;
        }
        
        .header h1 {
            font-size: 28px;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .header h1::before {
            content: '🔒';
            font-size: 32px;
        }
        
        .subtitle {
            color: var(--text-secondary);
            margin-top: 4px;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 32px 48px;
        }
        
        .section-title {
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 16px;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        
        .services-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 16px;
            margin-bottom: 32px;
        }
        
        .service-card {
            background: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 20px;
            transition: all 0.2s ease;
        }
        
        .service-card:hover {
            border-color: var(--accent-blue);
            transform: translateY(-2px);
        }
        
        .service-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 12px;
        }
        
        .service-name {
            font-size: 16px;
            font-weight: 600;
        }
        
        .service-status {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            font-weight: 500;
            padding: 4px 8px;
            border-radius: 6px;
        }
        
        .status-healthy {
            background: rgba(34, 197, 94, 0.1);
            color: var(--accent-green);
        }
        
        .status-offline, .status-unhealthy {
            background: rgba(239, 68, 68, 0.1);
            color: var(--accent-red);
        }
        
        .status-timeout {
            background: rgba(234, 179, 8, 0.1);
            color: var(--accent-yellow);
        }
        
        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: currentColor;
        }
        
        .service-url {
            font-size: 12px;
            color: var(--text-secondary);
            font-family: monospace;
            margin-bottom: 8px;
        }
        
        .service-latency {
            font-size: 12px;
            color: var(--text-secondary);
        }
        
        .categories {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 16px;
        }
        
        .category-card {
            background: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 20px;
        }
        
        .category-icon {
            font-size: 32px;
            margin-bottom: 12px;
        }
        
        .category-title {
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 8px;
        }
        
        .category-desc {
            font-size: 14px;
            color: var(--text-secondary);
            line-height: 1.5;
        }
        
        .tools-list {
            margin-top: 12px;
            padding-left: 16px;
        }
        
        .tools-list li {
            font-size: 13px;
            color: var(--text-secondary);
            margin-bottom: 4px;
        }
        
        .refresh-btn {
            background: var(--accent-blue);
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            margin-bottom: 16px;
        }
        
        .refresh-btn:hover {
            opacity: 0.9;
        }
        
        .warning-banner {
            background: rgba(234, 179, 8, 0.1);
            border: 1px solid var(--accent-yellow);
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 24px;
            display: flex;
            align-items: flex-start;
            gap: 12px;
        }
        
        .warning-icon {
            font-size: 24px;
        }
        
        .warning-text {
            font-size: 14px;
            line-height: 1.5;
        }
        
        .warning-text strong {
            color: var(--accent-yellow);
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Security Research Dashboard</h1>
        <p class="subtitle">Advanced signal intelligence, firmware analysis, and AI security tools</p>
    </div>
    
    <div class="container">
        <div class="warning-banner">
            <span class="warning-icon">⚠️</span>
            <div class="warning-text">
                <strong>Legal Notice:</strong> These tools are for authorized security research only. 
                Many require specialized hardware and may have legal restrictions. 
                Always ensure proper authorization before testing any systems.
            </div>
        </div>
        
        <button class="refresh-btn" onclick="refreshStatus()">🔄 Refresh Status</button>
        
        <p class="section-title">Service Status</p>
        <div class="services-grid" id="services-grid">
            <div class="service-card">
                <div class="service-header">
                    <span class="service-name">Loading...</span>
                </div>
            </div>
        </div>
        
        <p class="section-title">Tool Categories</p>
        <div class="categories">
            <div class="category-card">
                <div class="category-icon">🛡️</div>
                <div class="category-title">AI/ML Security</div>
                <div class="category-desc">
                    Test LLMs and ML models for vulnerabilities, jailbreaks, and adversarial attacks.
                </div>
                <ul class="tools-list">
                    <li>Garak - LLM vulnerability scanner</li>
                    <li>Counterfit - ML adversarial testing</li>
                    <li>TextAttack - NLP attacks</li>
                </ul>
            </div>
            
            <div class="category-card">
                <div class="category-icon">📡</div>
                <div class="category-title">RF & Spectrum Analysis</div>
                <div class="category-desc">
                    Signal classification, protocol identification, and spectrum monitoring.
                </div>
                <ul class="tools-list">
                    <li>FISSURE - Unified RF framework</li>
                    <li>Signal Classifier - ML modulation ID</li>
                    <li>TorchSig - Deep learning for RF</li>
                </ul>
            </div>
            
            <div class="category-card">
                <div class="category-icon">📱</div>
                <div class="category-title">Cellular & Baseband</div>
                <div class="category-desc">
                    5G/LTE security research, baseband analysis, and protocol testing.
                </div>
                <ul class="tools-list">
                    <li>Sni5Gect - 5G NR injection</li>
                    <li>FirmWire - Baseband emulation</li>
                    <li>LTESniffer - LTE interception</li>
                </ul>
            </div>
            
            <div class="category-card">
                <div class="category-icon">🛰️</div>
                <div class="category-title">Satellite & SATCOM</div>
                <div class="category-desc">
                    LEO constellation analysis, satellite protocol research.
                </div>
                <ul class="tools-list">
                    <li>gr-iridium - Iridium decoder</li>
                    <li>SatDump - Satellite data</li>
                    <li>Starlink-FI - Terminal research</li>
                </ul>
            </div>
            
            <div class="category-card">
                <div class="category-icon">🔧</div>
                <div class="category-title">Firmware Analysis</div>
                <div class="category-desc">
                    Extract, analyze, and modify firmware images from IoT and embedded devices.
                </div>
                <ul class="tools-list">
                    <li>Unblob - Universal extraction</li>
                    <li>OFRAK - Firmware modification</li>
                    <li>EMBA - Embedded analyzer</li>
                </ul>
            </div>
            
            <div class="category-card">
                <div class="category-icon">⚡</div>
                <div class="category-title">Hardware Security</div>
                <div class="category-desc">
                    Fault injection, side-channel analysis, and physical layer attacks.
                </div>
                <ul class="tools-list">
                    <li>PicoEMP - EM fault injection</li>
                    <li>VoltPillager - Voltage attacks</li>
                    <li>Jlsca - Side-channel analysis</li>
                </ul>
            </div>
            
            <div class="category-card">
                <div class="category-icon">🏭</div>
                <div class="category-title">ICS/SCADA Security</div>
                <div class="category-desc">
                    Industrial control system fuzzing and protocol analysis.
                </div>
                <ul class="tools-list">
                    <li>ICSFuzz - CODESYS fuzzer</li>
                    <li>Modbus/S7 testing</li>
                    <li>PLC security research</li>
                </ul>
            </div>
            
            <div class="category-card">
                <div class="category-icon">🚗</div>
                <div class="category-title">Automotive Security</div>
                <div class="category-desc">
                    Vehicle network analysis, CAN/automotive ethernet testing.
                </div>
                <ul class="tools-list">
                    <li>SOME/IP fuzzing</li>
                    <li>UDS diagnostics</li>
                    <li>UWB key attacks</li>
                </ul>
            </div>
        </div>
    </div>
    
    <script>
        async function refreshStatus() {
            try {
                const response = await fetch('/api/status');
                const data = await response.json();
                renderServices(data.services);
            } catch (error) {
                console.error('Failed to fetch status:', error);
            }
        }
        
        function renderServices(services) {
            const grid = document.getElementById('services-grid');
            grid.innerHTML = services.map(s => `
                <div class="service-card">
                    <div class="service-header">
                        <span class="service-name">${s.name}</span>
                        <span class="service-status status-${s.status}">
                            <span class="status-dot"></span>
                            ${s.status}
                        </span>
                    </div>
                    <div class="service-url">${s.url}</div>
                    ${s.latency_ms > 0 ? `<div class="service-latency">Latency: ${s.latency_ms}ms</div>` : ''}
                    ${s.error ? `<div class="service-latency" style="color: var(--accent-red);">Error: ${s.error}</div>` : ''}
                </div>
            `).join('');
        }
        
        // Initial load
        refreshStatus();
        
        // Auto-refresh every 30 seconds
        setInterval(refreshStatus, 30000);
    </script>
</body>
</html>
"""


@app.get("/", response_class=HTMLResponse)
async def dashboard():
    """Serve the dashboard HTML"""
    return DASHBOARD_HTML


@app.get("/health")
async def health():
    """Health check"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "services_configured": len(SERVICES),
    }


@app.get("/api/status")
async def get_status():
    """Get status of all services"""
    tasks = [check_service(name, url) for name, url in SERVICES.items()]
    results = await asyncio.gather(*tasks)
    
    return {
        "timestamp": datetime.utcnow().isoformat(),
        "services": [r.model_dump() for r in results],
        "healthy": sum(1 for r in results if r.status == "healthy"),
        "total": len(results),
    }


@app.get("/api/services")
async def list_services():
    """List configured services"""
    return {"services": SERVICES}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5610)
