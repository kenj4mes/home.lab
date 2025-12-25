"""
Swarm Intelligence - Sovereign Agent
LangGraph-based Multi-Agent Coordination

The agent's ability to spawn and coordinate multiple workers:
- Supervisor agent for task distribution
- Worker agents for parallel execution
- Shared memory/state
"""

import asyncio
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Optional

import structlog

logger = structlog.get_logger(__name__)


class WorkerState(str, Enum):
    """Worker agent states"""
    IDLE = "idle"
    WORKING = "working"
    COMPLETED = "completed"
    FAILED = "failed"


@dataclass
class Task:
    """A task to be executed by a worker"""
    task_id: str
    description: str
    assigned_to: Optional[str] = None
    status: str = "pending"
    result: Any = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    completed_at: Optional[datetime] = None


class WorkerAgent:
    """
    Worker Agent - Specialized Task Executor
    
    A lightweight agent that executes specific tasks
    under supervision of the swarm.
    """
    
    def __init__(
        self,
        name: str,
        specialty: str,
        llm: Any = None,
    ):
        """
        Initialize Worker Agent.
        
        Args:
            name: Worker identifier
            specialty: What this worker is good at
            llm: Language model for reasoning
        """
        self.name = name
        self.specialty = specialty
        self.llm = llm
        
        self.state = WorkerState.IDLE
        self.current_task: Optional[Task] = None
        self.tasks_completed: int = 0
        
    async def execute(self, task: Task) -> Any:
        """
        Execute a task.
        
        Args:
            task: Task to execute
            
        Returns:
            Task result
        """
        self.state = WorkerState.WORKING
        self.current_task = task
        
        logger.info("worker.executing",
                   worker=self.name,
                   task=task.task_id)
        
        try:
            if self.llm:
                # Use LLM for reasoning
                prompt = f"""You are {self.name}, a worker specializing in {self.specialty}.

Task: {task.description}

Execute this task and provide the result."""
                
                response = await self.llm.ainvoke(prompt)
                result = response.content
            else:
                # Simple execution
                result = f"Task '{task.description}' completed by {self.name}"
            
            self.state = WorkerState.COMPLETED
            self.tasks_completed += 1
            
            return result
            
        except Exception as e:
            self.state = WorkerState.FAILED
            logger.error("worker.failed",
                        worker=self.name,
                        error=str(e))
            raise
        finally:
            self.current_task = None
    
    def get_status(self) -> dict:
        """Get worker status"""
        return {
            "name": self.name,
            "specialty": self.specialty,
            "state": self.state.value,
            "tasks_completed": self.tasks_completed,
            "current_task": self.current_task.task_id if self.current_task else None,
        }


class Swarm:
    """
    Swarm - Multi-Agent Coordinator
    
    Uses LangGraph patterns for coordinating multiple worker agents.
    
    Features:
    - Task distribution
    - Parallel execution
    - Result aggregation
    - Worker management
    
    Example:
        >>> swarm = Swarm(llm=llm)
        >>> swarm.add_worker("researcher", "research and analysis")
        >>> swarm.add_worker("writer", "content creation")
        >>> result = await swarm.execute("Write a report about Base ecosystem")
    """
    
    def __init__(
        self,
        llm: Any = None,
        max_workers: int = 5,
    ):
        """
        Initialize Swarm.
        
        Args:
            llm: Language model for supervisor
            max_workers: Maximum concurrent workers
        """
        self.llm = llm
        self.max_workers = max_workers
        
        self.workers: dict[str, WorkerAgent] = {}
        self.task_queue: list[Task] = []
        self.completed_tasks: list[Task] = []
        
        self._running = False
        
    def add_worker(
        self,
        name: str,
        specialty: str,
    ) -> WorkerAgent:
        """
        Add a worker to the swarm.
        
        Args:
            name: Worker name
            specialty: Worker's specialization
            
        Returns:
            The created worker
        """
        if len(self.workers) >= self.max_workers:
            raise ValueError(f"Max workers ({self.max_workers}) reached")
        
        worker = WorkerAgent(
            name=name,
            specialty=specialty,
            llm=self.llm
        )
        
        self.workers[name] = worker
        
        logger.info("swarm.worker_added",
                   name=name,
                   specialty=specialty)
        
        return worker
    
    def remove_worker(self, name: str) -> bool:
        """
        Remove a worker from the swarm.
        
        Args:
            name: Worker to remove
            
        Returns:
            True if removed
        """
        if name in self.workers:
            del self.workers[name]
            return True
        return False
    
    # ==========================================================================
    # TASK EXECUTION
    # ==========================================================================
    
    async def execute(
        self,
        objective: str,
        max_iterations: int = 5,
    ) -> dict[str, Any]:
        """
        Execute an objective using the swarm.
        
        The supervisor breaks down the objective into tasks,
        assigns them to workers, and aggregates results.
        
        Args:
            objective: High-level objective to achieve
            max_iterations: Max planning iterations
            
        Returns:
            Execution result
        """
        logger.info("swarm.executing", objective=objective[:50] + "...")
        
        # Plan tasks
        tasks = await self._plan_tasks(objective)
        
        if not tasks:
            return {
                "status": "error",
                "error": "Could not plan tasks"
            }
        
        # Execute tasks
        results = await self._execute_tasks(tasks)
        
        # Aggregate results
        final_result = await self._aggregate_results(objective, results)
        
        return {
            "status": "success",
            "objective": objective,
            "tasks_executed": len(results),
            "result": final_result,
        }
    
    async def _plan_tasks(self, objective: str) -> list[Task]:
        """Plan tasks for objective"""
        tasks = []
        
        if not self.llm:
            # Simple single task
            tasks.append(Task(
                task_id="task_0",
                description=objective
            ))
            return tasks
        
        # Use LLM to break down objective
        worker_list = ", ".join([
            f"{w.name} ({w.specialty})" 
            for w in self.workers.values()
        ])
        
        prompt = f"""Break down this objective into tasks for workers.

Objective: {objective}

Available workers: {worker_list}

Output a list of tasks, one per line, in format:
TASK: [worker_name] - [task description]
"""
        
        try:
            response = await self.llm.ainvoke(prompt)
            content = response.content
            
            # Parse tasks
            for i, line in enumerate(content.split("\n")):
                if line.startswith("TASK:"):
                    parts = line[5:].strip().split(" - ", 1)
                    worker_name = parts[0].strip() if parts else None
                    description = parts[1].strip() if len(parts) > 1 else line
                    
                    task = Task(
                        task_id=f"task_{i}",
                        description=description,
                        assigned_to=worker_name if worker_name in self.workers else None
                    )
                    tasks.append(task)
                    
        except Exception as e:
            logger.error("swarm.planning_failed", error=str(e))
        
        return tasks or [Task(task_id="task_0", description=objective)]
    
    async def _execute_tasks(self, tasks: list[Task]) -> list[dict]:
        """Execute tasks in parallel"""
        results = []
        
        # Group tasks by worker
        worker_tasks: dict[str, list[Task]] = {}
        unassigned: list[Task] = []
        
        for task in tasks:
            if task.assigned_to and task.assigned_to in self.workers:
                worker_tasks.setdefault(task.assigned_to, []).append(task)
            else:
                unassigned.append(task)
        
        # Distribute unassigned tasks
        available_workers = list(self.workers.keys())
        for i, task in enumerate(unassigned):
            if available_workers:
                worker = available_workers[i % len(available_workers)]
                task.assigned_to = worker
                worker_tasks.setdefault(worker, []).append(task)
        
        # Execute in parallel
        async def run_worker_tasks(worker_name: str, tasks: list[Task]) -> list[dict]:
            worker = self.workers[worker_name]
            worker_results = []
            
            for task in tasks:
                try:
                    result = await worker.execute(task)
                    task.status = "completed"
                    task.result = result
                    task.completed_at = datetime.utcnow()
                    
                    worker_results.append({
                        "task_id": task.task_id,
                        "worker": worker_name,
                        "status": "success",
                        "result": result
                    })
                except Exception as e:
                    task.status = "failed"
                    worker_results.append({
                        "task_id": task.task_id,
                        "worker": worker_name,
                        "status": "failed",
                        "error": str(e)
                    })
                    
                self.completed_tasks.append(task)
            
            return worker_results
        
        # Run all workers in parallel
        all_results = await asyncio.gather(*[
            run_worker_tasks(worker, tasks)
            for worker, tasks in worker_tasks.items()
        ])
        
        for worker_results in all_results:
            results.extend(worker_results)
        
        return results
    
    async def _aggregate_results(
        self,
        objective: str,
        results: list[dict],
    ) -> str:
        """Aggregate results into final output"""
        if not self.llm:
            # Simple concatenation
            return "\n".join([
                f"{r['task_id']}: {r.get('result', r.get('error'))}"
                for r in results
            ])
        
        # Use LLM to aggregate
        results_text = "\n".join([
            f"Task {r['task_id']} ({r['worker']}): {r.get('result', 'Failed: ' + r.get('error', 'unknown'))}"
            for r in results
        ])
        
        prompt = f"""Aggregate these task results into a coherent response.

Original objective: {objective}

Task results:
{results_text}

Provide a unified response that addresses the original objective."""
        
        try:
            response = await self.llm.ainvoke(prompt)
            return response.content
        except Exception as e:
            logger.error("swarm.aggregation_failed", error=str(e))
            return results_text
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_status(self) -> dict[str, Any]:
        """Get swarm status"""
        return {
            "workers": {
                name: worker.get_status()
                for name, worker in self.workers.items()
            },
            "queued_tasks": len(self.task_queue),
            "completed_tasks": len(self.completed_tasks),
            "running": self._running,
        }
    
    async def close(self) -> None:
        """Cleanup swarm"""
        self._running = False
        self.workers.clear()
        logger.info("swarm.closed")
