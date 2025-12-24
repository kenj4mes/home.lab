# ==============================================================================
# MusicGen - AI Music Generation
# ==============================================================================
# Meta's AudioCraft MusicGen for text-to-music generation.
#
# Build:
#   docker build -t homelab/musicgen .
#
# Run:
#   docker run -p 5000:5000 --gpus all homelab/musicgen
#
# API:
#   POST /generate {"prompt": "epic orchestral theme", "duration": 10}
#   GET  /health   Health check
# ==============================================================================

FROM nvidia/cuda:12.1-runtime-ubuntu22.04

LABEL maintainer="HomeLab"
LABEL description="MusicGen - AI Music Generation"
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
    libsndfile1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Install PyTorch first (for CUDA support)
RUN pip3 install --no-cache-dir \
    torch \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu121

# Install AudioCraft and dependencies
RUN pip3 install --no-cache-dir \
    flask \
    flask-cors \
    gunicorn \
    numpy \
    scipy \
    audiocraft \
    xformers

# Copy application code
COPY app.py .

# Create models directory
RUN mkdir -p /app/models

# Environment variables
ENV MUSICGEN_MODEL=small
ENV XDG_CACHE_HOME=/app/models

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Run the application
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "1", "--threads", "2", "--timeout", "600", "app:app"]
