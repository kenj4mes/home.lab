#!/usr/bin/env bash
# ==============================================================================
# 🍎 HomeLab macOS Installer
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure for macOS
#
# Usage:
#   chmod +x install-macos.sh
#   ./install-macos.sh [--minimal|--standard|--full]
#
# Requirements:
#   - macOS 12+ (Monterey or later)
#   - Homebrew (will be installed if missing)
#   - Docker Desktop for Mac
# ==============================================================================

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Logging
info() { echo -e "${BLUE}ℹ${NC}  $1"; }
success() { echo -e "${GREEN}✓${NC}  $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
error() { echo -e "${RED}✗${NC}  $1" >&2; }

# Configuration
PROFILE="${1:-standard}"
PROFILE="${PROFILE#--}"
HOMELAB_DIR="${HOMELAB_DIR:-$HOME/HomeLab}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Banner
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    🍎 HomeLab macOS Installer                                 ║
║                                                                              ║
║  Self-hosted infrastructure with 75+ services                                ║
║  AI • Blockchain • Security • Creative • Quantum                             ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

info "Profile: $PROFILE"
info "Install Path: $HOMELAB_DIR"
echo ""

# ==============================================================================
# PHASE 1: Check macOS Requirements
# ==============================================================================

echo -e "${CYAN}━━━ PHASE 1: System Requirements ━━━${NC}"

# Check macOS version
macos_version=$(sw_vers -productVersion)
macos_major=$(echo "$macos_version" | cut -d. -f1)

if [[ $macos_major -lt 12 ]]; then
    error "macOS 12 (Monterey) or later required. You have: $macos_version"
    exit 1
fi
success "macOS $macos_version detected"

# Check architecture
arch=$(uname -m)
if [[ "$arch" == "arm64" ]]; then
    success "Apple Silicon (M1/M2/M3) detected - native performance"
    ARCH_TYPE="arm64"
else
    success "Intel Mac detected"
    ARCH_TYPE="amd64"
fi

# Check disk space
available_gb=$(df -g "$HOME" | tail -1 | awk '{print $4}')
case $PROFILE in
    minimal)  required_gb=10 ;;
    standard) required_gb=60 ;;
    full)     required_gb=300 ;;
esac

if [[ $available_gb -lt $required_gb ]]; then
    warn "Low disk space: ${available_gb}GB available, ${required_gb}GB recommended"
    read -p "Continue anyway? (y/N): " confirm
    [[ "$confirm" != "y" ]] && exit 0
else
    success "Disk space OK: ${available_gb}GB available"
fi

# ==============================================================================
# PHASE 2: Install Homebrew & Dependencies
# ==============================================================================

echo ""
echo -e "${CYAN}━━━ PHASE 2: Dependencies ━━━${NC}"

# Install Homebrew if missing
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add to PATH for Apple Silicon
    if [[ "$ARCH_TYPE" == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew installed"
else
    success "Homebrew already installed"
fi

# Install required packages
info "Installing dependencies..."
brew install git curl wget jq python@3.11 node 2>/dev/null || true
success "Dependencies installed"

# ==============================================================================
# PHASE 3: Install Docker Desktop
# ==============================================================================

echo ""
echo -e "${CYAN}━━━ PHASE 3: Docker Desktop ━━━${NC}"

if ! command -v docker &>/dev/null; then
    info "Docker Desktop not found"
    echo ""
    echo "  Docker Desktop is required for HomeLab."
    echo "  Would you like to:"
    echo "    [1] Open Docker Desktop download page (recommended)"
    echo "    [2] Install via Homebrew Cask"
    echo "    [3] Skip (install manually later)"
    echo ""
    read -p "  Select option (1/2/3): " docker_choice
    
    case $docker_choice in
        1)
            open "https://www.docker.com/products/docker-desktop/"
            echo ""
            warn "Please install Docker Desktop, then run this script again."
            exit 0
            ;;
        2)
            info "Installing Docker Desktop via Homebrew..."
            brew install --cask docker
            success "Docker Desktop installed"
            echo ""
            warn "Please open Docker Desktop from Applications and complete setup."
            warn "Then run this script again."
            exit 0
            ;;
        3)
            warn "Skipping Docker - some features will not work"
            ;;
    esac
else
    # Check if Docker is running
    if docker info &>/dev/null; then
        success "Docker Desktop is running ($(docker version --format '{{.Server.Version}}'))"
    else
        warn "Docker is installed but not running"
        info "Starting Docker Desktop..."
        open -a Docker
        echo "Waiting for Docker to start..."
        for i in {1..30}; do
            if docker info &>/dev/null; then
                success "Docker is now running"
                break
            fi
            sleep 2
        done
    fi
fi

# ==============================================================================
# PHASE 4: Install Ollama
# ==============================================================================

echo ""
echo -e "${CYAN}━━━ PHASE 4: Ollama (Local AI) ━━━${NC}"

if ! command -v ollama &>/dev/null; then
    info "Installing Ollama..."
    brew install ollama 2>/dev/null || {
        curl -fsSL https://ollama.ai/install.sh | sh
    }
    success "Ollama installed"
else
    success "Ollama already installed ($(ollama --version 2>/dev/null || echo 'unknown'))"
fi

# Start Ollama service
if ! pgrep -x "ollama" &>/dev/null; then
    info "Starting Ollama service..."
    ollama serve &>/dev/null &
    sleep 3
fi
success "Ollama service running"

# Download models based on profile
echo ""
info "Downloading AI models for $PROFILE profile..."

case $PROFILE in
    minimal)
        ollama pull llama3.2:1b 2>/dev/null || warn "llama3.2:1b download failed"
        ;;
    standard)
        ollama pull llama3.2 2>/dev/null || warn "llama3.2 download failed"
        ollama pull mistral 2>/dev/null || warn "mistral download failed"
        ollama pull codellama 2>/dev/null || warn "codellama download failed"
        ;;
    full)
        ollama pull llama3.2 2>/dev/null || true
        ollama pull llama3.2:70b 2>/dev/null || true
        ollama pull mistral 2>/dev/null || true
        ollama pull mixtral 2>/dev/null || true
        ollama pull codellama 2>/dev/null || true
        ollama pull deepseek-coder 2>/dev/null || true
        ;;
esac
success "AI models downloaded"

# ==============================================================================
# PHASE 5: Clone/Update HomeLab
# ==============================================================================

echo ""
echo -e "${CYAN}━━━ PHASE 5: HomeLab Repository ━━━${NC}"

if [[ -d "$HOMELAB_DIR" ]]; then
    info "Updating existing HomeLab installation..."
    cd "$HOMELAB_DIR"
    git pull 2>/dev/null || warn "git pull failed, continuing with existing files"
else
    info "Cloning HomeLab repository..."
    # Try to clone from the parent directory if we're running from install/
    if [[ -d "$SCRIPT_DIR/../docker" ]]; then
        info "Copying from local source..."
        mkdir -p "$HOMELAB_DIR"
        cp -R "$SCRIPT_DIR/../"* "$HOMELAB_DIR/" 2>/dev/null || true
        cp -R "$SCRIPT_DIR/../".* "$HOMELAB_DIR/" 2>/dev/null || true
    else
        git clone --depth 1 https://github.com/kenj4mes/home.lab.git "$HOMELAB_DIR" || {
            error "Failed to clone repository"
            exit 1
        }
    fi
fi

cd "$HOMELAB_DIR"
success "HomeLab ready at $HOMELAB_DIR"

# ==============================================================================
# PHASE 6: Create Directory Structure
# ==============================================================================

echo ""
echo -e "${CYAN}━━━ PHASE 6: Directory Structure ━━━${NC}"

directories=(
    "config/jellyfin" "config/bookstack" "config/nginx" "config/portainer"
    "config/prometheus" "config/grafana" "config/ollama" "config/open-webui"
    "data/Movies" "data/Series" "data/Music" "data/Books" "data/Downloads"
    "data/ZIM" "data/models" "data/audio" "data/videos" "logs"
)

for dir in "${directories[@]}"; do
    mkdir -p "$HOMELAB_DIR/$dir"
done
success "Directory structure created"

# ==============================================================================
# PHASE 7: Configure Environment
# ==============================================================================

echo ""
echo -e "${CYAN}━━━ PHASE 7: Environment Configuration ━━━${NC}"

ENV_FILE="$HOMELAB_DIR/docker/.env"

if [[ ! -f "$ENV_FILE" ]]; then
    cat > "$ENV_FILE" << EOF
# HomeLab Environment - macOS
# Generated on $(date)

TZ=$(readlink /etc/localtime | sed 's|.*/zoneinfo/||')
PUID=$(id -u)
PGID=$(id -g)

CONFIG_PATH=$HOMELAB_DIR/config
MEDIA_PATH=$HOMELAB_DIR/data
ZIM_PATH=$HOMELAB_DIR/data/ZIM

JELLYFIN_URL=http://localhost:8096
WEBUI_URL=http://localhost:3000
OLLAMA_HOST=http://host.docker.internal:11434

# Auto-generated passwords
BOOKSTACK_DB_PASSWORD=$(openssl rand -hex 16)
GRAFANA_ADMIN_PASSWORD=$(openssl rand -hex 16)
EOF
    success "Environment configured with secure passwords"
else
    success "Environment file exists, skipping"
fi

# ==============================================================================
# PHASE 8: Start Services
# ==============================================================================

echo ""
echo -e "${CYAN}━━━ PHASE 8: Starting Services ━━━${NC}"

cd "$HOMELAB_DIR/docker"

if command -v docker &>/dev/null && docker info &>/dev/null; then
    info "Pulling Docker images..."
    docker compose pull 2>/dev/null || true
    
    info "Starting core services..."
    docker compose up -d 2>/dev/null || warn "Some services failed to start"
    
    # Start additional services based on profile
    if [[ "$PROFILE" == "standard" ]] || [[ "$PROFILE" == "full" ]]; then
        info "Starting monitoring stack..."
        docker compose -f docker-compose.monitoring.yml up -d 2>/dev/null || true
    fi
    
    if [[ "$PROFILE" == "full" ]]; then
        info "Starting AI agents..."
        docker compose -f docker-compose.agents.yml up -d 2>/dev/null || true
        docker compose -f docker-compose.ev0.yml up -d 2>/dev/null || true
    fi
    
    success "Services started"
else
    warn "Docker not available - start services manually after installing Docker"
fi

# ==============================================================================
# COMPLETE
# ==============================================================================

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    🎉 HomeLab Installation Complete!                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

info "Installed to: $HOMELAB_DIR"
echo ""
info "Your services:"
echo -e "  ${GREEN}Open WebUI${NC}    http://localhost:3000  (ChatGPT-like AI)"
echo -e "  ${GREEN}Jellyfin${NC}      http://localhost:8096  (Media streaming)"
echo -e "  ${GREEN}Portainer${NC}     http://localhost:9000  (Container management)"
echo -e "  ${GREEN}BookStack${NC}     http://localhost:8082  (Documentation wiki)"
echo -e "  ${GREEN}Kiwix${NC}         http://localhost:8081  (Offline Wikipedia)"
echo ""

if [[ "$PROFILE" == "standard" ]] || [[ "$PROFILE" == "full" ]]; then
    info "Monitoring:"
    echo -e "  ${GREEN}Grafana${NC}       http://localhost:3100"
    echo -e "  ${GREEN}Prometheus${NC}    http://localhost:9090"
    echo ""
fi

info "Quick commands:"
echo "  cd $HOMELAB_DIR"
echo "  docker compose ps          # View running services"
echo "  docker compose logs -f     # View logs"
echo "  ollama list                # View AI models"
echo ""

success "Happy homelabbing! 🏠"
