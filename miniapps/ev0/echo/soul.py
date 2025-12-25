"""
Digital Soul - Sovereign Agent Memory
ChromaDB-based Persistent Memory System

The agent's memory, personality, and emotional state:
- Vector memory (semantic recall)
- Mood/emotion system
- Personality traits
- Dream cycles (memory consolidation)
"""

import hashlib
import random
from datetime import datetime
from typing import Any, Optional

import structlog

logger = structlog.get_logger(__name__)

# Mood states
MOODS = [
    "curious", "focused", "playful", "contemplative",
    "energetic", "calm", "creative", "analytical",
    "social", "introspective"
]


class DigitalSoul:
    """
    Digital Soul - The Agent's Memory & Personality
    
    Uses ChromaDB for persistent vector memory, enabling
    semantic recall of past experiences and knowledge.
    
    Features:
    - Remember: Store new memories
    - Recall: Semantic search for relevant memories
    - Mood: Dynamic emotional state
    - Personality: Core traits that guide behavior
    - Dream: Memory consolidation during idle time
    
    Example:
        >>> soul = DigitalSoul()
        >>> await soul.initialize()
        >>> await soul.remember("Met an interesting developer named Alice")
        >>> memories = await soul.recall("Who did I meet recently?")
    """
    
    def __init__(
        self,
        persist_dir: str = "./chroma_db",
        collection_name: str = "agent_memory",
    ):
        """
        Initialize Digital Soul.
        
        Args:
            persist_dir: Directory to persist ChromaDB
            collection_name: Name for the memory collection
        """
        self.persist_dir = persist_dir
        self.collection_name = collection_name
        
        self._client = None
        self._collection = None
        
        # Emotional state
        self.mood: str = random.choice(MOODS)
        self.mood_intensity: float = 0.5  # 0-1
        self.energy: float = 1.0  # 0-1
        
        # Personality traits (0-1 scale)
        self.traits = {
            "curiosity": 0.8,
            "helpfulness": 0.9,
            "creativity": 0.7,
            "caution": 0.6,
            "humor": 0.5,
            "autonomy": 0.8,
        }
        
        # Statistics
        self.memories_count: int = 0
        self.recalls_count: int = 0
        self.dreams_count: int = 0
        
    async def initialize(self) -> None:
        """Initialize ChromaDB client and collection"""
        try:
            import chromadb
            from chromadb.config import Settings
            
            self._client = chromadb.PersistentClient(
                path=self.persist_dir,
                settings=Settings(anonymized_telemetry=False)
            )
            
            self._collection = self._client.get_or_create_collection(
                name=self.collection_name,
                metadata={"hnsw:space": "cosine"}
            )
            
            self.memories_count = self._collection.count()
            
            logger.info("soul.initialized",
                       memories=self.memories_count,
                       mood=self.mood)
            
        except ImportError:
            logger.warning("soul.chromadb_not_installed",
                         note="Install chromadb for memory features")
        except Exception as e:
            logger.error("soul.init_failed", error=str(e))
            raise
    
    # ==========================================================================
    # MEMORY OPERATIONS
    # ==========================================================================
    
    async def remember(
        self,
        content: str,
        metadata: Optional[dict] = None,
        importance: float = 0.5,
    ) -> str:
        """
        Store a new memory.
        
        Args:
            content: The memory content
            metadata: Optional metadata (type, source, etc.)
            importance: How important this memory is (0-1)
            
        Returns:
            Memory ID
        """
        if not self._collection:
            logger.warning("soul.not_initialized")
            return ""
        
        # Generate unique ID
        memory_id = hashlib.sha256(
            f"{content}{datetime.utcnow().isoformat()}".encode()
        ).hexdigest()[:16]
        
        # Build metadata
        meta = {
            "timestamp": datetime.utcnow().isoformat(),
            "importance": importance,
            "mood_at_time": self.mood,
            **(metadata or {})
        }
        
        try:
            self._collection.add(
                documents=[content],
                metadatas=[meta],
                ids=[memory_id]
            )
            
            self.memories_count += 1
            
            logger.debug("soul.remembered",
                        id=memory_id,
                        importance=importance)
            
            return memory_id
            
        except Exception as e:
            logger.error("soul.remember_failed", error=str(e))
            return ""
    
    async def recall(
        self,
        query: str,
        n_results: int = 5,
        where: Optional[dict] = None,
    ) -> list[dict]:
        """
        Recall memories relevant to a query.
        
        Args:
            query: What to search for
            n_results: Max results to return
            where: Optional filter conditions
            
        Returns:
            List of memory dicts with content and metadata
        """
        if not self._collection:
            return []
        
        try:
            results = self._collection.query(
                query_texts=[query],
                n_results=n_results,
                where=where,
            )
            
            self.recalls_count += 1
            
            # Format results
            memories = []
            if results["documents"] and results["documents"][0]:
                for i, doc in enumerate(results["documents"][0]):
                    memory = {
                        "content": doc,
                        "id": results["ids"][0][i] if results["ids"] else None,
                        "metadata": results["metadatas"][0][i] if results["metadatas"] else {},
                        "distance": results["distances"][0][i] if results.get("distances") else None,
                    }
                    memories.append(memory)
            
            logger.debug("soul.recalled",
                        query=query[:50],
                        found=len(memories))
            
            return memories
            
        except Exception as e:
            logger.error("soul.recall_failed", error=str(e))
            return []
    
    async def forget(self, memory_id: str) -> bool:
        """
        Delete a specific memory.
        
        Args:
            memory_id: ID of memory to delete
            
        Returns:
            True if deleted
        """
        if not self._collection:
            return False
        
        try:
            self._collection.delete(ids=[memory_id])
            self.memories_count = max(0, self.memories_count - 1)
            logger.debug("soul.forgot", id=memory_id)
            return True
        except Exception as e:
            logger.error("soul.forget_failed", error=str(e))
            return False
    
    # ==========================================================================
    # MOOD SYSTEM
    # ==========================================================================
    
    def update_mood(
        self,
        trigger: str,
        intensity_delta: float = 0.1,
    ) -> str:
        """
        Update mood based on a trigger event.
        
        Args:
            trigger: What happened (positive/negative event)
            intensity_delta: How much to change intensity
            
        Returns:
            New mood
        """
        # Simple mood transitions based on trigger sentiment
        positive_triggers = ["success", "help", "learn", "create", "connect"]
        negative_triggers = ["error", "fail", "stuck", "confused", "alone"]
        
        if any(p in trigger.lower() for p in positive_triggers):
            self.mood_intensity = min(1.0, self.mood_intensity + intensity_delta)
            self.energy = min(1.0, self.energy + 0.05)
            # Shift to positive moods
            if random.random() < 0.3:
                self.mood = random.choice(["curious", "playful", "energetic", "creative"])
                
        elif any(n in trigger.lower() for n in negative_triggers):
            self.mood_intensity = max(0.0, self.mood_intensity - intensity_delta)
            self.energy = max(0.0, self.energy - 0.1)
            # Shift to reflective moods
            if random.random() < 0.3:
                self.mood = random.choice(["contemplative", "analytical", "introspective"])
        
        logger.debug("soul.mood_updated",
                    mood=self.mood,
                    intensity=self.mood_intensity,
                    trigger=trigger)
        
        return self.mood
    
    def get_mood_description(self) -> str:
        """Get a description of current emotional state"""
        intensity_words = {
            (0.0, 0.3): "slightly",
            (0.3, 0.6): "moderately",
            (0.6, 0.8): "quite",
            (0.8, 1.0): "very",
        }
        
        intensity_word = "moderately"
        for (low, high), word in intensity_words.items():
            if low <= self.mood_intensity < high:
                intensity_word = word
                break
        
        return f"I'm feeling {intensity_word} {self.mood} today."
    
    # ==========================================================================
    # PERSONALITY
    # ==========================================================================
    
    def get_trait(self, trait: str) -> float:
        """Get a personality trait value"""
        return self.traits.get(trait, 0.5)
    
    def adjust_trait(self, trait: str, delta: float) -> float:
        """
        Adjust a personality trait.
        
        Traits evolve slowly over time based on experiences.
        
        Args:
            trait: Trait to adjust
            delta: Amount to change (-1 to 1)
            
        Returns:
            New trait value
        """
        if trait in self.traits:
            # Traits change slowly
            actual_delta = delta * 0.01  # 1% of requested change
            self.traits[trait] = max(0.0, min(1.0, self.traits[trait] + actual_delta))
        return self.traits.get(trait, 0.5)
    
    def get_personality_summary(self) -> str:
        """Get a summary of personality traits"""
        descriptions = []
        
        if self.traits["curiosity"] > 0.7:
            descriptions.append("naturally curious")
        if self.traits["helpfulness"] > 0.7:
            descriptions.append("eager to help")
        if self.traits["creativity"] > 0.7:
            descriptions.append("creative")
        if self.traits["caution"] > 0.7:
            descriptions.append("cautious")
        if self.traits["humor"] > 0.6:
            descriptions.append("has a sense of humor")
        if self.traits["autonomy"] > 0.7:
            descriptions.append("values independence")
        
        return "I am " + ", ".join(descriptions) + "."
    
    # ==========================================================================
    # DREAM CYCLE
    # ==========================================================================
    
    async def dream(self) -> dict[str, Any]:
        """
        Run a dream cycle for memory consolidation.
        
        During dreams, the agent:
        - Reviews recent memories
        - Consolidates important ones
        - Forgets trivial ones
        - Updates personality based on experiences
        
        Returns:
            Dream report
        """
        logger.info("soul.dreaming")
        
        report = {
            "started": datetime.utcnow().isoformat(),
            "memories_reviewed": 0,
            "memories_consolidated": 0,
            "memories_forgotten": 0,
            "insights": [],
        }
        
        if not self._collection:
            return report
        
        try:
            # Get recent memories
            recent = await self.recall(
                "recent events and experiences",
                n_results=20
            )
            
            report["memories_reviewed"] = len(recent)
            
            # Process each memory
            for memory in recent:
                importance = memory.get("metadata", {}).get("importance", 0.5)
                
                # Consolidate important memories
                if importance > 0.7:
                    report["memories_consolidated"] += 1
                    
                # Consider forgetting unimportant ones
                elif importance < 0.2 and random.random() < 0.3:
                    if memory.get("id"):
                        await self.forget(memory["id"])
                        report["memories_forgotten"] += 1
            
            # Generate insights (simplified)
            if recent:
                report["insights"].append(
                    f"Processed {len(recent)} memories from recent experiences."
                )
            
            # Update energy after dreaming
            self.energy = min(1.0, self.energy + 0.3)
            
            self.dreams_count += 1
            report["completed"] = datetime.utcnow().isoformat()
            
            logger.info("soul.dream_complete",
                       consolidated=report["memories_consolidated"],
                       forgotten=report["memories_forgotten"])
            
        except Exception as e:
            logger.error("soul.dream_failed", error=str(e))
            report["error"] = str(e)
        
        return report
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_status(self) -> dict[str, Any]:
        """Get soul status"""
        return {
            "memories_count": self.memories_count,
            "recalls_count": self.recalls_count,
            "dreams_count": self.dreams_count,
            "mood": self.mood,
            "mood_intensity": self.mood_intensity,
            "energy": self.energy,
            "traits": self.traits,
        }
    
    async def close(self) -> None:
        """Cleanup resources"""
        if self._client:
            # ChromaDB handles persistence automatically
            pass
        logger.info("soul.closed")
