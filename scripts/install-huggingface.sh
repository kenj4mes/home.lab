#!/usr/bin/env bash
# ==============================================================================
# 🤗 Hugging Face Ecosystem Installer
# ==============================================================================
#
# Installs the complete Hugging Face ecosystem for HomeLab:
#   - huggingface-cli (model downloads, authentication)
#   - transformers (NLP models)
#   - diffusers (image/video generation)
#   - accelerate (GPU optimization)
#   - datasets, tokenizers, safetensors
#
# Usage:
#   ./install-huggingface.sh              # Standard install
#   ./install-huggingface.sh --minimal    # Core packages only
#   ./install-huggingface.sh --full       # All packages
#   ./install-huggingface.sh --login      # Login after install
#   ./install-huggingface.sh --cache /mnt/data/hf  # Custom cache
#
# ==============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;37m'
NC='\033[0m'

# Defaults
MINIMAL=false
FULL=false
LOGIN=false
OFFLINE=false
CACHE_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --minimal) MINIMAL=true; shift ;;
        --full) FULL=true; shift ;;
        --login) LOGIN=true; shift ;;
        --offline) OFFLINE=true; shift ;;
        --cache) CACHE_DIR="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ==============================================================================
# FUNCTIONS
# ==============================================================================

log_step() {
    echo -e "${CYAN}  ▶ $1${NC}"
}

log_success() {
    echo -e "${GREEN}  ✓ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}  ⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}  ✗ $1${NC}"
}

check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1)
        if [[ $PYTHON_VERSION =~ Python\ 3\.(9|10|11|12) ]]; then
            return 0
        fi
    fi
    return 1
}

install_package() {
    local package=$1
    if pip install --upgrade "$package" &> /dev/null; then
        echo -e "    ${GREEN}✓${NC} $package"
        return 0
    else
        echo -e "    ${RED}✗${NC} $package"
        return 1
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================

echo ""
echo -e "${CYAN}  ╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}  ║            🤗 Hugging Face Ecosystem Installer                   ║${NC}"
echo -e "${CYAN}  ╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check Python
log_step "Checking Python installation..."

if ! check_python; then
    log_error "Python 3.9+ required. Install with: sudo apt install python3 python3-pip"
    exit 1
fi

PYTHON_VERSION=$(python3 --version)
log_success "Found: $PYTHON_VERSION"

# Upgrade pip
log_step "Upgrading pip..."
python3 -m pip install --upgrade pip &> /dev/null
log_success "pip upgraded"

# Build package list
PACKAGES=()

if $MINIMAL; then
    log_step "Minimal install: Core packages only"
    PACKAGES=(
        "huggingface_hub"
        "transformers"
        "safetensors"
        "tokenizers"
    )
elif $FULL; then
    log_step "Full install: All Hugging Face packages"
    PACKAGES=(
        # Core
        "huggingface_hub"
        "transformers"
        "safetensors"
        "tokenizers"
        # Diffusion
        "diffusers"
        "accelerate"
        "invisible-watermark"
        # Audio
        "torchaudio"
        "soundfile"
        "librosa"
        # Datasets
        "datasets"
        "evaluate"
        # Vision
        "timm"
        "albumentations"
    )
else
    log_step "Standard install: Core + Diffusion packages"
    PACKAGES=(
        "huggingface_hub"
        "transformers"
        "safetensors"
        "tokenizers"
        "diffusers"
        "accelerate"
        "invisible-watermark"
    )
fi

# Install PyTorch first
log_step "Installing PyTorch..."

# Check for NVIDIA GPU
if command -v nvidia-smi &> /dev/null; then
    log_step "NVIDIA GPU detected, installing CUDA version..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 &> /dev/null && \
        log_success "PyTorch installed with CUDA 12.1 support" || \
        { log_warn "CUDA install failed, trying CPU..."; pip install torch torchvision torchaudio &> /dev/null; }
else
    pip install torch torchvision torchaudio &> /dev/null
    log_success "PyTorch installed (CPU)"
fi

# Install Hugging Face packages
log_step "Installing Hugging Face packages..."

SUCCESS_COUNT=0
FAIL_COUNT=0

for package in "${PACKAGES[@]}"; do
    if install_package "$package"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
done

if [[ $FAIL_COUNT -eq 0 ]]; then
    log_success "All $SUCCESS_COUNT packages installed successfully"
else
    log_warn "Installed: $SUCCESS_COUNT, Failed: $FAIL_COUNT"
fi

# Set cache directory
if [[ -n "$CACHE_DIR" ]]; then
    log_step "Setting cache directory..."
    mkdir -p "$CACHE_DIR"
    
    # Add to bashrc
    {
        echo ""
        echo "# Hugging Face cache"
        echo "export HF_HOME=\"$CACHE_DIR\""
        echo "export TRANSFORMERS_CACHE=\"$CACHE_DIR/hub\""
        echo "export HUGGINGFACE_HUB_CACHE=\"$CACHE_DIR/hub\""
    } >> ~/.bashrc
    
    export HF_HOME="$CACHE_DIR"
    export TRANSFORMERS_CACHE="$CACHE_DIR/hub"
    export HUGGINGFACE_HUB_CACHE="$CACHE_DIR/hub"
    
    log_success "Cache set to: $CACHE_DIR"
else
    DEFAULT_CACHE="$HOME/.cache/huggingface"
    log_step "Using default cache: $DEFAULT_CACHE"
fi

# Set offline mode
if $OFFLINE; then
    log_step "Enabling offline mode..."
    {
        echo "export HF_HUB_OFFLINE=1"
        echo "export TRANSFORMERS_OFFLINE=1"
    } >> ~/.bashrc
    log_success "Offline mode enabled"
fi

# Login if requested
if $LOGIN; then
    log_step "Logging in to Hugging Face..."
    echo ""
    echo -e "${YELLOW}  Get your token from: https://huggingface.co/settings/tokens${NC}"
    echo ""
    huggingface-cli login
fi

# Verify installation
log_step "Verifying installation..."

echo ""
echo -e "  ${CYAN}Installed versions:${NC}"

# Check transformers
if python3 -c "import transformers; print(f'    transformers: {transformers.__version__}')" 2>/dev/null; then
    :
else
    echo -e "    ${RED}✗ transformers not working${NC}"
fi

# Check diffusers
if python3 -c "import diffusers; print(f'    diffusers: {diffusers.__version__}')" 2>/dev/null; then
    :
else
    echo -e "    ${RED}✗ diffusers not working${NC}"
fi

# Check huggingface-cli
if HF_VERSION=$(huggingface-cli --version 2>/dev/null); then
    echo "    huggingface-cli: $HF_VERSION"
else
    echo -e "    ${RED}✗ huggingface-cli not working${NC}"
fi

# Summary
echo ""
echo -e "  ═══════════════════════════════════════════════════════════════════"
echo ""
echo -e "  ${GREEN}🤗 Hugging Face Installation Complete${NC}"
echo ""
echo -e "  ${CYAN}Quick Start Commands:${NC}"
echo -e "  ${GRAY}  huggingface-cli login              # Authenticate${NC}"
echo -e "  ${GRAY}  huggingface-cli download MODEL     # Download model${NC}"
echo -e "  ${GRAY}  huggingface-cli scan-cache         # View cached models${NC}"
echo -e "  ${GRAY}  huggingface-cli delete-cache       # Clean cache${NC}"
echo ""
echo -e "  ${CYAN}Environment Variables:${NC}"
echo -e "  ${GRAY}  HF_HOME          - Hugging Face cache root${NC}"
echo -e "  ${GRAY}  HF_TOKEN         - API token (or use huggingface-cli login)${NC}"
echo -e "  ${GRAY}  HF_HUB_OFFLINE   - Set to 1 for offline mode${NC}"
echo ""
echo -e "  ${CYAN}Recommended Models for HomeLab:${NC}"
echo -e "  ${GRAY}  huggingface-cli download stabilityai/stable-diffusion-xl-base-1.0${NC}"
echo -e "  ${GRAY}  huggingface-cli download openai/whisper-large-v3${NC}"
echo -e "  ${GRAY}  huggingface-cli download facebook/musicgen-medium${NC}"
echo -e "  ${GRAY}  huggingface-cli download suno/bark${NC}"
echo ""
