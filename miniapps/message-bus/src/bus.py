"""
═══════════════════════════════════════════════════════════════
🏠 home.lab - Message Bus
Async inter-service messaging with priority queuing
═══════════════════════════════════════════════════════════════
"""

import os
import asyncio
import json
import hashlib
from datetime import datetime, timezone
from typing import Optional, Dict, List, Callable, Any
from contextlib import asynccontextmanager
from enum import IntEnum

import redis.asyncio as redis
from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
import structlog
import uvicorn

# ───────────────────────────────────────────────────────────────
# Configuration
# ───────────────────────────────────────────────────────────────
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/1")
BUS_HOST = os.getenv("BUS_HOST", "0.0.0.0")
BUS_PORT = int(os.getenv("BUS_PORT", "5100"))
MAX_HISTORY = int(os.getenv("MAX_HISTORY", "1000"))
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
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
# Message Models
# ───────────────────────────────────────────────────────────────
class Priority(IntEnum):
    """Message priority levels (1-10)"""
    BACKGROUND = 1
    LOW = 3
    NORMAL = 5
    HIGH = 8
    CRITICAL = 10


class MessageType(str):
    REQUEST = "request"
    RESPONSE = "response"
    EVENT = "event"
    ERROR = "error"
    BROADCAST = "broadcast"


class Message(BaseModel):
    """Message structure for inter-service communication"""
    id: str = Field(default_factory=lambda: hashlib.sha256(
        f"{datetime.now(timezone.utc).isoformat()}{os.urandom(8).hex()}".encode()
    ).hexdigest()[:16])
    
    source: str = Field(..., description="Source service/module ID")
    target: str = Field(default="*", description="Target service ID or * for broadcast")
    
    type: str = Field(default=MessageType.EVENT, description="Message type")
    action: str = Field(..., description="Action to perform")
    
    payload: Dict[str, Any] = Field(default_factory=dict, description="Message data")
    context: Optional[Dict[str, Any]] = Field(default=None, description="Optional context")
    
    priority: int = Field(default=Priority.NORMAL, ge=1, le=10)
    ttl: int = Field(default=300, description="Time-to-live in seconds")
    
    timestamp: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
    
    correlation_id: Optional[str] = Field(
        default=None, description="ID to correlate request/response"
    )


class Subscription(BaseModel):
    """Subscription to messages"""
    subscriber_id: str
    topics: List[str] = Field(default_factory=lambda: ["*"])
    filters: Optional[Dict[str, Any]] = None
    callback_url: Optional[str] = None


class BusStats(BaseModel):
    """Message bus statistics"""
    total_messages: int = 0
    messages_per_minute: float = 0.0
    active_subscribers: int = 0
    queue_depth: Dict[str, int] = Field(default_factory=dict)
    uptime_seconds: float = 0.0


# ───────────────────────────────────────────────────────────────
# Message Bus Core
# ───────────────────────────────────────────────────────────────
class MessageBus:
    """Core message bus implementation"""
    
    def __init__(self):
        self.redis: Optional[redis.Redis] = None
        self.subscribers: Dict[str, Subscription] = {}
        self.callbacks: Dict[str, Callable] = {}
        self.start_time = datetime.now(timezone.utc)
        self.message_count = 0
        
    async def connect(self):
        """Connect to Redis"""
        self.redis = redis.from_url(REDIS_URL, decode_responses=True)
        await self.redis.ping()
        logger.info("Connected to Redis", url=REDIS_URL)
        
    async def disconnect(self):
        """Disconnect from Redis"""
        if self.redis:
            await self.redis.close()
            logger.info("Disconnected from Redis")
            
    async def publish(self, message: Message) -> str:
        """Publish a message to the bus"""
        
        # Validate TTL
        if message.ttl <= 0:
            raise ValueError("Message TTL must be positive")
            
        # Determine channel(s)
        if message.target == "*":
            channel = "homelab:broadcast"
        else:
            channel = f"homelab:service:{message.target}"
            
        # Serialize message
        msg_data = message.model_dump_json()
        
        # Publish to Redis
        await self.redis.publish(channel, msg_data)
        
        # Store in history (sorted by timestamp)
        await self.redis.zadd(
            "homelab:messages:history",
            {msg_data: datetime.now(timezone.utc).timestamp()}
        )
        
        # Trim history to max size
        await self.redis.zremrangebyrank(
            "homelab:messages:history", 
            0, 
            -MAX_HISTORY - 1
        )
        
        # Store in priority queue
        priority_key = f"homelab:queue:priority:{message.priority}"
        await self.redis.lpush(priority_key, msg_data)
        await self.redis.expire(priority_key, message.ttl)
        
        self.message_count += 1
        
        logger.info(
            "Message published",
            message_id=message.id,
            source=message.source,
            target=message.target,
            action=message.action,
            priority=message.priority
        )
        
        return message.id
        
    async def subscribe(self, subscription: Subscription) -> str:
        """Subscribe to messages"""
        
        self.subscribers[subscription.subscriber_id] = subscription
        
        # Store in Redis for persistence
        await self.redis.hset(
            "homelab:subscribers",
            subscription.subscriber_id,
            subscription.model_dump_json()
        )
        
        logger.info(
            "Subscriber registered",
            subscriber_id=subscription.subscriber_id,
            topics=subscription.topics
        )
        
        return subscription.subscriber_id
        
    async def unsubscribe(self, subscriber_id: str) -> bool:
        """Unsubscribe from messages"""
        
        if subscriber_id in self.subscribers:
            del self.subscribers[subscriber_id]
            await self.redis.hdel("homelab:subscribers", subscriber_id)
            logger.info("Subscriber removed", subscriber_id=subscriber_id)
            return True
        return False
        
    async def get_history(
        self, 
        limit: int = 100,
        source: Optional[str] = None,
        target: Optional[str] = None,
        action: Optional[str] = None
    ) -> List[Message]:
        """Get message history with optional filters"""
        
        # Get recent messages from sorted set
        raw_messages = await self.redis.zrevrange(
            "homelab:messages:history",
            0,
            limit * 2  # Fetch extra for filtering
        )
        
        messages = []
        for raw in raw_messages:
            try:
                msg = Message.model_validate_json(raw)
                
                # Apply filters
                if source and msg.source != source:
                    continue
                if target and msg.target != target:
                    continue
                if action and msg.action != action:
                    continue
                    
                messages.append(msg)
                
                if len(messages) >= limit:
                    break
                    
            except Exception as e:
                logger.warning("Failed to parse message", error=str(e))
                
        return messages
        
    async def get_stats(self) -> BusStats:
        """Get message bus statistics"""
        
        uptime = (datetime.now(timezone.utc) - self.start_time).total_seconds()
        
        # Get queue depths
        queue_depth = {}
        for priority in Priority:
            key = f"homelab:queue:priority:{priority.value}"
            depth = await self.redis.llen(key)
            queue_depth[priority.name] = depth
            
        return BusStats(
            total_messages=self.message_count,
            messages_per_minute=self.message_count / (uptime / 60) if uptime > 0 else 0,
            active_subscribers=len(self.subscribers),
            queue_depth=queue_depth,
            uptime_seconds=uptime
        )
        
    async def process_queue(self, priority: int) -> Optional[Message]:
        """Pop and return next message from priority queue"""
        
        key = f"homelab:queue:priority:{priority}"
        raw = await self.redis.rpop(key)
        
        if raw:
            return Message.model_validate_json(raw)
        return None


# ───────────────────────────────────────────────────────────────
# FastAPI Application
# ───────────────────────────────────────────────────────────────
bus = MessageBus()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    await bus.connect()
    yield
    await bus.disconnect()


app = FastAPI(
    title="home.lab Message Bus",
    description="Async inter-service messaging with priority queuing",
    version="1.0.0",
    lifespan=lifespan
)


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        await bus.redis.ping()
        return {"status": "healthy", "redis": "connected"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))


@app.get("/stats", response_model=BusStats)
async def get_stats():
    """Get message bus statistics"""
    return await bus.get_stats()


@app.post("/messages", response_model=dict)
async def publish_message(message: Message):
    """Publish a message to the bus"""
    message_id = await bus.publish(message)
    return {"message_id": message_id, "status": "published"}


@app.get("/messages", response_model=List[Message])
async def get_messages(
    limit: int = 100,
    source: Optional[str] = None,
    target: Optional[str] = None,
    action: Optional[str] = None
):
    """Get message history"""
    return await bus.get_history(limit, source, target, action)


@app.post("/subscribe", response_model=dict)
async def subscribe(subscription: Subscription):
    """Subscribe to messages"""
    subscriber_id = await bus.subscribe(subscription)
    return {"subscriber_id": subscriber_id, "status": "subscribed"}


@app.delete("/subscribe/{subscriber_id}")
async def unsubscribe(subscriber_id: str):
    """Unsubscribe from messages"""
    success = await bus.unsubscribe(subscriber_id)
    if success:
        return {"status": "unsubscribed"}
    raise HTTPException(status_code=404, detail="Subscriber not found")


@app.get("/queue/{priority}", response_model=Optional[Message])
async def pop_from_queue(priority: int):
    """Pop next message from priority queue"""
    if priority < 1 or priority > 10:
        raise HTTPException(status_code=400, detail="Priority must be 1-10")
    return await bus.process_queue(priority)


# ───────────────────────────────────────────────────────────────
# Main Entry Point
# ───────────────────────────────────────────────────────────────
if __name__ == "__main__":
    uvicorn.run(
        "bus:app",
        host=BUS_HOST,
        port=BUS_PORT,
        reload=False,
        log_level=LOG_LEVEL.lower()
    )
