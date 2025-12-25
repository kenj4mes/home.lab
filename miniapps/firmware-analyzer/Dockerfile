FROM python:3.11-slim

WORKDIR /app

# Install system dependencies including binwalk and file utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    binwalk \
    file \
    p7zip-full \
    squashfs-tools \
    mtd-utils \
    gzip \
    bzip2 \
    xz-utils \
    unzip \
    lz4 \
    zstd \
    cpio \
    cabextract \
    cramfsswap \
    sleuthkit \
    && rm -rf /var/lib/apt/lists/*

# Install unblob
RUN pip install --no-cache-dir unblob

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app.py .

# Create directories
RUN mkdir -p /firmware /extracted

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5602/health')" || exit 1

# Run
EXPOSE 5602
CMD ["python", "app.py"]
