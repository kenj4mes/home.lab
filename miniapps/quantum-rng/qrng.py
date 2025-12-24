"""
Quantum Random Number Generator (QRNG) Service

Provides quantum-derived random entropy via REST API.
Uses multiple entropy sources with fallback chain:
1. Hardware QRNG (if available)
2. Public QRNG APIs (ANU, IBM)
3. OS CSPRNG (/dev/urandom)

Endpoints:
    GET /random/<bytes>  - Get N random bytes as hex
    GET /health          - Health check
    GET /info            - Service information
    GET /entropy         - Current entropy source info
"""

from flask import Flask, jsonify, request
import os
import time
import hashlib
import threading
from typing import Optional, Tuple

app = Flask(__name__)

# ============================================================================
# Configuration
# ============================================================================

MAX_BYTES = int(os.environ.get("QRNG_MAX_BYTES", 1024))
CACHE_SIZE = int(os.environ.get("QRNG_CACHE_SIZE", 4096))
ENABLE_REMOTE = os.environ.get("QRNG_ENABLE_REMOTE", "true").lower() == "true"

# Remote QRNG endpoints (public quantum random sources)
QRNG_ENDPOINTS = [
    {
        "name": "ANU QRNG",
        "url": "https://qrng.anu.edu.au/API/jsonI.php?length={length}&type=hex16&size={size}",
        "parser": lambda r: r.json().get("data", [])[0] if r.json().get("success") else None,
        "max_request": 1024,
    },
]

# ============================================================================
# Entropy Pool
# ============================================================================

class EntropyPool:
    """Thread-safe entropy pool with multiple sources."""
    
    def __init__(self, cache_size: int = CACHE_SIZE):
        self.cache_size = cache_size
        self.pool = bytearray()
        self.lock = threading.Lock()
        self.source = "os_csprng"
        self.last_refill = 0
        self.stats = {
            "requests": 0,
            "bytes_served": 0,
            "remote_fetches": 0,
            "remote_failures": 0,
        }
    
    def _fetch_remote_entropy(self, num_bytes: int) -> Optional[bytes]:
        """Attempt to fetch entropy from remote QRNG sources."""
        if not ENABLE_REMOTE:
            return None
        
        import requests
        
        for endpoint in QRNG_ENDPOINTS:
            try:
                # Calculate request parameters
                size = min(num_bytes, endpoint["max_request"])
                url = endpoint["url"].format(length=1, size=size)
                
                resp = requests.get(url, timeout=5)
                if resp.status_code == 200:
                    data = endpoint["parser"](resp)
                    if data:
                        self.source = endpoint["name"]
                        self.stats["remote_fetches"] += 1
                        return bytes.fromhex(data) if isinstance(data, str) else bytes(data)
            except Exception:
                self.stats["remote_failures"] += 1
                continue
        
        return None
    
    def _refill_pool(self):
        """Refill the entropy pool."""
        # Try remote QRNG first
        remote_entropy = self._fetch_remote_entropy(self.cache_size)
        
        if remote_entropy:
            self.pool.extend(remote_entropy)
        else:
            # Fallback to OS CSPRNG
            self.source = "os_csprng"
            self.pool.extend(os.urandom(self.cache_size))
        
        self.last_refill = time.time()
    
    def get_random_bytes(self, num_bytes: int) -> bytes:
        """Get random bytes from the pool."""
        with self.lock:
            self.stats["requests"] += 1
            self.stats["bytes_served"] += num_bytes
            
            # Refill if needed
            if len(self.pool) < num_bytes:
                self._refill_pool()
            
            # Extract bytes from pool
            if len(self.pool) >= num_bytes:
                result = bytes(self.pool[:num_bytes])
                del self.pool[:num_bytes]
            else:
                # Fallback to direct OS random
                result = os.urandom(num_bytes)
                self.source = "os_csprng"
            
            return result
    
    def get_info(self) -> dict:
        """Get pool status information."""
        with self.lock:
            return {
                "source": self.source,
                "pool_size": len(self.pool),
                "cache_size": self.cache_size,
                "last_refill": self.last_refill,
                "stats": dict(self.stats),
                "remote_enabled": ENABLE_REMOTE,
            }


# Global entropy pool
entropy_pool = EntropyPool()

# ============================================================================
# API Endpoints
# ============================================================================

@app.route("/random/<int:num_bytes>")
def get_random(num_bytes: int):
    """
    Get random bytes.
    
    Args:
        num_bytes: Number of bytes to generate (1-1024)
    
    Returns:
        JSON with hex-encoded random bytes
    """
    # Validate input
    if num_bytes < 1:
        return jsonify({"error": "num_bytes must be at least 1"}), 400
    if num_bytes > MAX_BYTES:
        return jsonify({"error": f"num_bytes cannot exceed {MAX_BYTES}"}), 400
    
    # Get random bytes
    random_bytes = entropy_pool.get_random_bytes(num_bytes)
    
    return jsonify({
        "hex": random_bytes.hex(),
        "bytes": num_bytes,
        "source": entropy_pool.source,
        "timestamp": time.time(),
    })


@app.route("/health")
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "healthy",
        "service": "quantum-rng",
        "timestamp": time.time(),
    })


@app.route("/info")
def info():
    """Service information endpoint."""
    return jsonify({
        "service": "HomeLab Quantum RNG",
        "version": "1.0.0",
        "description": "Quantum-derived random number generator with fallback to OS CSPRNG",
        "endpoints": {
            "/random/<bytes>": "Get N random bytes as hex",
            "/health": "Health check",
            "/info": "Service information",
            "/entropy": "Entropy pool status",
        },
        "config": {
            "max_bytes": MAX_BYTES,
            "cache_size": CACHE_SIZE,
            "remote_enabled": ENABLE_REMOTE,
        },
    })


@app.route("/entropy")
def entropy():
    """Entropy pool status endpoint."""
    return jsonify(entropy_pool.get_info())


# ============================================================================
# Utility Endpoints
# ============================================================================

@app.route("/uuid")
def get_uuid():
    """Generate a random UUID v4."""
    random_bytes = entropy_pool.get_random_bytes(16)
    
    # Set version (4) and variant bits
    b = bytearray(random_bytes)
    b[6] = (b[6] & 0x0f) | 0x40  # Version 4
    b[8] = (b[8] & 0x3f) | 0x80  # Variant 1
    
    # Format as UUID string
    uuid_str = f"{b[0:4].hex()}-{b[4:6].hex()}-{b[6:8].hex()}-{b[8:10].hex()}-{b[10:16].hex()}"
    
    return jsonify({
        "uuid": uuid_str,
        "source": entropy_pool.source,
    })


@app.route("/password/<int:length>")
def get_password(length: int):
    """Generate a random password."""
    if length < 8:
        return jsonify({"error": "Password length must be at least 8"}), 400
    if length > 128:
        return jsonify({"error": "Password length cannot exceed 128"}), 400
    
    # Character sets
    charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    
    # Generate password
    random_bytes = entropy_pool.get_random_bytes(length)
    password = "".join(charset[b % len(charset)] for b in random_bytes)
    
    return jsonify({
        "password": password,
        "length": length,
        "source": entropy_pool.source,
    })


# ============================================================================
# Main
# ============================================================================

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
