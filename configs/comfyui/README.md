# ComfyUI Configuration

This directory holds configuration files for ComfyUI node-based image generation.

## Files

Place your custom configs here:
- `extra_model_paths.yaml` - Additional model paths
- Custom workflows (.json)

## Models

Models should be placed in `data/models/comfyui/` directory:
- `models/checkpoints/` - Checkpoint models
- `models/loras/` - LoRA models
- `models/vae/` - VAE models
- `models/controlnet/` - ControlNet models

## Usage

```bash
docker compose -f docker/docker-compose.creative.yml up -d comfyui
```

Access at: http://localhost:8188
