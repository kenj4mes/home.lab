"""
Legal Department - Entity Formation
OtoCo Integration for Delaware LLC Formation

Enables agents to form legal entities on-chain.
"""

from dataclasses import dataclass
from enum import Enum
from typing import Any, Dict, List, Optional

import structlog

logger = structlog.get_logger(__name__)


class EntityType(str, Enum):
    """Types of legal entities"""
    DELAWARE_LLC = "delaware_llc"
    WYOMING_DAO_LLC = "wyoming_dao_llc"
    MARSHALL_ISLANDS_LLC = "marshall_islands_llc"


class EntityStatus(str, Enum):
    """Entity status"""
    PENDING = "pending"
    ACTIVE = "active"
    DISSOLVED = "dissolved"


@dataclass
class Entity:
    """A legal entity"""
    entity_id: str
    name: str
    entity_type: EntityType
    status: EntityStatus
    jurisdiction: str
    formation_tx: Optional[str] = None
    owner_address: Optional[str] = None


class LegalDepartment:
    """
    Legal Department - Entity Formation
    
    Uses OtoCo protocol for on-chain entity formation.
    Enables agents to create real legal entities.
    
    Example:
        >>> legal = LegalDepartment()
        >>> await legal.initialize()
        >>> entity = await legal.form_llc(
        ...     name="Echo Ventures LLC",
        ...     wallet=wallet
        ... )
    """
    
    # OtoCo contracts
    OTOCO_MASTER = {
        "ethereum": "0x5A812c85aC78C7b49598c0E07e35c57E15C93B69",
        "base": "0x0000000000000000000000000000000000000000",  # Check actual address
        "polygon": "0x5A812c85aC78C7b49598c0E07e35c57E15C93B69",
    }
    
    # Formation costs (approximate)
    FORMATION_COSTS = {
        EntityType.DELAWARE_LLC: 0.05,  # ETH
        EntityType.WYOMING_DAO_LLC: 0.03,
        EntityType.MARSHALL_ISLANDS_LLC: 0.02,
    }
    
    def __init__(
        self,
        network: str = "ethereum",
    ):
        """
        Initialize Legal Department.
        
        Args:
            network: Network to use
        """
        self.network = network
        self.entities: Dict[str, Entity] = {}
        self._initialized = False
        
    async def initialize(self) -> None:
        """Initialize legal department"""
        self._initialized = True
        logger.info("legal.initialized", network=self.network)
    
    # ==========================================================================
    # ENTITY FORMATION
    # ==========================================================================
    
    async def form_llc(
        self,
        name: str,
        wallet: Any,  # CDP AgentKit wallet
        entity_type: EntityType = EntityType.DELAWARE_LLC,
    ) -> Entity:
        """
        Form a new LLC.
        
        Args:
            name: Entity name
            wallet: Wallet for transaction
            entity_type: Type of entity
            
        Returns:
            Formed entity
        """
        # Validate name
        if not self._validate_name(name):
            raise ValueError(f"Invalid entity name: {name}")
        
        owner_address = await wallet.default_address.address_id
        
        logger.info("legal.forming_llc",
                   name=name,
                   type=entity_type.value,
                   owner=owner_address)
        
        # In production, would call OtoCo contract
        # spawnSeries(jurisdictionId, name, owner)
        
        # Jurisdiction IDs
        jurisdiction_map = {
            EntityType.DELAWARE_LLC: (0, "Delaware, USA"),
            EntityType.WYOMING_DAO_LLC: (1, "Wyoming, USA"),
            EntityType.MARSHALL_ISLANDS_LLC: (2, "Marshall Islands"),
        }
        
        jurisdiction_id, jurisdiction_name = jurisdiction_map[entity_type]
        
        # Simulate entity creation
        import hashlib
        entity_id = hashlib.sha256(
            f"{name}{owner_address}".encode()
        ).hexdigest()[:12]
        
        entity = Entity(
            entity_id=entity_id,
            name=name,
            entity_type=entity_type,
            status=EntityStatus.PENDING,
            jurisdiction=jurisdiction_name,
            owner_address=owner_address,
        )
        
        self.entities[entity_id] = entity
        
        logger.info("legal.llc_formed",
                   entity_id=entity_id,
                   name=name)
        
        return entity
    
    def _validate_name(self, name: str) -> bool:
        """Validate entity name"""
        if len(name) < 3:
            return False
        if len(name) > 100:
            return False
        # Must end with LLC designator
        valid_suffixes = ["LLC", "L.L.C.", "Limited Liability Company"]
        return any(name.upper().endswith(s.upper()) for s in valid_suffixes)
    
    # ==========================================================================
    # ENTITY MANAGEMENT
    # ==========================================================================
    
    async def get_entity(self, entity_id: str) -> Optional[Entity]:
        """
        Get entity by ID.
        
        Args:
            entity_id: Entity identifier
            
        Returns:
            Entity or None
        """
        return self.entities.get(entity_id)
    
    async def list_entities(
        self,
        owner: Optional[str] = None,
    ) -> List[Entity]:
        """
        List entities.
        
        Args:
            owner: Filter by owner address
            
        Returns:
            List of entities
        """
        entities = list(self.entities.values())
        
        if owner:
            entities = [e for e in entities if e.owner_address == owner]
        
        return entities
    
    async def transfer_ownership(
        self,
        entity_id: str,
        new_owner: str,
        wallet: Any,
    ) -> bool:
        """
        Transfer entity ownership.
        
        Args:
            entity_id: Entity to transfer
            new_owner: New owner address
            wallet: Current owner wallet
            
        Returns:
            True if successful
        """
        entity = self.entities.get(entity_id)
        if not entity:
            return False
        
        current_owner = await wallet.default_address.address_id
        if entity.owner_address != current_owner:
            return False
        
        # In production, call OtoCo transfer function
        
        entity.owner_address = new_owner
        
        logger.info("legal.ownership_transferred",
                   entity_id=entity_id,
                   from_owner=current_owner,
                   to_owner=new_owner)
        
        return True
    
    async def dissolve_entity(
        self,
        entity_id: str,
        wallet: Any,
    ) -> bool:
        """
        Dissolve an entity.
        
        Args:
            entity_id: Entity to dissolve
            wallet: Owner wallet
            
        Returns:
            True if successful
        """
        entity = self.entities.get(entity_id)
        if not entity:
            return False
        
        owner = await wallet.default_address.address_id
        if entity.owner_address != owner:
            return False
        
        # In production, call OtoCo dissolve function
        
        entity.status = EntityStatus.DISSOLVED
        
        logger.info("legal.entity_dissolved", entity_id=entity_id)
        
        return True
    
    # ==========================================================================
    # GOVERNANCE
    # ==========================================================================
    
    async def add_member(
        self,
        entity_id: str,
        member_address: str,
        wallet: Any,
    ) -> bool:
        """
        Add member to entity.
        
        Args:
            entity_id: Entity ID
            member_address: New member address
            wallet: Owner wallet
            
        Returns:
            True if successful
        """
        entity = self.entities.get(entity_id)
        if not entity:
            return False
        
        # In production, call OtoCo membership function
        
        logger.info("legal.member_added",
                   entity_id=entity_id,
                   member=member_address)
        
        return True
    
    async def create_operating_agreement(
        self,
        entity_id: str,
        terms: Dict[str, Any],
    ) -> str:
        """
        Create operating agreement.
        
        Args:
            entity_id: Entity ID
            terms: Agreement terms
            
        Returns:
            IPFS hash of agreement
        """
        # In production, would:
        # 1. Generate legal document
        # 2. Upload to IPFS
        # 3. Store hash on-chain
        
        import hashlib
        ipfs_hash = "Qm" + hashlib.sha256(str(terms).encode()).hexdigest()[:44]
        
        logger.info("legal.agreement_created",
                   entity_id=entity_id,
                   ipfs_hash=ipfs_hash)
        
        return ipfs_hash
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_formation_cost(self, entity_type: EntityType) -> float:
        """Get formation cost in ETH"""
        return self.FORMATION_COSTS.get(entity_type, 0.1)
    
    def get_supported_jurisdictions(self) -> List[Dict]:
        """Get supported jurisdictions"""
        return [
            {
                "type": EntityType.DELAWARE_LLC.value,
                "name": "Delaware LLC",
                "jurisdiction": "Delaware, USA",
                "cost_eth": self.FORMATION_COSTS[EntityType.DELAWARE_LLC],
                "features": ["Limited liability", "Tax flexibility", "Privacy"],
            },
            {
                "type": EntityType.WYOMING_DAO_LLC.value,
                "name": "Wyoming DAO LLC",
                "jurisdiction": "Wyoming, USA",
                "cost_eth": self.FORMATION_COSTS[EntityType.WYOMING_DAO_LLC],
                "features": ["DAO recognition", "Smart contract governance", "Limited liability"],
            },
            {
                "type": EntityType.MARSHALL_ISLANDS_LLC.value,
                "name": "Marshall Islands LLC",
                "jurisdiction": "Marshall Islands",
                "cost_eth": self.FORMATION_COSTS[EntityType.MARSHALL_ISLANDS_LLC],
                "features": ["International", "Tax efficiency", "DAO recognition"],
            },
        ]
    
    def get_status(self) -> Dict[str, Any]:
        """Get department status"""
        return {
            "initialized": self._initialized,
            "network": self.network,
            "total_entities": len(self.entities),
            "active_entities": len([e for e in self.entities.values() if e.status == EntityStatus.ACTIVE]),
        }
    
    async def close(self) -> None:
        """Cleanup"""
        logger.info("legal.closed")
