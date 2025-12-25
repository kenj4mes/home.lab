"""
Mesh Network - LoRa Communication
Decentralized Local Mesh Networking

Local communication without internet.
"""

import hashlib
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

import structlog

logger = structlog.get_logger(__name__)


class MeshStatus(str, Enum):
    """Mesh network status"""
    OFFLINE = "offline"
    LISTENING = "listening"
    CONNECTED = "connected"
    ERROR = "error"


class MessageType(str, Enum):
    """Mesh message types"""
    BROADCAST = "broadcast"
    DIRECT = "direct"
    ROUTE = "route"
    ACK = "ack"


@dataclass
class MeshNode:
    """A node in the mesh"""
    node_id: str
    address: str
    rssi: int  # Signal strength dBm
    snr: float  # Signal-to-noise ratio
    last_seen: datetime
    hop_count: int = 1


@dataclass
class MeshMessage:
    """A mesh message"""
    message_id: str
    message_type: MessageType
    source: str
    destination: Optional[str]
    content: str
    timestamp: datetime
    hop_count: int = 0
    ttl: int = 5


class MeshNetwork:
    """
    Mesh Network - LoRa Communication
    
    Provides decentralized local communication using
    LoRa radio mesh networking.
    
    Example:
        >>> mesh = MeshNetwork()
        >>> await mesh.initialize()
        >>> await mesh.broadcast("Hello mesh!")
        >>> nodes = mesh.get_neighbors()
    """
    
    # LoRa configuration
    DEFAULT_FREQUENCY = 915.0  # MHz (US)
    DEFAULT_BANDWIDTH = 125  # kHz
    DEFAULT_SPREADING_FACTOR = 7
    MAX_MESSAGE_SIZE = 255  # bytes
    
    def __init__(
        self,
        node_id: Optional[str] = None,
        frequency: float = DEFAULT_FREQUENCY,
        serial_port: Optional[str] = None,
    ):
        """
        Initialize Mesh Network.
        
        Args:
            node_id: This node's ID
            frequency: Radio frequency (MHz)
            serial_port: LoRa module port
        """
        self.node_id = node_id or self._generate_node_id()
        self.frequency = frequency
        self.serial_port = serial_port
        
        self._status = MeshStatus.OFFLINE
        self._neighbors: Dict[str, MeshNode] = {}
        self._message_buffer: List[MeshMessage] = []
        self._routing_table: Dict[str, str] = {}
        
    def _generate_node_id(self) -> str:
        """Generate unique node ID"""
        import uuid
        return hashlib.sha256(str(uuid.uuid4()).encode()).hexdigest()[:8]
    
    async def initialize(self) -> bool:
        """
        Initialize mesh network.
        
        Returns:
            True if radio initialized
        """
        if not self.serial_port:
            # Simulation mode
            self._status = MeshStatus.LISTENING
            logger.info("mesh.initialized",
                       node_id=self.node_id,
                       mode="simulation")
            return True
        
        try:
            # In production, initialize LoRa radio
            # Configure frequency, bandwidth, SF
            
            self._status = MeshStatus.LISTENING
            
            logger.info("mesh.initialized",
                       node_id=self.node_id,
                       frequency=self.frequency)
            
            return True
            
        except Exception as e:
            logger.error("mesh.init_failed", error=str(e))
            self._status = MeshStatus.ERROR
            return False
    
    # ==========================================================================
    # MESSAGING
    # ==========================================================================
    
    async def broadcast(
        self,
        content: str,
        ttl: int = 5,
    ) -> str:
        """
        Broadcast message to all nodes.
        
        Args:
            content: Message content
            ttl: Time-to-live (hops)
            
        Returns:
            Message ID
        """
        message_id = hashlib.sha256(
            f"{content}{datetime.utcnow().isoformat()}".encode()
        ).hexdigest()[:12]
        
        message = MeshMessage(
            message_id=message_id,
            message_type=MessageType.BROADCAST,
            source=self.node_id,
            destination=None,
            content=content[:self.MAX_MESSAGE_SIZE],
            timestamp=datetime.utcnow(),
            ttl=ttl,
        )
        
        await self._transmit(message)
        
        logger.info("mesh.broadcast",
                   id=message_id,
                   length=len(content))
        
        return message_id
    
    async def send_direct(
        self,
        destination: str,
        content: str,
    ) -> str:
        """
        Send direct message to specific node.
        
        Args:
            destination: Target node ID
            content: Message content
            
        Returns:
            Message ID
        """
        message_id = hashlib.sha256(
            f"{destination}{content}{datetime.utcnow().isoformat()}".encode()
        ).hexdigest()[:12]
        
        message = MeshMessage(
            message_id=message_id,
            message_type=MessageType.DIRECT,
            source=self.node_id,
            destination=destination,
            content=content[:self.MAX_MESSAGE_SIZE],
            timestamp=datetime.utcnow(),
        )
        
        # Find route
        next_hop = self._routing_table.get(destination, destination)
        
        await self._transmit(message)
        
        logger.info("mesh.direct",
                   id=message_id,
                   to=destination,
                   via=next_hop)
        
        return message_id
    
    async def _transmit(self, message: MeshMessage) -> bool:
        """Transmit a message"""
        if self._status not in [MeshStatus.LISTENING, MeshStatus.CONNECTED]:
            logger.warning("mesh.not_ready", status=self._status.value)
            return False
        
        # In production, send via LoRa radio
        # Serialize message
        # Send packet
        
        return True
    
    async def receive(self) -> Optional[MeshMessage]:
        """
        Receive next message from buffer.
        
        Returns:
            Message or None
        """
        if self._message_buffer:
            return self._message_buffer.pop(0)
        return None
    
    async def _handle_incoming(
        self,
        data: bytes,
        rssi: int,
        snr: float,
    ) -> None:
        """Handle incoming radio packet"""
        try:
            # Parse message
            # Update neighbor table
            # Route or buffer message
            pass
        except Exception as e:
            logger.error("mesh.receive_error", error=str(e))
    
    # ==========================================================================
    # NEIGHBOR DISCOVERY
    # ==========================================================================
    
    async def discover_neighbors(self) -> int:
        """
        Discover nearby nodes.
        
        Returns:
            Number of neighbors found
        """
        # Send discovery beacon
        await self.broadcast(f"DISCOVER:{self.node_id}", ttl=1)
        
        # In production, wait for responses
        
        return len(self._neighbors)
    
    def get_neighbors(self) -> List[MeshNode]:
        """Get list of known neighbors"""
        return list(self._neighbors.values())
    
    def add_neighbor(
        self,
        node_id: str,
        address: str,
        rssi: int,
        snr: float,
    ) -> None:
        """Add or update neighbor"""
        self._neighbors[node_id] = MeshNode(
            node_id=node_id,
            address=address,
            rssi=rssi,
            snr=snr,
            last_seen=datetime.utcnow(),
        )
        
        # Update routing table
        self._routing_table[node_id] = node_id
    
    def remove_neighbor(self, node_id: str) -> None:
        """Remove neighbor"""
        self._neighbors.pop(node_id, None)
        self._routing_table.pop(node_id, None)
    
    async def prune_stale_neighbors(
        self,
        max_age_seconds: int = 300,
    ) -> int:
        """
        Remove stale neighbors.
        
        Args:
            max_age_seconds: Max age before removal
            
        Returns:
            Number removed
        """
        now = datetime.utcnow()
        stale = []
        
        for node_id, node in self._neighbors.items():
            age = (now - node.last_seen).total_seconds()
            if age > max_age_seconds:
                stale.append(node_id)
        
        for node_id in stale:
            self.remove_neighbor(node_id)
        
        return len(stale)
    
    # ==========================================================================
    # ROUTING
    # ==========================================================================
    
    def update_route(
        self,
        destination: str,
        next_hop: str,
        hop_count: int,
    ) -> None:
        """
        Update routing table.
        
        Args:
            destination: Target node
            next_hop: Next hop node
            hop_count: Distance in hops
        """
        # Only update if better route
        current_hop = self._neighbors.get(self._routing_table.get(destination))
        if current_hop is None or hop_count < current_hop.hop_count:
            self._routing_table[destination] = next_hop
            
            if next_hop in self._neighbors:
                self._neighbors[next_hop].hop_count = hop_count
    
    def get_route(self, destination: str) -> Optional[str]:
        """Get next hop for destination"""
        return self._routing_table.get(destination)
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_status(self) -> Dict[str, Any]:
        """Get mesh network status"""
        return {
            "node_id": self.node_id,
            "status": self._status.value,
            "frequency_mhz": self.frequency,
            "neighbors": len(self._neighbors),
            "routes": len(self._routing_table),
            "buffered_messages": len(self._message_buffer),
        }
    
    def get_topology(self) -> Dict[str, Any]:
        """Get network topology"""
        return {
            "self": self.node_id,
            "neighbors": [
                {
                    "id": n.node_id,
                    "rssi": n.rssi,
                    "snr": n.snr,
                    "hops": n.hop_count,
                }
                for n in self._neighbors.values()
            ],
            "routes": self._routing_table,
        }
    
    async def close(self) -> None:
        """Shutdown mesh network"""
        self._status = MeshStatus.OFFLINE
        self._neighbors.clear()
        logger.info("mesh.closed")
