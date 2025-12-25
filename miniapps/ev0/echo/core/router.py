"""
Module Router - Core Module
Intent Classification and Request Routing

Routes user requests to appropriate modules.
"""

import re
from dataclasses import dataclass
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Tuple

import structlog

logger = structlog.get_logger(__name__)


class Layer(str, Enum):
    """Agent capability layers"""
    WALLET = "wallet"  # Financial operations
    MEMORY = "memory"  # Knowledge storage
    SOCIAL = "social"  # Social interactions
    VISION = "vision"  # Visual perception
    BROWSER = "browser"  # Web interaction
    YIELD = "yield"  # DeFi operations
    DEPIN = "depin"  # Hardware/DePIN
    SWARM = "swarm"  # Multi-agent coordination


@dataclass
class Route:
    """A route to a module"""
    layer: Layer
    handler: Callable
    patterns: List[str]
    priority: int = 0
    requires_auth: bool = False


@dataclass
class RouteResult:
    """Result of route resolution"""
    layer: Layer
    handler: Callable
    confidence: float
    matched_pattern: Optional[str] = None


class ModuleRouter:
    """
    Module Router - Request Routing
    
    Routes user requests to appropriate capability layers
    using pattern matching and intent classification.
    
    Example:
        >>> router = ModuleRouter()
        >>> router.register_route(Layer.WALLET, wallet.transfer, ["send", "transfer", "pay"])
        >>> result = router.route("send 10 USDC to vitalik.eth")
        >>> await result.handler(request)
    """
    
    # Intent patterns by layer
    DEFAULT_PATTERNS = {
        Layer.WALLET: [
            r"send|transfer|pay|tip",
            r"balance|funds|holdings",
            r"wallet|address|account",
            r"swap|trade|exchange",
            r"deploy|token|contract",
            r"usdc|eth|weth|token",
        ],
        Layer.MEMORY: [
            r"remember|recall|forget",
            r"memory|memories|stored",
            r"learn|learned|know|knowledge",
            r"save|store|record",
            r"search.*memory|find.*remembered",
        ],
        Layer.SOCIAL: [
            r"post|cast|tweet|share",
            r"reply|respond|comment",
            r"follow|unfollow|like",
            r"farcaster|twitter|social",
            r"message|dm|direct",
        ],
        Layer.VISION: [
            r"see|look|view|watch",
            r"screenshot|image|picture",
            r"analyze.*image|describe.*image",
            r"visual|ui|screen",
            r"ocr|read.*image",
        ],
        Layer.BROWSER: [
            r"browse|navigate|visit",
            r"click|type|scroll",
            r"website|webpage|url",
            r"search.*web|google|lookup",
            r"scrape|extract|fetch",
        ],
        Layer.YIELD: [
            r"yield|apy|interest",
            r"supply|deposit|stake",
            r"withdraw|unstake|claim",
            r"aave|compound|defi",
            r"borrow|loan|collateral",
        ],
        Layer.DEPIN: [
            r"bandwidth|compute|storage",
            r"hardware|device|sensor",
            r"oracle|price|data feed",
            r"mysterium|akash|fleek",
            r"attestation|verify|prove",
        ],
        Layer.SWARM: [
            r"swarm|collective|group",
            r"delegate|distribute|coordinate",
            r"consensus|vote|decide",
            r"agents|workers|nodes",
            r"parallel|concurrent|batch",
        ],
    }
    
    def __init__(self):
        """Initialize router"""
        self.routes: Dict[Layer, List[Route]] = {layer: [] for layer in Layer}
        self.fallback_handler: Optional[Callable] = None
        self._compiled_patterns: Dict[Layer, List[re.Pattern]] = {}
        
        # Compile default patterns
        for layer, patterns in self.DEFAULT_PATTERNS.items():
            self._compiled_patterns[layer] = [
                re.compile(p, re.IGNORECASE) for p in patterns
            ]
    
    def register_route(
        self,
        layer: Layer,
        handler: Callable,
        patterns: Optional[List[str]] = None,
        priority: int = 0,
        requires_auth: bool = False,
    ) -> None:
        """
        Register a route.
        
        Args:
            layer: Target layer
            handler: Handler function
            patterns: Custom patterns (optional)
            priority: Route priority
            requires_auth: Whether authentication required
        """
        route = Route(
            layer=layer,
            handler=handler,
            patterns=patterns or [],
            priority=priority,
            requires_auth=requires_auth,
        )
        
        self.routes[layer].append(route)
        self.routes[layer].sort(key=lambda r: r.priority, reverse=True)
        
        # Compile custom patterns
        if patterns:
            compiled = [re.compile(p, re.IGNORECASE) for p in patterns]
            self._compiled_patterns.setdefault(layer, []).extend(compiled)
        
        logger.debug("router.route_registered",
                    layer=layer.value,
                    patterns=len(patterns or []))
    
    def set_fallback(self, handler: Callable) -> None:
        """Set fallback handler for unmatched requests"""
        self.fallback_handler = handler
    
    # ==========================================================================
    # ROUTING
    # ==========================================================================
    
    def route(self, query: str) -> Optional[RouteResult]:
        """
        Route a query to appropriate layer.
        
        Args:
            query: User query
            
        Returns:
            Route result or None
        """
        scores: Dict[Layer, Tuple[float, Optional[str]]] = {}
        
        # Score each layer
        for layer, patterns in self._compiled_patterns.items():
            max_score = 0.0
            matched_pattern = None
            
            for pattern in patterns:
                matches = pattern.findall(query)
                if matches:
                    # Score based on match count and specificity
                    score = len(matches) * (1.0 + len(pattern.pattern) / 100)
                    if score > max_score:
                        max_score = score
                        matched_pattern = pattern.pattern
            
            if max_score > 0:
                scores[layer] = (max_score, matched_pattern)
        
        if not scores:
            return None
        
        # Select best match
        best_layer = max(scores, key=lambda l: scores[l][0])
        best_score, matched_pattern = scores[best_layer]
        
        # Get handler
        routes = self.routes.get(best_layer, [])
        handler = routes[0].handler if routes else self.fallback_handler
        
        if not handler:
            return None
        
        # Normalize confidence to 0-1
        confidence = min(1.0, best_score / 5.0)
        
        return RouteResult(
            layer=best_layer,
            handler=handler,
            confidence=confidence,
            matched_pattern=matched_pattern,
        )
    
    def route_with_context(
        self,
        query: str,
        context: Dict[str, Any],
    ) -> Optional[RouteResult]:
        """
        Route with additional context.
        
        Args:
            query: User query
            context: Additional context (history, user, etc.)
            
        Returns:
            Route result
        """
        result = self.route(query)
        
        if not result:
            return None
        
        # Boost based on context
        if context.get("last_layer") == result.layer:
            result.confidence = min(1.0, result.confidence * 1.2)
        
        return result
    
    async def dispatch(
        self,
        query: str,
        context: Optional[Dict] = None,
    ) -> Any:
        """
        Route and dispatch a request.
        
        Args:
            query: User query
            context: Optional context
            
        Returns:
            Handler result
        """
        result = self.route(query)
        
        if not result:
            if self.fallback_handler:
                return await self.fallback_handler(query, context)
            raise ValueError(f"No route found for: {query[:50]}")
        
        logger.info("router.dispatching",
                   layer=result.layer.value,
                   confidence=result.confidence)
        
        return await result.handler(query, context)
    
    # ==========================================================================
    # INTENT CLASSIFICATION
    # ==========================================================================
    
    def classify_intent(self, query: str) -> Dict[Layer, float]:
        """
        Classify intent across all layers.
        
        Args:
            query: User query
            
        Returns:
            Confidence scores by layer
        """
        scores: Dict[Layer, float] = {}
        
        for layer, patterns in self._compiled_patterns.items():
            layer_score = 0.0
            
            for pattern in patterns:
                matches = pattern.findall(query)
                layer_score += len(matches) * 0.2
            
            scores[layer] = min(1.0, layer_score)
        
        return scores
    
    def get_top_intents(self, query: str, n: int = 3) -> List[Tuple[Layer, float]]:
        """
        Get top N intent matches.
        
        Args:
            query: User query
            n: Number of results
            
        Returns:
            List of (layer, confidence) tuples
        """
        scores = self.classify_intent(query)
        sorted_scores = sorted(scores.items(), key=lambda x: x[1], reverse=True)
        return sorted_scores[:n]
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def add_pattern(self, layer: Layer, pattern: str) -> None:
        """Add pattern to layer"""
        compiled = re.compile(pattern, re.IGNORECASE)
        self._compiled_patterns.setdefault(layer, []).append(compiled)
    
    def get_routes_for_layer(self, layer: Layer) -> List[Route]:
        """Get all routes for a layer"""
        return self.routes.get(layer, [])
    
    def get_status(self) -> Dict[str, Any]:
        """Get router status"""
        return {
            "layers": len(self.routes),
            "routes_per_layer": {
                layer.value: len(routes)
                for layer, routes in self.routes.items()
            },
            "patterns_per_layer": {
                layer.value: len(patterns)
                for layer, patterns in self._compiled_patterns.items()
            },
            "has_fallback": self.fallback_handler is not None,
        }
