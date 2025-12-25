"""
Comms Package - Sovereign Agent
Physical Communication Modules

- PowerManager: UPS monitoring and power management
- SatelliteLink: Iridium satellite communication
- MeshNetwork: LoRa mesh networking
"""

from .bios import PowerManager
from .dead_hand import SatelliteLink
from .mesh import MeshNetwork

__all__ = [
    "PowerManager",
    "SatelliteLink",
    "MeshNetwork",
]
