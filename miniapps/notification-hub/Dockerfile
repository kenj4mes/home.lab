FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

EXPOSE 5502

CMD ["python", "-m", "uvicorn", "src.hub:app", "--host", "0.0.0.0", "--port", "5502"]
