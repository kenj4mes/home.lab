"""
Digital Courier - Sovereign Agent Messaging
XMTP Encrypted Messaging Integration

The agent's private communication channel:
- End-to-end encrypted DMs
- Wallet-to-wallet messaging
- Multi-party conversations
"""

import asyncio
from datetime import datetime
from typing import Any, Optional, Callable

import structlog

logger = structlog.get_logger(__name__)


class DigitalCourier:
    """
    Digital Courier - XMTP Messaging
    
    Uses XMTP protocol for wallet-to-wallet encrypted messaging.
    
    Capabilities:
    - Send encrypted messages
    - Receive messages
    - Create conversations
    - Group messaging
    
    Example:
        >>> courier = DigitalCourier(private_key="0x...")
        >>> await courier.initialize()
        >>> await courier.send("0x...", "Hello, friend!")
    """
    
    def __init__(
        self,
        private_key: Optional[str] = None,
        env: str = "production",
    ):
        """
        Initialize Digital Courier.
        
        Args:
            private_key: Wallet private key for XMTP identity
            env: XMTP environment (production/dev)
        """
        import os
        self.private_key = private_key or os.getenv("AGENT_PRIVATE_KEY")
        self.env = env
        
        self._client = None
        self.address: Optional[str] = None
        
        # Message tracking
        self.messages_sent: int = 0
        self.messages_received: int = 0
        self.conversations: dict[str, Any] = {}
        
        # Callbacks
        self._message_handlers: list[Callable] = []
        
    async def initialize(self) -> None:
        """Initialize XMTP client"""
        try:
            # XMTP Python SDK (when available)
            # For now, using HTTP API approach
            from eth_account import Account
            
            if self.private_key:
                account = Account.from_key(self.private_key)
                self.address = account.address
            
            logger.info("courier.initialized",
                       address=self.address[:10] + "..." if self.address else None,
                       env=self.env)
            
        except ImportError:
            logger.warning("courier.eth_account_not_installed")
        except Exception as e:
            logger.error("courier.init_failed", error=str(e))
    
    # ==========================================================================
    # MESSAGING
    # ==========================================================================
    
    async def send(
        self,
        to: str,
        message: str,
        content_type: str = "text",
    ) -> dict[str, Any]:
        """
        Send an encrypted message.
        
        Args:
            to: Recipient wallet address
            message: Message content
            content_type: Content type (text, reply, reaction)
            
        Returns:
            Send result
        """
        if not self.address:
            return {"status": "error", "error": "Not initialized"}
        
        # Get or create conversation
        convo = await self._get_or_create_conversation(to)
        
        if not convo:
            return {"status": "error", "error": "Could not create conversation"}
        
        try:
            # In production, use XMTP SDK
            # For now, simulate
            message_id = f"msg_{datetime.utcnow().timestamp()}"
            
            logger.info("courier.sent",
                       to=to[:10] + "...",
                       length=len(message))
            
            self.messages_sent += 1
            
            return {
                "status": "success",
                "message_id": message_id,
                "to": to,
                "timestamp": datetime.utcnow().isoformat(),
            }
            
        except Exception as e:
            logger.error("courier.send_failed", error=str(e))
            return {"status": "error", "error": str(e)}
    
    async def _get_or_create_conversation(self, peer: str) -> Optional[Any]:
        """Get existing or create new conversation"""
        if peer in self.conversations:
            return self.conversations[peer]
        
        # Create new conversation
        convo = {
            "peer": peer,
            "created_at": datetime.utcnow().isoformat(),
            "messages": []
        }
        
        self.conversations[peer] = convo
        return convo
    
    # ==========================================================================
    # RECEIVING
    # ==========================================================================
    
    def on_message(self, handler: Callable) -> None:
        """
        Register a message handler.
        
        Args:
            handler: Async function(message: dict)
        """
        self._message_handlers.append(handler)
    
    async def start_listening(self) -> None:
        """Start listening for incoming messages"""
        logger.info("courier.listening")
        
        # In production, stream messages from XMTP
        # For now, placeholder loop
        while True:
            await asyncio.sleep(5)
            # Check for new messages
    
    async def get_messages(
        self,
        peer: Optional[str] = None,
        limit: int = 20,
    ) -> list[dict]:
        """
        Get recent messages.
        
        Args:
            peer: Filter by peer address (None = all)
            limit: Max messages to return
            
        Returns:
            List of messages
        """
        messages = []
        
        if peer and peer in self.conversations:
            messages = self.conversations[peer].get("messages", [])
        else:
            for convo in self.conversations.values():
                messages.extend(convo.get("messages", []))
        
        # Sort by timestamp, newest first
        messages.sort(key=lambda m: m.get("timestamp", ""), reverse=True)
        
        return messages[:limit]
    
    # ==========================================================================
    # CONVERSATION MANAGEMENT
    # ==========================================================================
    
    async def get_conversations(self) -> list[dict]:
        """
        Get list of conversations.
        
        Returns:
            List of conversation summaries
        """
        return [
            {
                "peer": peer,
                "created_at": convo.get("created_at"),
                "message_count": len(convo.get("messages", [])),
            }
            for peer, convo in self.conversations.items()
        ]
    
    async def can_message(self, address: str) -> bool:
        """
        Check if an address is reachable via XMTP.
        
        Args:
            address: Wallet address to check
            
        Returns:
            True if address has XMTP identity
        """
        # In production, check with XMTP network
        # For now, assume all addresses are reachable
        return True
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_status(self) -> dict[str, Any]:
        """Get courier status"""
        return {
            "address": self.address,
            "env": self.env,
            "conversations": len(self.conversations),
            "messages_sent": self.messages_sent,
            "messages_received": self.messages_received,
        }
    
    async def close(self) -> None:
        """Cleanup resources"""
        self._message_handlers.clear()
        logger.info("courier.closed")
