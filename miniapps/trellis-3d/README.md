# TRELLIS.2 - Image to 3D Generation

Microsoft's state-of-the-art 4B parameter model for high-fidelity image-to-3D generation.

## Features

- **Image → 3D Model** in seconds
- **PBR Materials** (Base Color, Roughness, Metallic, Opacity)
- **Multiple Resolutions** (512³, 1024³, 1536³)
- **GLB Export** for universal 3D software compatibility

## Requirements

- **GPU**: NVIDIA with 24GB+ VRAM (A100, H100, RTX 4090)
- **CUDA**: 12.4+
- **Storage**: ~50GB for model weights

## Quick Start

### Docker (Recommended)

```bash
cd docker
docker compose -f docker-compose.dev.yml up trellis-3d -d

# Check status
curl http://localhost:5003/health
```

### Direct Installation

```bash
# Install dependencies
./scripts/install-trellis.sh

# Activate environment
trellis-activate

# Start web interface
trellis-run web
```

## API Usage

### Generate 3D Model

```bash
# Upload image and start generation
curl -X POST http://localhost:5003/generate \
  -F "image=@photo.png" \
  -F "resolution=1024"

# Response
{
  "job_id": "abc-123",
  "status": "queued",
  "check_status": "/status/abc-123"
}
```

### Check Status

```bash
curl http://localhost:5003/status/abc-123

# Response (when complete)
{
  "id": "abc-123",
  "status": "completed",
  "output_size": 15728640,
  "output_path": "/app/outputs/abc-123.glb"
}
```

### Download Model

```bash
curl -o model.glb http://localhost:5003/download/abc-123
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/generate` | POST | Upload image, start 3D generation |
| `/status/<id>` | GET | Check job status |
| `/download/<id>` | GET | Download generated GLB |
| `/jobs` | GET | List all jobs |
| `/health` | GET | Health check |

## Resolution vs Performance

| Resolution | Time* | GPU Memory | Detail Level |
|------------|-------|------------|--------------|
| 512³ | ~3s | ~16GB | Good |
| 1024³ | ~17s | ~20GB | High |
| 1536³ | ~60s | ~24GB | Maximum |

*Tested on NVIDIA H100

## Offline Operation

1. Pre-download model weights:
   ```bash
   ./scripts/install-trellis.sh --models-only
   ```

2. Mount weights to container:
   ```yaml
   volumes:
     - /opt/homelab/models/trellis2:/models
   ```

3. Generate without internet connection

## Output Format

Generated `.glb` files include:

- High-poly mesh (up to 1M triangles)
- 4K PBR textures
- Base Color map
- Roughness/Metallic maps
- Optional opacity/alpha

## Integration Examples

### Python

```python
import httpx

# Generate
with open("image.png", "rb") as f:
    resp = httpx.post(
        "http://localhost:5003/generate",
        files={"image": f},
        data={"resolution": 1024}
    )
job_id = resp.json()["job_id"]

# Poll for completion
while True:
    status = httpx.get(f"http://localhost:5003/status/{job_id}").json()
    if status["status"] == "completed":
        break
    time.sleep(5)

# Download
model = httpx.get(f"http://localhost:5003/download/{job_id}")
with open("output.glb", "wb") as f:
    f.write(model.content)
```

### JavaScript

```javascript
const formData = new FormData();
formData.append('image', imageFile);
formData.append('resolution', '1024');

const response = await fetch('http://localhost:5003/generate', {
  method: 'POST',
  body: formData
});

const { job_id } = await response.json();
```

## Troubleshooting

### Out of Memory

Reduce resolution or use a GPU with more VRAM:
```bash
curl -X POST http://localhost:5003/generate \
  -F "image=@photo.png" \
  -F "resolution=512"  # Lower resolution
```

### Pipeline Not Loading

Check GPU availability:
```bash
nvidia-smi
curl http://localhost:5003/health
```

## Links

- [TRELLIS.2 GitHub](https://github.com/microsoft/TRELLIS.2)
- [Paper](https://arxiv.org/abs/2512.14692)
- [HuggingFace Model](https://huggingface.co/microsoft/TRELLIS.2-4B)
