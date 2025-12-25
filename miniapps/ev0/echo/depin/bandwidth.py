"""
Bandwidth Node - DePIN Module
Mysterium Network Integration

Earn MYST tokens by sharing bandwidth.
"""

from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

import structlog

logger = structlog.get_logger(__name__)


class NodeStatus(str, Enum):
    """Node status"""
    OFFLINE = "offline"
    STARTING = "starting"
    ONLINE = "online"
    SERVING = "serving"
    ERROR = "error"


class ServiceType(str, Enum):
    """Service types"""
    VPN = "vpn"
    PROXY = "proxy"
    DATA_SCRAPING = "scraping"


@dataclass
class BandwidthStats:
    """Bandwidth statistics"""
    bytes_sent: int = 0
    bytes_received: int = 0
    sessions_served: int = 0
    earnings_myst: float = 0.0
    uptime_seconds: int = 0


class BandwidthNode:
    """
    Bandwidth Node - Mysterium Network
    
    Provides bandwidth to the Mysterium Network and earns
    MYST tokens for data transfer.
    
    Example:
        >>> node = BandwidthNode()
        >>> await node.initialize()
        >>> await node.start_serving()
        >>> stats = node.get_stats()
    """
    
    # Mysterium configuration
    MYST_TOKEN = "0x4Cf89ca06ad997bC732Dc876ed2A7F26a9E7f361"
    DEFAULT_PRICE_PER_GB = 0.1  # MYST per GB
    
    def __init__(
        self,
        identity_path: Optional[str] = None,
        price_per_gb: float = DEFAULT_PRICE_PER_GB,
        services: Optional[List[ServiceType]] = None,
    ):
        """
        Initialize Bandwidth Node.
        
        Args:
            identity_path: Path to Mysterium identity
            price_per_gb: Price per GB in MYST
            services: Services to offer
        """
        self.identity_path = identity_path
        self.price_per_gb = price_per_gb
        self.services = services or [ServiceType.VPN]
        
        self.status = NodeStatus.OFFLINE
        self.stats = BandwidthStats()
        self._start_time: Optional[datetime] = None
        
    async def initialize(self) -> None:
        """Initialize bandwidth node"""
        self.status = NodeStatus.STARTING
        
        # In production:
        # 1. Load or create Mysterium identity
        # 2. Register with network
        # 3. Configure services
        
        logger.info("bandwidth.initialized",
                   services=[s.value for s in self.services],
                   price=self.price_per_gb)
    
    # ==========================================================================
    # NODE OPERATIONS
    # ==========================================================================
    
    async def start_serving(self) -> bool:
        """
        Start serving bandwidth.
        
        Returns:
            True if started successfully
        """
        if self.status == NodeStatus.SERVING:
            return True
        
        self.status = NodeStatus.ONLINE
        self._start_time = datetime.utcnow()
        
        # In production, start Mysterium node daemon
        
        logger.info("bandwidth.serving",
                   services=[s.value for s in self.services])
        
        self.status = NodeStatus.SERVING
        return True
    
    async def stop_serving(self) -> None:
        """Stop serving bandwidth"""
        if self._start_time:
            uptime = (datetime.utcnow() - self._start_time).total_seconds()
            self.stats.uptime_seconds += int(uptime)
        
        self.status = NodeStatus.OFFLINE
        self._start_time = None
        
        logger.info("bandwidth.stopped",
                   total_uptime=self.stats.uptime_seconds)
    
    async def set_price(self, price_per_gb: float) -> None:
        """
        Set price per GB.
        
        Args:
            price_per_gb: New price in MYST
        """
        self.price_per_gb = price_per_gb
        logger.info("bandwidth.price_updated", price=price_per_gb)
    
    # ==========================================================================
    # SERVICE MANAGEMENT
    # ==========================================================================
    
    async def enable_service(self, service: ServiceType) -> bool:
        """
        Enable a service.
        
        Args:
            service: Service to enable
            
        Returns:
            True if enabled
        """
        if service not in self.services:
            self.services.append(service)
            logger.info("bandwidth.service_enabled", service=service.value)
        return True
    
    async def disable_service(self, service: ServiceType) -> bool:
        """
        Disable a service.
        
        Args:
            service: Service to disable
            
        Returns:
            True if disabled
        """
        if service in self.services:
            self.services.remove(service)
            logger.info("bandwidth.service_disabled", service=service.value)
        return True
    
    def get_available_services(self) -> List[ServiceType]:
        """Get list of available services"""
        return list(ServiceType)
    
    # ==========================================================================
    # STATISTICS
    # ==========================================================================
    
    def get_stats(self) -> BandwidthStats:
        """Get bandwidth statistics"""
        if self._start_time and self.status == NodeStatus.SERVING:
            current_uptime = (datetime.utcnow() - self._start_time).total_seconds()
            self.stats.uptime_seconds += int(current_uptime)
        
        return self.stats
    
    async def record_transfer(
        self,
        bytes_sent: int,
        bytes_received: int,
    ) -> None:
        """
        Record a data transfer.
        
        Args:
            bytes_sent: Bytes sent
            bytes_received: Bytes received
        """
        self.stats.bytes_sent += bytes_sent
        self.stats.bytes_received += bytes_received
        self.stats.sessions_served += 1
        
        # Calculate earnings
        total_gb = (bytes_sent + bytes_received) / (1024 ** 3)
        self.stats.earnings_myst += total_gb * self.price_per_gb
    
    # ==========================================================================
    # EARNINGS
    # ==========================================================================
    
    async def get_earnings(self) -> Dict[str, Any]:
        """
        Get earnings information.
        
        Returns:
            Earnings details
        """
        return {
            "myst_earned": self.stats.earnings_myst,
            "total_gb_served": (self.stats.bytes_sent + self.stats.bytes_received) / (1024 ** 3),
            "sessions": self.stats.sessions_served,
            "price_per_gb": self.price_per_gb,
        }
    
    async def withdraw_earnings(
        self,
        to_address: str,
        amount: Optional[float] = None,
    ) -> Dict[str, Any]:
        """
        Withdraw MYST earnings.
        
        Args:
            to_address: Recipient address
            amount: Amount to withdraw (None = all)
            
        Returns:
            Withdrawal result
        """
        withdraw_amount = amount or self.stats.earnings_myst
        
        if withdraw_amount > self.stats.earnings_myst:
            return {
                "success": False,
                "error": "Insufficient balance"
            }
        
        # In production, initiate Mysterium withdrawal
        
        self.stats.earnings_myst -= withdraw_amount
        
        logger.info("bandwidth.withdrawal",
                   amount=withdraw_amount,
                   to=to_address)
        
        return {
            "success": True,
            "amount": withdraw_amount,
            "to": to_address,
        }
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_status(self) -> Dict[str, Any]:
        """Get node status"""
        return {
            "status": self.status.value,
            "services": [s.value for s in self.services],
            "price_per_gb": self.price_per_gb,
            "stats": {
                "bytes_sent": self.stats.bytes_sent,
                "bytes_received": self.stats.bytes_received,
                "sessions": self.stats.sessions_served,
                "earnings_myst": self.stats.earnings_myst,
                "uptime_seconds": self.stats.uptime_seconds,
            },
        }
    
    async def close(self) -> None:
        """Shutdown node"""
        await self.stop_serving()
        logger.info("bandwidth.closed")
