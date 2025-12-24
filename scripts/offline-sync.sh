#!/usr/bin/env bash
# ==============================================================================
# 📦 Offline Sync - Cache All Dependencies for Offline Operation
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Downloads and caches everything needed for offline operation:
#   - Ollama models (LLMs)
#   - Docker images
#   - npm packages
#   - Python packages
#   - TRELLIS.2 model weights
#   - ZIM files (optional)
#
# Usage:
#   chmod +x offline-sync.sh
#   sudo ./offline-sync.sh [--full|--minimal] [--include-zim]
# ==============================================================================

set -e

# Colors (some may be unused but kept for consistency)
# shellcheck disable=SC2034
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
PROFILE="${1:-standard}"
[[ "$PROFILE" == "--full" ]] && PROFILE="full"
[[ "$PROFILE" == "--minimal" ]] && PROFILE="minimal"
INCLUDE_ZIM=false
[[ "$*" == *"--include-zim"* ]] && INCLUDE_ZIM=true

CACHE_BASE="${CACHE_DIR:-/opt/homelab/cache}"
MODELS_DIR="${MODELS_DIR:-/opt/homelab/models}"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    📦 HomeLab Offline Sync                                    ║"
echo "║               Cache Everything for Offline Operation                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}Profile: ${PROFILE}${NC}"
echo -e "${BLUE}Cache: ${CACHE_BASE}${NC}"
echo ""

# Create directories
mkdir -p "${CACHE_BASE}"/{docker,npm,python,ollama}
mkdir -p "${MODELS_DIR}"/{ollama,trellis2}

# ==============================================================================
# 1. Ollama Models
# ==============================================================================

echo -e "${BLUE}[1/6] Syncing Ollama models...${NC}"

# Model list based on profile
case $PROFILE in
    minimal)
        OLLAMA_MODELS=("phi3" "tinyllama")
        ;;
    standard)
        OLLAMA_MODELS=("mistral" "codellama" "llama3.2")
        ;;
    full)
        OLLAMA_MODELS=(
            "mistral"
            "codellama"
            "llama3.2"
            "deepseek-r1:7b"
            "deepseek-coder:6.7b"
            "qwen2.5-coder:7b"
            "nomic-embed-text"
        )
        ;;
esac

# Pull models
for model in "${OLLAMA_MODELS[@]}"; do
    echo "Pulling Ollama model: ${model}"
    ollama pull "$model" || echo -e "${YELLOW}Warning: Failed to pull ${model}${NC}"
done

# Copy Ollama models to cache
if [[ -d "${HOME}/.ollama/models" ]]; then
    cp -r "${HOME}/.ollama/models"/* "${MODELS_DIR}/ollama/" 2>/dev/null || true
fi

echo -e "${GREEN}✓ Ollama models synced${NC}"

# ==============================================================================
# 2. Docker Images
# ==============================================================================

echo -e "${BLUE}[2/6] Caching Docker images...${NC}"

# Core images
DOCKER_IMAGES=(
    "ollama/ollama:latest"
    "ghcr.io/open-webui/open-webui:main"
    "postgres:15-alpine"
    "redis:7-alpine"
    "nginx:alpine"
    "portainer/portainer-ce:latest"
    "chromadb/chroma:latest"
)

# Profile-specific images
case $PROFILE in
    standard|full)
        DOCKER_IMAGES+=(
            "prom/prometheus:latest"
            "grafana/grafana:latest"
            "grafana/loki:latest"
            "blockscout/blockscout:latest"
            "us-docker.pkg.dev/oplabs-tools-artifacts/images/op-geth:latest"
        )
        ;;
esac

if [[ "$PROFILE" == "full" ]]; then
    DOCKER_IMAGES+=(
        "ghcr.io/foundry-rs/foundry:latest"
        "node:20-slim"
        "python:3.12-slim"
    )
fi

# Pull and save images
mkdir -p "${CACHE_BASE}/docker"
for image in "${DOCKER_IMAGES[@]}"; do
    echo "Pulling Docker image: ${image}"
    docker pull "$image" 2>/dev/null || echo -e "${YELLOW}Warning: Failed to pull ${image}${NC}"
done

# Save images to tar (for truly offline restore)
if [[ "$PROFILE" == "full" ]]; then
    echo "Saving Docker images to tar archive..."
    docker save "${DOCKER_IMAGES[@]}" | gzip > "${CACHE_BASE}/docker/homelab-images.tar.gz" 2>/dev/null || true
fi

echo -e "${GREEN}✓ Docker images cached${NC}"

# ==============================================================================
# 3. npm Packages
# ==============================================================================

echo -e "${BLUE}[3/6] Caching npm packages...${NC}"

NPM_CACHE="${CACHE_BASE}/npm"

# Create package cache using pnpm
if command -v pnpm &> /dev/null; then
    pnpm config set store-dir "${NPM_CACHE}/store"
fi

# Cache Hardhat dependencies
if [[ -f "../miniapps/hardhat-dev/package.json" ]]; then
    echo "Caching Hardhat dependencies..."
    cd ../miniapps/hardhat-dev
    npm pack --pack-destination "${NPM_CACHE}" 2>/dev/null || true
    pnpm install --prefer-offline 2>/dev/null || npm install 2>/dev/null || true
    cd -
fi

# Global packages to cache
NPM_PACKAGES=(
    "hardhat"
    "typescript"
    "ts-node"
    "prettier"
    "solhint"
)

for pkg in "${NPM_PACKAGES[@]}"; do
    npm cache add "$pkg" 2>/dev/null || true
done

echo -e "${GREEN}✓ npm packages cached${NC}"

# ==============================================================================
# 4. Python Packages
# ==============================================================================

echo -e "${BLUE}[4/6] Caching Python packages...${NC}"

PIP_CACHE="${CACHE_BASE}/python"

# Download packages for offline install
PIP_PACKAGES=(
    "langchain"
    "langchain-core"
    "langchain-community"
    "langchain-ollama"
    "langgraph"
    "crewai"
    "mcp"
    "chromadb"
    "flask"
    "fastapi"
    "uvicorn"
    "httpx"
    "pydantic"
)

pip download -d "${PIP_CACHE}" "${PIP_PACKAGES[@]}" 2>/dev/null || {
    echo -e "${YELLOW}Some Python packages failed to download${NC}"
}

echo -e "${GREEN}✓ Python packages cached${NC}"

# ==============================================================================
# 5. TRELLIS.2 Model Weights (Full profile only)
# ==============================================================================

if [[ "$PROFILE" == "full" ]]; then
    echo -e "${BLUE}[5/6] Downloading TRELLIS.2 model weights...${NC}"
    
    TRELLIS_MODELS="${MODELS_DIR}/trellis2"
    
    if command -v huggingface-cli &> /dev/null; then
        huggingface-cli download microsoft/TRELLIS.2-4B \
            --local-dir "${TRELLIS_MODELS}/TRELLIS.2-4B" \
            --local-dir-use-symlinks False \
            --resume-download 2>/dev/null || {
            echo -e "${YELLOW}TRELLIS.2 download failed (may need HF token)${NC}"
        }
    else
        echo -e "${YELLOW}huggingface-cli not found, skipping TRELLIS.2${NC}"
        echo "Install with: pip install huggingface_hub"
    fi
    
    echo -e "${GREEN}✓ TRELLIS.2 models synced${NC}"
else
    echo -e "${BLUE}[5/6] Skipping TRELLIS.2 (full profile only)${NC}"
fi

# ==============================================================================
# 6. ZIM Files (Optional)
# ==============================================================================

if [[ "$INCLUDE_ZIM" == "true" ]]; then
    echo -e "${BLUE}[6/6] Downloading ZIM files for Kiwix...${NC}"
    
    ZIM_DIR="${CACHE_BASE}/zim"
    mkdir -p "${ZIM_DIR}"
    
    case $PROFILE in
        minimal)
            ZIM_FILES=("wikipedia_en_simple_all_maxi")
            ;;
        standard)
            ZIM_FILES=("wikipedia_en_all_maxi")
            ;;
        full)
            ZIM_FILES=(
                "wikipedia_en_all_maxi"
                "wikibooks_en_all_maxi"
                "wikivoyage_en_all_maxi"
                "stackexchange_stackoverflow.com_en_all"
            )
            ;;
    esac
    
    for zim in "${ZIM_FILES[@]}"; do
        echo "Downloading: ${zim}"
        # Use download-all.sh if available
        if [[ -f "./download-all.sh" ]]; then
            ./download-all.sh --"${PROFILE}" --skip-ollama 2>/dev/null || true
        fi
    done
    
    echo -e "${GREEN}✓ ZIM files synced${NC}"
else
    echo -e "${BLUE}[6/6] Skipping ZIM files (use --include-zim to enable)${NC}"
fi

# ==============================================================================
# Summary
# ==============================================================================

echo -e "\n${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    ✓ Offline Sync Complete                                    ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Calculate cache size
CACHE_SIZE=$(du -sh "${CACHE_BASE}" 2>/dev/null | cut -f1)
MODELS_SIZE=$(du -sh "${MODELS_DIR}" 2>/dev/null | cut -f1)

echo "Cache Summary:"
echo "  Cache Directory: ${CACHE_BASE} (${CACHE_SIZE})"
echo "  Models Directory: ${MODELS_DIR} (${MODELS_SIZE})"
echo ""
echo "Cached Components:"
echo "  ✓ Ollama models (${#OLLAMA_MODELS[@]} models)"
echo "  ✓ Docker images (${#DOCKER_IMAGES[@]} images)"
echo "  ✓ npm packages"
echo "  ✓ Python packages"
if [[ "$PROFILE" == "full" ]]; then
    echo "  ✓ TRELLIS.2 model weights"
fi
if [[ "$INCLUDE_ZIM" == "true" ]]; then
    echo "  ✓ ZIM files for Kiwix"
fi
echo ""

echo -e "${BLUE}Offline Installation:${NC}"
echo "  1. Copy ${CACHE_BASE} and ${MODELS_DIR} to target machine"
echo "  2. Set CACHE_DIR and MODELS_DIR environment variables"
echo "  3. Run: ./init-homelab.sh --offline"
echo ""

# Create restore script
cat > "${CACHE_BASE}/restore-docker-images.sh" << 'EOF'
#!/bin/bash
# Restore Docker images from cache
if [[ -f "docker/homelab-images.tar.gz" ]]; then
    echo "Restoring Docker images..."
    gunzip -c docker/homelab-images.tar.gz | docker load
    echo "Done!"
else
    echo "No cached images found"
fi
EOF
chmod +x "${CACHE_BASE}/restore-docker-images.sh"

echo -e "${GREEN}Created: ${CACHE_BASE}/restore-docker-images.sh${NC}"
