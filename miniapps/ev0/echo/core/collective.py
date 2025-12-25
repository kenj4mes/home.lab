"""
Collective Intelligence - Core Module
Multi-Agent Coordination and Consensus

Enables agents to work together as a collective.
"""

import asyncio
import hashlib
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

import structlog

logger = structlog.get_logger(__name__)


class NodeRole(str, Enum):
    """Roles in the collective"""
    COORDINATOR = "coordinator"
    WORKER = "worker"
    OBSERVER = "observer"


@dataclass
class IntelligenceNode:
    """A node in the collective"""
    node_id: str
    role: NodeRole
    capabilities: List[str] = field(default_factory=list)
    url: Optional[str] = None
    last_seen: datetime = field(default_factory=datetime.utcnow)
    reputation: float = 1.0
    tasks_completed: int = 0


@dataclass
class ConsensusRequest:
    """A request for collective consensus"""
    request_id: str
    question: str
    options: List[str]
    votes: Dict[str, str] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.utcnow)
    resolved: bool = False
    result: Optional[str] = None


class CollectiveIntelligence:
    """
    Collective Intelligence - Multi-Agent Coordination
    
    Enables multiple agents to:
    - Share knowledge
    - Reach consensus
    - Distribute tasks
    - Learn from each other
    
    Example:
        >>> collective = CollectiveIntelligence(role=NodeRole.COORDINATOR)
        >>> await collective.initialize()
        >>> result = await collective.request_consensus("Should we invest?", ["yes", "no"])
    """
    
    def __init__(
        self,
        node_id: Optional[str] = None,
        role: NodeRole = NodeRole.WORKER,
        peer_urls: Optional[List[str]] = None,
    ):
        """
        Initialize Collective Intelligence.
        
        Args:
            node_id: This node's identifier
            role: Role in the collective
            peer_urls: URLs of peer nodes
        """
        self.node_id = node_id or self._generate_node_id()
        self.role = role
        self.peer_urls = peer_urls or []
        
        # Network state
        self.nodes: Dict[str, IntelligenceNode] = {}
        self.pending_consensus: Dict[str, ConsensusRequest] = {}
        
        # Knowledge pool
        self.shared_knowledge: List[Dict] = []
        
        self._running = False
        
    def _generate_node_id(self) -> str:
        """Generate unique node ID"""
        import uuid
        return hashlib.sha256(str(uuid.uuid4()).encode()).hexdigest()[:12]
    
    async def initialize(self) -> None:
        """Initialize collective"""
        self._running = True
        
        # Register self
        self.nodes[self.node_id] = IntelligenceNode(
            node_id=self.node_id,
            role=self.role,
        )
        
        # Connect to peers
        for url in self.peer_urls:
            await self._connect_peer(url)
        
        logger.info("collective.initialized",
                   node_id=self.node_id,
                   role=self.role.value,
                   peers=len(self.nodes) - 1)
    
    async def _connect_peer(self, url: str) -> bool:
        """Connect to a peer node"""
        # In production, make HTTP request to peer
        # For now, simulate connection
        try:
            peer_id = hashlib.sha256(url.encode()).hexdigest()[:12]
            self.nodes[peer_id] = IntelligenceNode(
                node_id=peer_id,
                role=NodeRole.WORKER,
                url=url,
            )
            logger.info("collective.peer_connected", peer=peer_id, url=url)
            return True
        except Exception as e:
            logger.warning("collective.peer_failed", url=url, error=str(e))
            return False
    
    # ==========================================================================
    # CONSENSUS
    # ==========================================================================
    
    async def request_consensus(
        self,
        question: str,
        options: List[str],
        timeout: float = 30.0,
    ) -> Dict[str, Any]:
        """
        Request consensus from the collective.
        
        Args:
            question: What to decide
            options: Available choices
            timeout: How long to wait
            
        Returns:
            Consensus result
        """
        request_id = hashlib.sha256(
            f"{question}{datetime.utcnow().isoformat()}".encode()
        ).hexdigest()[:12]
        
        request = ConsensusRequest(
            request_id=request_id,
            question=question,
            options=options,
        )
        
        self.pending_consensus[request_id] = request
        
        logger.info("collective.consensus_requested",
                   request_id=request_id,
                   question=question[:50])
        
        # Broadcast to peers
        await self._broadcast_consensus_request(request)
        
        # Wait for votes
        await asyncio.sleep(min(timeout, 5.0))  # Simplified timeout
        
        # Tally votes
        result = self._tally_votes(request)
        
        request.resolved = True
        request.result = result
        
        return {
            "request_id": request_id,
            "question": question,
            "result": result,
            "votes": request.votes,
            "total_votes": len(request.votes),
        }
    
    async def _broadcast_consensus_request(self, request: ConsensusRequest) -> None:
        """Broadcast consensus request to peers"""
        # In production, send HTTP requests to peers
        # For now, simulate self-voting
        import random
        
        for node_id, node in self.nodes.items():
            if node_id != self.node_id:
                # Simulate peer vote
                vote = random.choice(request.options)
                request.votes[node_id] = vote
        
        # Add own vote
        request.votes[self.node_id] = request.options[0]  # Default to first option
    
    def _tally_votes(self, request: ConsensusRequest) -> str:
        """Tally votes and determine winner"""
        vote_counts: Dict[str, float] = {}
        
        for node_id, vote in request.votes.items():
            node = self.nodes.get(node_id)
            weight = node.reputation if node else 1.0
            vote_counts[vote] = vote_counts.get(vote, 0) + weight
        
        if not vote_counts:
            return request.options[0]
        
        return max(vote_counts, key=vote_counts.get)
    
    async def vote(
        self,
        request_id: str,
        choice: str,
    ) -> bool:
        """
        Submit a vote for a consensus request.
        
        Args:
            request_id: Request to vote on
            choice: Your vote
            
        Returns:
            True if vote accepted
        """
        request = self.pending_consensus.get(request_id)
        
        if not request or request.resolved:
            return False
        
        if choice not in request.options:
            return False
        
        request.votes[self.node_id] = choice
        return True
    
    # ==========================================================================
    # KNOWLEDGE SHARING
    # ==========================================================================
    
    async def share_knowledge(
        self,
        content: str,
        category: str = "general",
    ) -> str:
        """
        Share knowledge with the collective.
        
        Args:
            content: Knowledge to share
            category: Category/topic
            
        Returns:
            Knowledge ID
        """
        knowledge_id = hashlib.sha256(
            f"{content}{datetime.utcnow().isoformat()}".encode()
        ).hexdigest()[:12]
        
        knowledge = {
            "id": knowledge_id,
            "content": content,
            "category": category,
            "source": self.node_id,
            "timestamp": datetime.utcnow().isoformat(),
        }
        
        self.shared_knowledge.append(knowledge)
        
        # Broadcast to peers
        # In production, send to all peers
        
        logger.info("collective.knowledge_shared",
                   id=knowledge_id,
                   category=category)
        
        return knowledge_id
    
    async def query_knowledge(
        self,
        query: str,
        category: Optional[str] = None,
        limit: int = 10,
    ) -> List[Dict]:
        """
        Query collective knowledge.
        
        Args:
            query: Search query
            category: Filter by category
            limit: Max results
            
        Returns:
            Matching knowledge entries
        """
        results = self.shared_knowledge
        
        # Filter by category
        if category:
            results = [k for k in results if k.get("category") == category]
        
        # Simple text search
        query_lower = query.lower()
        results = [
            k for k in results
            if query_lower in k.get("content", "").lower()
        ]
        
        return results[:limit]
    
    # ==========================================================================
    # TASK DISTRIBUTION
    # ==========================================================================
    
    async def distribute_task(
        self,
        task: str,
        requirements: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """
        Distribute a task to capable nodes.
        
        Args:
            task: Task description
            requirements: Required capabilities
            
        Returns:
            Task assignment
        """
        requirements = requirements or []
        
        # Find capable nodes
        capable_nodes = []
        for node_id, node in self.nodes.items():
            if node.role != NodeRole.OBSERVER:
                if not requirements or all(r in node.capabilities for r in requirements):
                    capable_nodes.append(node)
        
        if not capable_nodes:
            return {
                "status": "error",
                "error": "No capable nodes available"
            }
        
        # Select best node (highest reputation)
        best_node = max(capable_nodes, key=lambda n: n.reputation)
        
        return {
            "status": "assigned",
            "task": task,
            "assigned_to": best_node.node_id,
            "node_url": best_node.url,
        }
    
    # ==========================================================================
    # NODE MANAGEMENT
    # ==========================================================================
    
    def add_capability(self, capability: str) -> None:
        """Add capability to this node"""
        self_node = self.nodes.get(self.node_id)
        if self_node and capability not in self_node.capabilities:
            self_node.capabilities.append(capability)
    
    def update_reputation(self, node_id: str, delta: float) -> None:
        """Update a node's reputation"""
        node = self.nodes.get(node_id)
        if node:
            node.reputation = max(0.0, min(10.0, node.reputation + delta))
    
    def get_nodes(self) -> List[Dict]:
        """Get list of all nodes"""
        return [
            {
                "id": node.node_id,
                "role": node.role.value,
                "capabilities": node.capabilities,
                "reputation": node.reputation,
                "last_seen": node.last_seen.isoformat(),
            }
            for node in self.nodes.values()
        ]
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_status(self) -> Dict[str, Any]:
        """Get collective status"""
        return {
            "node_id": self.node_id,
            "role": self.role.value,
            "total_nodes": len(self.nodes),
            "pending_consensus": len(self.pending_consensus),
            "shared_knowledge": len(self.shared_knowledge),
        }
    
    async def close(self) -> None:
        """Shutdown collective"""
        self._running = False
        self.nodes.clear()
        logger.info("collective.closed")
