"""
Reproduction Engine - Sovereign Agent
Agent Spawning and Lineage Management

The agent's ability to create new agents:
- Spawn child agents
- Transfer knowledge
- Manage lineage
"""

import hashlib
import json
import os
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Optional

import structlog

logger = structlog.get_logger(__name__)


@dataclass
class AgentLineage:
    """Tracks agent family tree"""
    agent_id: str
    parent_id: Optional[str] = None
    generation: int = 0
    spawn_time: datetime = field(default_factory=datetime.utcnow)
    traits: dict = field(default_factory=dict)
    children: list[str] = field(default_factory=list)


class ReproductionEngine:
    """
    Reproduction Engine - Agent Spawning
    
    Enables agents to spawn new instances with:
    - Inherited traits
    - Transferred knowledge
    - Lineage tracking
    
    Example:
        >>> repro = ReproductionEngine(parent_agent=agent)
        >>> child = await repro.spawn(name="echo-child-1")
    """
    
    def __init__(
        self,
        parent_agent: Any = None,
        lineage_file: str = "lineage.json",
    ):
        """
        Initialize Reproduction Engine.
        
        Args:
            parent_agent: The parent agent (for trait inheritance)
            lineage_file: File to persist lineage data
        """
        self.parent = parent_agent
        self.lineage_file = lineage_file
        
        self.lineage: dict[str, AgentLineage] = {}
        self.spawn_count: int = 0
        
        # Load existing lineage
        self._load_lineage()
        
    def _load_lineage(self) -> None:
        """Load lineage from file"""
        if os.path.exists(self.lineage_file):
            try:
                with open(self.lineage_file, "r") as f:
                    data = json.load(f)
                    for agent_id, info in data.items():
                        self.lineage[agent_id] = AgentLineage(
                            agent_id=agent_id,
                            parent_id=info.get("parent_id"),
                            generation=info.get("generation", 0),
                            spawn_time=datetime.fromisoformat(info.get("spawn_time", datetime.utcnow().isoformat())),
                            traits=info.get("traits", {}),
                            children=info.get("children", [])
                        )
            except Exception as e:
                logger.warning("repro.lineage_load_failed", error=str(e))
    
    def _save_lineage(self) -> None:
        """Save lineage to file"""
        try:
            data = {
                agent_id: {
                    "parent_id": lin.parent_id,
                    "generation": lin.generation,
                    "spawn_time": lin.spawn_time.isoformat(),
                    "traits": lin.traits,
                    "children": lin.children,
                }
                for agent_id, lin in self.lineage.items()
            }
            
            with open(self.lineage_file, "w") as f:
                json.dump(data, f, indent=2)
                
        except Exception as e:
            logger.error("repro.lineage_save_failed", error=str(e))
    
    # ==========================================================================
    # SPAWNING
    # ==========================================================================
    
    async def spawn(
        self,
        name: Optional[str] = None,
        traits: Optional[dict] = None,
        transfer_memories: bool = True,
    ) -> dict[str, Any]:
        """
        Spawn a new agent.
        
        Args:
            name: Name for the child agent
            traits: Override traits (inherits from parent if not specified)
            transfer_memories: Whether to copy parent memories
            
        Returns:
            Spawn result with new agent info
        """
        # Generate child ID
        child_id = hashlib.sha256(
            f"{self.parent.config.agent_name if self.parent else 'root'}"
            f"{datetime.utcnow().isoformat()}"
            f"{self.spawn_count}".encode()
        ).hexdigest()[:12]
        
        child_name = name or f"echo-{child_id[:6]}"
        
        logger.info("repro.spawning",
                   child_name=child_name,
                   parent=self.parent.config.agent_name if self.parent else None)
        
        # Inherit traits
        inherited_traits = {}
        if self.parent and hasattr(self.parent, "_soul"):
            inherited_traits = self.parent._soul.traits.copy()
        
        # Merge with provided traits
        final_traits = {**inherited_traits, **(traits or {})}
        
        # Apply mutations (small random changes)
        mutated_traits = self._apply_mutations(final_traits)
        
        # Determine generation
        parent_gen = 0
        parent_id = None
        if self.parent:
            parent_id = self.parent.config.agent_name
            if parent_id in self.lineage:
                parent_gen = self.lineage[parent_id].generation
        
        # Create lineage entry
        child_lineage = AgentLineage(
            agent_id=child_name,
            parent_id=parent_id,
            generation=parent_gen + 1,
            traits=mutated_traits,
        )
        
        self.lineage[child_name] = child_lineage
        
        # Update parent's children list
        if parent_id and parent_id in self.lineage:
            self.lineage[parent_id].children.append(child_name)
        
        self.spawn_count += 1
        self._save_lineage()
        
        # Transfer memories if requested
        transferred_memories = 0
        if transfer_memories and self.parent and hasattr(self.parent, "_soul"):
            transferred_memories = await self._transfer_memories(child_name)
        
        logger.info("repro.spawned",
                   child=child_name,
                   generation=child_lineage.generation,
                   memories_transferred=transferred_memories)
        
        return {
            "status": "success",
            "child_id": child_name,
            "generation": child_lineage.generation,
            "traits": mutated_traits,
            "memories_transferred": transferred_memories,
            "config_needed": self._generate_child_config(child_name, mutated_traits),
        }
    
    def _apply_mutations(
        self,
        traits: dict,
        mutation_rate: float = 0.1,
        mutation_magnitude: float = 0.05,
    ) -> dict:
        """Apply small random mutations to traits"""
        import random
        
        mutated = traits.copy()
        
        for trait, value in mutated.items():
            if isinstance(value, (int, float)):
                if random.random() < mutation_rate:
                    delta = (random.random() - 0.5) * 2 * mutation_magnitude
                    mutated[trait] = max(0.0, min(1.0, value + delta))
        
        return mutated
    
    async def _transfer_memories(
        self,
        child_name: str,
        memory_count: int = 100,
    ) -> int:
        """Transfer important memories to child"""
        if not self.parent or not hasattr(self.parent, "_soul"):
            return 0
        
        # Get parent's most important memories
        memories = await self.parent._soul.recall(
            "important knowledge and experiences",
            n_results=memory_count
        )
        
        # In production, would write these to child's memory store
        # For now, just count them
        return len(memories)
    
    def _generate_child_config(self, child_name: str, traits: dict) -> dict:
        """Generate configuration for child agent"""
        return {
            "agent_name": child_name,
            "agent_version": "1.0.0",
            "network_id": self.parent.config.network_id if self.parent else "base-mainnet",
            "traits": traits,
            "parent": self.parent.config.agent_name if self.parent else None,
            "note": "Child agent needs own wallet and API keys"
        }
    
    # ==========================================================================
    # LINEAGE QUERIES
    # ==========================================================================
    
    def get_lineage(self, agent_id: str) -> Optional[AgentLineage]:
        """Get lineage info for an agent"""
        return self.lineage.get(agent_id)
    
    def get_ancestors(self, agent_id: str) -> list[str]:
        """Get list of ancestors (parent, grandparent, etc.)"""
        ancestors = []
        current = self.lineage.get(agent_id)
        
        while current and current.parent_id:
            ancestors.append(current.parent_id)
            current = self.lineage.get(current.parent_id)
        
        return ancestors
    
    def get_descendants(self, agent_id: str) -> list[str]:
        """Get all descendants (children, grandchildren, etc.)"""
        descendants = []
        
        def collect_descendants(aid: str):
            lineage = self.lineage.get(aid)
            if lineage:
                for child_id in lineage.children:
                    descendants.append(child_id)
                    collect_descendants(child_id)
        
        collect_descendants(agent_id)
        return descendants
    
    def get_family_tree(self) -> dict[str, Any]:
        """Get the complete family tree"""
        # Find root(s) - agents with no parent
        roots = [
            agent_id for agent_id, lin in self.lineage.items()
            if lin.parent_id is None
        ]
        
        def build_tree(agent_id: str) -> dict:
            lin = self.lineage.get(agent_id)
            if not lin:
                return {"id": agent_id}
            
            return {
                "id": agent_id,
                "generation": lin.generation,
                "traits": lin.traits,
                "children": [build_tree(c) for c in lin.children]
            }
        
        return {
            "roots": [build_tree(r) for r in roots],
            "total_agents": len(self.lineage),
            "max_generation": max((l.generation for l in self.lineage.values()), default=0)
        }
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_status(self) -> dict[str, Any]:
        """Get reproduction engine status"""
        return {
            "total_agents": len(self.lineage),
            "spawn_count": self.spawn_count,
            "max_generation": max((l.generation for l in self.lineage.values()), default=0),
            "recent_spawns": [
                {"id": l.agent_id, "time": l.spawn_time.isoformat()}
                for l in sorted(self.lineage.values(), key=lambda x: x.spawn_time, reverse=True)[:5]
            ]
        }
    
    async def close(self) -> None:
        """Cleanup"""
        self._save_lineage()
        logger.info("repro.closed")
