# TRELLIS.2 Image-to-3D Generation

HomeLab includes Microsoft TRELLIS.2 for generating 3D models from single images.

## Overview

TRELLIS.2 (TRansformEr-based 3D Latent Synthesis) converts 2D images into textured 3D meshes using a 4B parameter model with O-Voxel representation.

| Feature | Value |
|---------|-------|
| **Model Size** | 4B parameters |
| **GPU Required** | 24GB+ VRAM |
| **Input** | Single image (PNG/JPG) |
| **Output** | GLB mesh, OBJ+MTL, Gaussian splats |
| **Framework** | PyTorch 2.6 + CUDA 12.4 |

## Requirements

### Hardware

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **GPU** | RTX 3090 (24GB) | RTX 4090 (24GB) |
| **RAM** | 32GB | 64GB |
| **Storage** | 50GB | 100GB (with cache) |
| **CUDA** | 12.4+ | 12.4+ |

### Software

- NVIDIA Driver 550+
- CUDA Toolkit 12.4
- Docker with NVIDIA Container Toolkit

## Quick Start

### Start Service

```bash
# Linux/WSL
./homelab.sh --action trellis

# Windows (WSL2 with GPU passthrough)
wsl docker compose -f docker-compose.dev.yml --profile gpu up -d trellis-3d

# Direct Docker
docker compose -f docker-compose.dev.yml --profile gpu up -d trellis-3d
```

### Generate 3D Model

```bash
# Upload image and generate
curl -X POST http://localhost:5003/generate \
  -F "image=@input.png" \
  -F "format=glb"

# Response
{
  "job_id": "abc-123",
  "status": "processing"
}

# Check status
curl http://localhost:5003/status/abc-123

# Download result
curl -o output.glb http://localhost:5003/download/abc-123
```

## API Reference

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/generate` | POST | Submit image for 3D generation |
| `/status/{job_id}` | GET | Check job status |
| `/download/{job_id}` | GET | Download generated 3D model |
| `/health` | GET | Service health check |

### Generate Request

```bash
POST /generate
Content-Type: multipart/form-data

image: <binary image data>
format: glb | obj | ply (default: glb)
resolution: 256 | 512 (default: 256)
export_gaussian: true | false (default: false)
```

### Response

```json
{
  "job_id": "uuid-string",
  "status": "queued | processing | completed | failed",
  "created_at": "2024-12-23T10:00:00",
  "input_size": [512, 512],
  "output_format": "glb"
}
```

## Gradio Interface

Interactive web UI available at **http://localhost:7860**

Features:
- Drag-and-drop image upload
- Real-time generation preview
- Multiple output format options
- 3D model viewer

## Output Formats

### GLB (Recommended)

Binary glTF with embedded textures.

```bash
curl -F "image=@photo.png" -F "format=glb" http://localhost:5003/generate
```

Best for: Web viewers, Unity, Unreal, Blender

### OBJ + MTL

Wavefront OBJ with material file.

```bash
curl -F "image=@photo.png" -F "format=obj" http://localhost:5003/generate
```

Best for: CAD software, legacy tools

### Gaussian Splats

3D Gaussian splatting point cloud.

```bash
curl -F "image=@photo.png" -F "format=glb" -F "export_gaussian=true" http://localhost:5003/generate
```

Best for: Real-time rendering, NeRF-style views

## Docker Configuration

### GPU Support

```yaml
# docker-compose.dev.yml
services:
  trellis-3d:
    image: homelab/trellis-3d:latest
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    ports:
      - "5003:5003"
      - "7860:7860"
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TRELLIS_MODEL` | TRELLIS.2-4B | Model variant |
| `TRELLIS_RESOLUTION` | 256 | Default mesh resolution |
| `CUDA_VISIBLE_DEVICES` | 0 | GPU device ID |
| `MAX_CONCURRENT_JOBS` | 2 | Parallel generation limit |

## Installation (Native)

For bare-metal installation without Docker:

```bash
# Run installer
./scripts/install-trellis.sh

# Activate environment
source /opt/homelab/trellis/venv/bin/activate

# Or use helper
trellis-activate
```

### Manual Setup

```bash
# Install CUDA 12.4
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update && sudo apt install -y cuda-toolkit-12-4

# Clone TRELLIS.2
git clone https://github.com/microsoft/TRELLIS.2.git /opt/trellis
cd /opt/trellis

# Create environment
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Download model
huggingface-cli download microsoft/TRELLIS.2-4B --local-dir ./checkpoints
```

## Offline Operation

### Pre-download Model

```bash
# Download during online phase
./scripts/offline-sync.sh --profile full

# Model location
/opt/homelab/cache/models/trellis/TRELLIS.2-4B/
```

### Configure Offline

```bash
export TRANSFORMERS_OFFLINE=1
export HF_DATASETS_OFFLINE=1
export HF_HUB_OFFLINE=1

# Point to local cache
export TRELLIS_CHECKPOINT_DIR=/opt/homelab/cache/models/trellis
```

## Integration Examples

### Python API

```python
import requests

def generate_3d(image_path: str, output_path: str):
    """Generate 3D model from image."""
    with open(image_path, "rb") as f:
        response = requests.post(
            "http://localhost:5003/generate",
            files={"image": f},
            data={"format": "glb"}
        )
    
    job_id = response.json()["job_id"]
    
    # Poll for completion
    while True:
        status = requests.get(f"http://localhost:5003/status/{job_id}").json()
        if status["status"] == "completed":
            break
        time.sleep(5)
    
    # Download result
    result = requests.get(f"http://localhost:5003/download/{job_id}")
    with open(output_path, "wb") as f:
        f.write(result.content)

generate_3d("input.png", "output.glb")
```

### Agent Integration

```python
# Use with HomeLab agent orchestrator
from crewai import Tool

trellis_tool = Tool(
    name="generate_3d_model",
    description="Generate a 3D model from an image",
    func=lambda image_url: generate_3d(image_url, "output.glb")
)
```

## Performance Tuning

### Resolution vs Speed

| Resolution | VRAM Usage | Time (RTX 4090) |
|------------|------------|-----------------|
| 256 | ~12GB | ~30s |
| 512 | ~22GB | ~120s |

### Batch Processing

```bash
# Process multiple images
for img in *.png; do
  curl -X POST http://localhost:5003/generate \
    -F "image=@$img" \
    -F "format=glb"
done
```

## Troubleshooting

### "CUDA out of memory"

Reduce resolution or ensure no other GPU processes:
```bash
# Check GPU memory
nvidia-smi

# Kill other processes if needed
sudo fuser -v /dev/nvidia*
```

### "Model not found"

Download the checkpoint:
```bash
huggingface-cli download microsoft/TRELLIS.2-4B \
  --local-dir /opt/homelab/cache/models/trellis/TRELLIS.2-4B
```

### "Container not starting"

Verify NVIDIA Container Toolkit:
```bash
docker run --rm --gpus all nvidia/cuda:12.4-base nvidia-smi
```

### "Poor quality output"

- Use high-quality input images (512x512+)
- Ensure good lighting and clear subject
- Avoid complex backgrounds

## Resources

- [TRELLIS.2 GitHub](https://github.com/microsoft/TRELLIS.2)
- [TRELLIS Paper](https://arxiv.org/abs/2412.01506)
- [O-Voxel Representation](https://github.com/microsoft/TRELLIS.2#o-voxel)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)
