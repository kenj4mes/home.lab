"""
Infinite Genome - Core Module
Neural Architecture Evolution

7.9M+ possible architectures across families and strategies.
"""

import hashlib
import random
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple

import structlog

logger = structlog.get_logger(__name__)


class ArchitectureFamily(str, Enum):
    """Architecture families"""
    TRANSFORMER = "transformer"
    SSM = "ssm"  # State Space Models
    RNN = "rnn"
    HYBRID = "hybrid"


class OptimizationStrategy(str, Enum):
    """Optimization strategies"""
    GRADIENT_DESCENT = "gradient_descent"
    EVOLUTIONARY = "evolutionary"
    BAYESIAN = "bayesian"
    RANDOM_SEARCH = "random_search"
    GRID_SEARCH = "grid_search"


class FitnessMetric(str, Enum):
    """Metrics for architecture fitness"""
    PERPLEXITY = "perplexity"
    LATENCY = "latency"
    MEMORY = "memory"
    ACCURACY = "accuracy"
    THROUGHPUT = "throughput"
    COST = "cost"


@dataclass
class Gene:
    """A single gene encoding an architecture parameter"""
    name: str
    value: Any
    min_value: Any = None
    max_value: Any = None
    choices: Optional[List[Any]] = None
    mutation_rate: float = 0.1


@dataclass 
class Chromosome:
    """A chromosome containing multiple genes"""
    genes: Dict[str, Gene] = field(default_factory=dict)
    fitness: float = 0.0
    generation: int = 0
    parent_ids: List[str] = field(default_factory=list)
    
    def get_genome_id(self) -> str:
        """Generate unique ID for this genome"""
        gene_str = str(sorted([(k, g.value) for k, g in self.genes.items()]))
        return hashlib.sha256(gene_str.encode()).hexdigest()[:12]


@dataclass
class ArchitectureSpec:
    """Specification for a neural architecture"""
    family: ArchitectureFamily
    layers: int
    hidden_size: int
    attention_heads: int = 0
    ff_multiplier: float = 4.0
    dropout: float = 0.1
    activation: str = "gelu"
    normalization: str = "layer_norm"
    context_length: int = 2048
    
    def param_count(self) -> int:
        """Estimate parameter count"""
        embed_params = self.hidden_size * 50000  # vocab size
        layer_params = self.layers * (
            4 * self.hidden_size * self.hidden_size +  # attention
            2 * self.hidden_size * int(self.hidden_size * self.ff_multiplier)  # FFN
        )
        return embed_params + layer_params


class InfiniteGenome:
    """
    Infinite Genome - Architecture Evolution
    
    Explores 7.9M+ architecture configurations through:
    - Genetic algorithms
    - Multi-objective optimization
    - Neural architecture search
    
    Example:
        >>> genome = InfiniteGenome()
        >>> await genome.initialize()
        >>> arch = await genome.generate_architecture()
        >>> await genome.evaluate_fitness(arch, metrics={...})
    """
    
    # Architecture search space
    LAYER_RANGE = (1, 64)
    HIDDEN_RANGE = (64, 8192)
    HEADS_RANGE = (1, 128)
    FF_RANGE = (1.0, 8.0)
    DROPOUT_RANGE = (0.0, 0.5)
    CONTEXT_RANGE = (512, 131072)
    
    ACTIVATIONS = ["gelu", "relu", "swish", "silu", "mish"]
    NORMALIZATIONS = ["layer_norm", "rms_norm", "batch_norm", "group_norm"]
    
    def __init__(
        self,
        population_size: int = 100,
        generations: int = 50,
        mutation_rate: float = 0.1,
        crossover_rate: float = 0.8,
        elite_ratio: float = 0.1,
    ):
        """
        Initialize Infinite Genome.
        
        Args:
            population_size: Number of architectures per generation
            generations: Number of evolution cycles
            mutation_rate: Probability of gene mutation
            crossover_rate: Probability of crossover
            elite_ratio: Top performers preserved
        """
        self.population_size = population_size
        self.generations = generations
        self.mutation_rate = mutation_rate
        self.crossover_rate = crossover_rate
        self.elite_ratio = elite_ratio
        
        # Evolution state
        self.population: List[Chromosome] = []
        self.best_ever: Optional[Chromosome] = None
        self.generation_count = 0
        
        # History
        self.fitness_history: List[float] = []
        self.architecture_log: List[Dict] = []
        
    async def initialize(self) -> None:
        """Initialize with random population"""
        self.population = [
            self._random_chromosome()
            for _ in range(self.population_size)
        ]
        
        logger.info("genome.initialized",
                   population=self.population_size,
                   search_space=self._estimate_search_space())
    
    def _estimate_search_space(self) -> int:
        """Estimate total search space size"""
        layers = self.LAYER_RANGE[1] - self.LAYER_RANGE[0]
        hidden = (self.HIDDEN_RANGE[1] - self.HIDDEN_RANGE[0]) // 64
        heads = self.HEADS_RANGE[1] - self.HEADS_RANGE[0]
        activations = len(self.ACTIVATIONS)
        normalizations = len(self.NORMALIZATIONS)
        families = len(ArchitectureFamily)
        
        return layers * hidden * heads * activations * normalizations * families
    
    def _random_chromosome(self) -> Chromosome:
        """Create random chromosome"""
        genes = {
            "family": Gene(
                name="family",
                value=random.choice(list(ArchitectureFamily)).value,
                choices=[f.value for f in ArchitectureFamily],
            ),
            "layers": Gene(
                name="layers",
                value=random.randint(*self.LAYER_RANGE),
                min_value=self.LAYER_RANGE[0],
                max_value=self.LAYER_RANGE[1],
            ),
            "hidden_size": Gene(
                name="hidden_size",
                value=random.choice([64, 128, 256, 512, 768, 1024, 2048, 4096]),
                min_value=self.HIDDEN_RANGE[0],
                max_value=self.HIDDEN_RANGE[1],
            ),
            "attention_heads": Gene(
                name="attention_heads",
                value=random.choice([1, 2, 4, 8, 12, 16, 32, 64]),
                min_value=self.HEADS_RANGE[0],
                max_value=self.HEADS_RANGE[1],
            ),
            "ff_multiplier": Gene(
                name="ff_multiplier",
                value=random.choice([2.0, 2.67, 4.0, 5.33, 8.0]),
                min_value=self.FF_RANGE[0],
                max_value=self.FF_RANGE[1],
            ),
            "dropout": Gene(
                name="dropout",
                value=round(random.uniform(*self.DROPOUT_RANGE), 2),
                min_value=self.DROPOUT_RANGE[0],
                max_value=self.DROPOUT_RANGE[1],
            ),
            "activation": Gene(
                name="activation",
                value=random.choice(self.ACTIVATIONS),
                choices=self.ACTIVATIONS,
            ),
            "normalization": Gene(
                name="normalization",
                value=random.choice(self.NORMALIZATIONS),
                choices=self.NORMALIZATIONS,
            ),
            "context_length": Gene(
                name="context_length",
                value=random.choice([512, 1024, 2048, 4096, 8192]),
                min_value=self.CONTEXT_RANGE[0],
                max_value=self.CONTEXT_RANGE[1],
            ),
        }
        
        return Chromosome(genes=genes)
    
    # ==========================================================================
    # ARCHITECTURE GENERATION
    # ==========================================================================
    
    async def generate_architecture(
        self,
        constraints: Optional[Dict] = None,
    ) -> ArchitectureSpec:
        """
        Generate a new architecture.
        
        Args:
            constraints: Optional constraints (max_params, max_latency, etc.)
            
        Returns:
            Architecture specification
        """
        # Use best chromosome or random
        chromosome = self.best_ever or random.choice(self.population)
        
        spec = ArchitectureSpec(
            family=ArchitectureFamily(chromosome.genes["family"].value),
            layers=chromosome.genes["layers"].value,
            hidden_size=chromosome.genes["hidden_size"].value,
            attention_heads=chromosome.genes["attention_heads"].value,
            ff_multiplier=chromosome.genes["ff_multiplier"].value,
            dropout=chromosome.genes["dropout"].value,
            activation=chromosome.genes["activation"].value,
            normalization=chromosome.genes["normalization"].value,
            context_length=chromosome.genes["context_length"].value,
        )
        
        # Apply constraints
        if constraints:
            max_params = constraints.get("max_params")
            if max_params and spec.param_count() > max_params:
                # Reduce architecture size
                while spec.param_count() > max_params and spec.layers > 1:
                    spec.layers -= 1
        
        self.architecture_log.append({
            "genome_id": chromosome.get_genome_id(),
            "spec": spec.__dict__,
            "params": spec.param_count(),
        })
        
        return spec
    
    def chromosome_to_spec(self, chromosome: Chromosome) -> ArchitectureSpec:
        """Convert chromosome to architecture spec"""
        return ArchitectureSpec(
            family=ArchitectureFamily(chromosome.genes["family"].value),
            layers=chromosome.genes["layers"].value,
            hidden_size=chromosome.genes["hidden_size"].value,
            attention_heads=chromosome.genes["attention_heads"].value,
            ff_multiplier=chromosome.genes["ff_multiplier"].value,
            dropout=chromosome.genes["dropout"].value,
            activation=chromosome.genes["activation"].value,
            normalization=chromosome.genes["normalization"].value,
            context_length=chromosome.genes["context_length"].value,
        )
    
    # ==========================================================================
    # EVOLUTION
    # ==========================================================================
    
    async def evolve(
        self,
        fitness_fn: Optional[Any] = None,
    ) -> Chromosome:
        """
        Run one generation of evolution.
        
        Args:
            fitness_fn: Optional async function to evaluate fitness
            
        Returns:
            Best chromosome
        """
        self.generation_count += 1
        
        # Evaluate fitness
        if fitness_fn:
            for chromosome in self.population:
                spec = self.chromosome_to_spec(chromosome)
                chromosome.fitness = await fitness_fn(spec)
        else:
            # Default fitness: inversely proportional to param count
            for chromosome in self.population:
                spec = self.chromosome_to_spec(chromosome)
                chromosome.fitness = 1.0 / (spec.param_count() / 1e9 + 0.1)
        
        # Sort by fitness
        self.population.sort(key=lambda c: c.fitness, reverse=True)
        
        # Update best ever
        if not self.best_ever or self.population[0].fitness > self.best_ever.fitness:
            self.best_ever = self.population[0]
        
        # Record history
        best_fitness = self.population[0].fitness
        self.fitness_history.append(best_fitness)
        
        # Selection and reproduction
        elite_count = int(self.population_size * self.elite_ratio)
        new_population = self.population[:elite_count]  # Keep elites
        
        # Fill rest with offspring
        while len(new_population) < self.population_size:
            # Tournament selection
            parent1 = self._tournament_select()
            parent2 = self._tournament_select()
            
            # Crossover
            if random.random() < self.crossover_rate:
                child = self._crossover(parent1, parent2)
            else:
                child = Chromosome(
                    genes={k: Gene(**g.__dict__) for k, g in parent1.genes.items()}
                )
            
            # Mutation
            child = self._mutate(child)
            child.generation = self.generation_count
            child.parent_ids = [parent1.get_genome_id(), parent2.get_genome_id()]
            
            new_population.append(child)
        
        self.population = new_population
        
        logger.info("genome.evolved",
                   generation=self.generation_count,
                   best_fitness=best_fitness,
                   best_id=self.best_ever.get_genome_id())
        
        return self.best_ever
    
    def _tournament_select(self, tournament_size: int = 3) -> Chromosome:
        """Tournament selection"""
        candidates = random.sample(self.population, min(tournament_size, len(self.population)))
        return max(candidates, key=lambda c: c.fitness)
    
    def _crossover(self, parent1: Chromosome, parent2: Chromosome) -> Chromosome:
        """Single-point crossover"""
        genes = {}
        gene_names = list(parent1.genes.keys())
        crossover_point = random.randint(0, len(gene_names))
        
        for i, name in enumerate(gene_names):
            source = parent1 if i < crossover_point else parent2
            genes[name] = Gene(**source.genes[name].__dict__)
        
        return Chromosome(genes=genes)
    
    def _mutate(self, chromosome: Chromosome) -> Chromosome:
        """Mutate genes"""
        for gene in chromosome.genes.values():
            if random.random() < self.mutation_rate:
                if gene.choices:
                    gene.value = random.choice(gene.choices)
                elif gene.min_value is not None and gene.max_value is not None:
                    if isinstance(gene.value, int):
                        gene.value = random.randint(gene.min_value, gene.max_value)
                    else:
                        gene.value = random.uniform(gene.min_value, gene.max_value)
        
        return chromosome
    
    # ==========================================================================
    # FITNESS EVALUATION
    # ==========================================================================
    
    async def evaluate_fitness(
        self,
        spec: ArchitectureSpec,
        metrics: Dict[str, float],
        weights: Optional[Dict[str, float]] = None,
    ) -> float:
        """
        Evaluate architecture fitness.
        
        Args:
            spec: Architecture to evaluate
            metrics: Measured metrics (perplexity, latency, etc.)
            weights: Optional metric weights
            
        Returns:
            Fitness score
        """
        weights = weights or {
            FitnessMetric.PERPLEXITY.value: -0.4,  # Lower is better
            FitnessMetric.LATENCY.value: -0.2,
            FitnessMetric.MEMORY.value: -0.1,
            FitnessMetric.ACCURACY.value: 0.2,
            FitnessMetric.THROUGHPUT.value: 0.1,
        }
        
        fitness = 0.0
        for metric, value in metrics.items():
            weight = weights.get(metric, 0.0)
            # Normalize to 0-1 range (approximate)
            normalized = min(1.0, max(0.0, value / 100.0))
            fitness += weight * normalized
        
        return fitness
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_best_architectures(self, n: int = 5) -> List[Dict]:
        """Get top N architectures"""
        sorted_pop = sorted(self.population, key=lambda c: c.fitness, reverse=True)
        
        return [
            {
                "genome_id": c.get_genome_id(),
                "fitness": c.fitness,
                "generation": c.generation,
                "spec": self.chromosome_to_spec(c).__dict__,
                "params": self.chromosome_to_spec(c).param_count(),
            }
            for c in sorted_pop[:n]
        ]
    
    def get_evolution_stats(self) -> Dict[str, Any]:
        """Get evolution statistics"""
        return {
            "generation": self.generation_count,
            "population_size": len(self.population),
            "best_fitness": self.best_ever.fitness if self.best_ever else 0,
            "best_genome_id": self.best_ever.get_genome_id() if self.best_ever else None,
            "fitness_history": self.fitness_history[-50:],
            "search_space": self._estimate_search_space(),
        }
    
    async def close(self) -> None:
        """Cleanup"""
        self.population.clear()
        logger.info("genome.closed")
