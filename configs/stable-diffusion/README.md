# Stable Diffusion Configuration

This directory holds configuration files for AUTOMATIC1111 Stable Diffusion WebUI.

## Files

Place your custom configs here:
- `config.json` - WebUI settings
- `ui-config.json` - UI customizations
- `styles.csv` - Prompt styles

## Models

Models should be placed in `data/models/stable-diffusion/` directory:
- `models/Stable-diffusion/` - Checkpoint models (.safetensors, .ckpt)
- `models/Lora/` - LoRA models
- `models/VAE/` - VAE models

## Usage

```bash
docker compose -f docker/docker-compose.creative.yml up -d stable-diffusion
```

Access at: http://localhost:7860
