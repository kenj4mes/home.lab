# ==============================================================================
# 🤖 Agent Orchestrator Container
# ==============================================================================
# Multi-agent runtime with LangGraph, CrewAI, and MCP support
# ==============================================================================

FROM python:3.12-slim

LABEL maintainer="HomeLab <homelab@local>"
LABEL description="AI Agent Orchestrator with LangGraph, CrewAI, MCP"
LABEL version="1.0.0"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy requirements first for caching
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create directories
RUN mkdir -p /app/data /app/logs

# Environment
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Expose ports
# 5004 - REST API
# 5005 - MCP Server
EXPOSE 5004 5005

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:5004/health || exit 1

# Default command
CMD ["python", "server.py"]
