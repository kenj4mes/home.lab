#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════
💾 home.lab - Backup Manager
Centralized backup orchestration and management
═══════════════════════════════════════════════════════════════
"""

import asyncio
import hashlib
import json
import os
import shutil
import subprocess
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import BackgroundTasks, FastAPI, HTTPException
from pydantic import BaseModel

# ───────────────────────────────────────────────────────────────
# Configuration
# ───────────────────────────────────────────────────────────────
app = FastAPI(title="Backup Manager", version="1.0.0")

BACKUP_DIR = Path(os.getenv("BACKUP_DIR", "/var/backups/homelab"))
RETENTION_DAYS = int(os.getenv("BACKUP_RETENTION_DAYS", "30"))
MAX_BACKUPS = int(os.getenv("MAX_BACKUPS", "10"))

class BackupConfig(BaseModel):
    """Backup configuration"""
    name: str
    source: str
    type: str = "directory"  # directory, database, docker
    compression: str = "gzip"  # gzip, zstd, none
    encryption: bool = False

class BackupResult(BaseModel):
    """Backup result"""
    id: str
    name: str
    status: str
    size_mb: float
    duration_seconds: float
    checksum: str
    timestamp: str

# In-memory backup history
backup_history: List[Dict[str, Any]] = []

# ───────────────────────────────────────────────────────────────
# Lifecycle
# ───────────────────────────────────────────────────────────────
@app.on_event("startup")
async def startup():
    """Initialize backup manager"""
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    load_backup_history()

@app.get("/health")
async def health():
    """Health check"""
    free_space = shutil.disk_usage(BACKUP_DIR).free / (1024**3)
    return {
        "status": "healthy",
        "service": "backup-manager",
        "backup_dir": str(BACKUP_DIR),
        "free_space_gb": round(free_space, 2),
        "total_backups": len(backup_history),
        "timestamp": datetime.utcnow().isoformat()
    }

def load_backup_history():
    """Load backup history from disk"""
    global backup_history
    history_file = BACKUP_DIR / "history.json"
    if history_file.exists():
        with open(history_file) as f:
            backup_history = json.load(f)

def save_backup_history():
    """Save backup history to disk"""
    history_file = BACKUP_DIR / "history.json"
    with open(history_file, "w") as f:
        json.dump(backup_history, f, indent=2)

# ───────────────────────────────────────────────────────────────
# Backup Operations
# ───────────────────────────────────────────────────────────────
@app.post("/backup")
async def create_backup(config: BackupConfig, background_tasks: BackgroundTasks):
    """Create a new backup"""
    backup_id = f"backup_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}_{config.name}"
    
    background_tasks.add_task(run_backup, backup_id, config)
    
    return {
        "backup_id": backup_id,
        "status": "started",
        "message": "Backup started in background"
    }

@app.post("/backup/sync")
async def create_backup_sync(config: BackupConfig):
    """Create a backup synchronously"""
    backup_id = f"backup_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}_{config.name}"
    result = await run_backup(backup_id, config)
    return result

async def run_backup(backup_id: str, config: BackupConfig) -> Dict:
    """Execute backup operation"""
    start_time = datetime.utcnow()
    backup_path = BACKUP_DIR / backup_id
    
    try:
        if config.type == "directory":
            result = await backup_directory(backup_path, config)
        elif config.type == "database":
            result = await backup_database(backup_path, config)
        elif config.type == "docker":
            result = await backup_docker_volumes(backup_path, config)
        else:
            raise ValueError(f"Unknown backup type: {config.type}")
        
        # Calculate size and checksum
        size_bytes = backup_path.stat().st_size if backup_path.exists() else 0
        checksum = calculate_checksum(backup_path) if backup_path.exists() else ""
        
        duration = (datetime.utcnow() - start_time).total_seconds()
        
        # Record backup
        backup_record = {
            "id": backup_id,
            "name": config.name,
            "type": config.type,
            "status": "completed",
            "path": str(backup_path),
            "size_mb": round(size_bytes / (1024**2), 2),
            "duration_seconds": round(duration, 2),
            "checksum": checksum,
            "timestamp": start_time.isoformat()
        }
        
        backup_history.append(backup_record)
        save_backup_history()
        
        # Cleanup old backups
        await cleanup_old_backups(config.name)
        
        return backup_record
        
    except Exception as e:
        backup_record = {
            "id": backup_id,
            "name": config.name,
            "type": config.type,
            "status": "failed",
            "error": str(e),
            "timestamp": start_time.isoformat()
        }
        backup_history.append(backup_record)
        save_backup_history()
        return backup_record

async def backup_directory(backup_path: Path, config: BackupConfig) -> Dict:
    """Backup a directory"""
    source = Path(config.source)
    if not source.exists():
        raise FileNotFoundError(f"Source not found: {source}")
    
    if config.compression == "gzip":
        archive_path = backup_path.with_suffix(".tar.gz")
        cmd = f"tar -czf {archive_path} -C {source.parent} {source.name}"
    elif config.compression == "zstd":
        archive_path = backup_path.with_suffix(".tar.zst")
        cmd = f"tar -I zstd -cf {archive_path} -C {source.parent} {source.name}"
    else:
        archive_path = backup_path.with_suffix(".tar")
        cmd = f"tar -cf {archive_path} -C {source.parent} {source.name}"
    
    result = subprocess.run(cmd, shell=True, capture_output=True)
    if result.returncode != 0:
        raise RuntimeError(f"Backup failed: {result.stderr.decode()}")
    
    return {"path": str(archive_path)}

async def backup_database(backup_path: Path, config: BackupConfig) -> Dict:
    """Backup a database"""
    # Parse source as database connection info
    # Format: type://host:port/database
    source = config.source
    
    if source.startswith("postgres://"):
        # PostgreSQL backup
        dump_path = backup_path.with_suffix(".sql.gz")
        cmd = f"pg_dump {source} | gzip > {dump_path}"
    elif source.startswith("mysql://"):
        # MySQL backup
        dump_path = backup_path.with_suffix(".sql.gz")
        cmd = f"mysqldump --single-transaction {source} | gzip > {dump_path}"
    else:
        raise ValueError(f"Unsupported database type: {source}")
    
    result = subprocess.run(cmd, shell=True, capture_output=True)
    if result.returncode != 0:
        raise RuntimeError(f"Database backup failed: {result.stderr.decode()}")
    
    return {"path": str(dump_path)}

async def backup_docker_volumes(backup_path: Path, config: BackupConfig) -> Dict:
    """Backup Docker volumes"""
    volume_name = config.source
    archive_path = backup_path.with_suffix(".tar.gz")
    
    cmd = f"docker run --rm -v {volume_name}:/data -v {BACKUP_DIR}:/backup alpine tar -czf /backup/{backup_path.name}.tar.gz -C /data ."
    
    result = subprocess.run(cmd, shell=True, capture_output=True)
    if result.returncode != 0:
        raise RuntimeError(f"Volume backup failed: {result.stderr.decode()}")
    
    return {"path": str(archive_path)}

def calculate_checksum(path: Path) -> str:
    """Calculate SHA-256 checksum"""
    sha256 = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            sha256.update(chunk)
    return sha256.hexdigest()

# ───────────────────────────────────────────────────────────────
# Restore Operations
# ───────────────────────────────────────────────────────────────
@app.post("/restore/{backup_id}")
async def restore_backup(backup_id: str, target: Optional[str] = None):
    """Restore a backup"""
    # Find backup in history
    backup = next((b for b in backup_history if b["id"] == backup_id), None)
    if not backup:
        raise HTTPException(status_code=404, detail="Backup not found")
    
    backup_path = Path(backup["path"])
    if not backup_path.exists():
        raise HTTPException(status_code=404, detail="Backup file not found")
    
    # Verify checksum
    current_checksum = calculate_checksum(backup_path)
    if current_checksum != backup.get("checksum"):
        raise HTTPException(status_code=400, detail="Backup checksum mismatch")
    
    # Determine target
    restore_target = Path(target) if target else Path(backup_path.stem)
    
    # Restore based on type
    if backup_path.suffix in [".gz", ".tar.gz"]:
        cmd = f"tar -xzf {backup_path} -C {restore_target}"
    elif backup_path.suffix == ".zst":
        cmd = f"tar -I zstd -xf {backup_path} -C {restore_target}"
    else:
        cmd = f"tar -xf {backup_path} -C {restore_target}"
    
    restore_target.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(cmd, shell=True, capture_output=True)
    
    if result.returncode != 0:
        raise HTTPException(status_code=500, detail=f"Restore failed: {result.stderr.decode()}")
    
    return {
        "status": "restored",
        "backup_id": backup_id,
        "target": str(restore_target)
    }

# ───────────────────────────────────────────────────────────────
# Backup History
# ───────────────────────────────────────────────────────────────
@app.get("/backups")
async def list_backups(name: Optional[str] = None, limit: int = 50):
    """List all backups"""
    backups = backup_history
    
    if name:
        backups = [b for b in backups if b["name"] == name]
    
    return {
        "backups": sorted(backups, key=lambda x: x["timestamp"], reverse=True)[:limit],
        "total": len(backups)
    }

@app.get("/backups/{backup_id}")
async def get_backup(backup_id: str):
    """Get backup details"""
    backup = next((b for b in backup_history if b["id"] == backup_id), None)
    if not backup:
        raise HTTPException(status_code=404, detail="Backup not found")
    return backup

@app.delete("/backups/{backup_id}")
async def delete_backup(backup_id: str):
    """Delete a backup"""
    global backup_history
    
    backup = next((b for b in backup_history if b["id"] == backup_id), None)
    if not backup:
        raise HTTPException(status_code=404, detail="Backup not found")
    
    # Delete file
    backup_path = Path(backup["path"])
    if backup_path.exists():
        backup_path.unlink()
    
    # Remove from history
    backup_history = [b for b in backup_history if b["id"] != backup_id]
    save_backup_history()
    
    return {"status": "deleted", "backup_id": backup_id}

# ───────────────────────────────────────────────────────────────
# Cleanup
# ───────────────────────────────────────────────────────────────
async def cleanup_old_backups(name: str):
    """Remove old backups beyond retention period"""
    global backup_history
    
    cutoff = datetime.utcnow() - timedelta(days=RETENTION_DAYS)
    
    # Get backups for this name
    name_backups = [b for b in backup_history if b["name"] == name]
    name_backups.sort(key=lambda x: x["timestamp"], reverse=True)
    
    # Keep MAX_BACKUPS most recent, delete rest
    to_delete = name_backups[MAX_BACKUPS:]
    
    # Also delete anything older than retention
    for backup in name_backups[:MAX_BACKUPS]:
        backup_time = datetime.fromisoformat(backup["timestamp"])
        if backup_time < cutoff:
            to_delete.append(backup)
    
    for backup in to_delete:
        backup_path = Path(backup["path"])
        if backup_path.exists():
            backup_path.unlink()
        backup_history = [b for b in backup_history if b["id"] != backup["id"]]
    
    save_backup_history()

@app.get("/stats")
async def get_stats():
    """Get backup statistics"""
    total_size = sum(b.get("size_mb", 0) for b in backup_history)
    completed = len([b for b in backup_history if b.get("status") == "completed"])
    failed = len([b for b in backup_history if b.get("status") == "failed"])
    
    free_space = shutil.disk_usage(BACKUP_DIR).free / (1024**3)
    
    return {
        "total_backups": len(backup_history),
        "completed": completed,
        "failed": failed,
        "total_size_mb": round(total_size, 2),
        "free_space_gb": round(free_space, 2),
        "retention_days": RETENTION_DAYS,
        "max_per_name": MAX_BACKUPS
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5501)
