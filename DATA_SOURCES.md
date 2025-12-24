# 📦 HomeLab Data Sources

> **Pre-download these assets for offline operation.**

This document lists all large data files needed for a complete HomeLab installation.
Use the download scripts or manually fetch from the sources below.

---

## 📚 Kiwix ZIM Files (~22 GB)

Offline knowledge bases for air-gapped operation.

| File | Size | Source |
|------|------|--------|
| `wikipedia_en_all_mini_2025-12.zim` | 11.5 GB | [Kiwix](https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_mini_2025-12.zim) |
| `electronics.stackexchange.com_en_all_2025-12.zim` | 3.9 GB | [Kiwix](https://download.kiwix.org/zim/stack_exchange/electronics.stackexchange.com_en_all_2025-12.zim) |
| `superuser.com_en_all_2025-12.zim` | 3.7 GB | [Kiwix](https://download.kiwix.org/zim/stack_exchange/superuser.com_en_all_2025-12.zim) |
| `askubuntu.com_en_all_2025-12.zim` | 2.6 GB | [Kiwix](https://download.kiwix.org/zim/stack_exchange/askubuntu.com_en_all_2025-12.zim) |
| `security.stackexchange.com_en_all_2025-12.zim` | 0.4 GB | [Kiwix](https://download.kiwix.org/zim/stack_exchange/security.stackexchange.com_en_all_2025-12.zim) |
| `archlinux_en_all_maxi_2025-09.zim` | 0.03 GB | [Kiwix](https://download.kiwix.org/zim/other/archlinux_en_all_maxi_2025-09.zim) |

### Download Command
```powershell
.\scripts\download-zim-fast.ps1
```

---

## 🤖 Ollama LLM Models (~26 GB)

Local language models for AI inference.

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

---

## ⛓️ Superchain Repositories (~1 GB)

OP-Stack L2 blockchain source code.

| Repository | Category | Source |
|------------|----------|--------|
| `optimism` | Core | [GitHub](https://github.com/ethereum-optimism/optimism) |
| `op-geth` | Execution | [GitHub](https://github.com/ethereum-optimism/op-geth) |
| `base-node` | L2 | [GitHub](https://github.com/base-org/node) |
| `unichain-node` | L2 | [GitHub](https://github.com/Uniswap/unichain-node) |
| `superchain-registry` | Registry | [GitHub](https://github.com/ethereum-optimism/superchain-registry) |
| *...17 more* | Various | See script |

### Clone Command
```powershell
.\scripts\clone-superchain.ps1 -DestinationPath ".\superchain" -ShallowClone
```

---

## 📊 Total Storage Requirements

| Profile | Size | Contents |
|---------|------|----------|
| **Minimal** | ~26 GB | Ollama models only |
| **Standard** | ~50 GB | + ZIM files |
| **Full** | ~100 GB | + Creative AI models |
| **Complete** | ~101 GB | + Superchain repos |

---

## 🚀 Quick Start

### Download Everything
```powershell
# Windows
.\scripts\download-all.ps1 -Full

# Linux
./scripts/download-all.sh --full
```

### Verify Downloads
```powershell
# Check ZIM files
Get-ChildItem .\data\zim -Filter "*.zim" | Measure-Object -Property Length -Sum

# Check Ollama models
ollama list

# Check Superchain repos
Get-ChildItem .\superchain -Directory | Measure-Object
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
