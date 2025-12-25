"""
Configuration - Sovereign Agent
Pydantic-based settings management

Loads from environment variables with sensible defaults.
"""

import os
from typing import Optional
from pydantic_settings import BaseSettings
from pydantic import Field


class Config(BaseSettings):
    """
    Sovereign Agent Configuration
    
    All settings can be overridden via environment variables.
    Prefix: AGENT_ for most settings.
    
    Example:
        # .env file
        AGENT_NAME=aria
        OPENAI_API_KEY=sk-...
        CDP_API_KEY_NAME=...
    """
    
    # ==========================================================================
    # IDENTITY
    # ==========================================================================
    
    agent_name: str = Field(
        default="echo",
        description="Agent's name/identity"
    )
    
    agent_version: str = Field(
        default="1.0.0",
        description="Agent version"
    )
    
    # ==========================================================================
    # AI PROVIDERS
    # ==========================================================================
    
    # OpenAI
    openai_api_key: Optional[str] = Field(
        default=None,
        description="OpenAI API key for GPT models"
    )
    
    openai_model: str = Field(
        default="gpt-4o",
        description="Default OpenAI model"
    )
    
    # Anthropic
    anthropic_api_key: Optional[str] = Field(
        default=None,
        description="Anthropic API key for Claude"
    )
    
    anthropic_model: str = Field(
        default="claude-sonnet-4-20250514",
        description="Default Anthropic model"
    )
    
    # Google
    google_api_key: Optional[str] = Field(
        default=None,
        description="Google API key for Gemini"
    )
    
    # DeepSeek
    deepseek_api_key: Optional[str] = Field(
        default=None,
        description="DeepSeek API key"
    )
    
    # Perplexity
    perplexity_api_key: Optional[str] = Field(
        default=None,
        description="Perplexity API key for search"
    )
    
    # Ollama
    ollama_base_url: str = Field(
        default="http://localhost:11434",
        description="Ollama server URL"
    )
    
    # ==========================================================================
    # BLOCKCHAIN (BASE)
    # ==========================================================================
    
    # Coinbase Developer Platform
    cdp_api_key_name: Optional[str] = Field(
        default=None,
        description="CDP API key name"
    )
    
    cdp_api_key_private_key: Optional[str] = Field(
        default=None,
        description="CDP API key private key"
    )
    
    # Network
    network_id: str = Field(
        default="base-mainnet",
        description="Blockchain network ID"
    )
    
    base_rpc_url: str = Field(
        default="https://mainnet.base.org",
        description="Base RPC URL"
    )
    
    # Wallet
    wallet_file: str = Field(
        default="wallet_data.json",
        description="Path to wallet data file"
    )
    
    # ==========================================================================
    # SOCIAL
    # ==========================================================================
    
    # Farcaster (via Neynar)
    neynar_api_key: Optional[str] = Field(
        default=None,
        description="Neynar API key for Farcaster"
    )
    
    farcaster_signer_uuid: Optional[str] = Field(
        default=None,
        description="Farcaster signer UUID"
    )
    
    farcaster_fid: Optional[int] = Field(
        default=None,
        description="Farcaster FID"
    )
    
    # ==========================================================================
    # MESSAGING
    # ==========================================================================
    
    # XMTP
    xmtp_env: str = Field(
        default="production",
        description="XMTP environment (production/dev)"
    )
    
    # ==========================================================================
    # MEMORY
    # ==========================================================================
    
    # ChromaDB
    chroma_persist_dir: str = Field(
        default="./chroma_db",
        description="ChromaDB persistence directory"
    )
    
    chroma_collection: str = Field(
        default="agent_memory",
        description="ChromaDB collection name"
    )
    
    # ==========================================================================
    # DEFI
    # ==========================================================================
    
    # Aave
    aave_pool_address: str = Field(
        default="0xA238Dd80C259a72e81d7e4664a9801593F98d1c5",
        description="Aave V3 Pool on Base"
    )
    
    # Yield targets
    min_yield_apy: float = Field(
        default=2.0,
        description="Minimum acceptable APY"
    )
    
    max_position_size: float = Field(
        default=10000.0,
        description="Max single position in USDC"
    )
    
    # ==========================================================================
    # DEPIN
    # ==========================================================================
    
    # Mysterium (Bandwidth)
    mysterium_api: str = Field(
        default="http://localhost:4449",
        description="Local Mysterium node API"
    )
    
    # Fleek (Compute)
    fleek_api_key: Optional[str] = Field(
        default=None,
        description="Fleek API key"
    )
    
    # ==========================================================================
    # PHYSICAL LAYER
    # ==========================================================================
    
    # Iridium (Satellite)
    iridium_imei: Optional[str] = Field(
        default=None,
        description="Iridium modem IMEI"
    )
    
    iridium_port: str = Field(
        default="/dev/ttyUSB0",
        description="Iridium serial port"
    )
    
    # LoRa (Mesh)
    lora_port: str = Field(
        default="/dev/ttyUSB1",
        description="LoRa module serial port"
    )
    
    lora_frequency: float = Field(
        default=915.0,
        description="LoRa frequency in MHz"
    )
    
    # ==========================================================================
    # SERVER
    # ==========================================================================
    
    server_host: str = Field(
        default="0.0.0.0",
        description="Server bind host"
    )
    
    server_port: int = Field(
        default=8000,
        description="Server bind port"
    )
    
    # ==========================================================================
    # LOGGING
    # ==========================================================================
    
    log_level: str = Field(
        default="INFO",
        description="Logging level"
    )
    
    log_format: str = Field(
        default="json",
        description="Log format (json/console)"
    )
    
    # ==========================================================================
    # COLLECTIVE
    # ==========================================================================
    
    collective_enabled: bool = Field(
        default=False,
        description="Enable collective intelligence"
    )
    
    collective_peers: str = Field(
        default="",
        description="Comma-separated peer URLs"
    )
    
    node_role: str = Field(
        default="worker",
        description="Node role in collective (coordinator/worker/observer)"
    )
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False
        
    def get_peer_list(self) -> list[str]:
        """Parse peer URLs from comma-separated string"""
        if not self.collective_peers:
            return []
        return [p.strip() for p in self.collective_peers.split(",") if p.strip()]
    
    def is_mainnet(self) -> bool:
        """Check if running on mainnet"""
        return "mainnet" in self.network_id.lower()
    
    def has_wallet_credentials(self) -> bool:
        """Check if wallet credentials are configured"""
        return bool(self.cdp_api_key_name and self.cdp_api_key_private_key)
    
    def has_social_credentials(self) -> bool:
        """Check if social (Farcaster) credentials are configured"""
        return bool(self.neynar_api_key and self.farcaster_signer_uuid)
    
    def has_ai_credentials(self) -> bool:
        """Check if any AI provider is configured"""
        return bool(
            self.openai_api_key or 
            self.anthropic_api_key or 
            self.google_api_key or
            self.deepseek_api_key
        )


# Global config instance (lazy loaded)
_config: Optional[Config] = None


def get_config() -> Config:
    """Get or create global config instance"""
    global _config
    if _config is None:
        _config = Config()
    return _config
