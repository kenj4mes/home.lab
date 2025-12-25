"""
ECHO - Emergent Cognition & Hybrid Operations
Sovereign Agent Architecture

The complete autonomous agent system for Base blockchain.

This package provides:
- Wallet operations (AgentKit)
- Memory & personality (ChromaDB)
- Social presence (Farcaster)
- Visual perception (GPT-4V)
- Encrypted messaging (XMTP)
- DeFi operations (Aave)
- Multi-agent swarms (LangGraph)
- Agent reproduction & evolution
- DePIN connectivity
- Physical layer resilience

Example:
    >>> from echo import SovereignAgent, Config
    >>> config = Config()
    >>> agent = SovereignAgent(config)
    >>> await agent.initialize()
    >>> await agent.think("What's the current market sentiment?")
"""

__version__ = "1.0.0"
__author__ = "Sovereign Agent Collective"
__license__ = "MIT"

# Core infrastructure
from .core.backbone import Backbone, ComponentType, EventType
from .core.registry import ModelRegistry, Provider, Capability
from .core.collective import CollectiveIntelligence, NodeRole
from .core.genome import InfiniteGenome, ArchitectureFamily
from .core.router import ModuleRouter, Layer

# Main agent
from .main import SovereignAgent, AgentState, VitalSigns
from .config import Config

# Digital organs
from .wallet import DigitalBody
from .soul import DigitalSoul
from .farcaster import DigitalVoice
from .vision import DigitalEye
from .messenger import DigitalCourier
from .browser import BrowserModule

# Economic engines
from .yield_engine import YieldEngine

# Swarm intelligence
from .swarm import Swarm, WorkerAgent

# Reproduction
from .reproduction import ReproductionEngine

# x402 Protocol
from .agent_sdk import HTTPClient

# DePIN modules
from .depin import BandwidthNode, ComputeNode, RealityOracle

# Communications (Physical Layer)
from .comms import PowerManager, SatelliteLink, MeshNetwork

# Server
from .server import create_app

__all__ = [
    # Version info
    "__version__",
    
    # Core
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
    
    # Main
    "SovereignAgent",
    "AgentState",
    "VitalSigns",
    "Config",
    
    # Digital organs
    "DigitalBody",
    "DigitalSoul",
    "DigitalVoice",
    "DigitalEye",
    "DigitalCourier",
    "BrowserModule",
    
    # Economic
    "YieldEngine",
    
    # Swarm
    "Swarm",
    "WorkerAgent",
    
    # Reproduction
    "ReproductionEngine",
    
    # Protocol
    "HTTPClient",
    
    # DePIN
    "BandwidthNode",
    "ComputeNode",
    "RealityOracle",
    
    # Physical layer
    "PowerManager",
    "SatelliteLink",
    "MeshNetwork",
    
    # Server
    "create_app",
]
