"""
Power Manager - BIOS Layer
UPS Monitoring and Power Management

Physical infrastructure for agent resilience.
"""

from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

import structlog

logger = structlog.get_logger(__name__)


class PowerStatus(str, Enum):
    """Power status"""
    ON_GRID = "on_grid"
    ON_BATTERY = "on_battery"
    LOW_BATTERY = "low_battery"
    CRITICAL = "critical"
    CHARGING = "charging"
    UNKNOWN = "unknown"


class ShutdownReason(str, Enum):
    """Shutdown reasons"""
    LOW_BATTERY = "low_battery"
    USER_REQUEST = "user_request"
    SCHEDULED = "scheduled"
    OVERHEAT = "overheat"


@dataclass
class PowerMetrics:
    """Power metrics"""
    battery_percent: float
    voltage: float
    current_draw: float  # Watts
    runtime_remaining: int  # seconds
    temperature: float  # Celsius
    is_charging: bool
    on_battery: bool


@dataclass
class UPSDevice:
    """UPS device info"""
    device_id: str
    model: str
    capacity_wh: float
    connected: bool
    last_seen: datetime


class PowerManager:
    """
    Power Manager - BIOS Layer
    
    Monitors UPS status and manages power for agent
    hardware resilience.
    
    Example:
        >>> power = PowerManager()
        >>> await power.initialize()
        >>> metrics = await power.get_metrics()
        >>> await power.wake_on_lan("AA:BB:CC:DD:EE:FF")
    """
    
    # Power thresholds
    LOW_BATTERY_THRESHOLD = 20  # percent
    CRITICAL_THRESHOLD = 10  # percent
    
    def __init__(
        self,
        ups_device: Optional[str] = None,
        auto_shutdown: bool = True,
        shutdown_threshold: int = 5,  # percent
    ):
        """
        Initialize Power Manager.
        
        Args:
            ups_device: UPS device path
            auto_shutdown: Enable auto shutdown on low battery
            shutdown_threshold: Battery % to trigger shutdown
        """
        self.ups_device = ups_device
        self.auto_shutdown = auto_shutdown
        self.shutdown_threshold = shutdown_threshold
        
        self._status = PowerStatus.UNKNOWN
        self._devices: Dict[str, UPSDevice] = {}
        self._monitoring = False
        
    async def initialize(self) -> None:
        """Initialize power manager"""
        # In production, detect UPS via USB/NUT
        
        # Simulate detected UPS
        self._devices["ups0"] = UPSDevice(
            device_id="ups0",
            model="CyberPower CP1500",
            capacity_wh=1500,
            connected=True,
            last_seen=datetime.utcnow(),
        )
        
        self._status = PowerStatus.ON_GRID
        
        logger.info("power.initialized",
                   devices=len(self._devices),
                   auto_shutdown=self.auto_shutdown)
    
    # ==========================================================================
    # MONITORING
    # ==========================================================================
    
    async def start_monitoring(self) -> None:
        """Start power monitoring"""
        self._monitoring = True
        logger.info("power.monitoring_started")
    
    async def stop_monitoring(self) -> None:
        """Stop power monitoring"""
        self._monitoring = False
        logger.info("power.monitoring_stopped")
    
    async def get_metrics(self) -> PowerMetrics:
        """
        Get current power metrics.
        
        Returns:
            Power metrics
        """
        # In production, query UPS via NUT/apcupsd
        
        # Simulate metrics
        metrics = PowerMetrics(
            battery_percent=85.0,
            voltage=120.0,
            current_draw=150.0,
            runtime_remaining=3600,  # 1 hour
            temperature=35.0,
            is_charging=False,
            on_battery=False,
        )
        
        # Update status based on metrics
        if metrics.on_battery:
            if metrics.battery_percent < self.CRITICAL_THRESHOLD:
                self._status = PowerStatus.CRITICAL
            elif metrics.battery_percent < self.LOW_BATTERY_THRESHOLD:
                self._status = PowerStatus.LOW_BATTERY
            else:
                self._status = PowerStatus.ON_BATTERY
        elif metrics.is_charging:
            self._status = PowerStatus.CHARGING
        else:
            self._status = PowerStatus.ON_GRID
        
        return metrics
    
    def get_status(self) -> PowerStatus:
        """Get current power status"""
        return self._status
    
    # ==========================================================================
    # DEVICE MANAGEMENT
    # ==========================================================================
    
    def get_devices(self) -> List[UPSDevice]:
        """Get connected UPS devices"""
        return list(self._devices.values())
    
    async def refresh_devices(self) -> int:
        """
        Refresh device list.
        
        Returns:
            Number of devices found
        """
        # In production, scan for UPS devices
        
        for device in self._devices.values():
            device.last_seen = datetime.utcnow()
        
        return len(self._devices)
    
    # ==========================================================================
    # WAKE-ON-LAN
    # ==========================================================================
    
    async def wake_on_lan(
        self,
        mac_address: str,
        broadcast: str = "255.255.255.255",
        port: int = 9,
    ) -> bool:
        """
        Send Wake-on-LAN magic packet.
        
        Args:
            mac_address: Target MAC address
            broadcast: Broadcast address
            port: UDP port
            
        Returns:
            True if sent
        """
        import socket
        
        # Parse MAC address
        mac_bytes = bytes.fromhex(mac_address.replace(":", "").replace("-", ""))
        
        if len(mac_bytes) != 6:
            raise ValueError("Invalid MAC address")
        
        # Magic packet: 6 bytes of FF followed by MAC repeated 16 times
        magic_packet = b"\xff" * 6 + mac_bytes * 16
        
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
            sock.sendto(magic_packet, (broadcast, port))
            sock.close()
            
            logger.info("power.wol_sent",
                       mac=mac_address,
                       broadcast=broadcast)
            return True
            
        except Exception as e:
            logger.error("power.wol_failed",
                        mac=mac_address,
                        error=str(e))
            return False
    
    # ==========================================================================
    # SHUTDOWN MANAGEMENT
    # ==========================================================================
    
    async def request_shutdown(
        self,
        reason: ShutdownReason,
        delay: int = 60,
    ) -> bool:
        """
        Request system shutdown.
        
        Args:
            reason: Shutdown reason
            delay: Delay in seconds
            
        Returns:
            True if shutdown initiated
        """
        logger.warning("power.shutdown_requested",
                      reason=reason.value,
                      delay=delay)
        
        # In production, call OS shutdown command
        # subprocess.run(["shutdown", "-h", "+1"])
        
        return True
    
    async def cancel_shutdown(self) -> bool:
        """
        Cancel pending shutdown.
        
        Returns:
            True if cancelled
        """
        # In production, call shutdown cancel
        # subprocess.run(["shutdown", "-c"])
        
        logger.info("power.shutdown_cancelled")
        return True
    
    async def check_auto_shutdown(self) -> None:
        """Check if auto shutdown should be triggered"""
        if not self.auto_shutdown:
            return
        
        metrics = await self.get_metrics()
        
        if metrics.on_battery and metrics.battery_percent <= self.shutdown_threshold:
            logger.critical("power.auto_shutdown_triggered",
                          battery=metrics.battery_percent)
            
            await self.request_shutdown(
                reason=ShutdownReason.LOW_BATTERY,
                delay=30
            )
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_info(self) -> Dict[str, Any]:
        """Get power manager info"""
        return {
            "status": self._status.value,
            "monitoring": self._monitoring,
            "auto_shutdown": self.auto_shutdown,
            "shutdown_threshold": self.shutdown_threshold,
            "devices": [
                {
                    "id": d.device_id,
                    "model": d.model,
                    "capacity_wh": d.capacity_wh,
                    "connected": d.connected,
                }
                for d in self._devices.values()
            ],
        }
    
    async def close(self) -> None:
        """Shutdown power manager"""
        await self.stop_monitoring()
        logger.info("power.closed")
