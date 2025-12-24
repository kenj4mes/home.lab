#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════
📋 home.lab - Log Aggregator
Centralized log collection and search
═══════════════════════════════════════════════════════════════
"""

import asyncio
import gzip
import json
import os
import re
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel

# ───────────────────────────────────────────────────────────────
# Configuration
# ───────────────────────────────────────────────────────────────
app = FastAPI(title="Log Aggregator", version="1.0.0")

LOG_DIR = Path(os.getenv("LOG_DIR", "/var/log/homelab"))
RETENTION_DAYS = int(os.getenv("LOG_RETENTION_DAYS", "30"))
MAX_RESULTS = 1000

class LogEntry(BaseModel):
    """Log entry model"""
    timestamp: str
    level: str
    service: str
    message: str
    metadata: Optional[Dict[str, Any]] = None

class LogQuery(BaseModel):
    """Log query parameters"""
    service: Optional[str] = None
    level: Optional[str] = None
    pattern: Optional[str] = None
    since: Optional[str] = None
    until: Optional[str] = None
    limit: int = 100

# ───────────────────────────────────────────────────────────────
# In-memory log buffer (for recent logs)
# ───────────────────────────────────────────────────────────────
log_buffer: List[LogEntry] = []
BUFFER_SIZE = 10000

# ───────────────────────────────────────────────────────────────
# Lifecycle
# ───────────────────────────────────────────────────────────────
@app.on_event("startup")
async def startup():
    """Initialize log aggregator"""
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    asyncio.create_task(cleanup_old_logs())

@app.get("/health")
async def health():
    """Health check"""
    return {
        "status": "healthy",
        "service": "log-aggregator",
        "buffer_size": len(log_buffer),
        "log_dir": str(LOG_DIR),
        "timestamp": datetime.utcnow().isoformat()
    }

# ───────────────────────────────────────────────────────────────
# Log Ingestion
# ───────────────────────────────────────────────────────────────
@app.post("/ingest")
async def ingest_log(entry: LogEntry):
    """Ingest a single log entry"""
    global log_buffer
    
    # Add to buffer
    log_buffer.append(entry)
    
    # Trim buffer if needed
    if len(log_buffer) > BUFFER_SIZE:
        log_buffer = log_buffer[-BUFFER_SIZE:]
    
    # Write to file
    log_file = LOG_DIR / f"{entry.service}_{datetime.utcnow().strftime('%Y%m%d')}.jsonl"
    with open(log_file, "a") as f:
        f.write(json.dumps(entry.dict()) + "\n")
    
    return {"status": "ingested"}

@app.post("/ingest/batch")
async def ingest_batch(entries: List[LogEntry]):
    """Ingest multiple log entries"""
    for entry in entries:
        await ingest_log(entry)
    return {"status": "ingested", "count": len(entries)}

# ───────────────────────────────────────────────────────────────
# Log Query
# ───────────────────────────────────────────────────────────────
@app.get("/logs")
async def query_logs(
    service: Optional[str] = None,
    level: Optional[str] = None,
    pattern: Optional[str] = None,
    since: Optional[str] = None,
    until: Optional[str] = None,
    limit: int = Query(default=100, le=MAX_RESULTS)
):
    """Query logs with filters"""
    results = []
    
    # Parse time filters
    since_dt = None
    until_dt = None
    if since:
        since_dt = datetime.fromisoformat(since.replace("Z", "+00:00"))
    if until:
        until_dt = datetime.fromisoformat(until.replace("Z", "+00:00"))
    
    # Compile pattern if provided
    regex = None
    if pattern:
        try:
            regex = re.compile(pattern, re.IGNORECASE)
        except re.error:
            raise HTTPException(status_code=400, detail="Invalid regex pattern")
    
    # Search buffer first (most recent)
    for entry in reversed(log_buffer):
        if len(results) >= limit:
            break
            
        if not matches_filters(entry, service, level, regex, since_dt, until_dt):
            continue
            
        results.append(entry.dict())
    
    # If need more, search files
    if len(results) < limit:
        file_results = await search_log_files(
            service, level, regex, since_dt, until_dt,
            limit - len(results)
        )
        results.extend(file_results)
    
    return {
        "logs": results[:limit],
        "total": len(results),
        "has_more": len(results) >= limit
    }

@app.post("/search")
async def search_logs(query: LogQuery):
    """Advanced log search"""
    return await query_logs(
        service=query.service,
        level=query.level,
        pattern=query.pattern,
        since=query.since,
        until=query.until,
        limit=query.limit
    )

def matches_filters(
    entry: LogEntry,
    service: Optional[str],
    level: Optional[str],
    regex: Optional[re.Pattern],
    since: Optional[datetime],
    until: Optional[datetime]
) -> bool:
    """Check if log entry matches filters"""
    if service and entry.service != service:
        return False
    if level and entry.level.lower() != level.lower():
        return False
    if regex and not regex.search(entry.message):
        return False
    
    if since or until:
        try:
            entry_dt = datetime.fromisoformat(entry.timestamp.replace("Z", "+00:00"))
            if since and entry_dt < since:
                return False
            if until and entry_dt > until:
                return False
        except ValueError:
            pass
    
    return True

async def search_log_files(
    service: Optional[str],
    level: Optional[str],
    regex: Optional[re.Pattern],
    since: Optional[datetime],
    until: Optional[datetime],
    limit: int
) -> List[Dict]:
    """Search log files on disk"""
    results = []
    
    # Get relevant log files
    log_files = sorted(LOG_DIR.glob("*.jsonl"), reverse=True)
    
    # Also check compressed files
    log_files.extend(sorted(LOG_DIR.glob("*.jsonl.gz"), reverse=True))
    
    for log_file in log_files:
        if len(results) >= limit:
            break
        
        # Filter by service if specified
        if service and service not in log_file.name:
            continue
        
        # Read file
        try:
            if log_file.suffix == ".gz":
                with gzip.open(log_file, "rt") as f:
                    lines = f.readlines()
            else:
                with open(log_file) as f:
                    lines = f.readlines()
            
            for line in reversed(lines):
                if len(results) >= limit:
                    break
                
                try:
                    entry_data = json.loads(line)
                    entry = LogEntry(**entry_data)
                    
                    if matches_filters(entry, service, level, regex, since, until):
                        results.append(entry_data)
                except (json.JSONDecodeError, ValueError):
                    continue
                    
        except Exception:
            continue
    
    return results

# ───────────────────────────────────────────────────────────────
# Statistics
# ───────────────────────────────────────────────────────────────
@app.get("/stats")
async def get_stats():
    """Get log statistics"""
    # Count by level in buffer
    level_counts = {}
    service_counts = {}
    
    for entry in log_buffer:
        level = entry.level.upper()
        level_counts[level] = level_counts.get(level, 0) + 1
        service_counts[entry.service] = service_counts.get(entry.service, 0) + 1
    
    # Count files
    log_files = list(LOG_DIR.glob("*.jsonl")) + list(LOG_DIR.glob("*.jsonl.gz"))
    total_size = sum(f.stat().st_size for f in log_files)
    
    return {
        "buffer_entries": len(log_buffer),
        "level_distribution": level_counts,
        "service_distribution": service_counts,
        "files_count": len(log_files),
        "total_size_mb": round(total_size / (1024 * 1024), 2),
        "retention_days": RETENTION_DAYS
    }

# ───────────────────────────────────────────────────────────────
# Maintenance
# ───────────────────────────────────────────────────────────────
async def cleanup_old_logs():
    """Periodically clean up old log files"""
    while True:
        try:
            cutoff = datetime.utcnow() - timedelta(days=RETENTION_DAYS)
            
            for log_file in LOG_DIR.glob("*.jsonl*"):
                # Parse date from filename
                try:
                    date_str = log_file.stem.split("_")[-1].replace(".jsonl", "")
                    file_date = datetime.strptime(date_str, "%Y%m%d")
                    
                    if file_date < cutoff:
                        log_file.unlink()
                except (ValueError, IndexError):
                    continue
            
            # Compress old logs (older than 1 day)
            yesterday = datetime.utcnow() - timedelta(days=1)
            for log_file in LOG_DIR.glob("*.jsonl"):
                try:
                    date_str = log_file.stem.split("_")[-1]
                    file_date = datetime.strptime(date_str, "%Y%m%d")
                    
                    if file_date < yesterday:
                        with open(log_file, "rb") as f_in:
                            with gzip.open(f"{log_file}.gz", "wb") as f_out:
                                f_out.writelines(f_in)
                        log_file.unlink()
                except (ValueError, IndexError):
                    continue
                    
        except Exception:
            pass
        
        # Run daily
        await asyncio.sleep(86400)

@app.post("/rotate")
async def rotate_logs():
    """Force log rotation"""
    global log_buffer
    
    # Flush buffer to disk
    for entry in log_buffer:
        log_file = LOG_DIR / f"{entry.service}_{datetime.utcnow().strftime('%Y%m%d')}.jsonl"
        with open(log_file, "a") as f:
            f.write(json.dumps(entry.dict()) + "\n")
    
    log_buffer = []
    
    return {"status": "rotated"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5500)
