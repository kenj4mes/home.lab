# ==============================================================================
# Bark TTS - Text-to-Speech with Voice Synthesis
# ==============================================================================
# Neural text-to-speech with voice cloning, multilingual support,
# and sound effect generation.
#
# Build:
#   docker build -t homelab/bark-tts .
#
# Run:
#   docker run -p 5000:5000 --gpus all homelab/bark-tts
#
# API:
#   POST /synthesize {"text": "Hello world", "voice": "v2/en_speaker_6"}
#   GET  /voices      List available voice presets
#   GET  /health      Health check
# ==============================================================================

FROM nvidia/cuda:12.1-runtime-ubuntu22.04

LABEL maintainer="HomeLab"
LABEL description="Bark TTS - Neural Text-to-Speech"
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

# Install Python dependencies
RUN pip3 install --no-cache-dir \
    flask \
    flask-cors \
    gunicorn \
    numpy \
    scipy \
    torch \
    torchaudio \
    transformers \
    encodec \
    bark

# Copy application code
COPY app.py .
# Note: voices/ directory is optional, created at runtime if not present
# COPY voices/ ./voices/

# Create models directory
RUN mkdir -p /app/models

# Environment variables
ENV BARK_SMALL_MODEL=false
ENV BARK_USE_GPU=true
ENV XDG_CACHE_HOME=/app/models

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Run the application
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "1", "--threads", "4", "--timeout", "300", "app:app"]
