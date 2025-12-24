"""
Stable Video Diffusion - Image to Video API
Flask application providing REST API for video generation.
"""

import os
import io
import base64
import logging
import tempfile
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from PIL import Image

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Lazy load model
_svd_pipeline = None

def get_pipeline():
    """Lazy load SVD pipeline."""
    global _svd_pipeline
    if _svd_pipeline is None:
        logger.info("Loading Stable Video Diffusion pipeline...")
        import torch
        from diffusers import StableVideoDiffusionPipeline
        from diffusers.utils import export_to_video
        
        model_id = os.environ.get("SVD_MODEL", "svd-xt")
        model_path = f"stabilityai/stable-video-diffusion-img2vid-{model_id}"
        
        _svd_pipeline = StableVideoDiffusionPipeline.from_pretrained(
            model_path,
            torch_dtype=torch.float16,
            variant="fp16"
        )
        _svd_pipeline.to("cuda")
        _svd_pipeline.enable_model_cpu_offload()
        
        logger.info(f"SVD pipeline ({model_id}) loaded successfully")
    return _svd_pipeline

@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "healthy",
        "service": "video-diffusion",
        "version": "1.0.0",
        "model": os.environ.get("SVD_MODEL", "svd-xt")
    })

@app.route("/generate", methods=["POST"])
def generate():
    """
    Generate video from image.
    
    Request body:
        {
            "image": "base64_encoded_image",
            "frames": 14,                    # optional, 14 or 25
            "fps": 7,                        # optional, frames per second
            "motion_bucket_id": 127,         # optional, 1-255 controls motion
            "noise_aug_strength": 0.02,      # optional, augmentation strength
            "decode_chunk_size": 8,          # optional, memory optimization
            "output_format": "mp4"           # optional: mp4, gif, base64
        }
    
    Returns:
        Video file (mp4/gif) or base64-encoded video
    """
    try:
        data = request.get_json()
        
        if not data or "image" not in data:
            return jsonify({"error": "Missing 'image' field (base64)"}), 400
        
        # Decode image
        image_b64 = data["image"]
        if "," in image_b64:
            image_b64 = image_b64.split(",")[1]  # Remove data URI prefix
        
        image_bytes = base64.b64decode(image_b64)
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        
        # Resize to model input size (1024x576 for SVD)
        image = image.resize((1024, 576))
        
        # Get parameters
        frames = data.get("frames", 14)
        fps = data.get("fps", 7)
        motion_bucket_id = data.get("motion_bucket_id", 127)
        noise_aug_strength = data.get("noise_aug_strength", 0.02)
        decode_chunk_size = data.get("decode_chunk_size", 8)
        output_format = data.get("output_format", "mp4")
        
        logger.info(f"Generating video: {frames} frames @ {fps} fps")
        
        # Generate video
        import torch
        
        pipeline = get_pipeline()
        
        generator = torch.Generator(device="cuda").manual_seed(42)
        
        with torch.no_grad():
            video_frames = pipeline(
                image,
                num_frames=frames,
                decode_chunk_size=decode_chunk_size,
                motion_bucket_id=motion_bucket_id,
                noise_aug_strength=noise_aug_strength,
                generator=generator
            ).frames[0]
        
        # Export video
        import imageio
        import numpy as np
        
        # Convert frames to numpy
        frames_np = [(np.array(f) * 255).astype(np.uint8) if f.max() <= 1 
                     else np.array(f).astype(np.uint8) for f in video_frames]
        
        # Write to buffer
        buffer = io.BytesIO()
        
        if output_format == "gif":
            imageio.mimwrite(buffer, frames_np, format="GIF", fps=fps, loop=0)
            mimetype = "image/gif"
            filename = "video.gif"
        else:
            # Save to temp file first (imageio needs seekable file for mp4)
            with tempfile.NamedTemporaryFile(suffix=".mp4", delete=False) as tmp:
                imageio.mimwrite(tmp.name, frames_np, format="mp4", fps=fps)
                with open(tmp.name, "rb") as f:
                    buffer.write(f.read())
                os.unlink(tmp.name)
            mimetype = "video/mp4"
            filename = "video.mp4"
        
        buffer.seek(0)
        
        if output_format == "base64":
            video_b64 = base64.b64encode(buffer.read()).decode("utf-8")
            return jsonify({
                "video": video_b64,
                "format": "mp4",
                "frames": frames,
                "fps": fps
            })
        else:
            return send_file(
                buffer,
                mimetype=mimetype,
                as_attachment=True,
                download_name=filename
            )
    
    except Exception as e:
        logger.error(f"Generation error: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route("/generate_from_url", methods=["POST"])
def generate_from_url():
    """
    Generate video from image URL.
    
    Request body:
        {
            "url": "https://example.com/image.jpg",
            "frames": 14,
            "fps": 7
        }
    """
    try:
        import requests
        
        data = request.get_json()
        
        if not data or "url" not in data:
            return jsonify({"error": "Missing 'url' field"}), 400
        
        # Download image
        response = requests.get(data["url"], timeout=30)
        response.raise_for_status()
        
        # Convert to base64 and process
        image_b64 = base64.b64encode(response.content).decode("utf-8")
        data["image"] = image_b64
        del data["url"]
        
        # Forward to main generate endpoint
        return generate()
    
    except Exception as e:
        logger.error(f"URL generation error: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route("/", methods=["GET"])
def index():
    """API documentation."""
    return jsonify({
        "service": "Stable Video Diffusion",
        "version": "1.0.0",
        "model": os.environ.get("SVD_MODEL", "svd-xt"),
        "endpoints": {
            "/health": "GET - Health check",
            "/generate": "POST - Generate video from base64 image",
            "/generate_from_url": "POST - Generate video from image URL"
        },
        "example": {
            "image": "base64_encoded_image_data",
            "frames": 14,
            "fps": 7,
            "motion_bucket_id": 127,
            "output_format": "mp4"
        },
        "models": {
            "svd": "14 frames, 576x1024",
            "svd-xt": "25 frames, 576x1024 (default)"
        },
        "requirements": {
            "gpu_vram": "12GB minimum, 24GB recommended",
            "input_resolution": "1024x576 (auto-resized)"
        }
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
