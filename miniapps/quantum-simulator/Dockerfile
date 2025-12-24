# Quantum Simulator Service
#
# Provides a REST API for executing quantum circuits using:
# - Qiskit (IBM)
# - Cirq (Google)
# - PennyLane (Xanadu)
#
# Endpoints:
#   POST /run         - Execute a quantum circuit
#   GET /health       - Health check
#   GET /info         - Service information
#   GET /backends     - List available backends
#
# Build:
#   docker build -t homelab/quantum-simulator .
#
# Run:
#   docker run -p 5002:5000 homelab/quantum-simulator
#
FROM python:3.11-slim

LABEL org.opencontainers.image.title="HomeLab Quantum Simulator"
LABEL org.opencontainers.image.description="Quantum circuit simulator with Qiskit, Cirq, PennyLane"
LABEL org.opencontainers.image.source="https://github.com/YOUR_USERNAME/HomeLab"
LABEL org.opencontainers.image.licenses="MIT"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir \
    flask==3.0.* \
    gunicorn==21.* \
    numpy==1.26.* \
    qiskit==1.0.* \
    qiskit-aer==0.13.* \
    cirq-core==1.3.* \
    pennylane==0.34.*

# Create non-root user
RUN useradd -r -s /bin/false quantum

# Copy application
WORKDIR /app
COPY quantum_api.py /app/quantum_api.py
COPY circuits.py /app/circuits.py

# Set ownership
RUN chown -R quantum:quantum /app

# Switch to non-root user
USER quantum

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

# Run with gunicorn (single worker due to quantum simulations)
ENTRYPOINT ["gunicorn", "-b", "0.0.0.0:5000", "-w", "1", "--timeout", "120", "--access-logfile", "-", "quantum_api:app"]
