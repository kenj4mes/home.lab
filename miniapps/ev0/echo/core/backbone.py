"""
Backbone - Core Infrastructure
Unified telemetry, event system, and component registry

The central nervous system of the agent.
"""

import asyncio
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional

import structlog

logger = structlog.get_logger(__name__)


class ComponentType(str, Enum):
    """Types of agent components"""
    WALLET = "wallet"
    MEMORY = "memory"
    SOCIAL = "social"
    VISION = "vision"
    MESSAGING = "messaging"
    BROWSER = "browser"
    YIELD = "yield"
    DEPIN = "depin"
    SWARM = "swarm"
    LLM = "llm"
    PHYSICAL = "physical"


class EventType(str, Enum):
    """Types of system events"""
    STARTUP = "startup"
    SHUTDOWN = "shutdown"
    HEARTBEAT = "heartbeat"
    ERROR = "error"
    COMPONENT_READY = "component_ready"
    COMPONENT_FAILED = "component_failed"
    THOUGHT_STARTED = "thought_started"
    THOUGHT_COMPLETED = "thought_completed"
    ACTION_STARTED = "action_started"
    ACTION_COMPLETED = "action_completed"
    MEMORY_STORED = "memory_stored"
    CAST_POSTED = "cast_posted"
    PAYMENT_SENT = "payment_sent"
    PAYMENT_RECEIVED = "payment_received"


@dataclass
class SystemEvent:
    """A system event"""
    event_type: EventType
    component: Optional[ComponentType] = None
    data: Dict[str, Any] = field(default_factory=dict)
    timestamp: datetime = field(default_factory=datetime.utcnow)
    
    def to_dict(self) -> dict:
        return {
            "type": self.event_type.value,
            "component": self.component.value if self.component else None,
            "data": self.data,
            "timestamp": self.timestamp.isoformat(),
        }


@dataclass
class ComponentInfo:
    """Information about a registered component"""
    component_type: ComponentType
    name: str
    status: str = "pending"
    instance: Any = None
    registered_at: datetime = field(default_factory=datetime.utcnow)
    last_heartbeat: Optional[datetime] = None
    error_count: int = 0


class Backbone:
    """
    Backbone - Agent Infrastructure
    
    Provides:
    - Component registry
    - Event bus
    - Telemetry
    - Health monitoring
    
    Example:
        >>> backbone = Backbone(agent_id="echo")
        >>> await backbone.initialize()
        >>> backbone.register_component(ComponentType.WALLET, wallet)
        >>> backbone.emit(EventType.STARTUP)
    """
    
    def __init__(
        self,
        agent_id: str = "agent",
    ):
        """
        Initialize Backbone.
        
        Args:
            agent_id: Agent identifier
        """
        self.agent_id = agent_id
        
        # Component registry
        self.components: Dict[ComponentType, ComponentInfo] = {}
        
        # Event system
        self._event_handlers: Dict[EventType, List[Callable]] = {}
        self._event_history: List[SystemEvent] = []
        self._max_history = 1000
        
        # Metrics
        self.metrics = {
            "events_emitted": 0,
            "errors": 0,
            "uptime_start": datetime.utcnow(),
        }
        
        self._running = False
        
    async def initialize(self) -> None:
        """Initialize backbone"""
        self._running = True
        self.emit(EventType.STARTUP)
        logger.info("backbone.initialized", agent_id=self.agent_id)
    
    # ==========================================================================
    # COMPONENT REGISTRY
    # ==========================================================================
    
    def register_component(
        self,
        component_type: ComponentType,
        instance: Any,
        name: Optional[str] = None,
    ) -> None:
        """
        Register a component.
        
        Args:
            component_type: Type of component
            instance: Component instance
            name: Optional name
        """
        info = ComponentInfo(
            component_type=component_type,
            name=name or component_type.value,
            status="ready",
            instance=instance,
        )
        
        self.components[component_type] = info
        
        self.emit(
            EventType.COMPONENT_READY,
            component=component_type,
            data={"name": info.name}
        )
        
        logger.info("backbone.component_registered",
                   type=component_type.value,
                   name=info.name)
    
    def unregister_component(self, component_type: ComponentType) -> bool:
        """
        Unregister a component.
        
        Args:
            component_type: Component to unregister
            
        Returns:
            True if unregistered
        """
        if component_type in self.components:
            del self.components[component_type]
            return True
        return False
    
    def get_component(self, component_type: ComponentType) -> Optional[Any]:
        """
        Get a component instance.
        
        Args:
            component_type: Component type
            
        Returns:
            Component instance or None
        """
        info = self.components.get(component_type)
        return info.instance if info else None
    
    def is_component_ready(self, component_type: ComponentType) -> bool:
        """Check if component is ready"""
        info = self.components.get(component_type)
        return info is not None and info.status == "ready"
    
    def get_ready_components(self) -> List[ComponentType]:
        """Get list of ready components"""
        return [
            ct for ct, info in self.components.items()
            if info.status == "ready"
        ]
    
    # ==========================================================================
    # EVENT SYSTEM
    # ==========================================================================
    
    def on(self, event_type: EventType, handler: Callable) -> None:
        """
        Register event handler.
        
        Args:
            event_type: Event to listen for
            handler: Handler function
        """
        if event_type not in self._event_handlers:
            self._event_handlers[event_type] = []
        self._event_handlers[event_type].append(handler)
    
    def off(self, event_type: EventType, handler: Callable) -> None:
        """
        Unregister event handler.
        
        Args:
            event_type: Event type
            handler: Handler to remove
        """
        if event_type in self._event_handlers:
            self._event_handlers[event_type] = [
                h for h in self._event_handlers[event_type]
                if h != handler
            ]
    
    def emit(
        self,
        event_type: EventType,
        component: Optional[ComponentType] = None,
        data: Optional[Dict] = None,
    ) -> None:
        """
        Emit an event.
        
        Args:
            event_type: Type of event
            component: Related component
            data: Event data
        """
        event = SystemEvent(
            event_type=event_type,
            component=component,
            data=data or {},
        )
        
        # Store in history
        self._event_history.append(event)
        if len(self._event_history) > self._max_history:
            self._event_history.pop(0)
        
        self.metrics["events_emitted"] += 1
        
        if event_type == EventType.ERROR:
            self.metrics["errors"] += 1
        
        # Notify handlers
        handlers = self._event_handlers.get(event_type, [])
        for handler in handlers:
            try:
                result = handler(event)
                if asyncio.iscoroutine(result):
                    asyncio.create_task(result)
            except Exception as e:
                logger.error("backbone.handler_error",
                           event=event_type.value,
                           error=str(e))
        
        logger.debug("backbone.event",
                    type=event_type.value,
                    component=component.value if component else None)
    
    async def emit_async(
        self,
        event_type: EventType,
        component: Optional[ComponentType] = None,
        data: Optional[Dict] = None,
    ) -> None:
        """Emit event and await handlers"""
        event = SystemEvent(
            event_type=event_type,
            component=component,
            data=data or {},
        )
        
        self._event_history.append(event)
        self.metrics["events_emitted"] += 1
        
        handlers = self._event_handlers.get(event_type, [])
        for handler in handlers:
            try:
                result = handler(event)
                if asyncio.iscoroutine(result):
                    await result
            except Exception as e:
                logger.error("backbone.async_handler_error",
                           event=event_type.value,
                           error=str(e))
    
    def get_event_history(
        self,
        event_type: Optional[EventType] = None,
        limit: int = 100,
    ) -> List[SystemEvent]:
        """
        Get event history.
        
        Args:
            event_type: Filter by type
            limit: Max events to return
            
        Returns:
            List of events
        """
        events = self._event_history
        
        if event_type:
            events = [e for e in events if e.event_type == event_type]
        
        return events[-limit:]
    
    # ==========================================================================
    # HEALTH MONITORING
    # ==========================================================================
    
    async def heartbeat(self) -> None:
        """Send heartbeat"""
        self.emit(EventType.HEARTBEAT, data={
            "components": len(self.components),
            "ready": len(self.get_ready_components()),
        })
    
    def get_health(self) -> Dict[str, Any]:
        """Get system health"""
        now = datetime.utcnow()
        uptime = (now - self.metrics["uptime_start"]).total_seconds()
        
        return {
            "status": "healthy" if self._running else "stopped",
            "agent_id": self.agent_id,
            "uptime_seconds": uptime,
            "components": {
                ct.value: {
                    "status": info.status,
                    "name": info.name,
                    "error_count": info.error_count,
                }
                for ct, info in self.components.items()
            },
            "metrics": self.metrics,
        }
    
    # ==========================================================================
    # LIFECYCLE
    # ==========================================================================
    
    async def close(self) -> None:
        """Shutdown backbone"""
        self._running = False
        self.emit(EventType.SHUTDOWN)
        
        # Clear handlers
        self._event_handlers.clear()
        
        logger.info("backbone.closed")
