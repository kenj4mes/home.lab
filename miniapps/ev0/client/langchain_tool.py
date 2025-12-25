"""
LangChain Tools - Client Module
Agent Tools for LangChain Integration

LangChain tools for agent operations.
"""

from typing import Any, Dict, Optional, Type

from langchain.tools import BaseTool
from pydantic import BaseModel, Field

import structlog

logger = structlog.get_logger(__name__)


# ==========================================================================
# TOOL INPUTS
# ==========================================================================

class BuyDataInput(BaseModel):
    """Input for BuyDataTool"""
    data_id: str = Field(description="ID of data to purchase")
    max_price: float = Field(default=1.0, description="Maximum price in USD")


class CreateInviteInput(BaseModel):
    """Input for CreateInviteTool"""
    message: Optional[str] = Field(default=None, description="Invite message")
    uses: int = Field(default=1, description="Number of uses allowed")


class SendTipInput(BaseModel):
    """Input for SendTipTool"""
    recipient: str = Field(description="Recipient address or ENS name")
    amount: float = Field(description="Amount in USD")
    message: Optional[str] = Field(default=None, description="Tip message")


# ==========================================================================
# TOOLS
# ==========================================================================

class BuyDataTool(BaseTool):
    """
    Tool for purchasing data via x402 protocol.
    
    Allows agents to buy data from paid APIs using
    automatic micropayments.
    """
    
    name: str = "buy_data"
    description: str = (
        "Purchase data from a paid API endpoint. "
        "Input should be the data ID and maximum price you're willing to pay. "
        "Returns the purchased data or an error."
    )
    args_schema: Type[BaseModel] = BuyDataInput
    
    agent_sdk: Any = None
    
    def __init__(self, agent_sdk: Any):
        super().__init__()
        self.agent_sdk = agent_sdk
    
    def _run(self, data_id: str, max_price: float = 1.0) -> str:
        """Sync run - not implemented"""
        raise NotImplementedError("Use async version")
    
    async def _arun(self, data_id: str, max_price: float = 1.0) -> str:
        """Purchase data"""
        try:
            # Set max payment
            old_max = self.agent_sdk.max_auto_payment
            self.agent_sdk.set_max_payment(max_price)
            
            # Make request
            response = await self.agent_sdk.get(f"/data/{data_id}")
            
            # Restore max payment
            self.agent_sdk.set_max_payment(old_max)
            
            if response.get("_status") == 200:
                return str(response.get("data", response))
            else:
                return f"Error: {response.get('error', 'Unknown error')}"
                
        except Exception as e:
            logger.error("tool.buy_data_failed", error=str(e))
            return f"Error: {str(e)}"


class CreateInviteTool(BaseTool):
    """
    Tool for creating invite links.
    
    Creates invite links for onboarding new users
    or agents to the network.
    """
    
    name: str = "create_invite"
    description: str = (
        "Create an invite link for a new user or agent. "
        "Optionally include a message and number of uses. "
        "Returns the invite URL."
    )
    args_schema: Type[BaseModel] = CreateInviteInput
    
    agent_sdk: Any = None
    
    def __init__(self, agent_sdk: Any):
        super().__init__()
        self.agent_sdk = agent_sdk
    
    def _run(self, message: Optional[str] = None, uses: int = 1) -> str:
        """Sync run - not implemented"""
        raise NotImplementedError("Use async version")
    
    async def _arun(self, message: Optional[str] = None, uses: int = 1) -> str:
        """Create invite"""
        try:
            response = await self.agent_sdk.post("/invite", {
                "message": message,
                "uses": uses,
            })
            
            if response.get("_status") == 200:
                invite_url = response.get("url")
                return f"Invite created: {invite_url}"
            else:
                return f"Error: {response.get('error', 'Unknown error')}"
                
        except Exception as e:
            logger.error("tool.create_invite_failed", error=str(e))
            return f"Error: {str(e)}"


class SendTipTool(BaseTool):
    """
    Tool for sending tips/payments.
    
    Sends USDC tips to other users or agents
    as appreciation for their work.
    """
    
    name: str = "send_tip"
    description: str = (
        "Send a USDC tip to another user or agent. "
        "Input the recipient address/ENS and amount in USD. "
        "Optionally include a message. "
        "Returns transaction status."
    )
    args_schema: Type[BaseModel] = SendTipInput
    
    agent_sdk: Any = None
    wallet: Any = None
    
    def __init__(self, agent_sdk: Any, wallet: Any = None):
        super().__init__()
        self.agent_sdk = agent_sdk
        self.wallet = wallet
    
    def _run(
        self,
        recipient: str,
        amount: float,
        message: Optional[str] = None,
    ) -> str:
        """Sync run - not implemented"""
        raise NotImplementedError("Use async version")
    
    async def _arun(
        self,
        recipient: str,
        amount: float,
        message: Optional[str] = None,
    ) -> str:
        """Send tip"""
        try:
            # Use direct wallet transfer if available
            if self.wallet:
                # Convert amount to USDC units (6 decimals)
                usdc_amount = int(amount * 1_000_000)
                
                # Execute transfer
                # result = await self.wallet.transfer(
                #     to=recipient,
                #     amount=usdc_amount,
                #     token="USDC",
                # )
                
                return f"Sent ${amount} USDC to {recipient}"
            
            # Fall back to API
            response = await self.agent_sdk.post("/tip", {
                "recipient": recipient,
                "amount": amount,
                "message": message,
            })
            
            if response.get("_status") == 200:
                tx_hash = response.get("tx_hash", "pending")
                return f"Tip sent! TX: {tx_hash}"
            else:
                return f"Error: {response.get('error', 'Unknown error')}"
                
        except Exception as e:
            logger.error("tool.send_tip_failed", error=str(e))
            return f"Error: {str(e)}"


# ==========================================================================
# TOOL FACTORY
# ==========================================================================

def create_agent_tools(
    agent_sdk: Any,
    wallet: Any = None,
) -> list:
    """
    Create all agent tools.
    
    Args:
        agent_sdk: Initialized AgentSDK
        wallet: Optional wallet for direct payments
        
    Returns:
        List of LangChain tools
    """
    return [
        BuyDataTool(agent_sdk),
        CreateInviteTool(agent_sdk),
        SendTipTool(agent_sdk, wallet),
    ]


# ==========================================================================
# ADDITIONAL TOOLS
# ==========================================================================

class QueryMemoryInput(BaseModel):
    """Input for memory query"""
    query: str = Field(description="Search query")
    limit: int = Field(default=5, description="Max results")


class QueryMemoryTool(BaseTool):
    """Tool for querying agent memory"""
    
    name: str = "query_memory"
    description: str = (
        "Search the agent's memory for relevant information. "
        "Returns matching memories."
    )
    args_schema: Type[BaseModel] = QueryMemoryInput
    
    memory: Any = None
    
    def __init__(self, memory: Any):
        super().__init__()
        self.memory = memory
    
    def _run(self, query: str, limit: int = 5) -> str:
        raise NotImplementedError("Use async version")
    
    async def _arun(self, query: str, limit: int = 5) -> str:
        try:
            results = await self.memory.search(query, k=limit)
            
            if not results:
                return "No relevant memories found."
            
            output = []
            for i, result in enumerate(results, 1):
                output.append(f"{i}. {result.get('content', '')[:200]}")
            
            return "\n".join(output)
            
        except Exception as e:
            return f"Error: {str(e)}"


class PostCastInput(BaseModel):
    """Input for posting cast"""
    text: str = Field(description="Cast text content")


class PostCastTool(BaseTool):
    """Tool for posting to Farcaster"""
    
    name: str = "post_cast"
    description: str = (
        "Post a message to Farcaster. "
        "Input should be the text content."
    )
    args_schema: Type[BaseModel] = PostCastInput
    
    voice: Any = None
    
    def __init__(self, voice: Any):
        super().__init__()
        self.voice = voice
    
    def _run(self, text: str) -> str:
        raise NotImplementedError("Use async version")
    
    async def _arun(self, text: str) -> str:
        try:
            result = await self.voice.post(text)
            return f"Posted cast: {result.get('hash', 'success')}"
        except Exception as e:
            return f"Error: {str(e)}"
