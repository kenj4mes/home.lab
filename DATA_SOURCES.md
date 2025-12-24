# 📦 HomeLab Data Sources

> **Most data is included via Git LFS** - additional sources for expansion.

This document lists data files in HomeLab. Core assets are included via Git LFS.
Use the download scripts for additional models and content.

---

## ✅ Included via Git LFS (~29 GB)

These files are automatically downloaded when you clone the repository.

### 📚 Kiwix ZIM Files (~22 GB) - `data/zim/`

| File | Size | Status |
|------|------|--------|
| `wikipedia_en_all_mini_2025-12.zim` | 11.5 GB | ✅ Included |
| `electronics.stackexchange.com_en_all_2025-12.zim` | 3.9 GB | ✅ Included |
| `superuser.com_en_all_2025-12.zim` | 3.7 GB | ✅ Included |
| `askubuntu.com_en_all_2025-12.zim` | 2.6 GB | ✅ Included |
| `security.stackexchange.com_en_all_2025-12.zim` | 0.4 GB | ✅ Included |
| `archlinux_en_all_maxi_2025-09.zim` | 0.03 GB | ✅ Included |

### 🎨 Creative AI Models (~6.8 GB) - `data/models/`

| Model | Size | Status |
|-------|------|--------|
| `sd_xl_base_1.0.safetensors` | 6.6 GB | ✅ Included |
| `whisper/model.bin` | 138 MB | ✅ Included |

### ⛓️ Superchain Repositories (~1 GB) - `superchain/`

| Repository | Status |
|------------|--------|
| 21 OP-Stack L2 repos | ✅ Included |

---

## 📥 Optional Downloads

These are NOT included in the repo - download as needed.

### 🤖 Ollama LLM Models (~26 GB)

| Model | Size | Use Case |
|-------|------|----------|
| `llama3.2:3b` | 2.0 GB | Fast general chat |
| `llama3.2:1b` | 1.3 GB | Ultra-fast, low RAM |
| `mistral:7b` | 4.1 GB | Balanced performance |
| `phi3:mini` | 2.2 GB | Microsoft compact |
| `gemma2:2b` | 1.6 GB | Google lightweight |
| `codellama:7b` | 3.8 GB | Code generation |
| `deepseek-coder:6.7b` | 3.8 GB | Advanced coding |
| `nomic-embed-text` | 0.3 GB | Embeddings/RAG |
| `llava:7b` | 4.5 GB | Vision + text |
| `deepseek-r1:8b` | 4.9 GB | Reasoning |

### Download Command
```powershell
.\scripts\download-models.ps1
# Or individual:
ollama pull llama3.2:3b
```

### Source
All models from [Ollama Library](https://ollama.com/library)

---

## 🎨 Creative AI Models (~50 GB)

For image, audio, and video generation.

| Model | Size | Source |
|-------|------|--------|
| **Stable Diffusion XL** | 6.5 GB | [Hugging Face](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0) |
| **SDXL Refiner** | 6.0 GB | [Hugging Face](https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0) |
| **Whisper Large-v3** | 3.0 GB | [Hugging Face](https://huggingface.co/openai/whisper-large-v3) |
| **Bark TTS** | 5.0 GB | [Hugging Face](https://huggingface.co/suno/bark) |
| **MusicGen Medium** | 3.3 GB | [Hugging Face](https://huggingface.co/facebook/musicgen-medium) |
| **Stable Video Diffusion** | 9.0 GB | [Hugging Face](https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt) |

### Download Command
```powershell
.\scripts\download-creative-models.ps1
```

> **Note:** SDXL Base is already included via Git LFS. This downloads additional models.

---

## 📊 Total Storage Requirements

| Profile | Size | Contents |
|---------|------|----------|
| **Git Clone (LFS)** | ~29 GB | ZIM + SDXL + Whisper + Superchain ✅ |
| **+ Ollama Models** | ~55 GB | + Local LLMs (llama3, codellama, etc.) |
| **+ Creative AI** | ~100 GB | + Bark, MusicGen, SVD |
| **Full** | ~130 GB | Everything above combined |

---

## 🚀 Quick Start

### Already Included (via Git LFS)
After cloning with LFS, you already have:
- ✅ ZIM offline encyclopedias (~22 GB)
- ✅ SDXL + Whisper models (~6.8 GB)  
- ✅ Superchain repositories (~1 GB)

### Download Optional Extras
```powershell
# Windows - Add Ollama models
.\scripts\download-all.ps1 -Ollama

# Linux - Add Ollama models
./scripts/download-all.sh --ollama

# Add Creative AI (Bark, MusicGen, SVD)
.\scripts\download-all.ps1 -CreativeAI
```

### Verify Data
```powershell
# Check ZIM files (LFS-tracked)
Get-ChildItem .\data\zim -Filter "*.zim" | Measure-Object -Property Length -Sum

# Check AI models (LFS-tracked)
Get-ChildItem .\data\models -Recurse -File | Measure-Object -Property Length -Sum

# Check Ollama models (if installed)
ollama list

# Check Superchain repos (LFS-tracked)
Get-ChildItem .\superchain -Directory | Measure-Object
```

---

## 🤗 Hugging Face Tooling

For full Hugging Face functionality, install the ecosystem:

```powershell
# Windows
.\scripts\install-huggingface.ps1

# Linux/macOS
./scripts/install-huggingface.sh

# With options
.\scripts\install-huggingface.ps1 -Full -Login -CacheDir "D:\HF_Cache"
```

### Installed Packages
| Package | Purpose |
|---------|---------|
| `huggingface_hub` | CLI and API for model downloads |
| `transformers` | NLP/LLM models (BERT, GPT, LLaMA) |
| `diffusers` | Image/video diffusion (SDXL, SVD) |
| `accelerate` | GPU optimization and distributed training |
| `safetensors` | Secure model format |
| `tokenizers` | Fast tokenization |

### Key Commands
```bash
huggingface-cli login                    # Authenticate (for gated models)
huggingface-cli download MODEL_ID        # Download model
huggingface-cli scan-cache               # View cached models
huggingface-cli delete-cache             # Clean cache

# Download recommended models
huggingface-cli download stabilityai/stable-diffusion-xl-base-1.0
huggingface-cli download openai/whisper-large-v3
huggingface-cli download facebook/musicgen-medium
```

---

## 🔗 Alternative Mirrors

If primary sources are slow:

| Source | Mirror |
|--------|--------|
| Kiwix | `https://ftp.fau.de/kiwix/zim/` |
| Hugging Face | Use `huggingface-cli` with cache |
| Ollama | Self-host with `ollama serve` |

---

*Last updated: December 2025*
