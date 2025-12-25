"""
Agent SDK - Client Module
x402 HTTP Client SDK

HTTP client with x402 payment protocol support.
"""

import hashlib
import time
from dataclasses import dataclass
from typing import Any, Dict, Optional
from urllib.parse import urljoin

import structlog

logger = structlog.get_logger(__name__)


@dataclass
class PaymentHeader:
    """x402 payment header"""
    version: str
    network: str
    token: str
    amount: str
    recipient: str
    expires: int
    signature: str


class AgentSDK:
    """
    Agent SDK - x402 HTTP Client
    
    HTTP client that automatically handles x402 payment
    challenges for paid API access.
    
    Example:
        >>> sdk = AgentSDK(base_url="https://api.echo.xyz", wallet=wallet)
        >>> response = await sdk.get("/data/alpha")
        >>> response = await sdk.post("/tip", {"amount": "1.00"})
    """
    
    def __init__(
        self,
        base_url: str,
        wallet: Any = None,
        max_auto_payment: float = 1.0,  # USD
        timeout: int = 30,
    ):
        """
        Initialize Agent SDK.
        
        Args:
            base_url: API base URL
            wallet: CDP wallet for payments
            max_auto_payment: Max payment without confirmation
            timeout: Request timeout
        """
        self.base_url = base_url.rstrip("/")
        self.wallet = wallet
        self.max_auto_payment = max_auto_payment
        self.timeout = timeout
        
        self._session = None
        self._payment_cache: Dict[str, PaymentHeader] = {}
        
    async def initialize(self) -> None:
        """Initialize HTTP session"""
        try:
            import httpx
            self._session = httpx.AsyncClient(timeout=self.timeout)
        except ImportError:
            import aiohttp
            self._session = aiohttp.ClientSession()
            
        logger.info("sdk.initialized", base_url=self.base_url)
    
    # ==========================================================================
    # HTTP METHODS
    # ==========================================================================
    
    async def get(
        self,
        path: str,
        params: Optional[Dict] = None,
        headers: Optional[Dict] = None,
    ) -> Dict[str, Any]:
        """
        Make GET request.
        
        Args:
            path: API path
            params: Query parameters
            headers: Additional headers
            
        Returns:
            Response data
        """
        return await self._request("GET", path, params=params, headers=headers)
    
    async def post(
        self,
        path: str,
        data: Optional[Dict] = None,
        headers: Optional[Dict] = None,
    ) -> Dict[str, Any]:
        """
        Make POST request.
        
        Args:
            path: API path
            data: Request body
            headers: Additional headers
            
        Returns:
            Response data
        """
        return await self._request("POST", path, data=data, headers=headers)
    
    async def put(
        self,
        path: str,
        data: Optional[Dict] = None,
        headers: Optional[Dict] = None,
    ) -> Dict[str, Any]:
        """
        Make PUT request.
        
        Args:
            path: API path
            data: Request body
            headers: Additional headers
            
        Returns:
            Response data
        """
        return await self._request("PUT", path, data=data, headers=headers)
    
    async def delete(
        self,
        path: str,
        headers: Optional[Dict] = None,
    ) -> Dict[str, Any]:
        """
        Make DELETE request.
        
        Args:
            path: API path
            headers: Additional headers
            
        Returns:
            Response data
        """
        return await self._request("DELETE", path, headers=headers)
    
    # ==========================================================================
    # REQUEST HANDLING
    # ==========================================================================
    
    async def _request(
        self,
        method: str,
        path: str,
        params: Optional[Dict] = None,
        data: Optional[Dict] = None,
        headers: Optional[Dict] = None,
    ) -> Dict[str, Any]:
        """Make HTTP request with x402 handling"""
        url = urljoin(self.base_url + "/", path.lstrip("/"))
        headers = headers or {}
        
        # Check for cached payment
        cached_payment = self._payment_cache.get(path)
        if cached_payment and cached_payment.expires > time.time():
            headers["X-Payment"] = self._encode_payment_header(cached_payment)
        
        # Make request
        response = await self._do_request(method, url, params, data, headers)
        
        # Handle 402 Payment Required
        if response.get("_status") == 402:
            payment_request = response.get("payment_request", {})
            
            if self._should_auto_pay(payment_request):
                payment = await self._make_payment(payment_request)
                
                if payment:
                    headers["X-Payment"] = self._encode_payment_header(payment)
                    response = await self._do_request(method, url, params, data, headers)
        
        return response
    
    async def _do_request(
        self,
        method: str,
        url: str,
        params: Optional[Dict],
        data: Optional[Dict],
        headers: Dict,
    ) -> Dict[str, Any]:
        """Execute HTTP request"""
        try:
            if hasattr(self._session, "request"):
                # httpx
                response = await self._session.request(
                    method,
                    url,
                    params=params,
                    json=data,
                    headers=headers,
                )
                
                response_data = response.json() if response.content else {}
                return {
                    "_status": response.status_code,
                    "_headers": dict(response.headers),
                    **response_data,
                }
            else:
                # aiohttp
                async with self._session.request(
                    method,
                    url,
                    params=params,
                    json=data,
                    headers=headers,
                ) as response:
                    result = await response.json() if response.content_length else {}
                    return {
                        "_status": response.status,
                        "_headers": dict(response.headers),
                        **result,
                    }
                    
        except Exception as e:
            logger.error("sdk.request_failed",
                        method=method,
                        url=url,
                        error=str(e))
            return {
                "_status": 0,
                "error": str(e),
            }
    
    # ==========================================================================
    # x402 PAYMENT
    # ==========================================================================
    
    def _should_auto_pay(self, payment_request: Dict) -> bool:
        """Check if payment should be auto-approved"""
        if not self.wallet:
            return False
        
        amount = float(payment_request.get("amount", 0))
        return amount <= self.max_auto_payment
    
    async def _make_payment(self, payment_request: Dict) -> Optional[PaymentHeader]:
        """Make x402 payment"""
        if not self.wallet:
            logger.warning("sdk.no_wallet")
            return None
        
        try:
            network = payment_request.get("network", "base")
            token = payment_request.get("token", "USDC")
            amount = payment_request.get("amount", "0")
            recipient = payment_request.get("recipient", "")
            
            # Get wallet address
            sender = await self.wallet.default_address.address_id
            
            # Create payment message
            expires = int(time.time()) + 300  # 5 minutes
            message = f"{network}:{token}:{amount}:{recipient}:{expires}"
            
            # Sign message
            signature = await self._sign_message(message)
            
            payment = PaymentHeader(
                version="1.0",
                network=network,
                token=token,
                amount=amount,
                recipient=recipient,
                expires=expires,
                signature=signature,
            )
            
            logger.info("sdk.payment_created",
                       amount=amount,
                       token=token,
                       recipient=recipient[:10])
            
            return payment
            
        except Exception as e:
            logger.error("sdk.payment_failed", error=str(e))
            return None
    
    async def _sign_message(self, message: str) -> str:
        """Sign message with wallet"""
        # In production, use wallet to sign
        # signature = await self.wallet.sign_message(message)
        
        # Simulate signature
        return hashlib.sha256(message.encode()).hexdigest()
    
    def _encode_payment_header(self, payment: PaymentHeader) -> str:
        """Encode payment header for HTTP"""
        return (
            f"x402 version={payment.version},"
            f"network={payment.network},"
            f"token={payment.token},"
            f"amount={payment.amount},"
            f"recipient={payment.recipient},"
            f"expires={payment.expires},"
            f"signature={payment.signature}"
        )
    
    def _parse_payment_request(self, header: str) -> Dict:
        """Parse x402 payment request header"""
        result = {}
        
        # Remove x402 prefix
        if header.startswith("x402 "):
            header = header[5:]
        
        # Parse key=value pairs
        for part in header.split(","):
            if "=" in part:
                key, value = part.strip().split("=", 1)
                result[key] = value
        
        return result
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def set_max_payment(self, amount: float) -> None:
        """Set max auto-payment amount"""
        self.max_auto_payment = amount
    
    def clear_payment_cache(self) -> None:
        """Clear cached payments"""
        self._payment_cache.clear()
    
    def get_stats(self) -> Dict[str, Any]:
        """Get SDK stats"""
        return {
            "base_url": self.base_url,
            "has_wallet": self.wallet is not None,
            "max_auto_payment": self.max_auto_payment,
            "cached_payments": len(self._payment_cache),
        }
    
    async def close(self) -> None:
        """Close HTTP session"""
        if self._session:
            await self._session.aclose() if hasattr(self._session, "aclose") else await self._session.close()
        logger.info("sdk.closed")
