"""
Reality Oracle - DePIN Module
Pyth/Chainlink Price Feeds and EAS Attestations

Provides real-world data to the agent.
"""

from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

import structlog

logger = structlog.get_logger(__name__)


class PriceSource(str, Enum):
    """Price data sources"""
    PYTH = "pyth"
    CHAINLINK = "chainlink"
    COINGECKO = "coingecko"


class AttestationType(str, Enum):
    """Types of attestations"""
    IDENTITY = "identity"
    CREDENTIAL = "credential"
    MEMBERSHIP = "membership"
    ACHIEVEMENT = "achievement"


@dataclass
class PriceFeed:
    """A price feed"""
    symbol: str
    price: float
    confidence: float
    timestamp: datetime
    source: PriceSource


@dataclass
class Attestation:
    """An EAS attestation"""
    uid: str
    schema_id: str
    attestor: str
    recipient: str
    data: Dict[str, Any]
    timestamp: datetime
    revocable: bool = True
    revoked: bool = False


class RealityOracle:
    """
    Reality Oracle - Real-World Data
    
    Provides price feeds from Pyth/Chainlink and
    creates/verifies EAS attestations.
    
    Example:
        >>> oracle = RealityOracle()
        >>> await oracle.initialize()
        >>> price = await oracle.get_price("ETH/USD")
        >>> attestation = await oracle.create_attestation(...)
    """
    
    # Pyth price feed IDs (mainnet)
    PYTH_FEEDS = {
        "ETH/USD": "0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace",
        "BTC/USD": "0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43",
        "USDC/USD": "0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a",
        "SOL/USD": "0xef0d8b6fda2ceba41da15d4095d1da392a0d2f8ed0c6c7bc0f4cfac8c280b56d",
    }
    
    # Chainlink feed addresses (Base)
    CHAINLINK_FEEDS = {
        "ETH/USD": "0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70",
        "USDC/USD": "0x7e860098F58bBFC8648a4311b374B1D669a2bc6B",
    }
    
    # EAS Schema Registry
    EAS_SCHEMAS = {
        AttestationType.IDENTITY: "0xf8b05c79f090979bf4a80270aba232dff11a10d9ca55c4f88de95317970f0de9",
        AttestationType.CREDENTIAL: "0x1801901fabd0e6189356b4fb52bb0ab855276d84f7ec140839fbd1f6801ca065",
    }
    
    def __init__(
        self,
        default_source: PriceSource = PriceSource.PYTH,
        network: str = "base",
    ):
        """
        Initialize Reality Oracle.
        
        Args:
            default_source: Default price source
            network: Network for EAS
        """
        self.default_source = default_source
        self.network = network
        
        self._price_cache: Dict[str, PriceFeed] = {}
        self._attestations: Dict[str, Attestation] = {}
        
    async def initialize(self) -> None:
        """Initialize oracle"""
        logger.info("oracle.initialized",
                   source=self.default_source.value,
                   network=self.network)
    
    # ==========================================================================
    # PRICE FEEDS
    # ==========================================================================
    
    async def get_price(
        self,
        symbol: str,
        source: Optional[PriceSource] = None,
    ) -> PriceFeed:
        """
        Get price for a symbol.
        
        Args:
            symbol: Price pair (e.g., "ETH/USD")
            source: Price source
            
        Returns:
            Price feed data
        """
        source = source or self.default_source
        
        # Check cache (30 second TTL)
        cached = self._price_cache.get(f"{symbol}:{source.value}")
        if cached:
            age = (datetime.utcnow() - cached.timestamp).total_seconds()
            if age < 30:
                return cached
        
        # Fetch price based on source
        if source == PriceSource.PYTH:
            price_data = await self._fetch_pyth_price(symbol)
        elif source == PriceSource.CHAINLINK:
            price_data = await self._fetch_chainlink_price(symbol)
        else:
            price_data = await self._fetch_coingecko_price(symbol)
        
        feed = PriceFeed(
            symbol=symbol,
            price=price_data["price"],
            confidence=price_data.get("confidence", 0.01),
            timestamp=datetime.utcnow(),
            source=source,
        )
        
        # Update cache
        self._price_cache[f"{symbol}:{source.value}"] = feed
        
        logger.debug("oracle.price_fetched",
                    symbol=symbol,
                    price=feed.price,
                    source=source.value)
        
        return feed
    
    async def _fetch_pyth_price(self, symbol: str) -> Dict:
        """Fetch price from Pyth"""
        feed_id = self.PYTH_FEEDS.get(symbol)
        
        if not feed_id:
            raise ValueError(f"Unknown Pyth feed: {symbol}")
        
        # In production, query Pyth API
        # GET https://hermes.pyth.network/api/latest_price_feeds?ids[]={feed_id}
        
        # Simulate prices
        prices = {
            "ETH/USD": 2500.0,
            "BTC/USD": 45000.0,
            "USDC/USD": 1.0,
            "SOL/USD": 100.0,
        }
        
        return {
            "price": prices.get(symbol, 0.0),
            "confidence": 0.005,  # 0.5%
        }
    
    async def _fetch_chainlink_price(self, symbol: str) -> Dict:
        """Fetch price from Chainlink"""
        feed_address = self.CHAINLINK_FEEDS.get(symbol)
        
        if not feed_address:
            raise ValueError(f"Unknown Chainlink feed: {symbol}")
        
        # In production, query Chainlink aggregator
        
        prices = {
            "ETH/USD": 2500.0,
            "USDC/USD": 1.0,
        }
        
        return {
            "price": prices.get(symbol, 0.0),
            "confidence": 0.001,
        }
    
    async def _fetch_coingecko_price(self, symbol: str) -> Dict:
        """Fetch price from CoinGecko"""
        # In production, call CoinGecko API
        
        # Parse symbol
        base = symbol.split("/")[0].lower()
        
        prices = {
            "eth": 2500.0,
            "btc": 45000.0,
            "usdc": 1.0,
            "sol": 100.0,
        }
        
        return {
            "price": prices.get(base, 0.0),
            "confidence": 0.02,
        }
    
    async def get_multiple_prices(
        self,
        symbols: List[str],
    ) -> Dict[str, PriceFeed]:
        """
        Get prices for multiple symbols.
        
        Args:
            symbols: List of price pairs
            
        Returns:
            Dictionary of prices
        """
        results = {}
        for symbol in symbols:
            try:
                results[symbol] = await self.get_price(symbol)
            except Exception as e:
                logger.warning("oracle.price_failed",
                             symbol=symbol,
                             error=str(e))
        return results
    
    # ==========================================================================
    # ATTESTATIONS
    # ==========================================================================
    
    async def create_attestation(
        self,
        attestation_type: AttestationType,
        recipient: str,
        data: Dict[str, Any],
        wallet: Any,  # CDP AgentKit wallet
    ) -> Attestation:
        """
        Create an EAS attestation.
        
        Args:
            attestation_type: Type of attestation
            recipient: Recipient address
            data: Attestation data
            wallet: Attestor wallet
            
        Returns:
            Created attestation
        """
        schema_id = self.EAS_SCHEMAS.get(attestation_type)
        if not schema_id:
            raise ValueError(f"Unknown attestation type: {attestation_type}")
        
        attestor = await wallet.default_address.address_id
        
        # Generate UID (in production, this comes from EAS contract)
        import hashlib
        uid = "0x" + hashlib.sha256(
            f"{schema_id}{recipient}{str(data)}".encode()
        ).hexdigest()
        
        attestation = Attestation(
            uid=uid,
            schema_id=schema_id,
            attestor=attestor,
            recipient=recipient,
            data=data,
            timestamp=datetime.utcnow(),
        )
        
        self._attestations[uid] = attestation
        
        logger.info("oracle.attestation_created",
                   uid=uid[:12],
                   type=attestation_type.value,
                   recipient=recipient[:10])
        
        # In production, submit to EAS contract
        
        return attestation
    
    async def verify_attestation(
        self,
        uid: str,
    ) -> Optional[Attestation]:
        """
        Verify an attestation.
        
        Args:
            uid: Attestation UID
            
        Returns:
            Attestation if valid, None otherwise
        """
        attestation = self._attestations.get(uid)
        
        if not attestation:
            # In production, query EAS subgraph
            logger.warning("oracle.attestation_not_found", uid=uid[:12])
            return None
        
        if attestation.revoked:
            logger.warning("oracle.attestation_revoked", uid=uid[:12])
            return None
        
        return attestation
    
    async def revoke_attestation(
        self,
        uid: str,
        wallet: Any,
    ) -> bool:
        """
        Revoke an attestation.
        
        Args:
            uid: Attestation UID
            wallet: Attestor wallet
            
        Returns:
            True if revoked
        """
        attestation = self._attestations.get(uid)
        
        if not attestation:
            return False
        
        if not attestation.revocable:
            return False
        
        attestor = await wallet.default_address.address_id
        if attestation.attestor != attestor:
            return False
        
        attestation.revoked = True
        
        logger.info("oracle.attestation_revoked", uid=uid[:12])
        
        return True
    
    async def get_attestations_for_recipient(
        self,
        recipient: str,
        attestation_type: Optional[AttestationType] = None,
    ) -> List[Attestation]:
        """
        Get attestations for a recipient.
        
        Args:
            recipient: Recipient address
            attestation_type: Filter by type
            
        Returns:
            List of attestations
        """
        attestations = [
            a for a in self._attestations.values()
            if a.recipient.lower() == recipient.lower() and not a.revoked
        ]
        
        if attestation_type:
            schema_id = self.EAS_SCHEMAS.get(attestation_type)
            attestations = [a for a in attestations if a.schema_id == schema_id]
        
        return attestations
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_supported_price_feeds(self) -> Dict[str, List[str]]:
        """Get supported price feeds by source"""
        return {
            PriceSource.PYTH.value: list(self.PYTH_FEEDS.keys()),
            PriceSource.CHAINLINK.value: list(self.CHAINLINK_FEEDS.keys()),
            PriceSource.COINGECKO.value: ["ETH/USD", "BTC/USD", "SOL/USD", "USDC/USD"],
        }
    
    def get_status(self) -> Dict[str, Any]:
        """Get oracle status"""
        return {
            "default_source": self.default_source.value,
            "network": self.network,
            "cached_prices": len(self._price_cache),
            "attestations": len(self._attestations),
        }
    
    async def close(self) -> None:
        """Cleanup"""
        self._price_cache.clear()
        logger.info("oracle.closed")
