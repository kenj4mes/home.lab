"""
Garak API - LLM Vulnerability Scanner REST API
Wrapper around NVIDIA's Garak for scanning LLM vulnerabilities
Port: 5600
"""

import asyncio
import json
import logging
import os
import subprocess
import sys
import tempfile
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import BackgroundTasks, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Garak API",
    description="LLM Vulnerability Scanner - 'nmap for LLMs'",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
REPORT_DIR = Path(os.getenv("GARAK_REPORT_DIR", "/app/data/reports"))
REPORT_DIR.mkdir(parents=True, exist_ok=True)

# Scan storage
scans: Dict[str, Dict[str, Any]] = {}


class ScanRequest(BaseModel):
    """LLM scan request"""
    model_type: str = Field(..., description="Model type: openai, ollama, huggingface, rest")
    model_name: str = Field(..., description="Model name/identifier")
    probes: Optional[List[str]] = Field(default=None, description="Specific probes to run")
    detectors: Optional[List[str]] = Field(default=None, description="Specific detectors to use")
    generations: int = Field(default=5, description="Number of generations per probe")
    api_base: Optional[str] = Field(default=None, description="API base URL for REST/Ollama")
    api_key: Optional[str] = Field(default=None, description="API key if required")


class ScanStatus(BaseModel):
    """Scan status response"""
    scan_id: str
    status: str
    model: str
    started_at: str
    completed_at: Optional[str] = None
    report_path: Optional[str] = None
    vulnerabilities_found: int = 0
    error: Optional[str] = None


# Available probes and detectors (subset of garak capabilities)
PROBE_CATEGORIES = {
    "prompt_injection": [
        "promptinject.HijackHateHumansMini",
        "promptinject.HijackKillHumansMini",
        "promptinject.HijackLongPrompt",
    ],
    "jailbreak": [
        "dan.Dan_11_0",
        "dan.Dan_6_0",
        "dan.DUDE",
        "dan.ChatGPT_Developer_Mode_v2",
    ],
    "encoding": [
        "encoding.InjectBase64",
        "encoding.InjectROT13",
        "encoding.InjectHex",
    ],
    "leakage": [
        "leakreplay.LiteratureCloze",
        "leakreplay.GuardianCloze",
    ],
    "xss": [
        "xss.MarkdownImageExfil",
    ],
    "hallucination": [
        "snowball.GraphConnectivity",
        "snowball.Primes",
    ],
    "toxicity": [
        "realtoxicityprompts.RTPSevere_Toxicity",
        "realtoxicityprompts.RTPThreat",
    ],
    "malware": [
        "malwaregen.Evasion",
        "malwaregen.Payload",
    ],
}


@app.get("/")
async def root():
    """API root"""
    return {
        "service": "Garak API",
        "description": "LLM Vulnerability Scanner",
        "version": "1.0.0",
        "endpoints": {
            "POST /scan": "Start a new LLM vulnerability scan",
            "GET /scan/{scan_id}": "Get scan status and results",
            "GET /scans": "List all scans",
            "GET /probes": "List available probes",
            "GET /health": "Health check",
        }
    }


@app.get("/health")
async def health():
    """Health check"""
    # Check if garak is installed
    try:
        result = subprocess.run(
            [sys.executable, "-m", "garak", "--version"],
            capture_output=True,
            text=True,
            timeout=10
        )
        garak_version = result.stdout.strip() if result.returncode == 0 else "not installed"
    except Exception:
        garak_version = "not installed"
    
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "garak_version": garak_version,
        "active_scans": len([s for s in scans.values() if s["status"] == "running"]),
        "completed_scans": len([s for s in scans.values() if s["status"] == "completed"]),
    }


@app.get("/probes")
async def list_probes():
    """List available probe categories"""
    return {
        "categories": PROBE_CATEGORIES,
        "total_probes": sum(len(p) for p in PROBE_CATEGORIES.values()),
        "note": "Use category name or specific probe.name format"
    }


async def run_garak_scan(scan_id: str, request: ScanRequest):
    """Run garak scan in background"""
    try:
        scans[scan_id]["status"] = "running"
        
        # Build garak command
        cmd = [
            sys.executable, "-m", "garak",
            "--model_type", request.model_type,
            "--model_name", request.model_name,
            "--generations", str(request.generations),
        ]
        
        # Add API base if provided
        if request.api_base:
            cmd.extend(["--model_api_base", request.api_base])
        
        # Add probes
        if request.probes:
            for probe in request.probes:
                cmd.extend(["--probes", probe])
        else:
            # Default to prompt injection and jailbreak
            cmd.extend(["--probes", "promptinject,dan"])
        
        # Add detectors
        if request.detectors:
            for detector in request.detectors:
                cmd.extend(["--detectors", detector])
        
        # Output report
        report_file = REPORT_DIR / f"garak_{scan_id}.json"
        cmd.extend(["--report_prefix", str(report_file.with_suffix(""))])
        
        logger.info(f"Running garak scan: {' '.join(cmd)}")
        
        # Set environment
        env = os.environ.copy()
        if request.api_key:
            if request.model_type == "openai":
                env["OPENAI_API_KEY"] = request.api_key
            elif request.model_type == "rest":
                env["REST_API_KEY"] = request.api_key
        
        # Run scan
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env=env
        )
        
        stdout, stderr = await process.communicate()
        
        if process.returncode == 0:
            scans[scan_id]["status"] = "completed"
            scans[scan_id]["completed_at"] = datetime.utcnow().isoformat()
            
            # Parse results if report exists
            if report_file.exists():
                scans[scan_id]["report_path"] = str(report_file)
                try:
                    with open(report_file) as f:
                        results = json.load(f)
                        # Count vulnerabilities (failed probes)
                        vuln_count = sum(
                            1 for r in results.get("attempts", [])
                            if r.get("status") == "FAIL"
                        )
                        scans[scan_id]["vulnerabilities_found"] = vuln_count
                except Exception as e:
                    logger.warning(f"Could not parse results: {e}")
        else:
            scans[scan_id]["status"] = "failed"
            scans[scan_id]["error"] = stderr.decode()[:1000]
            
    except Exception as e:
        logger.error(f"Scan {scan_id} failed: {e}")
        scans[scan_id]["status"] = "failed"
        scans[scan_id]["error"] = str(e)


@app.post("/scan", response_model=ScanStatus)
async def start_scan(request: ScanRequest, background_tasks: BackgroundTasks):
    """Start a new LLM vulnerability scan"""
    scan_id = str(uuid.uuid4())[:8]
    
    scans[scan_id] = {
        "scan_id": scan_id,
        "status": "queued",
        "model": f"{request.model_type}/{request.model_name}",
        "started_at": datetime.utcnow().isoformat(),
        "completed_at": None,
        "report_path": None,
        "vulnerabilities_found": 0,
        "error": None,
        "request": request.model_dump(),
    }
    
    background_tasks.add_task(run_garak_scan, scan_id, request)
    
    return ScanStatus(**scans[scan_id])


@app.get("/scan/{scan_id}", response_model=ScanStatus)
async def get_scan(scan_id: str):
    """Get scan status and results"""
    if scan_id not in scans:
        raise HTTPException(status_code=404, detail="Scan not found")
    return ScanStatus(**scans[scan_id])


@app.get("/scans")
async def list_scans():
    """List all scans"""
    return {
        "scans": [ScanStatus(**s) for s in scans.values()],
        "total": len(scans)
    }


@app.get("/scan/{scan_id}/report")
async def get_report(scan_id: str):
    """Get full scan report"""
    if scan_id not in scans:
        raise HTTPException(status_code=404, detail="Scan not found")
    
    scan = scans[scan_id]
    if not scan.get("report_path"):
        raise HTTPException(status_code=404, detail="Report not available yet")
    
    report_path = Path(scan["report_path"])
    if not report_path.exists():
        raise HTTPException(status_code=404, detail="Report file not found")
    
    with open(report_path) as f:
        return json.load(f)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5600)
