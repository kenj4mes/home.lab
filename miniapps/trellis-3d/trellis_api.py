#!/usr/bin/env python3
"""
TRELLIS.2 REST API Wrapper
Provides HTTP endpoints for image-to-3D generation.

Endpoints:
    POST /generate    - Generate 3D model from image
    GET  /status/<id> - Check generation status
    GET  /download/<id> - Download generated model
    GET  /health      - Health check
"""

import os
import sys
import uuid
import json
import base64
import logging
import threading
from pathlib import Path
from datetime import datetime
from typing import Optional

from flask import Flask, request, jsonify, send_file
from werkzeug.utils import secure_filename

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
TRELLIS_DIR = os.getenv("TRELLIS_DIR", "/app/trellis2")
MODELS_DIR = os.getenv("MODELS_DIR", "/models")
OUTPUT_DIR = os.getenv("OUTPUT_DIR", "/app/outputs")
MAX_RESOLUTION = int(os.getenv("MAX_RESOLUTION", "1024"))

# Add TRELLIS to path
sys.path.insert(0, TRELLIS_DIR)

# Job storage
jobs = {}
jobs_lock = threading.Lock()

# Initialize TRELLIS pipeline (lazy load)
pipeline = None


def load_pipeline():
    """Lazy load the TRELLIS.2 pipeline."""
    global pipeline
    if pipeline is not None:
        return pipeline
    
    try:
        logger.info("Loading TRELLIS.2 pipeline...")
        
        # Set environment
        os.environ['OPENCV_IO_ENABLE_OPENEXR'] = '1'
        os.environ['PYTORCH_CUDA_ALLOC_CONF'] = 'expandable_segments:True'
        
        from trellis2.pipelines import Trellis2ImageTo3DPipeline
        
        model_path = os.path.join(MODELS_DIR, "TRELLIS.2-4B")
        if not os.path.exists(model_path):
            model_path = "microsoft/TRELLIS.2-4B"
        
        pipeline = Trellis2ImageTo3DPipeline.from_pretrained(model_path)
        pipeline.cuda()
        
        logger.info("TRELLIS.2 pipeline loaded successfully")
        return pipeline
    
    except Exception as e:
        logger.error(f"Failed to load pipeline: {e}")
        return None


def generate_3d(job_id: str, image_path: str, resolution: int = 512):
    """Generate 3D model from image (runs in background thread)."""
    try:
        with jobs_lock:
            jobs[job_id]["status"] = "processing"
            jobs[job_id]["started_at"] = datetime.now().isoformat()
        
        # Load pipeline
        pipe = load_pipeline()
        if pipe is None:
            raise RuntimeError("Pipeline not available")
        
        # Load image
        from PIL import Image
        image = Image.open(image_path)
        
        logger.info(f"Generating 3D for job {job_id} at resolution {resolution}")
        
        # Run generation
        mesh = pipe.run(image, resolution=resolution)[0]
        mesh.simplify(16777216)  # nvdiffrast limit
        
        # Export to GLB
        output_path = os.path.join(OUTPUT_DIR, f"{job_id}.glb")
        
        import o_voxel
        glb = o_voxel.postprocess.to_glb(
            vertices=mesh.vertices,
            faces=mesh.faces,
            attr_volume=mesh.attrs,
            coords=mesh.coords,
            attr_layout=mesh.layout,
            voxel_size=mesh.voxel_size,
            aabb=[[-0.5, -0.5, -0.5], [0.5, 0.5, 0.5]],
            decimation_target=1000000,
            texture_size=4096,
            remesh=True,
        )
        glb.export(output_path, extension_webp=True)
        
        with jobs_lock:
            jobs[job_id]["status"] = "completed"
            jobs[job_id]["completed_at"] = datetime.now().isoformat()
            jobs[job_id]["output_path"] = output_path
            jobs[job_id]["output_size"] = os.path.getsize(output_path)
        
        logger.info(f"Job {job_id} completed: {output_path}")
        
    except Exception as e:
        logger.error(f"Job {job_id} failed: {e}")
        with jobs_lock:
            jobs[job_id]["status"] = "failed"
            jobs[job_id]["error"] = str(e)


@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint."""
    try:
        import torch
        gpu_available = torch.cuda.is_available()
        gpu_name = torch.cuda.get_device_name(0) if gpu_available else None
        gpu_memory = torch.cuda.get_device_properties(0).total_memory // (1024**3) if gpu_available else 0
    except:
        gpu_available = False
        gpu_name = None
        gpu_memory = 0
    
    return jsonify({
        "status": "healthy",
        "service": "trellis-3d",
        "version": "1.0.0",
        "pipeline_loaded": pipeline is not None,
        "gpu": {
            "available": gpu_available,
            "name": gpu_name,
            "memory_gb": gpu_memory,
        },
        "active_jobs": sum(1 for j in jobs.values() if j["status"] == "processing"),
    })


@app.route("/generate", methods=["POST"])
def generate():
    """
    Generate 3D model from image.
    
    Request (multipart/form-data):
        - image: Image file (PNG, JPG, WebP)
        - resolution: Optional resolution (512, 1024, 1536)
    
    Response:
        - job_id: ID to check status/download
    """
    if "image" not in request.files:
        return jsonify({"error": "No image provided"}), 400
    
    image_file = request.files["image"]
    if image_file.filename == "":
        return jsonify({"error": "Empty filename"}), 400
    
    # Validate resolution
    resolution = min(int(request.form.get("resolution", 512)), MAX_RESOLUTION)
    if resolution not in [512, 1024, 1536]:
        resolution = 512
    
    # Create job
    job_id = str(uuid.uuid4())
    
    # Save uploaded image
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    filename = secure_filename(f"{job_id}_{image_file.filename}")
    image_path = os.path.join(OUTPUT_DIR, filename)
    image_file.save(image_path)
    
    # Create job record
    with jobs_lock:
        jobs[job_id] = {
            "id": job_id,
            "status": "queued",
            "created_at": datetime.now().isoformat(),
            "resolution": resolution,
            "input_path": image_path,
        }
    
    # Start generation in background
    thread = threading.Thread(target=generate_3d, args=(job_id, image_path, resolution))
    thread.start()
    
    return jsonify({
        "job_id": job_id,
        "status": "queued",
        "resolution": resolution,
        "check_status": f"/status/{job_id}",
    }), 202


@app.route("/status/<job_id>", methods=["GET"])
def status(job_id: str):
    """Check job status."""
    with jobs_lock:
        if job_id not in jobs:
            return jsonify({"error": "Job not found"}), 404
        return jsonify(jobs[job_id])


@app.route("/download/<job_id>", methods=["GET"])
def download(job_id: str):
    """Download generated 3D model."""
    with jobs_lock:
        if job_id not in jobs:
            return jsonify({"error": "Job not found"}), 404
        
        job = jobs[job_id]
        if job["status"] != "completed":
            return jsonify({"error": f"Job status: {job['status']}"}), 400
        
        output_path = job.get("output_path")
        if not output_path or not os.path.exists(output_path):
            return jsonify({"error": "Output file not found"}), 404
    
    return send_file(
        output_path,
        mimetype="model/gltf-binary",
        as_attachment=True,
        download_name=f"{job_id}.glb",
    )


@app.route("/jobs", methods=["GET"])
def list_jobs():
    """List all jobs."""
    with jobs_lock:
        return jsonify({
            "total": len(jobs),
            "jobs": list(jobs.values()),
        })


@app.route("/", methods=["GET"])
def index():
    """API documentation."""
    return jsonify({
        "service": "TRELLIS.2 Image-to-3D API",
        "version": "1.0.0",
        "endpoints": {
            "POST /generate": "Generate 3D model from image",
            "GET /status/<job_id>": "Check generation status",
            "GET /download/<job_id>": "Download generated GLB",
            "GET /jobs": "List all jobs",
            "GET /health": "Health check",
        },
        "capabilities": {
            "resolutions": [512, 1024, 1536],
            "output_format": "GLB (glTF Binary)",
            "pbr_materials": True,
        },
    })


if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    port = int(os.getenv("PORT", 5003))
    debug = os.getenv("DEBUG", "false").lower() == "true"
    
    logger.info(f"Starting TRELLIS.2 API on port {port}")
    
    # Pre-load pipeline if not in debug mode
    if not debug:
        load_pipeline()
    
    app.run(host="0.0.0.0", port=port, debug=debug)
