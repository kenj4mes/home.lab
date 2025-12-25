"""
FastAPI Server - Sovereign Agent
HTTP API for Agent Interactions

Exposes agent capabilities via REST API.
"""

from typing import Any, Optional

import structlog

logger = structlog.get_logger(__name__)


def create_app(agent: Any = None):
    """
    Create FastAPI application for the agent.
    
    Args:
        agent: SovereignAgent instance (optional, can be set later)
        
    Returns:
        FastAPI application
    """
    from fastapi import FastAPI, HTTPException
    from fastapi.middleware.cors import CORSMiddleware
    from pydantic import BaseModel
    
    app = FastAPI(
        title="Sovereign Agent API",
        description="HTTP API for the Sovereign Agent",
        version="1.0.0",
    )
    
    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Store agent reference
    app.state.agent = agent
    
    # ==========================================================================
    # REQUEST MODELS
    # ==========================================================================
    
    class ThinkRequest(BaseModel):
        prompt: str
        
    class RememberRequest(BaseModel):
        content: str
        importance: float = 0.5
        
    class RecallRequest(BaseModel):
        query: str
        n_results: int = 5
        
    class BrowseRequest(BaseModel):
        url: str
        
    class PostRequest(BaseModel):
        text: str
        reply_to: Optional[str] = None
        
    class SendRequest(BaseModel):
        to: str
        amount: float
        asset: str = "usdc"
    
    # ==========================================================================
    # ROUTES
    # ==========================================================================
    
    @app.get("/")
    async def root():
        """API info"""
        return {
            "name": "Sovereign Agent API",
            "version": "1.0.0",
            "status": "operational",
        }
    
    @app.get("/health")
    async def health():
        """Health check"""
        return {"status": "ok"}
    
    @app.get("/status")
    async def status():
        """Get agent status"""
        if not app.state.agent:
            raise HTTPException(status_code=503, detail="Agent not initialized")
        return app.state.agent.get_status()
    
    # ==========================================================================
    # THINKING
    # ==========================================================================
    
    @app.post("/think")
    async def think(request: ThinkRequest):
        """Process a thought"""
        if not app.state.agent:
            raise HTTPException(status_code=503, detail="Agent not initialized")
        
        response = await app.state.agent.think(request.prompt)
        return {"response": response}
    
    # ==========================================================================
    # MEMORY
    # ==========================================================================
    
    @app.post("/remember")
    async def remember(request: RememberRequest):
        """Store a memory"""
        if not app.state.agent or not app.state.agent._soul:
            raise HTTPException(status_code=503, detail="Memory not available")
        
        memory_id = await app.state.agent._soul.remember(
            request.content,
            importance=request.importance
        )
        return {"memory_id": memory_id}
    
    @app.post("/recall")
    async def recall(request: RecallRequest):
        """Recall memories"""
        if not app.state.agent or not app.state.agent._soul:
            raise HTTPException(status_code=503, detail="Memory not available")
        
        memories = await app.state.agent._soul.recall(
            request.query,
            n_results=request.n_results
        )
        return {"memories": memories}
    
    # ==========================================================================
    # BROWSING
    # ==========================================================================
    
    @app.post("/browse")
    async def browse(request: BrowseRequest):
        """Browse a URL"""
        if not app.state.agent or not app.state.agent._browser:
            raise HTTPException(status_code=503, detail="Browser not available")
        
        content = await app.state.agent._browser.get_content(request.url)
        return content
    
    # ==========================================================================
    # SOCIAL
    # ==========================================================================
    
    @app.post("/post")
    async def post_cast(request: PostRequest):
        """Post to Farcaster"""
        if not app.state.agent or not app.state.agent._voice:
            raise HTTPException(status_code=503, detail="Social not available")
        
        result = await app.state.agent._voice.post(
            request.text,
            reply_to=request.reply_to
        )
        return result
    
    @app.get("/mentions")
    async def get_mentions():
        """Get recent mentions"""
        if not app.state.agent or not app.state.agent._voice:
            raise HTTPException(status_code=503, detail="Social not available")
        
        mentions = await app.state.agent._voice.get_mentions()
        return {"mentions": mentions}
    
    # ==========================================================================
    # WALLET
    # ==========================================================================
    
    @app.get("/wallet")
    async def wallet_status():
        """Get wallet status"""
        if not app.state.agent or not app.state.agent._wallet:
            raise HTTPException(status_code=503, detail="Wallet not available")
        
        balances = await app.state.agent._wallet.get_balances()
        return {
            "address": app.state.agent._wallet.address,
            "basename": app.state.agent._wallet.basename,
            "balances": balances,
        }
    
    @app.post("/wallet/send")
    async def send_funds(request: SendRequest):
        """Send funds"""
        if not app.state.agent or not app.state.agent._wallet:
            raise HTTPException(status_code=503, detail="Wallet not available")
        
        if request.asset.lower() == "usdc":
            result = await app.state.agent._wallet.send_usdc(
                request.to,
                request.amount
            )
        elif request.asset.lower() == "eth":
            result = await app.state.agent._wallet.send_eth(
                request.to,
                request.amount
            )
        else:
            raise HTTPException(status_code=400, detail=f"Unknown asset: {request.asset}")
        
        return result
    
    # ==========================================================================
    # DEFI
    # ==========================================================================
    
    @app.get("/yield")
    async def yield_status():
        """Get yield positions"""
        if not app.state.agent or not app.state.agent._yield:
            raise HTTPException(status_code=503, detail="Yield engine not available")
        
        positions = await app.state.agent._yield.get_positions()
        return positions
    
    @app.post("/yield/optimize")
    async def optimize_yield():
        """Optimize yield positions"""
        if not app.state.agent or not app.state.agent._yield:
            raise HTTPException(status_code=503, detail="Yield engine not available")
        
        result = await app.state.agent._yield.optimize()
        return result
    
    return app
