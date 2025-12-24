# MusicGen API

FastAPI service wrapping Meta's AudioCraft MusicGen model for AI music generation from text prompts.

## Features

- Text-to-music generation
- Multiple model sizes (small, medium, large, melody)
- Adjustable duration (up to 30 seconds)
- Melody conditioning support
- WAV/MP3 output formats

## Requirements

- **GPU**: NVIDIA GPU with 8GB+ VRAM (16GB for large model)
- **CUDA**: 11.7+ with cuDNN
- **Memory**: 16GB+ RAM

## Deployment

### Docker Compose (Recommended)

```bash
cd home.lab
docker compose -f docker/docker-compose.creative.yml up -d musicgen
```

### Standalone Docker

```bash
docker build -t musicgen .
docker run -d --gpus all -p 5012:5012 musicgen
```

## API Usage

### Generate Music

```bash
curl -X POST http://localhost:5012/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "upbeat electronic dance music with heavy bass",
    "duration": 10,
    "model": "small"
  }' \
  --output music.wav
```

### With Melody Conditioning

```bash
curl -X POST http://localhost:5012/generate \
  -F "prompt=jazz piano continuation" \
  -F "melody=@input_melody.wav" \
  -F "duration=15" \
  --output continuation.wav
```

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/generate` | POST | Generate music from prompt |
| `/models` | GET | List available models |
| `/health` | GET | Health check |

### Models

| Model | VRAM | Quality | Speed |
|-------|------|---------|-------|
| `small` | 4GB | Good | Fast |
| `medium` | 8GB | Better | Medium |
| `large` | 16GB | Best | Slow |
| `melody` | 8GB | Good + Melody | Medium |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MUSICGEN_MODEL` | `small` | Default model size |
| `MAX_DURATION` | `30` | Max generation length (seconds) |
| `CUDA_VISIBLE_DEVICES` | `0` | GPU device ID |

## Related Documentation

- [CREATIVE.md](../../docs/CREATIVE.md) - Creative AI Studio guide
- [docker-compose.creative.yml](../../docker/docker-compose.creative.yml) - Full creative stack
