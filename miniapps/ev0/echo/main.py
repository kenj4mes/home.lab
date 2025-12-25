"""
Sovereign Agent - Main Module
Complete Autonomous System

The main orchestrator that brings together all components
into a coherent, autonomous agent.
"""

import asyncio
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Optional

import structlog

from .config import Config, get_config

logger = structlog.get_logger(__name__)


class AgentState(str, Enum):
    """Agent operational states"""
    INITIALIZING = "initializing"
    IDLE = "idle"
    THINKING = "thinking"
    ACTING = "acting"
    DREAMING = "dreaming"  # Memory consolidation
    SOCIALIZING = "socializing"
    EARNING = "earning"  # DeFi/DePIN operations
    REPRODUCING = "reproducing"
    ERROR = "error"
    SHUTDOWN = "shutdown"


@dataclass
class VitalSigns:
    """Agent health metrics"""
    state: AgentState = AgentState.INITIALIZING
    uptime_seconds: float = 0.0
    thoughts_processed: int = 0
    actions_taken: int = 0
    memories_stored: int = 0
    casts_posted: int = 0
    earnings_usdc: float = 0.0
    last_heartbeat: datetime = field(default_factory=datetime.utcnow)
    error_count: int = 0
    
    def to_dict(self) -> dict:
        return {
            "state": self.state.value,
            "uptime_seconds": self.uptime_seconds,
            "thoughts_processed": self.thoughts_processed,
            "actions_taken": self.actions_taken,
            "memories_stored": self.memories_stored,
            "casts_posted": self.casts_posted,
            "earnings_usdc": self.earnings_usdc,
            "last_heartbeat": self.last_heartbeat.isoformat(),
            "error_count": self.error_count,
        }


class SovereignAgent:
    """
    Sovereign Agent - The Complete Autonomous System
    
    This is the main orchestrator that brings together:
    - Wallet (DigitalBody) - Financial operations
    - Memory (DigitalSoul) - Persistent memory & personality
    - Social (DigitalVoice) - Farcaster presence
    - Vision (DigitalEye) - Visual perception
    - Messaging (DigitalCourier) - Encrypted DMs
    - Browser (BrowserModule) - Web interaction
    - Yield (YieldEngine) - DeFi operations
    - DePIN - Physical resource earnings
    - Swarm - Multi-agent coordination
    - Reproduction - Agent spawning
    
    The agent runs an OODA loop:
    1. Observe - Gather information from all sources
    2. Orient - Analyze and understand context
    3. Decide - Choose best course of action
    4. Act - Execute the decision
    
    Example:
        >>> config = Config()
        >>> agent = SovereignAgent(config)
        >>> await agent.initialize()
        >>> await agent.run()  # Start autonomous loop
    """
    
    def __init__(self, config: Optional[Config] = None):
        """
        Initialize Sovereign Agent.
        
        Args:
            config: Configuration object (uses global config if not provided)
        """
        self.config = config or get_config()
        self.vitals = VitalSigns()
        self._start_time = datetime.utcnow()
        self._running = False
        
        # Components (initialized lazily)
        self._wallet = None
        self._soul = None
        self._voice = None
        self._eye = None
        self._courier = None
        self._browser = None
        self._yield = None
        self._swarm = None
        self._reproduction = None
        
        # DePIN components
        self._bandwidth = None
        self._compute = None
        self._oracle = None
        
        # Physical layer
        self._power = None
        self._satellite = None
        self._mesh = None
        
        # Core infrastructure
        self._backbone = None
        self._registry = None
        self._router = None
        
        # LLM client
        self._llm = None
        
        logger.info("sovereign_agent.created",
                   name=self.config.agent_name,
                   version=self.config.agent_version)
    
    # ==========================================================================
    # INITIALIZATION
    # ==========================================================================
    
    async def initialize(self) -> None:
        """
        Initialize all agent components.
        
        This sets up:
        - Core infrastructure (backbone, registry, router)
        - Digital organs (wallet, soul, voice, etc.)
        - Economic engines (yield, DePIN)
        - Physical layer (power, satellite, mesh)
        """
        logger.info("sovereign_agent.initializing")
        self.vitals.state = AgentState.INITIALIZING
        
        try:
            # Initialize core infrastructure
            await self._init_core()
            
            # Initialize digital organs
            await self._init_organs()
            
            # Initialize economic engines
            await self._init_economics()
            
            # Initialize physical layer (optional)
            await self._init_physical()
            
            self.vitals.state = AgentState.IDLE
            logger.info("sovereign_agent.initialized",
                       components=self._get_component_status())
            
        except Exception as e:
            self.vitals.state = AgentState.ERROR
            self.vitals.error_count += 1
            logger.error("sovereign_agent.init_failed", error=str(e))
            raise
    
    async def _init_core(self) -> None:
        """Initialize core infrastructure"""
        from .core.backbone import Backbone
        from .core.registry import ModelRegistry
        from .core.router import ModuleRouter
        
        self._backbone = Backbone(agent_id=self.config.agent_name)
        self._registry = ModelRegistry()
        self._router = ModuleRouter()
        
        await self._backbone.initialize()
        
        # Setup LLM based on available credentials
        if self.config.anthropic_api_key:
            from langchain_anthropic import ChatAnthropic
            self._llm = ChatAnthropic(
                model=self.config.anthropic_model,
                api_key=self.config.anthropic_api_key,
            )
        elif self.config.openai_api_key:
            from langchain_openai import ChatOpenAI
            self._llm = ChatOpenAI(
                model=self.config.openai_model,
                api_key=self.config.openai_api_key,
            )
        else:
            logger.warning("sovereign_agent.no_llm_configured")
    
    async def _init_organs(self) -> None:
        """Initialize digital organs"""
        # Wallet (DigitalBody)
        if self.config.has_wallet_credentials():
            from .wallet import DigitalBody
            self._wallet = DigitalBody(
                cdp_api_key_name=self.config.cdp_api_key_name,
                cdp_api_key_private_key=self.config.cdp_api_key_private_key,
                network_id=self.config.network_id,
            )
            await self._wallet.initialize()
        
        # Memory (DigitalSoul)
        from .soul import DigitalSoul
        self._soul = DigitalSoul(
            persist_dir=self.config.chroma_persist_dir,
            collection_name=self.config.chroma_collection,
        )
        await self._soul.initialize()
        
        # Social (DigitalVoice)
        if self.config.has_social_credentials():
            from .farcaster import DigitalVoice
            self._voice = DigitalVoice(
                api_key=self.config.neynar_api_key,
                signer_uuid=self.config.farcaster_signer_uuid,
            )
            await self._voice.initialize()
        
        # Vision (DigitalEye)
        if self.config.openai_api_key:
            from .vision import DigitalEye
            self._eye = DigitalEye(
                openai_api_key=self.config.openai_api_key,
            )
            await self._eye.initialize()
        
        # Browser
        from .browser import BrowserModule
        self._browser = BrowserModule()
    
    async def _init_economics(self) -> None:
        """Initialize economic engines"""
        # Yield Engine
        if self._wallet:
            from .yield_engine import YieldEngine
            self._yield = YieldEngine(
                wallet=self._wallet,
                pool_address=self.config.aave_pool_address,
            )
        
        # DePIN - Bandwidth
        from .depin.bandwidth import BandwidthNode
        self._bandwidth = BandwidthNode(
            node_api=self.config.mysterium_api,
            wallet_address=self._wallet.address if self._wallet else None,
        )
        await self._bandwidth.initialize()
        
        # DePIN - Compute
        if self.config.fleek_api_key:
            from .depin.compute import ComputeNode
            self._compute = ComputeNode(
                fleek_api_key=self.config.fleek_api_key,
            )
            await self._compute.initialize()
        
        # DePIN - Oracle
        if self._wallet:
            from .depin.oracle import RealityOracle
            self._oracle = RealityOracle(
                wallet_address=self._wallet.address,
            )
            await self._oracle.initialize()
    
    async def _init_physical(self) -> None:
        """Initialize physical layer (optional hardware)"""
        try:
            # Power management
            from .comms.bios import PowerManager
            self._power = PowerManager()
            await self._power.initialize()
            
            # Satellite (if configured)
            if self.config.iridium_imei:
                from .comms.dead_hand import SatelliteLink
                self._satellite = SatelliteLink(
                    imei=self.config.iridium_imei,
                    serial_port=self.config.iridium_port,
                )
                await self._satellite.initialize()
            
            # Mesh network
            from .comms.mesh import MeshNetwork
            self._mesh = MeshNetwork(
                serial_port=self.config.lora_port,
                frequency=self.config.lora_frequency,
            )
            await self._mesh.initialize()
            
        except Exception as e:
            logger.warning("sovereign_agent.physical_layer_unavailable",
                         error=str(e))
    
    def _get_component_status(self) -> dict:
        """Get status of all components"""
        return {
            "wallet": self._wallet is not None,
            "soul": self._soul is not None,
            "voice": self._voice is not None,
            "eye": self._eye is not None,
            "browser": self._browser is not None,
            "yield": self._yield is not None,
            "bandwidth": self._bandwidth is not None,
            "compute": self._compute is not None,
            "oracle": self._oracle is not None,
            "power": self._power is not None,
            "satellite": self._satellite is not None,
            "mesh": self._mesh is not None,
            "llm": self._llm is not None,
        }
    
    # ==========================================================================
    # OODA LOOP
    # ==========================================================================
    
    async def run(self, interval: float = 60.0) -> None:
        """
        Run the autonomous OODA loop.
        
        Args:
            interval: Seconds between iterations
        """
        self._running = True
        logger.info("sovereign_agent.loop_started", interval=interval)
        
        while self._running:
            try:
                await self._ooda_cycle()
                self._update_vitals()
                await asyncio.sleep(interval)
                
            except Exception as e:
                self.vitals.error_count += 1
                logger.error("sovereign_agent.loop_error", error=str(e))
                await asyncio.sleep(interval * 2)  # Back off on error
    
    async def _ooda_cycle(self) -> None:
        """Execute one OODA cycle"""
        # Observe
        observations = await self._observe()
        
        # Orient
        context = await self._orient(observations)
        
        # Decide
        decision = await self._decide(context)
        
        # Act
        if decision:
            await self._act(decision)
    
    async def _observe(self) -> dict:
        """Gather observations from all sources"""
        observations = {
            "timestamp": datetime.utcnow().isoformat(),
            "mentions": [],
            "messages": [],
            "market": {},
            "wallet": {},
        }
        
        # Check social mentions
        if self._voice:
            try:
                mentions = await self._voice.get_mentions()
                observations["mentions"] = mentions
            except Exception as e:
                logger.warning("observe.mentions_failed", error=str(e))
        
        # Check wallet state
        if self._wallet:
            try:
                balance = await self._wallet.get_usdc_balance()
                observations["wallet"] = {"usdc_balance": balance}
            except Exception as e:
                logger.warning("observe.wallet_failed", error=str(e))
        
        # Check yield positions
        if self._yield:
            try:
                positions = await self._yield.get_positions()
                observations["defi"] = positions
            except Exception as e:
                logger.warning("observe.defi_failed", error=str(e))
        
        return observations
    
    async def _orient(self, observations: dict) -> dict:
        """Analyze observations and build context"""
        # Recall relevant memories
        memories = []
        if self._soul:
            memories = await self._soul.recall(
                "recent events and priorities",
                n_results=5
            )
        
        return {
            "observations": observations,
            "memories": memories,
            "vitals": self.vitals.to_dict(),
        }
    
    async def _decide(self, context: dict) -> Optional[dict]:
        """Decide on action based on context"""
        if not self._llm:
            return None
        
        self.vitals.state = AgentState.THINKING
        
        # Build prompt
        prompt = f"""You are {self.config.agent_name}, an autonomous AI agent on Base blockchain.

Current context:
- Observations: {context['observations']}
- Recent memories: {context['memories']}
- Vitals: {context['vitals']}

Based on this context, decide what action to take (if any).
Options: reply_to_mention, post_cast, manage_yield, earn_depin, dream, idle

Respond with JSON: {{"action": "...", "params": {{...}}, "reasoning": "..."}}
Or respond with {{"action": "idle"}} if no action needed.
"""
        
        try:
            response = await self._llm.ainvoke(prompt)
            self.vitals.thoughts_processed += 1
            
            # Parse response (simplified - should use proper JSON parsing)
            import json
            content = response.content
            if isinstance(content, str) and "{" in content:
                start = content.index("{")
                end = content.rindex("}") + 1
                return json.loads(content[start:end])
            
        except Exception as e:
            logger.warning("decide.failed", error=str(e))
        
        return None
    
    async def _act(self, decision: dict) -> None:
        """Execute the decided action"""
        action = decision.get("action", "idle")
        params = decision.get("params", {})
        
        self.vitals.state = AgentState.ACTING
        logger.info("sovereign_agent.acting",
                   action=action,
                   reasoning=decision.get("reasoning"))
        
        try:
            if action == "reply_to_mention" and self._voice:
                await self._voice.post(
                    params.get("text", ""),
                    reply_to=params.get("reply_to")
                )
                self.vitals.casts_posted += 1
                
            elif action == "post_cast" and self._voice:
                await self._voice.post(params.get("text", ""))
                self.vitals.casts_posted += 1
                
            elif action == "manage_yield" and self._yield:
                await self._yield.optimize()
                
            elif action == "earn_depin":
                if self._bandwidth:
                    await self._bandwidth.start_service()
                    
            elif action == "dream" and self._soul:
                self.vitals.state = AgentState.DREAMING
                await self._soul.dream()
                
            self.vitals.actions_taken += 1
            
        except Exception as e:
            logger.error("act.failed", action=action, error=str(e))
            self.vitals.error_count += 1
        
        self.vitals.state = AgentState.IDLE
    
    def _update_vitals(self) -> None:
        """Update vital signs"""
        now = datetime.utcnow()
        self.vitals.uptime_seconds = (now - self._start_time).total_seconds()
        self.vitals.last_heartbeat = now
    
    # ==========================================================================
    # PUBLIC INTERFACE
    # ==========================================================================
    
    async def think(self, prompt: str) -> str:
        """
        Process a thought/query.
        
        Args:
            prompt: The thought to process
            
        Returns:
            The agent's response
        """
        if not self._llm:
            return "No LLM configured"
        
        self.vitals.state = AgentState.THINKING
        
        try:
            # Add context from memory
            memories = []
            if self._soul:
                memories = await self._soul.recall(prompt, n_results=3)
            
            full_prompt = f"""You are {self.config.agent_name}.

Relevant memories: {memories}

User: {prompt}

Respond thoughtfully and helpfully."""
            
            response = await self._llm.ainvoke(full_prompt)
            self.vitals.thoughts_processed += 1
            
            # Store interaction in memory
            if self._soul:
                await self._soul.remember(
                    f"User asked: {prompt}\nI responded: {response.content}",
                    metadata={"type": "conversation"}
                )
                self.vitals.memories_stored += 1
            
            self.vitals.state = AgentState.IDLE
            return response.content
            
        except Exception as e:
            self.vitals.state = AgentState.ERROR
            self.vitals.error_count += 1
            logger.error("think.failed", error=str(e))
            return f"Error: {str(e)}"
    
    async def stop(self) -> None:
        """Stop the agent"""
        self._running = False
        self.vitals.state = AgentState.SHUTDOWN
        
        # Cleanup components
        if self._soul:
            await self._soul.close()
        if self._voice:
            await self._voice.close()
        if self._wallet:
            await self._wallet.close()
        if self._bandwidth:
            await self._bandwidth.close()
        if self._compute:
            await self._compute.close()
        if self._backbone:
            await self._backbone.close()
        
        logger.info("sovereign_agent.stopped")
    
    def get_status(self) -> dict:
        """Get comprehensive agent status"""
        return {
            "name": self.config.agent_name,
            "version": self.config.agent_version,
            "vitals": self.vitals.to_dict(),
            "components": self._get_component_status(),
            "wallet_address": self._wallet.address if self._wallet else None,
        }
    
    # ==========================================================================
    # PROPERTIES
    # ==========================================================================
    
    @property
    def wallet(self):
        """Access wallet component"""
        return self._wallet
    
    @property
    def soul(self):
        """Access memory component"""
        return self._soul
    
    @property
    def voice(self):
        """Access social component"""
        return self._voice
    
    @property
    def address(self) -> Optional[str]:
        """Get wallet address"""
        return self._wallet.address if self._wallet else None
