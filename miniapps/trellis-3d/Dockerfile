# ==============================================================================
# 🎨 TRELLIS.2 - Image to 3D API Container
# ==============================================================================
# GPU-accelerated 3D generation from images
# Requires: NVIDIA GPU with 24GB+ VRAM
# ==============================================================================

FROM nvidia/cuda:12.4.0-devel-ubuntu22.04

LABEL maintainer="HomeLab <homelab@local>"
LABEL description="TRELLIS.2 Image-to-3D generation API"
LABEL version="1.0.0"

# Environment
ENV DEBIAN_FRONTEND=noninteractive
ENV CUDA_HOME=/usr/local/cuda
ENV OPENCV_IO_ENABLE_OPENEXR=1
ENV PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    python3 \
    python3-pip \
    python3-venv \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libopenexr-dev \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Clone TRELLIS.2 (at build time for caching)
# In production, mount weights externally
RUN git clone --recursive https://github.com/microsoft/TRELLIS.2.git /app/trellis2

WORKDIR /app/trellis2

# Install Python dependencies
RUN pip3 install --no-cache-dir \
    torch==2.6.0 \
    torchvision \
    --index-url https://download.pytorch.org/whl/cu124

# Install TRELLIS.2 dependencies
RUN pip3 install --no-cache-dir \
    numpy \
    scipy \
    pillow \
    opencv-python \
    imageio \
    imageio-ffmpeg \
    gradio \
    transformers \
    huggingface_hub \
    safetensors \
    accelerate \
    flask \
    gunicorn

# Run setup script (partial - will need GPU at runtime for full setup)
# RUN . ./setup.sh --basic

# Copy API wrapper
COPY trellis_api.py /app/trellis_api.py

# Create model weights directory (mount at runtime)
RUN mkdir -p /models

# Expose ports
EXPOSE 5003 7860

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:5003/health || exit 1

# Default command - API server
CMD ["python3", "/app/trellis_api.py"]
