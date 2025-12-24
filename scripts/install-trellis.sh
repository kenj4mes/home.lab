#!/usr/bin/env bash
# ==============================================================================
# 🎨 TRELLIS.2 - Image to 3D Model Installation
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Installs Microsoft TRELLIS.2 for image-to-3D generation:
#   - CUDA Toolkit 12.4
#   - PyTorch 2.6+ with CUDA
#   - TRELLIS.2 repository & dependencies
#   - Model weights from HuggingFace
#   - FlexGEMM, CuMesh, O-Voxel
#
# Requirements:
#   - NVIDIA GPU with 24GB+ VRAM (A100, H100, RTX 4090)
#   - Linux system with CUDA support
#   - ~50GB storage for models
#
# Usage:
#   chmod +x install-trellis.sh
#   sudo ./install-trellis.sh [--models-only]
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
MODELS_ONLY="${1:-false}"
[[ "$1" == "--models-only" ]] && MODELS_ONLY="true"

INSTALL_DIR="${TRELLIS_DIR:-/opt/homelab/trellis2}"
MODELS_DIR="${MODELS_DIR:-/opt/homelab/models/trellis2}"
CONDA_ENV="${TRELLIS_ENV:-trellis2}"
PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
CUDA_VERSION="${CUDA_VERSION:-12.4}"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    🎨 TRELLIS.2 Image-to-3D                                   ║"
echo "║                 Microsoft 4B Parameter 3D Generator                           ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check for NVIDIA GPU
check_gpu() {
    if ! command -v nvidia-smi &> /dev/null; then
        echo -e "${RED}ERROR: NVIDIA GPU not detected or drivers not installed${NC}"
        echo "TRELLIS.2 requires an NVIDIA GPU with 24GB+ VRAM"
        echo "Supported: A100, H100, RTX 4090, RTX A6000"
        exit 1
    fi
    
    GPU_MEM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
    if [[ "${GPU_MEM}" -lt 20000 ]]; then
        echo -e "${YELLOW}WARNING: GPU has ${GPU_MEM}MB VRAM${NC}"
        echo "TRELLIS.2 recommends 24GB+ for full resolution"
        echo "Lower resolutions may work with less VRAM"
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi
    
    echo -e "${GREEN}✓ GPU detected: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)${NC}"
    echo -e "${GREEN}✓ VRAM: ${GPU_MEM}MB${NC}"
}

# ==============================================================================
# 1. Check Prerequisites
# ==============================================================================

echo -e "${BLUE}[1/6] Checking prerequisites...${NC}"

check_gpu

# Check for conda
if ! command -v conda &> /dev/null; then
    echo "Installing Miniconda..."
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p /opt/miniconda3
    export PATH="/opt/miniconda3/bin:$PATH"
    conda init bash
    # shellcheck source=/dev/null
    source ~/.bashrc
    echo -e "${GREEN}✓ Miniconda installed${NC}"
else
    echo -e "${YELLOW}○ Conda already installed${NC}"
fi

# Check CUDA
if [[ ! -d "/usr/local/cuda-${CUDA_VERSION}" ]]; then
    echo -e "${YELLOW}CUDA ${CUDA_VERSION} not found at expected location${NC}"
    echo "Will rely on PyTorch's bundled CUDA"
fi

echo -e "${GREEN}✓ Prerequisites checked${NC}"

# ==============================================================================
# 2. Clone Repository
# ==============================================================================

echo -e "${BLUE}[2/6] Cloning TRELLIS.2 repository...${NC}"

mkdir -p "$(dirname "${INSTALL_DIR}")"

if [[ -d "${INSTALL_DIR}" ]]; then
    echo -e "${YELLOW}○ TRELLIS.2 directory exists, updating...${NC}"
    cd "${INSTALL_DIR}"
    git pull --recurse-submodules || true
else
    git clone --recursive https://github.com/microsoft/TRELLIS.2.git "${INSTALL_DIR}"
    cd "${INSTALL_DIR}"
fi

echo -e "${GREEN}✓ Repository ready at ${INSTALL_DIR}${NC}"

# ==============================================================================
# 3. Create Conda Environment
# ==============================================================================

if [[ "$MODELS_ONLY" == "true" ]]; then
    echo -e "${YELLOW}○ Skipping environment setup (--models-only)${NC}"
else
    echo -e "${BLUE}[3/6] Creating Conda environment...${NC}"
    
    # Create or update environment
    if conda env list | grep -q "^${CONDA_ENV} "; then
        echo -e "${YELLOW}○ Environment ${CONDA_ENV} exists, activating...${NC}"
    else
        echo "Creating new environment: ${CONDA_ENV}"
        conda create -n "${CONDA_ENV}" python="${PYTHON_VERSION}" -y
    fi
    
    # Activate environment
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate "${CONDA_ENV}"
    
    echo -e "${GREEN}✓ Environment ${CONDA_ENV} ready${NC}"
    
    # ==============================================================================
    # 4. Install Dependencies
    # ==============================================================================
    
    echo -e "${BLUE}[4/6] Installing dependencies...${NC}"
    
    cd "${INSTALL_DIR}"
    
    # Run the official setup script
    echo "Running TRELLIS.2 setup (this may take 15-30 minutes)..."
    
    # Set CUDA home
    export CUDA_HOME="${CUDA_HOME:-/usr/local/cuda}"
    
    # Run setup with all components
    . ./setup.sh --basic --flash-attn --nvdiffrast --nvdiffrec --cumesh --o-voxel --flexgemm 2>&1 | tee /tmp/trellis-setup.log || {
        echo -e "${YELLOW}Some components may have failed, checking...${NC}"
    }
    
    # Verify core imports
    python -c "import torch; print(f'PyTorch: {torch.__version__}')" || {
        echo -e "${RED}PyTorch import failed${NC}"
        exit 1
    }
    
    python -c "import trellis2; print('TRELLIS.2 module loaded')" || {
        echo -e "${YELLOW}TRELLIS.2 module not found, installing...${NC}"
        pip install -e .
    }
    
    echo -e "${GREEN}✓ Dependencies installed${NC}"
fi

# ==============================================================================
# 5. Download Model Weights
# ==============================================================================

echo -e "${BLUE}[5/6] Downloading TRELLIS.2-4B model weights...${NC}"

mkdir -p "${MODELS_DIR}"

# Check for HuggingFace CLI
if ! command -v huggingface-cli &> /dev/null; then
    pip install huggingface_hub
fi

# Download model
echo "Downloading from HuggingFace (this may take a while, ~20GB)..."
MODEL_REPO="microsoft/TRELLIS.2-4B"

if [[ -d "${MODELS_DIR}/TRELLIS.2-4B" ]] && [[ -f "${MODELS_DIR}/TRELLIS.2-4B/config.json" ]]; then
    echo -e "${YELLOW}○ Model weights already downloaded${NC}"
else
    huggingface-cli download "${MODEL_REPO}" \
        --local-dir "${MODELS_DIR}/TRELLIS.2-4B" \
        --local-dir-use-symlinks False \
        --resume-download
    
    echo -e "${GREEN}✓ Model weights downloaded to ${MODELS_DIR}/TRELLIS.2-4B${NC}"
fi

# Create symlink for easy access
if [[ ! -L "${INSTALL_DIR}/weights" ]]; then
    ln -sf "${MODELS_DIR}/TRELLIS.2-4B" "${INSTALL_DIR}/weights"
fi

# ==============================================================================
# 6. Create Helper Scripts
# ==============================================================================

echo -e "${BLUE}[6/6] Creating helper scripts...${NC}"

# Create activation script
cat > /usr/local/bin/trellis-activate << EOF
#!/bin/bash
# Activate TRELLIS.2 environment

export TRELLIS_DIR="${INSTALL_DIR}"
export CUDA_HOME="${CUDA_HOME:-/usr/local/cuda}"
export OPENCV_IO_ENABLE_OPENEXR=1
export PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True"

source "\$(conda info --base)/etc/profile.d/conda.sh"
conda activate ${CONDA_ENV}

cd "${INSTALL_DIR}"

echo "TRELLIS.2 environment activated"
echo "Run 'python app.py' for web interface"
echo "Run 'python example.py' for CLI example"
EOF
chmod +x /usr/local/bin/trellis-activate

# Create runner script
cat > /usr/local/bin/trellis-run << EOF
#!/bin/bash
# Run TRELLIS.2 with proper environment

source /usr/local/bin/trellis-activate

case "\${1:-web}" in
    web)
        echo "Starting TRELLIS.2 web interface..."
        python app.py --share
        ;;
    example)
        echo "Running example generation..."
        python example.py
        ;;
    api)
        echo "Starting API server..."
        python -m trellis2.serve --host 0.0.0.0 --port 5003
        ;;
    *)
        echo "Usage: trellis-run [web|example|api]"
        ;;
esac
EOF
chmod +x /usr/local/bin/trellis-run

# Create systemd service
cat > /etc/systemd/system/trellis2.service << EOF
[Unit]
Description=TRELLIS.2 Image-to-3D API Server
After=network.target

[Service]
Type=simple
User=root
Environment="CUDA_HOME=/usr/local/cuda"
Environment="OPENCV_IO_ENABLE_OPENEXR=1"
Environment="PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True"
WorkingDirectory=${INSTALL_DIR}
ExecStart=/bin/bash -c 'source /usr/local/bin/trellis-activate && python app.py --share --server-port 5003'
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# ==============================================================================
# Summary
# ==============================================================================

echo -e "\n${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                  ✓ TRELLIS.2 Installation Complete                            ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo "Installation Details:"
echo "  ✓ Repository: ${INSTALL_DIR}"
echo "  ✓ Model Weights: ${MODELS_DIR}/TRELLIS.2-4B"
echo "  ✓ Conda Environment: ${CONDA_ENV}"
echo ""
echo "Commands:"
echo "  trellis-activate    - Activate environment"
echo "  trellis-run web     - Start web interface (port 7860)"
echo "  trellis-run example - Run example generation"
echo "  trellis-run api     - Start API server (port 5003)"
echo ""
echo "Systemd Service:"
echo "  sudo systemctl enable trellis2"
echo "  sudo systemctl start trellis2"
echo ""
echo "Capabilities:"
echo "  • Image → 3D model (GLB/GLTF)"
echo "  • PBR material generation"
echo "  • 512³ to 1536³ resolution"
echo "  • ~3-60s generation time"
echo ""

echo -e "${BLUE}Documentation: docs/TRELLIS.md${NC}"
echo -e "${BLUE}GPU Memory Usage: ~20GB for 1024³ resolution${NC}"
