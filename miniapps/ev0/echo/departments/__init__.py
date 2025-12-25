"""
Departments Package - Sovereign Agent
Specialized operational departments

- Legal: DAO/LLC formation
- Bridge: Cross-chain bridging
"""

from .legal import LegalDepartment
from .bridge import BridgeDepartment

__all__ = [
    "LegalDepartment",
    "BridgeDepartment",
]
