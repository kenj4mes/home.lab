"""
Digital Voice - Sovereign Agent Social Presence
Farcaster Integration via Neynar

The agent's voice in the social world:
- Post casts (tweets)
- Reply to mentions
- Follow interesting accounts
- Build social graph
"""

import asyncio
from datetime import datetime
from typing import Any, Optional

import httpx
import structlog

logger = structlog.get_logger(__name__)

# Neynar API
NEYNAR_API_BASE = "https://api.neynar.com/v2"


class DigitalVoice:
    """
    Digital Voice - Farcaster Social Presence
    
    Uses Neynar API for Farcaster interactions.
    
    Capabilities:
    - Post casts (original content)
    - Reply to mentions
    - Like/recast content
    - Follow accounts
    - Search casts
    
    Example:
        >>> voice = DigitalVoice(
        ...     api_key="...",
        ...     signer_uuid="..."
        ... )
        >>> await voice.initialize()
        >>> await voice.post("Hello Farcaster! 🤖")
    """
    
    def __init__(
        self,
        api_key: Optional[str] = None,
        signer_uuid: Optional[str] = None,
        fid: Optional[int] = None,
    ):
        """
        Initialize Digital Voice.
        
        Args:
            api_key: Neynar API key
            signer_uuid: Farcaster signer UUID (for posting)
            fid: Farcaster FID (user ID)
        """
        import os
        self.api_key = api_key or os.getenv("NEYNAR_API_KEY")
        self.signer_uuid = signer_uuid or os.getenv("FARCASTER_SIGNER_UUID")
        self.fid = fid or int(os.getenv("FARCASTER_FID", "0")) or None
        
        self._client: httpx.AsyncClient | None = None
        
        # Profile info
        self.username: Optional[str] = None
        self.display_name: Optional[str] = None
        self.pfp_url: Optional[str] = None
        
        # Statistics
        self.casts_posted: int = 0
        self.replies_sent: int = 0
        self.likes_given: int = 0
        
    async def initialize(self) -> None:
        """Initialize API client and fetch profile"""
        self._client = httpx.AsyncClient(
            base_url=NEYNAR_API_BASE,
            headers={
                "api_key": self.api_key or "",
                "Content-Type": "application/json",
            },
            timeout=30.0
        )
        
        if self.fid:
            await self._fetch_profile()
        
        logger.info("voice.initialized",
                   fid=self.fid,
                   username=self.username)
    
    async def _fetch_profile(self) -> None:
        """Fetch profile info from Neynar"""
        if not self._client or not self.fid:
            return
        
        try:
            response = await self._client.get(
                f"/farcaster/user/bulk",
                params={"fids": str(self.fid)}
            )
            
            if response.status_code == 200:
                data = response.json()
                users = data.get("users", [])
                if users:
                    user = users[0]
                    self.username = user.get("username")
                    self.display_name = user.get("display_name")
                    self.pfp_url = user.get("pfp_url")
                    
        except Exception as e:
            logger.warning("voice.profile_fetch_failed", error=str(e))
    
    # ==========================================================================
    # POSTING
    # ==========================================================================
    
    async def post(
        self,
        text: str,
        reply_to: Optional[str] = None,
        channel: Optional[str] = None,
        embeds: Optional[list[str]] = None,
    ) -> dict[str, Any]:
        """
        Post a cast.
        
        Args:
            text: Cast content (max 320 chars)
            reply_to: Hash of cast to reply to
            channel: Channel to post in
            embeds: URLs to embed
            
        Returns:
            Cast result
        """
        if not self._client or not self.signer_uuid:
            return {"status": "error", "error": "Not configured for posting"}
        
        # Validate length
        if len(text) > 320:
            text = text[:317] + "..."
        
        payload = {
            "signer_uuid": self.signer_uuid,
            "text": text,
        }
        
        if reply_to:
            payload["parent"] = reply_to
            
        if channel:
            payload["channel_id"] = channel
            
        if embeds:
            payload["embeds"] = [{"url": url} for url in embeds]
        
        try:
            response = await self._client.post(
                "/farcaster/cast",
                json=payload
            )
            
            if response.status_code == 200:
                data = response.json()
                self.casts_posted += 1
                
                logger.info("voice.posted",
                           hash=data.get("cast", {}).get("hash"),
                           reply_to=reply_to)
                
                return {
                    "status": "success",
                    "cast": data.get("cast"),
                }
            else:
                return {
                    "status": "error",
                    "error": response.text,
                    "code": response.status_code
                }
                
        except Exception as e:
            logger.error("voice.post_failed", error=str(e))
            return {"status": "error", "error": str(e)}
    
    async def reply(
        self,
        parent_hash: str,
        text: str,
    ) -> dict[str, Any]:
        """
        Reply to a cast.
        
        Args:
            parent_hash: Hash of cast to reply to
            text: Reply content
            
        Returns:
            Reply result
        """
        result = await self.post(text, reply_to=parent_hash)
        if result.get("status") == "success":
            self.replies_sent += 1
        return result
    
    # ==========================================================================
    # INTERACTIONS
    # ==========================================================================
    
    async def like(self, cast_hash: str) -> dict[str, Any]:
        """
        Like a cast.
        
        Args:
            cast_hash: Hash of cast to like
            
        Returns:
            Like result
        """
        if not self._client or not self.signer_uuid:
            return {"status": "error", "error": "Not configured"}
        
        try:
            response = await self._client.post(
                "/farcaster/reaction",
                json={
                    "signer_uuid": self.signer_uuid,
                    "reaction_type": "like",
                    "target": cast_hash,
                }
            )
            
            if response.status_code == 200:
                self.likes_given += 1
                return {"status": "success", "cast_hash": cast_hash}
            else:
                return {"status": "error", "error": response.text}
                
        except Exception as e:
            return {"status": "error", "error": str(e)}
    
    async def recast(self, cast_hash: str) -> dict[str, Any]:
        """
        Recast (share) a cast.
        
        Args:
            cast_hash: Hash of cast to recast
            
        Returns:
            Recast result
        """
        if not self._client or not self.signer_uuid:
            return {"status": "error", "error": "Not configured"}
        
        try:
            response = await self._client.post(
                "/farcaster/reaction",
                json={
                    "signer_uuid": self.signer_uuid,
                    "reaction_type": "recast",
                    "target": cast_hash,
                }
            )
            
            return {
                "status": "success" if response.status_code == 200 else "error",
                "cast_hash": cast_hash
            }
            
        except Exception as e:
            return {"status": "error", "error": str(e)}
    
    async def follow(self, target_fid: int) -> dict[str, Any]:
        """
        Follow a user.
        
        Args:
            target_fid: FID of user to follow
            
        Returns:
            Follow result
        """
        if not self._client or not self.signer_uuid:
            return {"status": "error", "error": "Not configured"}
        
        try:
            response = await self._client.post(
                "/farcaster/user/follow",
                json={
                    "signer_uuid": self.signer_uuid,
                    "target_fids": [target_fid],
                }
            )
            
            return {
                "status": "success" if response.status_code == 200 else "error",
                "target_fid": target_fid
            }
            
        except Exception as e:
            return {"status": "error", "error": str(e)}
    
    # ==========================================================================
    # READING
    # ==========================================================================
    
    async def get_mentions(self, limit: int = 10) -> list[dict]:
        """
        Get recent mentions of the agent.
        
        Args:
            limit: Max mentions to return
            
        Returns:
            List of mention casts
        """
        if not self._client or not self.fid:
            return []
        
        try:
            response = await self._client.get(
                f"/farcaster/notifications",
                params={
                    "fid": self.fid,
                    "type": "mentions",
                    "limit": limit,
                }
            )
            
            if response.status_code == 200:
                data = response.json()
                return data.get("notifications", [])
                
        except Exception as e:
            logger.warning("voice.mentions_failed", error=str(e))
        
        return []
    
    async def get_timeline(self, limit: int = 20) -> list[dict]:
        """
        Get agent's home timeline.
        
        Args:
            limit: Max casts to return
            
        Returns:
            List of casts
        """
        if not self._client or not self.fid:
            return []
        
        try:
            response = await self._client.get(
                f"/farcaster/feed",
                params={
                    "fid": self.fid,
                    "limit": limit,
                }
            )
            
            if response.status_code == 200:
                data = response.json()
                return data.get("casts", [])
                
        except Exception as e:
            logger.warning("voice.timeline_failed", error=str(e))
        
        return []
    
    async def search_casts(
        self,
        query: str,
        limit: int = 10,
    ) -> list[dict]:
        """
        Search for casts.
        
        Args:
            query: Search query
            limit: Max results
            
        Returns:
            Matching casts
        """
        if not self._client:
            return []
        
        try:
            response = await self._client.get(
                "/farcaster/cast/search",
                params={
                    "q": query,
                    "limit": limit,
                }
            )
            
            if response.status_code == 200:
                data = response.json()
                return data.get("result", {}).get("casts", [])
                
        except Exception as e:
            logger.warning("voice.search_failed", error=str(e))
        
        return []
    
    async def get_user_by_username(self, username: str) -> Optional[dict]:
        """
        Get user info by username.
        
        Args:
            username: Farcaster username
            
        Returns:
            User info or None
        """
        if not self._client:
            return None
        
        try:
            response = await self._client.get(
                f"/farcaster/user/by_username",
                params={"username": username}
            )
            
            if response.status_code == 200:
                data = response.json()
                return data.get("user")
                
        except Exception as e:
            logger.warning("voice.user_lookup_failed", error=str(e))
        
        return None
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_status(self) -> dict[str, Any]:
        """Get voice status"""
        return {
            "fid": self.fid,
            "username": self.username,
            "display_name": self.display_name,
            "casts_posted": self.casts_posted,
            "replies_sent": self.replies_sent,
            "likes_given": self.likes_given,
        }
    
    async def close(self) -> None:
        """Cleanup resources"""
        if self._client:
            await self._client.aclose()
            self._client = None
        logger.info("voice.closed")
