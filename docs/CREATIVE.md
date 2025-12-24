# 🎨 Creative AI Stack

> **Multi-modal AI generation for images, audio, video, and 3D**

The Creative AI Stack brings powerful generative AI capabilities to your HomeLab, enabling text-to-image, text-to-speech, speech-to-text, music generation, and video synthesis—all running locally on your GPU.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Services](#services)
- [Quick Start](#quick-start)
- [GPU Requirements](#gpu-requirements)
- [API Reference](#api-reference)
- [Model Management](#model-management)
- [Integration Examples](#integration-examples)
- [Troubleshooting](#troubleshooting)

---

## Overview

| Service | Purpose | Port | GPU VRAM |
|---------|---------|------|----------|
| **Stable Diffusion** | Text-to-image generation | 7860 | 4-12 GB |
| **ComfyUI** | Node-based diffusion workflows | 8188 | 4-24 GB |
| **Bark TTS** | Text-to-speech with voice cloning | 5010 | 4 GB |
| **Faster-Whisper** | Speech-to-text transcription | 5011 | 2 GB |
| **MusicGen** | AI music generation | 5012 | 4-16 GB |
| **Video Diffusion** | Image-to-video generation | 5013 | 12-24 GB |
| **Creative Dashboard** | Unified web interface | 8190 | - |

---

## Services

### 🖼️ Stable Diffusion (Automatic1111 WebUI)

The most popular open-source text-to-image interface with extensive plugin support.

**Features:**
- Text-to-image (txt2img)
- Image-to-image (img2img)
- Inpainting and outpainting
- ControlNet for pose/depth control
- LoRA and fine-tuned model support
- Extensions ecosystem

**Access:** http://localhost:7860

```bash
# Generate image via API
curl -X POST http://localhost:7860/sdapi/v1/txt2img \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a cyberpunk cityscape at sunset, neon lights, rain",
    "negative_prompt": "blurry, low quality",
    "steps": 25,
    "width": 768,
    "height": 512,
    "cfg_scale": 7
  }'
```

### 🔀 ComfyUI

Node-based workflow editor for building complex diffusion pipelines.

**Features:**
- Visual graph editor
- Custom node support
- AnimateDiff for animation
- IPAdapter for style transfer
- Video frame-by-frame processing
- Workflow sharing

**Access:** http://localhost:8188

### 🗣️ Bark TTS

Neural text-to-speech with remarkable expressiveness.

**Features:**
- Multilingual (13+ languages)
- Voice presets and cloning
- Sound effects generation ([laughs], [sighs], ♪)
- Emotional expression

**API Example:**
```bash
# Generate speech
curl -X POST http://localhost:5010/synthesize \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello! [laughs] How are you today?",
    "voice": "v2/en_speaker_6",
    "output_format": "wav"
  }' -o speech.wav
```

**Special Tokens:**
- `[laughs]` - Laughter
- `[sighs]` - Sighing
- `[music]` - Music/singing
- `[clears throat]` - Throat clearing
- `♪` - Singing
- `...` - Hesitation
- `—` - Pause

### 🎤 Faster-Whisper

GPU-accelerated speech recognition using CTranslate2 optimized Whisper.

**Features:**
- Real-time transcription
- 99+ language support
- Automatic language detection
- Timestamps and word-level timing
- VAD (Voice Activity Detection)

**API Example:**
```bash
# Transcribe audio file
curl -X POST http://localhost:5011/api/transcribe \
  -F "audio=@recording.wav" \
  -F "language=en" \
  -F "task=transcribe"
```

### 🎵 MusicGen

Meta's AudioCraft for AI-powered music generation.

**Features:**
- Text-to-music generation
- Melody conditioning
- Multiple model sizes (300M - 3.3B params)
- Up to 30 seconds per generation

**API Example:**
```bash
# Generate music
curl -X POST http://localhost:5012/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "epic orchestral theme with powerful drums",
    "duration": 15
  }' -o music.wav
```

**Model Sizes:**
| Model | Parameters | VRAM | Quality |
|-------|------------|------|---------|
| small | 300M | 4 GB | Fast, good |
| medium | 1.5B | 8 GB | Balanced |
| large | 3.3B | 16 GB | Highest |

### 🎬 Stable Video Diffusion

Generate short video clips from images.

**Features:**
- Image-to-video generation
- 14 or 25 frame output
- Motion control (motion_bucket_id)
- 576x1024 resolution

**API Example:**
```bash
# Generate video from image
curl -X POST http://localhost:5013/generate \
  -H "Content-Type: application/json" \
  -d '{
    "image": "'$(base64 -w0 input.jpg)'",
    "frames": 14,
    "fps": 7,
    "motion_bucket_id": 127
  }' -o video.mp4
```

---

## Quick Start

### Start All Creative Services

```powershell
# Using homelab.ps1
.\homelab.ps1 -Action creative

# Using docker compose directly
cd docker
docker compose -f docker-compose.creative.yml --profile creative up -d
```

### Start Specific Profile

```powershell
# Image generation only
docker compose -f docker-compose.creative.yml --profile image-gen up -d

# Audio services only
docker compose -f docker-compose.creative.yml --profile audio up -d

# Video generation
docker compose -f docker-compose.creative.yml --profile video up -d
```

### Check Status

```powershell
.\homelab.ps1 -Action health

# Or check individual services
curl http://localhost:7860/sdapi/v1/options  # Stable Diffusion
curl http://localhost:5010/health             # Bark TTS
curl http://localhost:5012/health             # MusicGen
```

---

## GPU Requirements

### Minimum Requirements

| Service | Min VRAM | Recommended |
|---------|----------|-------------|
| Stable Diffusion (SD 1.5) | 4 GB | 8 GB |
| Stable Diffusion (SDXL) | 8 GB | 12 GB |
| ComfyUI | 4 GB | 12 GB |
| Bark TTS | 4 GB | 6 GB |
| Faster-Whisper | 2 GB | 4 GB |
| MusicGen (small) | 4 GB | 6 GB |
| MusicGen (large) | 16 GB | 24 GB |
| Video Diffusion | 12 GB | 24 GB |

### NVIDIA Driver Setup

```powershell
# Verify NVIDIA driver
nvidia-smi

# Install nvidia-container-toolkit (Linux)
# Windows: Ensure WSL2 + Docker Desktop with GPU support

# Test GPU access in Docker
docker run --rm --gpus all nvidia/cuda:12.1-base nvidia-smi
```

---

## API Reference

### Stable Diffusion API

```
POST /sdapi/v1/txt2img       - Generate image from text
POST /sdapi/v1/img2img       - Image-to-image transformation
GET  /sdapi/v1/sd-models     - List available models
GET  /sdapi/v1/samplers      - List available samplers
POST /sdapi/v1/options       - Get/set options
```

### Bark TTS API

```
POST /synthesize             - Generate speech
GET  /voices                 - List voice presets
GET  /health                 - Health check
```

### MusicGen API

```
POST /generate               - Generate music from prompt
POST /generate_with_melody   - Generate with melody conditioning
GET  /health                 - Health check
```

### Video Diffusion API

```
POST /generate               - Generate video from base64 image
POST /generate_from_url      - Generate video from image URL
GET  /health                 - Health check
```

---

## Model Management

### Pre-download Models (Offline Operation)

```powershell
# Run the model download script
.\scripts\download-creative-models.ps1

# Or manually download to volumes
# Stable Diffusion models
docker run --rm -v homelab-sd-models:/models alpine \
  wget -P /models/Stable-diffusion \
  https://huggingface.co/stabilityai/sdxl/resolve/main/sd_xl_base_1.0.safetensors
```

### Model Locations

| Service | Volume | Path in Container |
|---------|--------|-------------------|
| Stable Diffusion | homelab-sd-models | /stable-diffusion-webui/models |
| ComfyUI | homelab-comfyui-models | /ComfyUI/models |
| Bark | homelab-bark-models | /app/models |
| MusicGen | homelab-musicgen-models | /app/models |
| Video Diffusion | homelab-video-diffusion-models | /app/models |

---

## Integration Examples

### LangGraph Agent with Image Generation

```python
from langchain_core.tools import tool
import requests
import base64

@tool
def generate_image(prompt: str, width: int = 512, height: int = 512) -> str:
    """Generate an image using Stable Diffusion."""
    response = requests.post(
        "http://stable-diffusion:7860/sdapi/v1/txt2img",
        json={
            "prompt": prompt,
            "width": width,
            "height": height,
            "steps": 20
        }
    )
    images = response.json()["images"]
    return f"data:image/png;base64,{images[0]}"
```

### Multi-modal Pipeline

```python
# Generate story narration with music
async def create_story_video(story_text: str):
    # 1. Generate speech
    speech = requests.post(
        "http://bark-tts:5000/synthesize",
        json={"text": story_text}
    ).content
    
    # 2. Generate background music
    music = requests.post(
        "http://musicgen:5000/generate",
        json={"prompt": "ambient storytelling music", "duration": 30}
    ).content
    
    # 3. Generate scene images
    images = [
        generate_image(scene) 
        for scene in extract_scenes(story_text)
    ]
    
    # 4. Create video from images
    video = requests.post(
        "http://video-diffusion:5000/generate",
        json={"image": images[0], "frames": 25}
    ).content
    
    return combine_media(speech, music, video)
```

---

## Troubleshooting

### Common Issues

**CUDA Out of Memory**
```bash
# Reduce batch size in SD WebUI settings
# Or use --lowvram flag
COMMANDLINE_ARGS=--lowvram --medvram
```

**Model Not Loading**
```bash
# Check if model files exist
docker exec stable-diffusion ls -la /stable-diffusion-webui/models/Stable-diffusion/

# Check logs
docker logs stable-diffusion
```

**Services Not Starting**
```bash
# Check GPU availability
docker run --rm --gpus all nvidia/cuda:12.1-base nvidia-smi

# Verify nvidia-container-toolkit
docker info | grep -i nvidia
```

### Performance Optimization

1. **Use FP16 precision** - Enabled by default
2. **Enable xformers** - `COMMANDLINE_ARGS=--xformers`
3. **Use VAE tiling** - For large images
4. **Offload to CPU** - `--medvram` or `--lowvram`

---

## Service URLs Summary

| Service | URL | Notes |
|---------|-----|-------|
| Stable Diffusion | http://localhost:7860 | Full WebUI |
| ComfyUI | http://localhost:8188 | Node editor |
| Bark TTS | http://localhost:5010 | API only |
| Faster-Whisper | http://localhost:5011 | API only |
| MusicGen | http://localhost:5012 | API only |
| Video Diffusion | http://localhost:5013 | API only |
| Creative Dashboard | http://localhost:8190 | Unified UI |

---

## Resources

- [Stable Diffusion WebUI](https://github.com/AUTOMATIC1111/stable-diffusion-webui)
- [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- [Bark](https://github.com/suno-ai/bark)
- [Faster-Whisper](https://github.com/guillaumekln/faster-whisper)
- [AudioCraft (MusicGen)](https://github.com/facebookresearch/audiocraft)
- [Stable Video Diffusion](https://stability.ai/stable-video)
