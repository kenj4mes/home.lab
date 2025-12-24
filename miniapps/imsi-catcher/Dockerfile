# ==============================================================================
# IMSI Catcher - GSM IMSI Detection Tool
# ==============================================================================
# Build: docker build -t homelab/imsi-catcher .
# ==============================================================================

FROM ubuntu:22.04

LABEL maintainer="HomeLab"
LABEL description="GSM IMSI Catcher for security research"

# Avoid prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-numpy \
    python3-scipy \
    python3-scapy \
    gnuradio \
    gr-osmosdr \
    rtl-sdr \
    librtlsdr-dev \
    git \
    curl \
    wireshark-common \
    tshark \
    && rm -rf /var/lib/apt/lists/*

# Install gr-gsm (GSM decoder for GNU Radio)
RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake \
    build-essential \
    liborc-0.4-dev \
    libosmocore-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip3 install --no-cache-dir \
    python-decouple \
    mysqlclient \
    importlib

# Create app directory
WORKDIR /app

# Copy application files
COPY . /app/

# Create data directories
RUN mkdir -p /app/data /app/logs

# Make scripts executable
RUN chmod +x /app/*.py 2>/dev/null || true
RUN chmod +x /app/scan-and-livemon 2>/dev/null || true

# Default command - run the IMSI catcher
CMD ["python3", "simple_IMSI-catcher.py", "-s"]
