# ==============================================================================
# SDR Dashboard - Unified Web Interface for Radio Tools
# ==============================================================================

FROM python:3.12-slim

LABEL maintainer="HomeLab"
LABEL description="SDR Tools Web Dashboard"

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install --no-cache-dir \
    fastapi \
    uvicorn[standard] \
    httpx \
    jinja2 \
    python-multipart

# Copy application
COPY . /app/

# Create directories
RUN mkdir -p /app/data /app/templates /app/static

# Create basic app if not exists
RUN if [ ! -f /app/main.py ]; then \
    echo 'from fastapi import FastAPI, Request\n\
from fastapi.responses import HTMLResponse, JSONResponse\n\
import httpx\n\
import os\n\
\n\
app = FastAPI(title="SDR Dashboard")\n\
\n\
SERVICES = {\n\
    "imsi_catcher": os.getenv("IMSI_CATCHER_URL", "http://localhost:4729"),\n\
    "rayhunter": os.getenv("RAYHUNTER_URL", "http://localhost:8580"),\n\
    "ltesniffer": os.getenv("LTESNIFFER_URL", "http://localhost:8581"),\n\
}\n\
\n\
@app.get("/health")\n\
async def health():\n\
    return {"status": "healthy"}\n\
\n\
@app.get("/", response_class=HTMLResponse)\n\
async def root():\n\
    return """<!DOCTYPE html>\n\
<html><head><title>SDR Dashboard</title>\n\
<style>body{font-family:system-ui;max-width:800px;margin:0 auto;padding:20px;background:#1a1a2e;color:#eee}\n\
h1{color:#00d4ff}a{color:#00d4ff}.card{background:#16213e;padding:20px;margin:10px 0;border-radius:8px}</style>\n\
</head><body>\n\
<h1>🔊 SDR Dashboard</h1>\n\
<div class=\"card\"><h2>IMSI Catcher</h2><p>GSM IMSI Detection</p></div>\n\
<div class=\"card\"><h2>Rayhunter</h2><p>EFF IMSI Catcher Detector</p><a href=\"/rayhunter\">Open →</a></div>\n\
<div class=\"card\"><h2>LTESniffer</h2><p>LTE Traffic Analysis</p></div>\n\
<div class=\"card\"><h2>srsRAN</h2><p>5G gNB Base Station</p></div>\n\
</body></html>"""\n\
\n\
@app.get("/api/status")\n\
async def status():\n\
    results = {}\n\
    async with httpx.AsyncClient(timeout=5.0) as client:\n\
        for name, url in SERVICES.items():\n\
            try:\n\
                r = await client.get(f"{url}/health")\n\
                results[name] = {"status": "up", "code": r.status_code}\n\
            except:\n\
                results[name] = {"status": "down"}\n\
    return results\n\
' > /app/main.py; fi

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
