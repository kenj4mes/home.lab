# Video Diffusion API

FastAPI service wrapping Stability AI's Stable Video Diffusion for image-to-video generation.

## Features

- Image-to-video generation
- Configurable motion and FPS
- Multiple output formats (MP4, GIF, WebM)
- Resolution control
- GPU acceleration required

## Requirements

- **GPU**: NVIDIA GPU with 24GB+ VRAM
- **CUDA**: 11.7+ with cuDNN
- **Memory**: 32GB+ RAM

## ⚠️ Resource Warning

SVD requires significant GPU memory. The XT model needs 24GB VRAM minimum.

## Deployment

### Docker Compose (Recommended)

```bash
cd home.lab
docker compose -f docker/docker-compose.creative.yml --profile gpu up -d video-diffusion
```

### Standalone Docker

```bash
docker build -t video-diffusion .
docker run -d --gpus all -p 5013:5013 video-diffusion
```

## API Usage

### Generate Video from Image

```bash
curl -X POST http://localhost:5013/generate \
  -F "image=@input.png" \
  -F "motion_bucket_id=127" \
  -F "fps=6" \
  -F "num_frames=25" \
  --output video.mp4
```

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/generate` | POST | Generate video from image |
| `/health` | GET | Health check |

### Parameters

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `motion_bucket_id` | 127 | 1-255 | Motion intensity |
| `fps` | 6 | 1-30 | Frames per second |
| `num_frames` | 25 | 14-30 | Number of frames |
| `decode_chunk_size` | 8 | 1-16 | VRAM optimization |

## Models

| Model | VRAM | Frames | Quality |
|-------|------|--------|---------|
| `svd` | 16GB | 14 | Good |
| `svd-xt` | 24GB | 25 | Best |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SVD_MODEL` | `svd-xt` | Model variant |
| `VIDEO_OUTPUT_PATH` | `/data/videos` | Output directory |
| `CUDA_VISIBLE_DEVICES` | `0` | GPU device ID |

## Related Documentation

- [CREATIVE.md](../../docs/CREATIVE.md) - Creative AI Studio guide
- [docker-compose.creative.yml](../../docker/docker-compose.creative.yml) - Full creative stack
