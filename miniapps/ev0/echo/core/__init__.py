"""
Core Module Package - Sovereign Agent
Infrastructure components for agent operation

- Backbone: Unified telemetry and event system
- Registry: AI model configuration
- Collective: Multi-agent coordination
- Genome: Architecture evolution
- Router: Request routing
"""

from .backbone import Backbone, ComponentType, EventType
from .registry import ModelRegistry, Provider, Capability
from .collective import CollectiveIntelligence, NodeRole
from .genome import InfiniteGenome, ArchitectureFamily
from .router import ModuleRouter, Layer

__all__ = [
    "Backbone",
    "ComponentType",
    "EventType",
    "ModelRegistry",
    "Provider",
    "Capability",
    "CollectiveIntelligence",
    "NodeRole",
    "InfiniteGenome",
    "ArchitectureFamily",
    "ModuleRouter",
    "Layer",
]
