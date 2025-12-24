# ==============================================================================
# Stable Video Diffusion - Image/Text to Video
# ==============================================================================
# Generate short video clips from images or text prompts using
# Stability AI's Stable Video Diffusion models.
#
# Build:
#   docker build -t homelab/video-diffusion .
#
# Run:
#   docker run -p 5000:5000 --gpus all homelab/video-diffusion
#
# API:
#   POST /generate {"image": base64, "frames": 14, "fps": 7}
#   GET  /health   Health check
# ==============================================================================

FROM nvidia/cuda:12.1-runtime-ubuntu22.04

LABEL maintainer="HomeLab"
LABEL description="Stable Video Diffusion - Image to Video"
LABEL version="1.0.0"

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-dev \
    git \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Install PyTorch first (for CUDA support)
RUN pip3 install --no-cache-dir \
    torch \
    torchvision \
    --index-url https://download.pytorch.org/whl/cu121

# Install Diffusers and dependencies
RUN pip3 install --no-cache-dir \
    flask \
    flask-cors \
    gunicorn \
    numpy \
    pillow \
    diffusers \
    transformers \
    accelerate \
    safetensors \
    imageio[ffmpeg] \
    opencv-python-headless

# Copy application code
COPY app.py .

# Create directories
RUN mkdir -p /app/models /app/outputs

# Environment variables
ENV SVD_MODEL=svd-xt
ENV HF_HOME=/app/models
ENV TRANSFORMERS_CACHE=/app/models

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Run the application
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "1", "--threads", "1", "--timeout", "900", "app:app"]
