FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install garak from pip
RUN pip install --no-cache-dir garak

# Copy application
COPY app.py .

# Create data directory
RUN mkdir -p /app/data/reports

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5600/health')" || exit 1

# Run
EXPOSE 5600
CMD ["python", "app.py"]
