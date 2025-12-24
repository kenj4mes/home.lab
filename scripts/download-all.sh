#!/bin/bash
# ==============================================================================
# 📥 HomeLab Complete Download Script
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Downloads ALL required files for a complete offline HomeLab:
#   - Kiwix ZIM files (Wikipedia, Stack Overflow, etc.)
#   - Ollama models
#   - Creates required directory structure
#
# Usage:
#   chmod +x download-all.sh
#   sudo ./download-all.sh [OPTIONS]
#
# Options:
#   --minimal     Download minimal set (~5 GB total)
#   --standard    Download standard set (~50 GB total) [DEFAULT]
#   --full        Download everything (~250+ GB total)
#   --skip-zim    Skip Kiwix ZIM downloads
#   --skip-ollama Skip Ollama model downloads
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default paths (customize in .env or override here)
MEDIA_PATH="${MEDIA_PATH:-/srv/homelab/data}"
CONFIG_PATH="${CONFIG_PATH:-/srv/homelab/config}"
ZIM_PATH="${MEDIA_PATH}/ZIM"
OLLAMA_PATH="${CONFIG_PATH}/ollama"

# Default profile
PROFILE="standard"
SKIP_ZIM=false
SKIP_OLLAMA=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --minimal)  PROFILE="minimal"; shift ;;
        --standard) PROFILE="standard"; shift ;;
        --full)     PROFILE="full"; shift ;;
        --skip-zim) SKIP_ZIM=true; shift ;;
        --skip-ollama) SKIP_OLLAMA=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                     📥 HomeLab Complete Download Script                       ║"
echo "║                     HomeLab - Self-Hosted Infrastructure                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}Profile: ${PROFILE}${NC}"
echo -e "${CYAN}ZIM Path: ${ZIM_PATH}${NC}"
echo -e "${CYAN}Ollama Path: ${OLLAMA_PATH}${NC}"
echo ""

# ==============================================================================
# ESTIMATE SIZES
# ==============================================================================

case $PROFILE in
    minimal)
        echo -e "${YELLOW}📊 Estimated downloads:${NC}"
        echo "  - Wikipedia (Simple English, no pics): ~500 MB"
        echo "  - Ollama (phi3 - small model): ~2 GB"
        echo "  - Total: ~2.5 GB"
        ;;
    standard)
        echo -e "${YELLOW}📊 Estimated downloads:${NC}"
        echo "  - Wikipedia (English, no pics): ~20 GB"
        echo "  - Stack Overflow: ~5 GB"
        echo "  - Wikibooks: ~2 GB"
        echo "  - Ollama (mistral + codellama): ~8 GB"
        echo "  - Total: ~35 GB"
        ;;
    full)
        echo -e "${YELLOW}📊 Estimated downloads:${NC}"
        echo "  - Wikipedia (English, full): ~100 GB"
        echo "  - Stack Overflow: ~30 GB"
        echo "  - Project Gutenberg: ~60 GB"
        echo "  - Wikibooks: ~5 GB"
        echo "  - Wikiversity: ~2 GB"
        echo "  - Ollama (mistral + llama3 + codellama + deepseek): ~25 GB"
        echo "  - Total: ~220+ GB"
        ;;
esac

echo ""
read -p "Continue with download? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# ==============================================================================
# CREATE DIRECTORIES
# ==============================================================================

echo -e "\n${BLUE}📁 Creating directory structure...${NC}"

directories=(
    "${MEDIA_PATH}/Movies"
    "${MEDIA_PATH}/Series"
    "${MEDIA_PATH}/Music"
    "${MEDIA_PATH}/Photos"
    "${MEDIA_PATH}/Books"
    "${MEDIA_PATH}/Downloads"
    "${ZIM_PATH}"
    "${CONFIG_PATH}/jellyfin/config"
    "${CONFIG_PATH}/qbittorrent/config"
    "${CONFIG_PATH}/bookstack/config"
    "${CONFIG_PATH}/nginx"
    "${CONFIG_PATH}/ollama"
    "${CONFIG_PATH}/prowlarr"
    "${CONFIG_PATH}/radarr"
    "${CONFIG_PATH}/sonarr"
    "${CONFIG_PATH}/lidarr"
    "${CONFIG_PATH}/portainer"
    "${CONFIG_PATH}/open-webui"
)

for dir in "${directories[@]}"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        echo -e "  ${GREEN}✓${NC} Created $dir"
    else
        echo -e "  ${YELLOW}○${NC} Exists: $dir"
    fi
done

# Set permissions
chown -R ${PUID:-1000}:${PGID:-1000} "${MEDIA_PATH}" "${CONFIG_PATH}" 2>/dev/null || true

# ==============================================================================
# KIWIX ZIM DOWNLOADS
# ==============================================================================

if [[ "$SKIP_ZIM" == false ]]; then
    echo -e "\n${BLUE}📚 Downloading Kiwix ZIM files...${NC}"
    
    # Base URL for Kiwix downloads
    KIWIX_BASE="https://download.kiwix.org/zim"
    
    # Function to download ZIM file
    download_zim() {
        local name="$1"
        local url="$2"
        local filename
        filename=$(basename "$url")
        local filepath="${ZIM_PATH}/${filename}"
        
        if [[ -f "$filepath" ]]; then
            echo -e "  ${YELLOW}○${NC} Already exists: $name"
            return 0
        fi
        
        echo -e "  ${BLUE}↓${NC} Downloading: $name"
        echo -e "    ${CYAN}URL: $url${NC}"
        
        # Use wget with resume capability
        wget -c -q --show-progress -O "$filepath" "$url" || {
            echo -e "  ${RED}✗${NC} Failed to download $name"
            rm -f "$filepath"  # Remove partial file
            return 1
        }
        
        echo -e "  ${GREEN}✓${NC} Downloaded: $name"
    }
    
    # Download based on profile
    case $PROFILE in
        minimal)
            # Simple English Wikipedia - small and fast
            download_zim "Wikipedia (Simple English)" \
                "${KIWIX_BASE}/wikipedia/wikipedia_en_simple_all_nopic_2024-06.zim"
            ;;
            
        standard)
            # English Wikipedia without pictures
            download_zim "Wikipedia (English, no pics)" \
                "${KIWIX_BASE}/wikipedia/wikipedia_en_all_nopic_2024-06.zim"
            
            # Stack Overflow (smaller version)
            download_zim "Stack Overflow" \
                "${KIWIX_BASE}/stack_exchange/stackoverflow.com_en_all_2024-05.zim"
            
            # Wikibooks
            download_zim "Wikibooks" \
                "${KIWIX_BASE}/wikibooks/wikibooks_en_all_nopic_2024-06.zim"
            ;;
            
        full)
            # Full English Wikipedia with pictures
            download_zim "Wikipedia (English, full)" \
                "${KIWIX_BASE}/wikipedia/wikipedia_en_all_maxi_2024-06.zim"
            
            # Stack Overflow full
            download_zim "Stack Overflow" \
                "${KIWIX_BASE}/stack_exchange/stackoverflow.com_en_all_2024-05.zim"
            
            # Project Gutenberg (public domain books)
            download_zim "Project Gutenberg" \
                "${KIWIX_BASE}/gutenberg/gutenberg_en_all_2024-05.zim"
            
            # Wikibooks
            download_zim "Wikibooks" \
                "${KIWIX_BASE}/wikibooks/wikibooks_en_all_maxi_2024-06.zim"
            
            # Wikiversity
            download_zim "Wikiversity" \
                "${KIWIX_BASE}/wikiversity/wikiversity_en_all_maxi_2024-06.zim"
            
            # Wikimed (Medical Wikipedia)
            download_zim "WikiMed" \
                "${KIWIX_BASE}/other/wikimed_en_all_maxi_2024-06.zim"
            ;;
    esac
    
    # Create Kiwix library file
    echo -e "\n${BLUE}📖 Creating Kiwix library index...${NC}"
    
    # Generate library.xml for all downloaded ZIM files
    LIBRARY_FILE="${ZIM_PATH}/library.xml"
    echo '<?xml version="1.0" encoding="UTF-8"?>' > "$LIBRARY_FILE"
    echo '<library version="20110515">' >> "$LIBRARY_FILE"
    
    for zimfile in "${ZIM_PATH}"/*.zim; do
        if [[ -f "$zimfile" ]]; then
            filename=$(basename "$zimfile")
            echo "  <book path=\"/zim/${filename}\"/>" >> "$LIBRARY_FILE"
        fi
    done
    
    echo '</library>' >> "$LIBRARY_FILE"
    echo -e "  ${GREEN}✓${NC} Created library.xml"
    
    # Show downloaded ZIM files
    echo -e "\n${BLUE}📚 Downloaded ZIM files:${NC}"
    ls -lh "${ZIM_PATH}"/*.zim 2>/dev/null || echo "  No ZIM files found"
fi

# ==============================================================================
# OLLAMA MODEL DOWNLOADS
# ==============================================================================

if [[ "$SKIP_OLLAMA" == false ]]; then
    echo -e "\n${BLUE}🤖 Downloading Ollama models...${NC}"
    
    # Check if Ollama is installed
    if ! command -v ollama &> /dev/null; then
        echo -e "${YELLOW}⚠️  Ollama not installed. Installing...${NC}"
        curl -fsSL https://ollama.com/install.sh | sh
        sleep 2
    fi
    
    # Start Ollama if not running
    if ! pgrep -x "ollama" > /dev/null; then
        echo -e "  Starting Ollama service..."
        ollama serve &>/dev/null &
        sleep 3
    fi
    
    # Function to download model
    download_model() {
        local model="$1"
        echo -e "  ${BLUE}↓${NC} Pulling: $model"
        ollama pull "$model" || {
            echo -e "  ${RED}✗${NC} Failed to pull $model"
            return 1
        }
        echo -e "  ${GREEN}✓${NC} Downloaded: $model"
    }
    
    # Download based on profile
    case $PROFILE in
        minimal)
            download_model "phi3"           # ~2 GB, fast
            ;;
            
        standard)
            download_model "mistral"        # ~4 GB, general purpose
            download_model "codellama:7b"   # ~4 GB, coding
            ;;
            
        full)
            download_model "mistral"        # ~4 GB, general purpose
            download_model "llama3.2"       # ~2 GB, latest Meta
            download_model "codellama:13b"  # ~7 GB, better coding
            download_model "deepseek-r1:7b" # ~4 GB, reasoning
            download_model "qwen2.5"        # ~4 GB, multilingual
            download_model "gemma2:9b"      # ~5 GB, Google
            ;;
    esac
    
    # Show downloaded models
    echo -e "\n${BLUE}🤖 Installed Ollama models:${NC}"
    ollama list
fi

# ==============================================================================
# SUMMARY
# ==============================================================================

echo -e "\n${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                     ✅ Downloads Complete!                                    ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Calculate total size
echo -e "${BLUE}📊 Storage Usage:${NC}"
echo -e "  ZIM files:  $(du -sh "${ZIM_PATH}" 2>/dev/null | cut -f1 || echo "N/A")"
echo -e "  Ollama:     $(du -sh ~/.ollama/models 2>/dev/null | cut -f1 || echo "N/A")"

echo -e "\n${YELLOW}📋 Next Steps:${NC}"
echo "  1. Navigate to docker directory: cd ~/homelab/docker"
echo "  2. Copy environment file: cp .env.example .env"
echo "  3. Edit .env with your settings: nano .env"
echo "  4. Start all services: docker compose up -d"
echo ""

echo -e "${CYAN}🌐 Services will be available at:${NC}"
echo "  - Jellyfin:    http://localhost:8096"
echo "  - Kiwix:       http://localhost:8081"
echo "  - BookStack:   http://localhost:8082"
echo "  - Ollama:      http://localhost:11434"
echo "  - Open WebUI:  http://localhost:3000"
echo ""
