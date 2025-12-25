"""
Firmware Analyzer API - Universal Firmware Extraction and Analysis
Wrapper around Unblob, Binwalk, and custom analysis tools
Port: 5602
"""

import asyncio
import hashlib
import json
import logging
import os
import shutil
import subprocess
import tempfile
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import BackgroundTasks, FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Firmware Analyzer API",
    description="Universal firmware extraction and security analysis",
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
UPLOAD_DIR = Path(os.getenv("UPLOAD_DIR", "/firmware"))
EXTRACT_DIR = Path(os.getenv("EXTRACT_DIR", "/extracted"))
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
EXTRACT_DIR.mkdir(parents=True, exist_ok=True)

# Analysis storage
analyses: Dict[str, Dict[str, Any]] = {}


class AnalysisResult(BaseModel):
    """Firmware analysis result"""
    analysis_id: str
    status: str
    filename: str
    file_size: int
    sha256: str
    started_at: str
    completed_at: Optional[str] = None
    extraction_path: Optional[str] = None
    file_count: int = 0
    findings: List[Dict[str, Any]] = []
    error: Optional[str] = None


class FileInfo(BaseModel):
    """Extracted file information"""
    path: str
    size: int
    type: str
    permissions: Optional[str] = None


def calculate_sha256(file_path: Path) -> str:
    """Calculate SHA256 hash of file"""
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            sha256_hash.update(chunk)
    return sha256_hash.hexdigest()


def get_file_type(file_path: Path) -> str:
    """Get file type using file command"""
    try:
        result = subprocess.run(
            ["file", "-b", str(file_path)],
            capture_output=True,
            text=True,
            timeout=10
        )
        return result.stdout.strip()[:100]
    except Exception:
        return "unknown"


def count_files(directory: Path) -> int:
    """Count files in directory recursively"""
    count = 0
    for _ in directory.rglob("*"):
        count += 1
    return count


def find_interesting_files(directory: Path) -> List[Dict[str, Any]]:
    """Find security-relevant files in extracted firmware"""
    findings = []
    
    # Patterns to look for
    patterns = {
        "credentials": ["passwd", "shadow", "password", "credentials", ".pem", ".key", ".crt"],
        "config": ["*.conf", "*.cfg", "*.ini", "*.json", "*.yaml", "*.yml"],
        "scripts": ["*.sh", "*.py", "*.pl", "init.d/*", "rc.d/*"],
        "binaries": ["busybox", "dropbear", "telnetd", "sshd"],
        "web": ["*.php", "*.cgi", "*.html", "htdocs/*", "www/*"],
        "database": ["*.db", "*.sqlite", "*.sql"],
    }
    
    for category, pattern_list in patterns.items():
        for pattern in pattern_list:
            if "*" in pattern:
                # Glob pattern
                for match in directory.rglob(pattern):
                    if match.is_file():
                        findings.append({
                            "category": category,
                            "path": str(match.relative_to(directory)),
                            "size": match.stat().st_size,
                            "type": get_file_type(match),
                        })
            else:
                # Exact name
                for match in directory.rglob(f"*{pattern}*"):
                    if match.is_file():
                        findings.append({
                            "category": category,
                            "path": str(match.relative_to(directory)),
                            "size": match.stat().st_size,
                            "type": get_file_type(match),
                        })
    
    return findings[:100]  # Limit to 100 findings


async def run_extraction(analysis_id: str, file_path: Path, extract_path: Path):
    """Run firmware extraction in background"""
    try:
        analyses[analysis_id]["status"] = "extracting"
        
        # Try unblob first (preferred)
        try:
            result = subprocess.run(
                ["unblob", "-e", str(extract_path), str(file_path)],
                capture_output=True,
                text=True,
                timeout=600  # 10 minute timeout
            )
            if result.returncode != 0:
                raise Exception(f"Unblob failed: {result.stderr}")
            extractor = "unblob"
        except FileNotFoundError:
            # Fall back to binwalk
            result = subprocess.run(
                ["binwalk", "-e", "-C", str(extract_path), str(file_path)],
                capture_output=True,
                text=True,
                timeout=600
            )
            extractor = "binwalk"
        
        analyses[analysis_id]["status"] = "analyzing"
        analyses[analysis_id]["extraction_path"] = str(extract_path)
        analyses[analysis_id]["file_count"] = count_files(extract_path)
        
        # Find interesting files
        findings = find_interesting_files(extract_path)
        analyses[analysis_id]["findings"] = findings
        
        analyses[analysis_id]["status"] = "completed"
        analyses[analysis_id]["completed_at"] = datetime.utcnow().isoformat()
        analyses[analysis_id]["extractor"] = extractor
        
    except Exception as e:
        logger.error(f"Extraction {analysis_id} failed: {e}")
        analyses[analysis_id]["status"] = "failed"
        analyses[analysis_id]["error"] = str(e)


@app.get("/")
async def root():
    """API root"""
    return {
        "service": "Firmware Analyzer API",
        "description": "Universal firmware extraction and security analysis",
        "version": "1.0.0",
        "endpoints": {
            "POST /upload": "Upload firmware for analysis",
            "GET /analysis/{id}": "Get analysis status and results",
            "GET /analyses": "List all analyses",
            "GET /analysis/{id}/files": "List extracted files",
            "GET /health": "Health check",
        }
    }


@app.get("/health")
async def health():
    """Health check"""
    # Check available tools
    tools = {}
    for tool in ["unblob", "binwalk", "file"]:
        try:
            result = subprocess.run(
                [tool, "--version"],
                capture_output=True,
                text=True,
                timeout=5
            )
            tools[tool] = "available" if result.returncode == 0 else "error"
        except FileNotFoundError:
            tools[tool] = "not installed"
        except Exception:
            tools[tool] = "error"
    
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "tools": tools,
        "active_analyses": len([a for a in analyses.values() if a["status"] in ["extracting", "analyzing"]]),
        "completed_analyses": len([a for a in analyses.values() if a["status"] == "completed"]),
    }


@app.post("/upload", response_model=AnalysisResult)
async def upload_firmware(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(..., description="Firmware file to analyze")
):
    """Upload firmware for extraction and analysis"""
    analysis_id = str(uuid.uuid4())[:8]
    
    # Save uploaded file
    file_path = UPLOAD_DIR / f"{analysis_id}_{file.filename}"
    extract_path = EXTRACT_DIR / analysis_id
    extract_path.mkdir(parents=True, exist_ok=True)
    
    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)
    
    # Calculate hash
    sha256 = calculate_sha256(file_path)
    
    analyses[analysis_id] = {
        "analysis_id": analysis_id,
        "status": "queued",
        "filename": file.filename,
        "file_size": file_path.stat().st_size,
        "sha256": sha256,
        "started_at": datetime.utcnow().isoformat(),
        "completed_at": None,
        "extraction_path": None,
        "file_count": 0,
        "findings": [],
        "error": None,
    }
    
    # Start extraction in background
    background_tasks.add_task(run_extraction, analysis_id, file_path, extract_path)
    
    return AnalysisResult(**analyses[analysis_id])


@app.get("/analysis/{analysis_id}", response_model=AnalysisResult)
async def get_analysis(analysis_id: str):
    """Get analysis status and results"""
    if analysis_id not in analyses:
        raise HTTPException(status_code=404, detail="Analysis not found")
    return AnalysisResult(**analyses[analysis_id])


@app.get("/analyses")
async def list_analyses():
    """List all analyses"""
    return {
        "analyses": [AnalysisResult(**a) for a in analyses.values()],
        "total": len(analyses)
    }


@app.get("/analysis/{analysis_id}/files")
async def list_extracted_files(analysis_id: str, limit: int = 100, offset: int = 0):
    """List extracted files from analysis"""
    if analysis_id not in analyses:
        raise HTTPException(status_code=404, detail="Analysis not found")
    
    analysis = analyses[analysis_id]
    if not analysis.get("extraction_path"):
        raise HTTPException(status_code=400, detail="Extraction not complete")
    
    extract_path = Path(analysis["extraction_path"])
    if not extract_path.exists():
        raise HTTPException(status_code=404, detail="Extraction directory not found")
    
    files = []
    for i, path in enumerate(extract_path.rglob("*")):
        if i < offset:
            continue
        if len(files) >= limit:
            break
        if path.is_file():
            files.append({
                "path": str(path.relative_to(extract_path)),
                "size": path.stat().st_size,
                "type": get_file_type(path),
            })
    
    return {
        "analysis_id": analysis_id,
        "files": files,
        "total": analysis["file_count"],
        "offset": offset,
        "limit": limit,
    }


@app.get("/analysis/{analysis_id}/file/{file_path:path}")
async def download_extracted_file(analysis_id: str, file_path: str):
    """Download a specific extracted file"""
    if analysis_id not in analyses:
        raise HTTPException(status_code=404, detail="Analysis not found")
    
    analysis = analyses[analysis_id]
    if not analysis.get("extraction_path"):
        raise HTTPException(status_code=400, detail="Extraction not complete")
    
    extract_path = Path(analysis["extraction_path"])
    target_file = extract_path / file_path
    
    # Security check - prevent path traversal
    if not target_file.resolve().is_relative_to(extract_path.resolve()):
        raise HTTPException(status_code=403, detail="Access denied")
    
    if not target_file.exists():
        raise HTTPException(status_code=404, detail="File not found")
    
    return FileResponse(target_file, filename=target_file.name)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5602)
