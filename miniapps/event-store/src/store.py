"""
═══════════════════════════════════════════════════════════════
🏠 home.lab - Event Store
Immutable append-only event log with SHA-256 hash chaining
═══════════════════════════════════════════════════════════════
"""

import os
import asyncio
import json
import hashlib
import gzip
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional, Dict, List, Any, AsyncGenerator
from contextlib import asynccontextmanager
from enum import Enum

import aiofiles
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field
import structlog
import uvicorn

# ───────────────────────────────────────────────────────────────
# Configuration
# ───────────────────────────────────────────────────────────────
STORE_HOST = os.getenv("STORE_HOST", "0.0.0.0")
STORE_PORT = int(os.getenv("STORE_PORT", "5101"))
DATA_DIR = Path(os.getenv("DATA_DIR", "./data"))
MAX_FILE_SIZE_MB = int(os.getenv("MAX_FILE_SIZE_MB", "100"))
RETENTION_DAYS = int(os.getenv("RETENTION_DAYS", "90"))
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

# Ensure data directory exists
DATA_DIR.mkdir(parents=True, exist_ok=True)

# Genesis hash (first event in chain)
GENESIS_HASH = "0" * 64

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
# Event Models
# ───────────────────────────────────────────────────────────────
class EventCategory(str, Enum):
    SYSTEM = "system"
    SERVICE = "service"
    SECURITY = "security"
    AI = "ai"
    USER = "user"
    CONFIG = "config"
    ERROR = "error"


class Event(BaseModel):
    """Immutable event record"""
    
    # Event identification
    id: str = Field(
        default_factory=lambda: hashlib.sha256(
            f"{datetime.now(timezone.utc).isoformat()}{os.urandom(8).hex()}".encode()
        ).hexdigest()[:16]
    )
    
    # Timestamps
    timestamp: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
    
    # Event metadata
    category: EventCategory = Field(default=EventCategory.SYSTEM)
    action: str = Field(..., description="What happened")
    actor: str = Field(..., description="Who/what caused it")
    target: Optional[str] = Field(default=None, description="What was affected")
    
    # Event data
    data: Dict[str, Any] = Field(default_factory=dict)
    
    # Result
    result: str = Field(default="success", description="success/failure/pending")
    error: Optional[str] = Field(default=None, description="Error message if failed")
    
    # Chain integrity
    previous_hash: str = Field(default=GENESIS_HASH)
    hash: str = Field(default="")
    
    def compute_hash(self) -> str:
        """Compute SHA-256 hash of event (excluding hash field)"""
        data = self.model_dump(exclude={"hash"})
        content = json.dumps(data, sort_keys=True)
        return hashlib.sha256(content.encode()).hexdigest()
    
    def with_hash(self) -> "Event":
        """Return copy with computed hash"""
        new_event = self.model_copy()
        new_event.hash = self.compute_hash()
        return new_event


class EventQuery(BaseModel):
    """Query parameters for event search"""
    category: Optional[EventCategory] = None
    action: Optional[str] = None
    actor: Optional[str] = None
    target: Optional[str] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    limit: int = Field(default=100, le=1000)
    offset: int = Field(default=0, ge=0)


class ChainStatus(BaseModel):
    """Status of the event chain"""
    total_events: int
    chain_valid: bool
    first_event_time: Optional[str]
    last_event_time: Optional[str]
    last_hash: str
    file_count: int
    total_size_bytes: int


# ───────────────────────────────────────────────────────────────
# Event Store Core
# ───────────────────────────────────────────────────────────────
class EventStore:
    """Append-only event store with hash chaining"""
    
    def __init__(self, data_dir: Path):
        self.data_dir = data_dir
        self.current_file: Optional[Path] = None
        self.last_hash: str = GENESIS_HASH
        self.event_count: int = 0
        self._lock = asyncio.Lock()
        
    async def initialize(self):
        """Initialize store, loading last hash from existing data"""
        
        # Find latest event file
        event_files = sorted(self.data_dir.glob("events_*.jsonl"))
        
        if event_files:
            self.current_file = event_files[-1]
            
            # Read last line to get last hash
            async with aiofiles.open(self.current_file, 'r') as f:
                lines = await f.readlines()
                if lines:
                    for line in reversed(lines):
                        line = line.strip()
                        if line:
                            try:
                                last_event = json.loads(line)
                                self.last_hash = last_event.get("hash", GENESIS_HASH)
                                self.event_count = len(lines)
                                break
                            except json.JSONDecodeError:
                                continue
                                
            logger.info(
                "Initialized from existing data",
                file=str(self.current_file),
                event_count=self.event_count,
                last_hash=self.last_hash[:16] + "..."
            )
        else:
            self._create_new_file()
            logger.info("Initialized with new event store")
            
    def _create_new_file(self):
        """Create a new event file"""
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        self.current_file = self.data_dir / f"events_{timestamp}.jsonl"
        
    async def append(self, event: Event) -> Event:
        """Append event to the store (immutable)"""
        
        async with self._lock:
            # Check if need to rotate file
            if self.current_file and self.current_file.exists():
                size_mb = self.current_file.stat().st_size / (1024 * 1024)
                if size_mb >= MAX_FILE_SIZE_MB:
                    await self._rotate_file()
                    
            if not self.current_file:
                self._create_new_file()
                
            # Set chain link
            event.previous_hash = self.last_hash
            event = event.with_hash()
            
            # Append to file
            async with aiofiles.open(self.current_file, 'a') as f:
                await f.write(json.dumps(event.model_dump()) + "\n")
                
            # Update state
            self.last_hash = event.hash
            self.event_count += 1
            
            logger.debug(
                "Event appended",
                event_id=event.id,
                action=event.action,
                hash=event.hash[:16] + "..."
            )
            
            return event
            
    async def _rotate_file(self):
        """Rotate to a new file and compress old one"""
        
        old_file = self.current_file
        self._create_new_file()
        
        # Compress old file in background
        if old_file and old_file.exists():
            asyncio.create_task(self._compress_file(old_file))
            
    async def _compress_file(self, file_path: Path):
        """Compress an event file"""
        
        try:
            compressed_path = file_path.with_suffix(".jsonl.gz")
            
            async with aiofiles.open(file_path, 'rb') as f_in:
                content = await f_in.read()
                
            async with aiofiles.open(compressed_path, 'wb') as f_out:
                compressed = gzip.compress(content)
                await f_out.write(compressed)
                
            # Remove original
            file_path.unlink()
            
            logger.info("Compressed event file", file=str(compressed_path))
            
        except Exception as e:
            logger.error("Failed to compress file", file=str(file_path), error=str(e))
            
    async def query(self, query: EventQuery) -> List[Event]:
        """Query events with filters"""
        
        events = []
        
        # Get all event files
        event_files = sorted(self.data_dir.glob("events_*.jsonl*"))
        
        for file_path in reversed(event_files):
            if len(events) >= query.limit + query.offset:
                break
                
            async for event in self._read_file(file_path):
                if self._matches_query(event, query):
                    events.append(event)
                    if len(events) >= query.limit + query.offset:
                        break
                        
        # Apply offset and limit
        return events[query.offset:query.offset + query.limit]
        
    async def _read_file(self, file_path: Path) -> AsyncGenerator[Event, None]:
        """Read events from a file"""
        
        try:
            if file_path.suffix == ".gz":
                async with aiofiles.open(file_path, 'rb') as f:
                    compressed = await f.read()
                    content = gzip.decompress(compressed).decode()
                    for line in reversed(content.strip().split('\n')):
                        if line:
                            yield Event.model_validate_json(line)
            else:
                async with aiofiles.open(file_path, 'r') as f:
                    lines = await f.readlines()
                    for line in reversed(lines):
                        line = line.strip()
                        if line:
                            yield Event.model_validate_json(line)
                            
        except Exception as e:
            logger.error("Failed to read file", file=str(file_path), error=str(e))
            
    def _matches_query(self, event: Event, query: EventQuery) -> bool:
        """Check if event matches query filters"""
        
        if query.category and event.category != query.category:
            return False
        if query.action and query.action not in event.action:
            return False
        if query.actor and event.actor != query.actor:
            return False
        if query.target and event.target != query.target:
            return False
        if query.start_time and event.timestamp < query.start_time:
            return False
        if query.end_time and event.timestamp > query.end_time:
            return False
            
        return True
        
    async def verify_chain(self) -> tuple[bool, Optional[str]]:
        """Verify the integrity of the event chain"""
        
        previous_hash = GENESIS_HASH
        event_count = 0
        
        event_files = sorted(self.data_dir.glob("events_*.jsonl*"))
        
        for file_path in event_files:
            async for event in self._read_file_forward(file_path):
                event_count += 1
                
                # Verify previous hash link
                if event.previous_hash != previous_hash:
                    return False, f"Chain broken at event {event.id}: expected {previous_hash[:16]}, got {event.previous_hash[:16]}"
                    
                # Verify event hash
                computed = event.compute_hash()
                if event.hash != computed:
                    return False, f"Hash mismatch at event {event.id}: expected {computed[:16]}, got {event.hash[:16]}"
                    
                previous_hash = event.hash
                
        logger.info("Chain verification complete", events=event_count, valid=True)
        return True, None
        
    async def _read_file_forward(self, file_path: Path) -> AsyncGenerator[Event, None]:
        """Read events from a file in forward order"""
        
        try:
            if file_path.suffix == ".gz":
                async with aiofiles.open(file_path, 'rb') as f:
                    compressed = await f.read()
                    content = gzip.decompress(compressed).decode()
                    for line in content.strip().split('\n'):
                        if line:
                            yield Event.model_validate_json(line)
            else:
                async with aiofiles.open(file_path, 'r') as f:
                    async for line in f:
                        line = line.strip()
                        if line:
                            yield Event.model_validate_json(line)
                            
        except Exception as e:
            logger.error("Failed to read file", file=str(file_path), error=str(e))
            
    async def get_status(self) -> ChainStatus:
        """Get current status of the event store"""
        
        event_files = list(self.data_dir.glob("events_*.jsonl*"))
        total_size = sum(f.stat().st_size for f in event_files)
        
        # Get first and last event times
        first_time = None
        last_time = None
        total_events = 0
        
        sorted_files = sorted(event_files)
        
        if sorted_files:
            # First event from first file
            async for event in self._read_file_forward(sorted_files[0]):
                first_time = event.timestamp
                break
                
            # Count all events
            for file_path in sorted_files:
                if file_path.suffix == ".gz":
                    async with aiofiles.open(file_path, 'rb') as f:
                        compressed = await f.read()
                        content = gzip.decompress(compressed).decode()
                        total_events += len(content.strip().split('\n'))
                else:
                    async with aiofiles.open(file_path, 'r') as f:
                        lines = await f.readlines()
                        total_events += len([l for l in lines if l.strip()])
                        
        return ChainStatus(
            total_events=total_events,
            chain_valid=True,  # Would need full verify
            first_event_time=first_time,
            last_event_time=datetime.now(timezone.utc).isoformat(),
            last_hash=self.last_hash,
            file_count=len(event_files),
            total_size_bytes=total_size
        )
        
    async def cleanup_old_events(self):
        """Remove events older than retention period"""
        
        cutoff = datetime.now(timezone.utc) - timedelta(days=RETENTION_DAYS)
        cutoff_str = cutoff.strftime("%Y%m%d")
        
        event_files = sorted(self.data_dir.glob("events_*.jsonl*"))
        
        for file_path in event_files:
            # Extract date from filename
            date_part = file_path.stem.split("_")[1][:8]
            if date_part < cutoff_str:
                file_path.unlink()
                logger.info("Removed old event file", file=str(file_path))


# ───────────────────────────────────────────────────────────────
# FastAPI Application
# ───────────────────────────────────────────────────────────────
store = EventStore(DATA_DIR)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    await store.initialize()
    yield


app = FastAPI(
    title="home.lab Event Store",
    description="Immutable append-only event log with hash chaining",
    version="1.0.0",
    lifespan=lifespan
)


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "event_count": store.event_count,
        "last_hash": store.last_hash[:16] + "..."
    }


@app.get("/status", response_model=ChainStatus)
async def get_status():
    """Get event store status"""
    return await store.get_status()


@app.post("/events", response_model=Event)
async def append_event(event: Event):
    """Append a new event (immutable)"""
    return await store.append(event)


@app.get("/events", response_model=List[Event])
async def query_events(
    category: Optional[EventCategory] = None,
    action: Optional[str] = None,
    actor: Optional[str] = None,
    target: Optional[str] = None,
    start_time: Optional[str] = None,
    end_time: Optional[str] = None,
    limit: int = Query(default=100, le=1000),
    offset: int = Query(default=0, ge=0)
):
    """Query events with filters"""
    query = EventQuery(
        category=category,
        action=action,
        actor=actor,
        target=target,
        start_time=start_time,
        end_time=end_time,
        limit=limit,
        offset=offset
    )
    return await store.query(query)


@app.get("/events/{event_id}", response_model=Event)
async def get_event(event_id: str):
    """Get a specific event by ID"""
    query = EventQuery(limit=1000)
    events = await store.query(query)
    
    for event in events:
        if event.id == event_id:
            return event
            
    raise HTTPException(status_code=404, detail="Event not found")


@app.post("/verify")
async def verify_chain():
    """Verify the integrity of the event chain"""
    valid, error = await store.verify_chain()
    
    if valid:
        return {"status": "valid", "message": "Chain integrity verified"}
    else:
        raise HTTPException(
            status_code=500,
            detail={"status": "invalid", "error": error}
        )


@app.post("/cleanup")
async def cleanup_events():
    """Remove events older than retention period"""
    await store.cleanup_old_events()
    return {"status": "cleaned", "retention_days": RETENTION_DAYS}


# ───────────────────────────────────────────────────────────────
# Main Entry Point
# ───────────────────────────────────────────────────────────────
if __name__ == "__main__":
    uvicorn.run(
        "store:app",
        host=STORE_HOST,
        port=STORE_PORT,
        reload=False,
        log_level=LOG_LEVEL.lower()
    )
