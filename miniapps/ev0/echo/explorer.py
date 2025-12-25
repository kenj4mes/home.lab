"""
Digital Explorer - Sovereign Agent Web Search
Web Search and Alpha Detection

The agent's ability to find and analyze information:
- Web search
- Alpha signal detection
- News aggregation
"""

import asyncio
from datetime import datetime
from typing import Any, Optional

import httpx
import structlog

logger = structlog.get_logger(__name__)


class DigitalExplorer:
    """
    Digital Explorer - Web Search & Alpha Detection
    
    Uses multiple sources to search the web and
    detect alpha (valuable information signals).
    
    Capabilities:
    - Web search (via Perplexity)
    - News aggregation
    - Social signal detection
    - Alpha scoring
    
    Example:
        >>> explorer = DigitalExplorer(perplexity_key="...")
        >>> results = await explorer.search("Base ecosystem trends")
        >>> alpha = await explorer.detect_alpha("DeFi")
    """
    
    def __init__(
        self,
        perplexity_api_key: Optional[str] = None,
    ):
        """
        Initialize Digital Explorer.
        
        Args:
            perplexity_api_key: Perplexity API key for search
        """
        import os
        self.perplexity_key = perplexity_api_key or os.getenv("PERPLEXITY_API_KEY")
        
        self._client: httpx.AsyncClient | None = None
        
        # Statistics
        self.searches_performed: int = 0
        self.alpha_signals_detected: int = 0
        
    async def initialize(self) -> None:
        """Initialize HTTP client"""
        self._client = httpx.AsyncClient(timeout=30.0)
        logger.info("explorer.initialized")
    
    # ==========================================================================
    # WEB SEARCH
    # ==========================================================================
    
    async def search(
        self,
        query: str,
        max_results: int = 5,
    ) -> dict[str, Any]:
        """
        Search the web using Perplexity.
        
        Args:
            query: Search query
            max_results: Max results to return
            
        Returns:
            Search results
        """
        if not self.perplexity_key:
            return await self._fallback_search(query)
        
        try:
            response = await self._client.post(
                "https://api.perplexity.ai/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.perplexity_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": "llama-3.1-sonar-small-128k-online",
                    "messages": [
                        {"role": "user", "content": query}
                    ],
                }
            )
            
            if response.status_code == 200:
                data = response.json()
                self.searches_performed += 1
                
                content = data["choices"][0]["message"]["content"]
                citations = data.get("citations", [])
                
                return {
                    "status": "success",
                    "query": query,
                    "content": content,
                    "sources": citations,
                }
            else:
                return {"status": "error", "error": response.text}
                
        except Exception as e:
            logger.error("explorer.search_failed", error=str(e))
            return {"status": "error", "error": str(e)}
    
    async def _fallback_search(self, query: str) -> dict[str, Any]:
        """Fallback search without API key"""
        # Could use DuckDuckGo or other free APIs
        return {
            "status": "limited",
            "query": query,
            "content": f"Search for '{query}' requires Perplexity API key",
            "sources": []
        }
    
    # ==========================================================================
    # ALPHA DETECTION
    # ==========================================================================
    
    async def detect_alpha(
        self,
        topic: str,
        timeframe: str = "24h",
    ) -> dict[str, Any]:
        """
        Detect alpha signals for a topic.
        
        Alpha = valuable information that could lead to profit
        
        Args:
            topic: Topic to analyze
            timeframe: How far back to look
            
        Returns:
            Alpha signals with scores
        """
        logger.info("explorer.detecting_alpha", topic=topic)
        
        # Search for recent news/signals
        search_result = await self.search(
            f"latest {topic} news developments {timeframe}"
        )
        
        if search_result.get("status") != "success":
            return search_result
        
        # Analyze for alpha signals
        signals = await self._analyze_for_alpha(
            content=search_result.get("content", ""),
            topic=topic
        )
        
        self.alpha_signals_detected += len(signals)
        
        return {
            "status": "success",
            "topic": topic,
            "timeframe": timeframe,
            "signals": signals,
            "raw_content": search_result.get("content"),
        }
    
    async def _analyze_for_alpha(
        self,
        content: str,
        topic: str,
    ) -> list[dict]:
        """Analyze content for alpha signals"""
        signals = []
        
        # Keywords that might indicate alpha
        alpha_keywords = [
            "launch", "announce", "partner", "integrate", "raise",
            "funding", "airdrop", "upgrade", "mainnet", "testnet",
            "exploit", "hack", "vulnerability", "surge", "dump",
            "whale", "accumulate", "institutional", "listing"
        ]
        
        content_lower = content.lower()
        
        for keyword in alpha_keywords:
            if keyword in content_lower:
                # Extract context around keyword
                idx = content_lower.find(keyword)
                start = max(0, idx - 50)
                end = min(len(content), idx + 100)
                context = content[start:end]
                
                signals.append({
                    "type": keyword,
                    "context": context.strip(),
                    "score": self._score_alpha(keyword, context),
                })
        
        # Sort by score
        signals.sort(key=lambda x: x["score"], reverse=True)
        
        return signals[:10]  # Top 10 signals
    
    def _score_alpha(self, keyword: str, context: str) -> float:
        """Score alpha signal quality"""
        score = 0.5  # Base score
        
        # Higher scores for certain keywords
        high_value = ["exploit", "hack", "airdrop", "whale", "institutional"]
        medium_value = ["launch", "partner", "funding", "mainnet"]
        
        if keyword in high_value:
            score += 0.3
        elif keyword in medium_value:
            score += 0.2
        
        # Boost for specific tokens mentioned
        tokens = ["eth", "btc", "usdc", "base", "degen", "aero"]
        if any(t in context.lower() for t in tokens):
            score += 0.1
        
        # Boost for numbers (often indicates specific data)
        if any(c.isdigit() for c in context):
            score += 0.1
        
        return min(1.0, score)
    
    # ==========================================================================
    # NEWS AGGREGATION
    # ==========================================================================
    
    async def get_news(
        self,
        category: str = "crypto",
        limit: int = 10,
    ) -> dict[str, Any]:
        """
        Get latest news for a category.
        
        Args:
            category: News category
            limit: Max articles
            
        Returns:
            News articles
        """
        query = f"latest {category} news today"
        return await self.search(query, max_results=limit)
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_status(self) -> dict[str, Any]:
        """Get explorer status"""
        return {
            "perplexity_configured": bool(self.perplexity_key),
            "searches_performed": self.searches_performed,
            "alpha_signals_detected": self.alpha_signals_detected,
        }
    
    async def close(self) -> None:
        """Cleanup resources"""
        if self._client:
            await self._client.aclose()
            self._client = None
        logger.info("explorer.closed")
