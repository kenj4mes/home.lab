"""
Compute Node - DePIN Module
Fleek/Akash Compute Provision

Provide compute resources and IPFS pinning.
"""

import hashlib
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

import structlog

logger = structlog.get_logger(__name__)


class ComputeStatus(str, Enum):
    """Compute node status"""
    OFFLINE = "offline"
    ONLINE = "online"
    BUSY = "busy"
    ERROR = "error"


class JobType(str, Enum):
    """Types of compute jobs"""
    CONTAINER = "container"
    FUNCTION = "function"
    IPFS_PIN = "ipfs_pin"


@dataclass
class ComputeJob:
    """A compute job"""
    job_id: str
    job_type: JobType
    status: str
    started_at: datetime
    completed_at: Optional[datetime] = None
    result: Optional[str] = None
    earnings: float = 0.0


@dataclass
class ComputeStats:
    """Compute statistics"""
    jobs_completed: int = 0
    total_compute_seconds: int = 0
    files_pinned: int = 0
    bytes_stored: int = 0
    total_earnings: float = 0.0


class ComputeNode:
    """
    Compute Node - Fleek/Akash
    
    Provides compute resources to the network and
    earns tokens for job execution.
    
    Example:
        >>> compute = ComputeNode()
        >>> await compute.initialize()
        >>> await compute.start_accepting_jobs()
        >>> cid = await compute.pin_to_ipfs(data)
    """
    
    # Configuration
    DEFAULT_COMPUTE_PRICE = 0.001  # USD per compute-second
    DEFAULT_STORAGE_PRICE = 0.00001  # USD per byte per month
    
    def __init__(
        self,
        fleek_api_key: Optional[str] = None,
        akash_wallet: Optional[str] = None,
        compute_price: float = DEFAULT_COMPUTE_PRICE,
        storage_price: float = DEFAULT_STORAGE_PRICE,
    ):
        """
        Initialize Compute Node.
        
        Args:
            fleek_api_key: Fleek API key for IPFS
            akash_wallet: Akash wallet address
            compute_price: Price per compute-second
            storage_price: Price per byte per month
        """
        self.fleek_api_key = fleek_api_key
        self.akash_wallet = akash_wallet
        self.compute_price = compute_price
        self.storage_price = storage_price
        
        self.status = ComputeStatus.OFFLINE
        self.stats = ComputeStats()
        self.jobs: Dict[str, ComputeJob] = {}
        self.pinned_files: Dict[str, Dict] = {}
        
    async def initialize(self) -> None:
        """Initialize compute node"""
        self.status = ComputeStatus.ONLINE
        
        logger.info("compute.initialized",
                   fleek_configured=bool(self.fleek_api_key),
                   akash_configured=bool(self.akash_wallet))
    
    # ==========================================================================
    # JOB MANAGEMENT
    # ==========================================================================
    
    async def start_accepting_jobs(self) -> None:
        """Start accepting compute jobs"""
        self.status = ComputeStatus.ONLINE
        logger.info("compute.accepting_jobs")
    
    async def stop_accepting_jobs(self) -> None:
        """Stop accepting new jobs"""
        self.status = ComputeStatus.OFFLINE
        logger.info("compute.stopped_accepting")
    
    async def submit_job(
        self,
        job_type: JobType,
        config: Dict[str, Any],
    ) -> ComputeJob:
        """
        Submit a compute job.
        
        Args:
            job_type: Type of job
            config: Job configuration
            
        Returns:
            Job object
        """
        job_id = hashlib.sha256(
            f"{job_type}{datetime.utcnow().isoformat()}".encode()
        ).hexdigest()[:12]
        
        job = ComputeJob(
            job_id=job_id,
            job_type=job_type,
            status="pending",
            started_at=datetime.utcnow(),
        )
        
        self.jobs[job_id] = job
        
        logger.info("compute.job_submitted",
                   job_id=job_id,
                   type=job_type.value)
        
        # Execute job
        await self._execute_job(job, config)
        
        return job
    
    async def _execute_job(
        self,
        job: ComputeJob,
        config: Dict[str, Any],
    ) -> None:
        """Execute a compute job"""
        job.status = "running"
        
        try:
            if job.job_type == JobType.CONTAINER:
                # Deploy container
                result = await self._run_container(config)
            elif job.job_type == JobType.FUNCTION:
                # Run function
                result = await self._run_function(config)
            elif job.job_type == JobType.IPFS_PIN:
                # Pin to IPFS
                result = await self._pin_file(config)
            else:
                result = {"error": "Unknown job type"}
            
            job.status = "completed"
            job.result = str(result)
            job.completed_at = datetime.utcnow()
            job.earnings = self._calculate_earnings(job)
            
            self.stats.jobs_completed += 1
            self.stats.total_earnings += job.earnings
            
        except Exception as e:
            job.status = "failed"
            job.result = str(e)
            logger.error("compute.job_failed", job_id=job.job_id, error=str(e))
    
    async def _run_container(self, config: Dict) -> Dict:
        """Run a container job"""
        # In production, deploy via Akash
        image = config.get("image", "alpine")
        command = config.get("command", "echo hello")
        
        # Simulate container execution
        compute_time = 10  # seconds
        self.stats.total_compute_seconds += compute_time
        
        return {
            "status": "completed",
            "image": image,
            "output": "Container executed successfully",
            "compute_time": compute_time,
        }
    
    async def _run_function(self, config: Dict) -> Dict:
        """Run a serverless function"""
        # In production, use Fleek Functions
        code = config.get("code", "")
        
        compute_time = 1  # second
        self.stats.total_compute_seconds += compute_time
        
        return {
            "status": "completed",
            "output": "Function executed",
            "compute_time": compute_time,
        }
    
    async def _pin_file(self, config: Dict) -> Dict:
        """Pin file to IPFS"""
        data = config.get("data", b"")
        
        # Calculate CID (simplified)
        cid = "Qm" + hashlib.sha256(data if isinstance(data, bytes) else data.encode()).hexdigest()[:44]
        
        self.stats.files_pinned += 1
        self.stats.bytes_stored += len(data)
        
        return {
            "status": "pinned",
            "cid": cid,
            "size": len(data),
        }
    
    def _calculate_earnings(self, job: ComputeJob) -> float:
        """Calculate job earnings"""
        if job.job_type == JobType.IPFS_PIN:
            return 0.001  # Small fee for pinning
        else:
            if job.started_at and job.completed_at:
                duration = (job.completed_at - job.started_at).total_seconds()
                return duration * self.compute_price
        return 0.0
    
    # ==========================================================================
    # IPFS OPERATIONS
    # ==========================================================================
    
    async def pin_to_ipfs(
        self,
        data: bytes,
        name: Optional[str] = None,
    ) -> str:
        """
        Pin data to IPFS.
        
        Args:
            data: Data to pin
            name: Optional name
            
        Returns:
            CID of pinned content
        """
        # Calculate CID
        cid = "Qm" + hashlib.sha256(data).hexdigest()[:44]
        
        # In production, upload via Fleek Storage
        
        self.pinned_files[cid] = {
            "cid": cid,
            "name": name,
            "size": len(data),
            "pinned_at": datetime.utcnow().isoformat(),
        }
        
        self.stats.files_pinned += 1
        self.stats.bytes_stored += len(data)
        
        logger.info("compute.ipfs_pinned",
                   cid=cid,
                   size=len(data))
        
        return cid
    
    async def unpin_from_ipfs(self, cid: str) -> bool:
        """
        Unpin content from IPFS.
        
        Args:
            cid: Content ID to unpin
            
        Returns:
            True if unpinned
        """
        if cid in self.pinned_files:
            file_info = self.pinned_files.pop(cid)
            self.stats.bytes_stored -= file_info.get("size", 0)
            logger.info("compute.ipfs_unpinned", cid=cid)
            return True
        return False
    
    async def get_ipfs_gateway_url(self, cid: str) -> str:
        """
        Get IPFS gateway URL for content.
        
        Args:
            cid: Content ID
            
        Returns:
            Gateway URL
        """
        # Use Fleek gateway
        return f"https://ipfs.fleek.co/ipfs/{cid}"
    
    # ==========================================================================
    # STATISTICS
    # ==========================================================================
    
    def get_stats(self) -> ComputeStats:
        """Get compute statistics"""
        return self.stats
    
    def get_jobs(
        self,
        status: Optional[str] = None,
        limit: int = 50,
    ) -> List[ComputeJob]:
        """Get job list"""
        jobs = list(self.jobs.values())
        
        if status:
            jobs = [j for j in jobs if j.status == status]
        
        return jobs[-limit:]
    
    # ==========================================================================
    # UTILITIES
    # ==========================================================================
    
    def get_status(self) -> Dict[str, Any]:
        """Get node status"""
        return {
            "status": self.status.value,
            "stats": {
                "jobs_completed": self.stats.jobs_completed,
                "compute_seconds": self.stats.total_compute_seconds,
                "files_pinned": self.stats.files_pinned,
                "bytes_stored": self.stats.bytes_stored,
                "total_earnings": self.stats.total_earnings,
            },
            "pricing": {
                "compute_per_second": self.compute_price,
                "storage_per_byte_month": self.storage_price,
            },
        }
    
    async def close(self) -> None:
        """Shutdown compute node"""
        await self.stop_accepting_jobs()
        logger.info("compute.closed")
