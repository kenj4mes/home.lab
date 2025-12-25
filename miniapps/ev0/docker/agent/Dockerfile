# x402 Agent - Dockerfile
# Python-based x402 client

FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install poetry
RUN pip install poetry==1.7.1

# Copy dependency files
COPY pyproject.toml poetry.lock* ./

# Export requirements (we'll use pip in production image)
RUN poetry export -f requirements.txt --output requirements.txt --without-hashes

# Production image
FROM python:3.11-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    chromium \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 agent && \
    mkdir -p /app/data /app/memories && \
    chown -R agent:agent /app

# Copy requirements from builder
COPY --from=builder /app/requirements.txt ./

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY --chown=agent:agent . .

USER agent

# Environment
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV HEADLESS=true

# Volumes for persistence
VOLUME ["/app/data", "/app/memories"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Expose agent API
EXPOSE 8080

# Start agent
CMD ["python", "-m", "agent.main"]
