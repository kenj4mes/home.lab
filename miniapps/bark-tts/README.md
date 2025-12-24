# Bark TTS API

FastAPI service wrapping Suno's Bark text-to-speech model for realistic multi-speaker voice synthesis.

## Features

- Multi-speaker voice synthesis (10+ voice presets)
- Emotion and tone control via prompts
- Multiple audio format outputs (WAV, MP3, OGG)
- GPU acceleration support (CUDA)
- REST API for easy integration

## Requirements

- **GPU**: NVIDIA GPU with 4GB+ VRAM (8GB recommended)
- **CUDA**: 11.7+ with cuDNN
- **Memory**: 8GB+ RAM

## Deployment

### Docker Compose (Recommended)

```bash
cd home.lab
docker compose -f docker/docker-compose.creative.yml up -d bark-tts
```

### Standalone Docker

```bash
docker build -t bark-tts .
docker run -d --gpus all -p 5010:5010 bark-tts
```

## API Usage

### Synthesize Speech

```bash
curl -X POST http://localhost:5010/synthesize \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello, welcome to HomeLab!",
    "voice": "v2/en_speaker_0",
    "output_format": "wav"
  }' \
  --output speech.wav
```

### Available Voices

| Voice ID | Description |
|----------|-------------|
| `v2/en_speaker_0` | English Male 1 |
| `v2/en_speaker_1` | English Male 2 |
| `v2/en_speaker_2` | English Female 1 |
| `v2/en_speaker_3` | English Female 2 |
| `v2/en_speaker_6` | English Male (Narrator) |
| `v2/de_speaker_0` | German |
| `v2/es_speaker_0` | Spanish |
| `v2/fr_speaker_0` | French |
| `v2/ja_speaker_0` | Japanese |
| `v2/zh_speaker_0` | Chinese |

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/synthesize` | POST | Generate speech from text |
| `/voices` | GET | List available voice presets |
| `/health` | GET | Health check |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BARK_SMALL_MODEL` | `false` | Use smaller model (less VRAM) |
| `BARK_USE_GPU` | `true` | Enable GPU acceleration |
| `SUNO_USE_SMALL_MODELS` | `false` | Alias for BARK_SMALL_MODEL |

## Related Documentation

- [CREATIVE.md](../../docs/CREATIVE.md) - Creative AI Studio guide
- [docker-compose.creative.yml](../../docker/docker-compose.creative.yml) - Full creative stack
