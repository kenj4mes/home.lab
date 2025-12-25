"""
Model Registry - Core Module
AI Model Configuration and Management

Manages connections to multiple AI providers.
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional

import structlog

logger = structlog.get_logger(__name__)


class Provider(str, Enum):
    """AI model providers"""
    ANTHROPIC = "anthropic"
    OPENAI = "openai"
    DEEPSEEK = "deepseek"
    GOOGLE = "google"
    PERPLEXITY = "perplexity"
    OLLAMA = "ollama"


class Capability(str, Enum):
    """Model capabilities"""
    TEXT_GENERATION = "text_generation"
    CODE_GENERATION = "code_generation"
    VISION = "vision"
    FUNCTION_CALLING = "function_calling"
    EMBEDDING = "embedding"
    REASONING = "reasoning"
    SEARCH = "search"


@dataclass
class ModelConfig:
    """Configuration for a model"""
    id: str
    provider: Provider
    name: str
    capabilities: List[Capability]
    context_length: int = 4096
    max_output: int = 4096
    temperature: float = 0.7
    cost_per_1k_input: float = 0.0
    cost_per_1k_output: float = 0.0
    api_key_env: Optional[str] = None
    base_url: Optional[str] = None


# ==========================================================================
# DEFAULT MODELS
# ==========================================================================

DEFAULT_MODELS = [
    # Anthropic
    ModelConfig(
        id="claude-sonnet",
        provider=Provider.ANTHROPIC,
        name="claude-sonnet-4-20250514",
        capabilities=[
            Capability.TEXT_GENERATION,
            Capability.CODE_GENERATION,
            Capability.VISION,
            Capability.FUNCTION_CALLING,
            Capability.REASONING,
        ],
        context_length=200000,
        max_output=64000,
        cost_per_1k_input=0.003,
        cost_per_1k_output=0.015,
        api_key_env="ANTHROPIC_API_KEY",
    ),
    ModelConfig(
        id="claude-opus",
        provider=Provider.ANTHROPIC,
        name="claude-opus-4-20250514",
        capabilities=[
            Capability.TEXT_GENERATION,
            Capability.CODE_GENERATION,
            Capability.VISION,
            Capability.FUNCTION_CALLING,
            Capability.REASONING,
        ],
        context_length=200000,
        max_output=32000,
        cost_per_1k_input=0.015,
        cost_per_1k_output=0.075,
        api_key_env="ANTHROPIC_API_KEY",
    ),
    
    # OpenAI
    ModelConfig(
        id="gpt-4o",
        provider=Provider.OPENAI,
        name="gpt-4o",
        capabilities=[
            Capability.TEXT_GENERATION,
            Capability.CODE_GENERATION,
            Capability.VISION,
            Capability.FUNCTION_CALLING,
        ],
        context_length=128000,
        max_output=16384,
        cost_per_1k_input=0.005,
        cost_per_1k_output=0.015,
        api_key_env="OPENAI_API_KEY",
    ),
    ModelConfig(
        id="gpt-4o-mini",
        provider=Provider.OPENAI,
        name="gpt-4o-mini",
        capabilities=[
            Capability.TEXT_GENERATION,
            Capability.CODE_GENERATION,
            Capability.VISION,
            Capability.FUNCTION_CALLING,
        ],
        context_length=128000,
        max_output=16384,
        cost_per_1k_input=0.00015,
        cost_per_1k_output=0.0006,
        api_key_env="OPENAI_API_KEY",
    ),
    ModelConfig(
        id="o1",
        provider=Provider.OPENAI,
        name="o1",
        capabilities=[
            Capability.TEXT_GENERATION,
            Capability.CODE_GENERATION,
            Capability.REASONING,
        ],
        context_length=200000,
        max_output=100000,
        cost_per_1k_input=0.015,
        cost_per_1k_output=0.06,
        api_key_env="OPENAI_API_KEY",
    ),
    
    # DeepSeek
    ModelConfig(
        id="deepseek-chat",
        provider=Provider.DEEPSEEK,
        name="deepseek-chat",
        capabilities=[
            Capability.TEXT_GENERATION,
            Capability.CODE_GENERATION,
            Capability.FUNCTION_CALLING,
        ],
        context_length=64000,
        max_output=8192,
        cost_per_1k_input=0.00014,
        cost_per_1k_output=0.00028,
        api_key_env="DEEPSEEK_API_KEY",
        base_url="https://api.deepseek.com",
    ),
    ModelConfig(
        id="deepseek-reasoner",
        provider=Provider.DEEPSEEK,
        name="deepseek-reasoner",
        capabilities=[
            Capability.TEXT_GENERATION,
            Capability.CODE_GENERATION,
            Capability.REASONING,
        ],
        context_length=64000,
        max_output=8192,
        cost_per_1k_input=0.00055,
        cost_per_1k_output=0.00219,
        api_key_env="DEEPSEEK_API_KEY",
        base_url="https://api.deepseek.com",
    ),
    
    # Google
    ModelConfig(
        id="gemini-2-flash",
        provider=Provider.GOOGLE,
        name="gemini-2.0-flash",
        capabilities=[
            Capability.TEXT_GENERATION,
            Capability.CODE_GENERATION,
            Capability.VISION,
            Capability.FUNCTION_CALLING,
        ],
        context_length=1000000,
        max_output=8192,
        cost_per_1k_input=0.0001,
        cost_per_1k_output=0.0004,
        api_key_env="GOOGLE_API_KEY",
    ),
    
    # Perplexity
    ModelConfig(
        id="sonar-pro",
        provider=Provider.PERPLEXITY,
        name="sonar-pro",
        capabilities=[
            Capability.TEXT_GENERATION,
            Capability.SEARCH,
        ],
        context_length=200000,
        max_output=8000,
        cost_per_1k_input=0.003,
        cost_per_1k_output=0.015,
        api_key_env="PERPLEXITY_API_KEY",
        base_url="https://api.perplexity.ai",
    ),
    
    # Ollama (local)
    ModelConfig(
        id="llama3",
        provider=Provider.OLLAMA,
        name="llama3",
        capabilities=[
            Capability.TEXT_GENERATION,
            Capability.CODE_GENERATION,
        ],
        context_length=8192,
        max_output=4096,
        cost_per_1k_input=0.0,
        cost_per_1k_output=0.0,
        base_url="http://localhost:11434",
    ),
    ModelConfig(
        id="qwen2.5-coder",
        provider=Provider.OLLAMA,
        name="qwen2.5-coder:7b",
        capabilities=[
            Capability.TEXT_GENERATION,
            Capability.CODE_GENERATION,
        ],
        context_length=32768,
        max_output=8192,
        cost_per_1k_input=0.0,
        cost_per_1k_output=0.0,
        base_url="http://localhost:11434",
    ),
]


class ModelRegistry:
    """
    Model Registry - AI Model Management
    
    Manages configuration and selection of AI models from
    multiple providers.
    
    Example:
        >>> registry = ModelRegistry()
        >>> await registry.initialize()
        >>> model = registry.get_model("claude-sonnet")
        >>> model = registry.select_for_capability(Capability.VISION)
    """
    
    def __init__(self):
        """Initialize registry"""
        self.models: Dict[str, ModelConfig] = {}
        self.api_keys: Dict[Provider, Optional[str]] = {}
        self._default_model: Optional[str] = None
        
    async def initialize(self) -> None:
        """Initialize with default models"""
        import os
        
        # Register default models
        for model in DEFAULT_MODELS:
            self.register_model(model)
        
        # Load API keys from environment
        self.api_keys = {
            Provider.ANTHROPIC: os.getenv("ANTHROPIC_API_KEY"),
            Provider.OPENAI: os.getenv("OPENAI_API_KEY"),
            Provider.DEEPSEEK: os.getenv("DEEPSEEK_API_KEY"),
            Provider.GOOGLE: os.getenv("GOOGLE_API_KEY"),
            Provider.PERPLEXITY: os.getenv("PERPLEXITY_API_KEY"),
            Provider.OLLAMA: None,  # No key needed
        }
        
        # Set default model
        self._default_model = "claude-sonnet"
        
        logger.info("registry.initialized",
                   models=len(self.models),
                   providers=len([p for p, k in self.api_keys.items() if k or p == Provider.OLLAMA]))
    
    def register_model(self, config: ModelConfig) -> None:
        """
        Register a model configuration.
        
        Args:
            config: Model configuration
        """
        self.models[config.id] = config
        logger.debug("registry.model_registered", id=config.id, provider=config.provider.value)
    
    def get_model(self, model_id: str) -> Optional[ModelConfig]:
        """
        Get model configuration by ID.
        
        Args:
            model_id: Model identifier
            
        Returns:
            Model config or None
        """
        return self.models.get(model_id)
    
    def get_default_model(self) -> Optional[ModelConfig]:
        """Get default model"""
        if self._default_model:
            return self.models.get(self._default_model)
        return None
    
    def set_default_model(self, model_id: str) -> bool:
        """Set default model"""
        if model_id in self.models:
            self._default_model = model_id
            return True
        return False
    
    # ==========================================================================
    # MODEL SELECTION
    # ==========================================================================
    
    def select_for_capability(
        self,
        capability: Capability,
        prefer_cheap: bool = False,
    ) -> Optional[ModelConfig]:
        """
        Select model with specified capability.
        
        Args:
            capability: Required capability
            prefer_cheap: Prefer lower cost
            
        Returns:
            Best matching model
        """
        candidates = [
            m for m in self.models.values()
            if capability in m.capabilities
            and self._is_available(m)
        ]
        
        if not candidates:
            return None
        
        if prefer_cheap:
            return min(candidates, key=lambda m: m.cost_per_1k_input)
        else:
            # Prefer by context length
            return max(candidates, key=lambda m: m.context_length)
    
    def select_for_task(
        self,
        task: str,
        context_needed: int = 0,
        prefer_cheap: bool = False,
    ) -> Optional[ModelConfig]:
        """
        Select best model for a task.
        
        Args:
            task: Task description (code, vision, reasoning, search)
            context_needed: Minimum context length needed
            prefer_cheap: Prefer lower cost
            
        Returns:
            Best model for task
        """
        # Map task to capability
        task_mapping = {
            "code": Capability.CODE_GENERATION,
            "vision": Capability.VISION,
            "reasoning": Capability.REASONING,
            "search": Capability.SEARCH,
            "embed": Capability.EMBEDDING,
        }
        
        capability = task_mapping.get(task.lower(), Capability.TEXT_GENERATION)
        
        candidates = [
            m for m in self.models.values()
            if capability in m.capabilities
            and m.context_length >= context_needed
            and self._is_available(m)
        ]
        
        if not candidates:
            # Fall back to any available model
            candidates = [m for m in self.models.values() if self._is_available(m)]
        
        if not candidates:
            return None
        
        if prefer_cheap:
            return min(candidates, key=lambda m: m.cost_per_1k_input)
        else:
            return max(candidates, key=lambda m: m.context_length)
    
    def _is_available(self, model: ModelConfig) -> bool:
        """Check if model is available (has API key)"""
        if model.provider == Provider.OLLAMA:
            return True  # Assume local is available
        return self.api_keys.get(model.provider) is not None
    
    # ==========================================================================
    # PROVIDER ACCESS
    # ==========================================================================
    
    def get_api_key(self, provider: Provider) -> Optional[str]:
        """Get API key for provider"""
        return self.api_keys.get(provider)
    
    def set_api_key(self, provider: Provider, key: str) -> None:
        """Set API key for provider"""
        self.api_keys[provider] = key
    
    def get_available_providers(self) -> List[Provider]:
        """Get list of available providers"""
        return [
            p for p in Provider
            if self.api_keys.get(p) or p == Provider.OLLAMA
        ]
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def list_models(
        self,
        provider: Optional[Provider] = None,
        capability: Optional[Capability] = None,
    ) -> List[ModelConfig]:
        """
        List models with optional filtering.
        
        Args:
            provider: Filter by provider
            capability: Filter by capability
            
        Returns:
            List of matching models
        """
        models = list(self.models.values())
        
        if provider:
            models = [m for m in models if m.provider == provider]
        
        if capability:
            models = [m for m in models if capability in m.capabilities]
        
        return models
    
    def estimate_cost(
        self,
        model_id: str,
        input_tokens: int,
        output_tokens: int,
    ) -> float:
        """
        Estimate cost for a request.
        
        Args:
            model_id: Model to use
            input_tokens: Input token count
            output_tokens: Output token count
            
        Returns:
            Estimated cost in USD
        """
        model = self.get_model(model_id)
        if not model:
            return 0.0
        
        input_cost = (input_tokens / 1000) * model.cost_per_1k_input
        output_cost = (output_tokens / 1000) * model.cost_per_1k_output
        
        return input_cost + output_cost
    
    def get_status(self) -> Dict[str, Any]:
        """Get registry status"""
        return {
            "total_models": len(self.models),
            "available_providers": [p.value for p in self.get_available_providers()],
            "default_model": self._default_model,
            "models_by_provider": {
                p.value: len([m for m in self.models.values() if m.provider == p])
                for p in Provider
            },
        }
    
    async def close(self) -> None:
        """Cleanup"""
        self.models.clear()
        logger.info("registry.closed")
