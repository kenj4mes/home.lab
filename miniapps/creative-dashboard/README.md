# Creative Dashboard

Unified web interface for all Creative AI Studio services including Stable Diffusion, ComfyUI, Bark TTS, Whisper, MusicGen, and Video Diffusion.

## Features

- Single-pane-of-glass for all creative services
- Service health monitoring
- Quick launch links to individual UIs
- Generation history and gallery
- Real-time GPU utilization display

## Deployment

### Docker Compose (Recommended)

```bash
cd home.lab
docker compose -f docker/docker-compose.creative.yml up -d creative-dashboard
```

### Standalone Docker

```bash
docker build -t creative-dashboard .
docker run -d -p 8190:80 creative-dashboard
```

## Access

- **URL**: http://localhost:8190
- **No authentication required**

## Service Links

| Service | Port | Dashboard Link |
|---------|------|----------------|
| Stable Diffusion | 7860 | Image Generation |
| ComfyUI | 8188 | Node-based Workflows |
| Bark TTS | 5010 | Text-to-Speech |
| Whisper | 5011 | Speech-to-Text |
| MusicGen | 5012 | AI Music |
| Video Diffusion | 5013 | Image-to-Video |

## Related Documentation

- [CREATIVE.md](../../docs/CREATIVE.md) - Creative AI Studio guide
- [docker-compose.creative.yml](../../docker/docker-compose.creative.yml) - Full creative stack
