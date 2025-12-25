# ==============================================================================
# 🤖 Sovereign Agent - Production Dockerfile
# ==============================================================================
# Multi-stage build for optimized Python agent container
# ==============================================================================

FROM python:3.12-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --user -r requirements.txt

# ==============================================================================
# Production Stage
# ==============================================================================
FROM python:3.12-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    ca-certificates \
    # Playwright dependencies
    libnss3 \
    libxss1 \
    libasound2 \
    libgbm1 \
    libgtk-3-0 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 agent && \
    mkdir -p /app/data /app/memories && \
    chown -R agent:agent /app

# Copy Python packages from builder
COPY --from=builder /root/.local /home/agent/.local

# Copy application code
COPY --chown=agent:agent echo/ /app/echo/
COPY --chown=agent:agent requirements.txt /app/

# Set Python path
ENV PATH="/home/agent/.local/bin:$PATH"
ENV PYTHONPATH="/app"
ENV PYTHONUNBUFFERED=1

# Install Playwright browsers
RUN pip install playwright && playwright install chromium --with-deps

USER agent

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Expose ports
EXPOSE 8080

# Run the agent
CMD ["python", "-m", "echo.server"]
