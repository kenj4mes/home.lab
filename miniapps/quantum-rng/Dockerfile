# Quantum Random Number Generator (QRNG) Service
#
# Provides quantum-derived entropy via REST API.
# Falls back to OS CSPRNG when quantum sources unavailable.
#
# Endpoints:
#   GET /random/<bytes>  - Get N random bytes as hex
#   GET /health          - Health check
#   GET /info            - Service information
#
# Build:
#   docker build -t homelab/quantum-rng .
#
# Run:
#   docker run -p 5001:5000 homelab/quantum-rng
#
FROM python:3.12-slim

LABEL org.opencontainers.image.title="HomeLab Quantum RNG"
LABEL org.opencontainers.image.description="Quantum Random Number Generator service"
LABEL org.opencontainers.image.source="https://github.com/YOUR_USERNAME/HomeLab"
LABEL org.opencontainers.image.licenses="MIT"

# Install dependencies
RUN pip install --no-cache-dir \
    flask==3.0.* \
    gunicorn==21.* \
    requests==2.31.*

# Create non-root user
RUN useradd -r -s /bin/false qrng

# Copy application
WORKDIR /app
COPY qrng.py /app/qrng.py

# Set ownership
RUN chown -R qrng:qrng /app

# Switch to non-root user
USER qrng

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

# Run with gunicorn
ENTRYPOINT ["gunicorn", "-b", "0.0.0.0:5000", "-w", "2", "--access-logfile", "-", "qrng:app"]
