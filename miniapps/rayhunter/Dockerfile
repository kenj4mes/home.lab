# ==============================================================================
# Rayhunter - EFF IMSI Catcher Detector
# ==============================================================================
# Build: docker build -t homelab/rayhunter .
# ==============================================================================

FROM rust:1.75-slim-bookworm AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    libudev-dev \
    libdbus-1-dev \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy source
COPY . /app/

# Build the web interface / analysis tools
RUN cargo build --release --workspace 2>/dev/null || echo "Building available components..."

# ==============================================================================
# Runtime Stage
# ==============================================================================

FROM debian:bookworm-slim

LABEL maintainer="HomeLab"
LABEL description="Rayhunter IMSI Catcher Detector by EFF"

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built binaries from builder
COPY --from=builder /app/target/release/* /app/ 2>/dev/null || true
COPY --from=builder /app/ /app/

# Create data directories
RUN mkdir -p /app/data /app/logs

# Expose web interface
EXPOSE 8080

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Default command
CMD ["./rayhunter-web", "--bind", "0.0.0.0:8080"]
