"""
x402 HTTP Client - Sovereign Agent
SDK for x402 Protocol Communications

Handles HTTP 402 Payment Required flows:
- Auto-payment handling
- Session management
- Signature generation
"""

import hashlib
import json
import os
import time
from typing import Any, Optional

import httpx
import structlog

logger = structlog.get_logger(__name__)

try:
    from eth_account import Account
    from eth_account.messages import encode_defunct
    HAS_ETH_ACCOUNT = True
except ImportError:
    HAS_ETH_ACCOUNT = False
    Account = None


class HTTPClient:
    """
    x402 HTTP Client
    
    Handles HTTP 402 Payment Required flows automatically.
    
    When a server returns 402, this client:
    1. Parses the payment requirements
    2. Signs the payment authorization
    3. Retries the request with payment header
    
    Example:
        >>> client = HTTPClient(
        ...     private_key="0x...",
        ...     server_url="https://gateway.example.com"
        ... )
        >>> data = await client.get("/data")
    """
    
    def __init__(
        self,
        private_key: Optional[str] = None,
        server_url: str = "",
        client_id: str = "agent",
        max_spend_per_request: float = 5.0,
    ):
        """
        Initialize x402 HTTP Client.
        
        Args:
            private_key: Wallet private key for signing
            server_url: Base URL of x402 gateway
            client_id: Client identifier
            max_spend_per_request: Max USDC to spend per request
        """
        self.private_key = private_key or os.getenv("AGENT_PRIVATE_KEY")
        self.server_url = server_url.rstrip("/")
        self.client_id = client_id
        self.max_spend = max_spend_per_request
        
        self._http_client: httpx.AsyncClient | None = None
        self._account = None
        self.address: Optional[str] = None
        
        # Session
        self.token: Optional[str] = None
        self.token_expires: Optional[float] = None
        
        # Setup account
        if self.private_key and HAS_ETH_ACCOUNT:
            self._account = Account.from_key(self.private_key)
            self.address = self._account.address
        
    async def initialize(self) -> None:
        """Initialize HTTP client"""
        self._http_client = httpx.AsyncClient(
            base_url=self.server_url,
            timeout=30.0
        )
        
        logger.info("http_client.initialized",
                   server=self.server_url,
                   address=self.address[:10] + "..." if self.address else None)
    
    # ==========================================================================
    # HTTP METHODS
    # ==========================================================================
    
    async def get(
        self,
        endpoint: str,
        params: Optional[dict] = None,
    ) -> dict[str, Any]:
        """
        Make GET request with x402 handling.
        
        Args:
            endpoint: API endpoint
            params: Query parameters
            
        Returns:
            Response data
        """
        return await self._request("GET", endpoint, params=params)
    
    async def post(
        self,
        endpoint: str,
        data: Optional[dict] = None,
    ) -> dict[str, Any]:
        """
        Make POST request with x402 handling.
        
        Args:
            endpoint: API endpoint
            data: Request body
            
        Returns:
            Response data
        """
        return await self._request("POST", endpoint, json=data)
    
    async def _request(
        self,
        method: str,
        endpoint: str,
        **kwargs,
    ) -> dict[str, Any]:
        """Make request with x402 handling"""
        if not self._http_client:
            await self.initialize()
        
        headers = self._build_headers()
        
        try:
            response = await self._http_client.request(
                method,
                endpoint,
                headers=headers,
                **kwargs
            )
            
            # Handle 402 Payment Required
            if response.status_code == 402:
                return await self._handle_402(response, method, endpoint, **kwargs)
            
            # Handle 401/403 - try refreshing token
            if response.status_code in [401, 403]:
                if self.token:
                    self.token = None
                    return await self._request(method, endpoint, **kwargs)
                return {"status": "error", "code": response.status_code, "error": "Authentication required"}
            
            if response.status_code == 200:
                return {"status": "success", "data": response.json()}
            else:
                return {"status": "error", "code": response.status_code, "error": response.text}
                
        except Exception as e:
            logger.error("http_client.request_failed", error=str(e))
            return {"status": "error", "error": str(e)}
    
    async def _handle_402(
        self,
        response: httpx.Response,
        method: str,
        endpoint: str,
        **kwargs,
    ) -> dict[str, Any]:
        """Handle 402 Payment Required"""
        try:
            payment_info = response.json()
            
            # Parse payment requirements
            accepts = payment_info.get("accepts", [])
            if not accepts:
                return {"status": "error", "error": "No payment options"}
            
            option = accepts[0]  # Use first option
            amount = int(option.get("maxAmountRequired", 0))
            resource = option.get("resource", endpoint)
            
            # Check spend limit
            amount_usdc = amount / 1e6
            if amount_usdc > self.max_spend:
                return {
                    "status": "error",
                    "error": f"Amount ${amount_usdc} exceeds max spend ${self.max_spend}"
                }
            
            # Create payment header
            payment_header = self._create_payment_header(amount, resource)
            
            # Retry with payment
            headers = self._build_headers()
            headers["X-PAYMENT"] = payment_header
            
            retry_response = await self._http_client.request(
                method,
                endpoint,
                headers=headers,
                **kwargs
            )
            
            if retry_response.status_code == 200:
                data = retry_response.json()
                # Save token if returned
                if "token" in data:
                    self.token = data["token"]
                    self.token_expires = time.time() + 24 * 3600
                
                return {"status": "success", "data": data, "paid": amount_usdc}
            else:
                return {"status": "error", "error": retry_response.text}
                
        except Exception as e:
            logger.error("http_client.402_handling_failed", error=str(e))
            return {"status": "error", "error": str(e)}
    
    def _build_headers(self) -> dict[str, str]:
        """Build request headers"""
        headers = {
            "x-client-id": self.client_id,
            "Content-Type": "application/json",
        }
        
        if self.address:
            headers["x-wallet-address"] = self.address
        
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        
        return headers
    
    def _create_payment_header(self, amount: int, resource: str) -> str:
        """Create x402 payment header with signature"""
        if not self._account:
            raise ValueError("No signing key available")
        
        timestamp = int(time.time())
        nonce = hashlib.sha256(
            f"{timestamp}{resource}".encode()
        ).hexdigest()[:16]
        
        payment_data = {
            "amount": str(amount),
            "resource": resource,
            "timestamp": timestamp,
            "nonce": nonce,
            "payer": self.address,
        }
        
        # Sign the payment intent
        message = json.dumps(payment_data, sort_keys=True)
        message_hash = encode_defunct(text=message)
        signed = self._account.sign_message(message_hash)
        
        payment_data["signature"] = signed.signature.hex()
        
        return json.dumps(payment_data)
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def is_token_valid(self) -> bool:
        """Check if current token is valid"""
        if not self.token or not self.token_expires:
            return False
        return time.time() < (self.token_expires - 60)
    
    def get_status(self) -> dict[str, Any]:
        """Get client status"""
        return {
            "server": self.server_url,
            "address": self.address,
            "has_token": bool(self.token),
            "token_valid": self.is_token_valid(),
        }
    
    async def close(self) -> None:
        """Cleanup resources"""
        if self._http_client:
            await self._http_client.aclose()
            self._http_client = None
        logger.info("http_client.closed")
