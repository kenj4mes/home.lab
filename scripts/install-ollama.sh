#!/bin/bash
# ==============================================================================
# 🤖 Ollama Installation Script
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Installs Ollama and downloads recommended models
#
# Usage:
#   chmod +x install-ollama.sh
#   sudo ./install-ollama.sh
# ==============================================================================

set -e

# Colors (some may be unused but kept for consistency)
# shellcheck disable=SC2034
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                     🤖 Ollama Installation Script                             ║"
echo "║                     HomeLab - Self-Hosted Infrastructure                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ==============================================================================
# INSTALL OLLAMA
# ==============================================================================

echo -e "${BLUE}📦 Installing Ollama...${NC}"

# Official install script
curl -fsSL https://ollama.com/install.sh | sh

# Wait for service to start
sleep 3

# ==============================================================================
# CONFIGURE OLLAMA SERVICE
# ==============================================================================

echo -e "${BLUE}⚙️  Configuring Ollama service...${NC}"

# Create systemd override for custom settings
mkdir -p /etc/systemd/system/ollama.service.d

cat > /etc/systemd/system/ollama.service.d/override.conf << 'EOF'
[Service]
# Allow connections from any host (for Docker containers)
Environment="OLLAMA_HOST=0.0.0.0"

# Custom models directory (optional - uncomment to use)
# Environment="OLLAMA_MODELS=/srv/FlashBang/ollama/models"

# GPU settings (uncomment for NVIDIA)
# Environment="CUDA_VISIBLE_DEVICES=0"
EOF

systemctl daemon-reload
systemctl restart ollama
systemctl enable ollama

echo -e "${GREEN}✅ Ollama service configured${NC}"

# ==============================================================================
# DOWNLOAD MODELS
# ==============================================================================

echo -e "\n${BLUE}📥 Available models to download:${NC}"
echo "  1. mistral     (7B params, ~4GB)  - Fast, general purpose"
echo "  2. llama3.2    (3B params, ~2GB)  - Compact, fast"
echo "  3. codellama   (7B params, ~4GB)  - Code-focused"
echo "  4. phi3        (3.8B params, ~2GB) - Microsoft's compact model"
echo "  5. gemma2      (2B params, ~1.6GB) - Google's efficient model"
echo "  6. qwen2.5     (7B params, ~4GB)  - Multilingual"
echo "  7. deepseek-r1 (7B params, ~4GB)  - Reasoning focused"
echo ""

read -p "Enter model numbers to download (comma-separated, e.g., 1,2,3): " model_choices

# Parse choices and download
IFS=',' read -ra MODELS <<< "$model_choices"

for choice in "${MODELS[@]}"; do
    choice=$(echo "$choice" | tr -d ' ')
    case $choice in
        1) model="mistral" ;;
        2) model="llama3.2" ;;
        3) model="codellama" ;;
        4) model="phi3" ;;
        5) model="gemma2:2b" ;;
        6) model="qwen2.5" ;;
        7) model="deepseek-r1:7b" ;;
        *) continue ;;
    esac
    
    echo -e "\n${BLUE}📥 Downloading $model...${NC}"
    ollama pull $model
    echo -e "${GREEN}✅ $model downloaded${NC}"
done

# ==============================================================================
# VERIFY INSTALLATION
# ==============================================================================

echo -e "\n${BLUE}🔍 Verifying installation...${NC}"

echo -e "\n${YELLOW}📋 Installed models:${NC}"
ollama list

echo -e "\n${YELLOW}📋 Ollama service status:${NC}"
systemctl status ollama --no-pager || true

# ==============================================================================
# TEST
# ==============================================================================

echo -e "\n${BLUE}🧪 Testing Ollama...${NC}"

# Get first available model
first_model=$(ollama list | tail -n +2 | head -1 | awk '{print $1}')

if [[ -n "$first_model" ]]; then
    echo "Testing with model: $first_model"
    echo "Prompt: 'Say hello in exactly 5 words'"
    echo ""
    ollama run $first_model "Say hello in exactly 5 words" 2>/dev/null || echo "Test skipped"
fi

# ==============================================================================
# COMPLETE
# ==============================================================================

echo -e "\n${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                     ✅ Ollama Installation Complete!                          ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}📋 Usage:${NC}"
echo "  CLI:      ollama run mistral 'Your prompt here'"
echo "  API:      curl http://localhost:11434/api/generate -d '{\"model\":\"mistral\",\"prompt\":\"Hello\"}'"
echo "  Models:   ollama list"
echo "  Pull:     ollama pull <model-name>"
echo "  Remove:   ollama rm <model-name>"
echo ""

echo -e "${YELLOW}📋 API Endpoint:${NC}"
echo "  http://localhost:11434"
echo ""

echo -e "${YELLOW}📋 For Open WebUI (ChatGPT-like interface):${NC}"
echo "  docker run -d -p 3000:8080 -e OLLAMA_BASE_URL=http://host.docker.internal:11434 ghcr.io/open-webui/open-webui:main"
echo ""
