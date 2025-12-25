#!/usr/bin/env bash
# ==============================================================================
# 🔧 HomeLab Native Installation (No Docker)
# ==============================================================================
# Install HomeLab services directly on your OS without Docker.
# 
# USE CASES:
#   - Low-resource systems (Raspberry Pi, old laptops)
#   - Users who prefer native packages over containers
#   - Air-gapped systems where Docker isn't available
#   - Learning/development environments
#
# SUPPORTED:
#   - Debian 12 / Ubuntu 22.04+
#   - Fedora 38+
#   - Arch Linux
#   - Raspberry Pi OS
#
# Usage:
#   chmod +x install-native.sh
#   sudo ./install-native.sh [--minimal|--standard|--full]
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
phase() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}"; }

# Configuration
PROFILE="${1:-standard}"
PROFILE="${PROFILE#--}"
HOMELAB_DIR="${HOMELAB_DIR:-/opt/homelab}"
DATA_DIR="${DATA_DIR:-/srv/homelab}"
USER="${SUDO_USER:-$USER}"

# Detect package manager
detect_package_manager() {
    if command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

PKG_MGR=$(detect_package_manager)

# Banner
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    🔧 HomeLab Native Installation                             ║
║                                                                              ║
║  Direct installation without Docker                                          ║
║  Lightweight • Native Performance • Full Control                             ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

info "Profile: $PROFILE"
info "Install Path: $HOMELAB_DIR"
info "Data Path: $DATA_DIR"
info "Package Manager: $PKG_MGR"
echo ""

# Must run as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

# ==============================================================================
# PHASE 1: System Dependencies
# ==============================================================================

phase "PHASE 1: Installing System Dependencies"

case "$PKG_MGR" in
    apt)
        apt-get update -qq
        apt-get install -y -qq \
            git curl wget jq \
            python3 python3-pip python3-venv \
            nodejs npm \
            nginx \
            redis-server \
            sqlite3 \
            ffmpeg \
            build-essential \
            libssl-dev libffi-dev
        ;;
    dnf)
        dnf install -y \
            git curl wget jq \
            python3 python3-pip \
            nodejs npm \
            nginx \
            redis \
            sqlite \
            ffmpeg \
            gcc gcc-c++ make \
            openssl-devel libffi-devel
        ;;
    pacman)
        pacman -Sy --noconfirm \
            git curl wget jq \
            python python-pip \
            nodejs npm \
            nginx \
            redis \
            sqlite \
            ffmpeg \
            base-devel \
            openssl libffi
        ;;
    *)
        error "Unsupported package manager"
        exit 1
        ;;
esac

success "System dependencies installed"

# ==============================================================================
# PHASE 2: Install Ollama (Local AI)
# ==============================================================================

phase "PHASE 2: Installing Ollama"

if ! command -v ollama &>/dev/null; then
    info "Installing Ollama..."
    curl -fsSL https://ollama.ai/install.sh | sh
    success "Ollama installed"
else
    success "Ollama already installed"
fi

# Enable and start Ollama service
systemctl enable ollama 2>/dev/null || true
systemctl start ollama 2>/dev/null || true

# Download models based on profile
info "Downloading AI models..."
case $PROFILE in
    minimal)
        sudo -u "$USER" ollama pull llama3.2:1b 2>/dev/null || warn "Model download failed"
        ;;
    standard)
        sudo -u "$USER" ollama pull llama3.2 2>/dev/null || true
        sudo -u "$USER" ollama pull mistral 2>/dev/null || true
        sudo -u "$USER" ollama pull codellama 2>/dev/null || true
        ;;
    full)
        sudo -u "$USER" ollama pull llama3.2 2>/dev/null || true
        sudo -u "$USER" ollama pull llama3.2:70b 2>/dev/null || true
        sudo -u "$USER" ollama pull mistral 2>/dev/null || true
        sudo -u "$USER" ollama pull mixtral 2>/dev/null || true
        sudo -u "$USER" ollama pull codellama 2>/dev/null || true
        sudo -u "$USER" ollama pull deepseek-coder 2>/dev/null || true
        ;;
esac
success "AI models downloaded"

# ==============================================================================
# PHASE 3: Install Open WebUI (Python)
# ==============================================================================

phase "PHASE 3: Installing Open WebUI"

WEBUI_DIR="$HOMELAB_DIR/open-webui"
mkdir -p "$WEBUI_DIR"

# Create virtual environment
python3 -m venv "$WEBUI_DIR/venv"
source "$WEBUI_DIR/venv/bin/activate"

# Install Open WebUI
pip install --upgrade pip
pip install open-webui 2>/dev/null || {
    warn "open-webui pip package not available, cloning from source..."
    git clone --depth 1 https://github.com/open-webui/open-webui.git "$WEBUI_DIR/src"
    cd "$WEBUI_DIR/src"
    pip install -r requirements.txt 2>/dev/null || true
}

deactivate

# Create systemd service
cat > /etc/systemd/system/open-webui.service << EOF
[Unit]
Description=Open WebUI - ChatGPT-like Interface
After=network.target ollama.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$WEBUI_DIR
Environment=OLLAMA_BASE_URL=http://localhost:11434
ExecStart=$WEBUI_DIR/venv/bin/open-webui serve --port 3000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable open-webui 2>/dev/null || true
systemctl start open-webui 2>/dev/null || warn "Open WebUI service start failed"

success "Open WebUI installed"

# ==============================================================================
# PHASE 4: Install Kiwix (Offline Wikipedia)
# ==============================================================================

phase "PHASE 4: Installing Kiwix"

KIWIX_DIR="$HOMELAB_DIR/kiwix"
mkdir -p "$KIWIX_DIR" "$DATA_DIR/ZIM"

# Download Kiwix tools
KIWIX_VERSION="3.5.0"
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) KIWIX_ARCH="x86_64" ;;
    aarch64|arm64) KIWIX_ARCH="aarch64" ;;
    armv7l) KIWIX_ARCH="armv6" ;;
    *) KIWIX_ARCH="x86_64" ;;
esac

info "Downloading Kiwix tools..."
wget -q "https://download.kiwix.org/release/kiwix-tools/kiwix-tools_linux-$KIWIX_ARCH-$KIWIX_VERSION.tar.gz" \
    -O /tmp/kiwix-tools.tar.gz 2>/dev/null || warn "Kiwix download failed"

if [[ -f /tmp/kiwix-tools.tar.gz ]]; then
    tar -xzf /tmp/kiwix-tools.tar.gz -C "$KIWIX_DIR" --strip-components=1
    ln -sf "$KIWIX_DIR/kiwix-serve" /usr/local/bin/kiwix-serve
    success "Kiwix tools installed"
else
    warn "Kiwix installation skipped"
fi

# Create Kiwix service
cat > /etc/systemd/system/kiwix.service << EOF
[Unit]
Description=Kiwix Server - Offline Wikipedia
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/local/bin/kiwix-serve --port 8081 $DATA_DIR/ZIM/*.zim
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
# Don't start yet - no ZIM files

success "Kiwix configured (download ZIM files to $DATA_DIR/ZIM/)"

# ==============================================================================
# PHASE 5: Install BookStack (Documentation Wiki)
# ==============================================================================

phase "PHASE 5: Installing BookStack"

if [[ "$PROFILE" != "minimal" ]]; then
    BOOKSTACK_DIR="$HOMELAB_DIR/bookstack"
    mkdir -p "$BOOKSTACK_DIR"
    
    # Install PHP and dependencies
    case "$PKG_MGR" in
        apt)
            apt-get install -y -qq \
                php php-fpm php-mysql php-gd php-xml php-mbstring php-curl php-zip \
                mariadb-server 2>/dev/null || true
            ;;
        dnf)
            dnf install -y \
                php php-fpm php-mysqlnd php-gd php-xml php-mbstring php-curl php-zip \
                mariadb-server 2>/dev/null || true
            ;;
        pacman)
            pacman -Sy --noconfirm \
                php php-fpm php-gd \
                mariadb 2>/dev/null || true
            ;;
    esac
    
    info "BookStack requires manual setup - see docs/BOOKSTACK.md"
    warn "Run: https://www.bookstackapp.com/docs/admin/installation/"
else
    info "Skipping BookStack (minimal profile)"
fi

# ==============================================================================
# PHASE 6: Configure Nginx Reverse Proxy
# ==============================================================================

phase "PHASE 6: Configuring Nginx"

# Create HomeLab nginx config
cat > /etc/nginx/sites-available/homelab << 'EOF'
# HomeLab Reverse Proxy Configuration

# Open WebUI (AI Chat)
server {
    listen 80;
    server_name ai.local webui.local;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# Kiwix (Offline Wikipedia)
server {
    listen 80;
    server_name wiki.local kiwix.local;
    
    location / {
        proxy_pass http://localhost:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# Ollama API (for external access)
server {
    listen 80;
    server_name ollama.local llm.local;
    
    location / {
        proxy_pass http://localhost:11434;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/homelab /etc/nginx/sites-enabled/ 2>/dev/null || true

# Test and reload nginx
nginx -t 2>/dev/null && systemctl reload nginx || warn "Nginx config test failed"

success "Nginx configured"

# ==============================================================================
# PHASE 7: Create Directory Structure
# ==============================================================================

phase "PHASE 7: Creating Data Directories"

directories=(
    "$DATA_DIR/Movies"
    "$DATA_DIR/Series"
    "$DATA_DIR/Music"
    "$DATA_DIR/Books"
    "$DATA_DIR/Downloads"
    "$DATA_DIR/ZIM"
    "$DATA_DIR/models"
    "$DATA_DIR/backups"
    "$HOMELAB_DIR/config"
    "$HOMELAB_DIR/logs"
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
done

chown -R "$USER:$USER" "$HOMELAB_DIR" "$DATA_DIR"
success "Directories created"

# ==============================================================================
# PHASE 8: Create Management Script
# ==============================================================================

phase "PHASE 8: Creating Management Tools"

cat > /usr/local/bin/homelab << 'MGMT'
#!/bin/bash
# HomeLab Native Management Script

case "$1" in
    status)
        echo "=== HomeLab Service Status ==="
        systemctl status ollama --no-pager -l 2>/dev/null | head -5
        systemctl status open-webui --no-pager -l 2>/dev/null | head -5
        systemctl status kiwix --no-pager -l 2>/dev/null | head -5
        systemctl status nginx --no-pager -l 2>/dev/null | head -5
        ;;
    start)
        echo "Starting HomeLab services..."
        systemctl start ollama
        systemctl start open-webui
        systemctl start kiwix 2>/dev/null || true
        systemctl start nginx
        echo "Done!"
        ;;
    stop)
        echo "Stopping HomeLab services..."
        systemctl stop open-webui
        systemctl stop kiwix 2>/dev/null || true
        # Keep ollama running for CLI use
        echo "Done! (Ollama still running for CLI)"
        ;;
    restart)
        homelab stop
        sleep 2
        homelab start
        ;;
    logs)
        service="${2:-open-webui}"
        journalctl -u "$service" -f
        ;;
    models)
        ollama list
        ;;
    chat)
        model="${2:-llama3.2}"
        ollama run "$model"
        ;;
    update)
        echo "Updating HomeLab..."
        cd /opt/homelab
        git pull 2>/dev/null || echo "Not a git repo"
        pip install --upgrade open-webui 2>/dev/null || true
        echo "Done!"
        ;;
    *)
        echo "HomeLab Native Management"
        echo ""
        echo "Usage: homelab <command>"
        echo ""
        echo "Commands:"
        echo "  status    - Show service status"
        echo "  start     - Start all services"
        echo "  stop      - Stop web services"
        echo "  restart   - Restart all services"
        echo "  logs [svc]- View service logs"
        echo "  models    - List AI models"
        echo "  chat [m]  - Chat with model"
        echo "  update    - Update HomeLab"
        echo ""
        echo "Services:"
        echo "  Open WebUI:  http://localhost:3000"
        echo "  Kiwix:       http://localhost:8081"
        echo "  Ollama API:  http://localhost:11434"
        ;;
esac
MGMT

chmod +x /usr/local/bin/homelab
success "Management script installed: homelab"

# ==============================================================================
# PHASE 9: Optional Downloads
# ==============================================================================

phase "PHASE 9: Optional Content"

echo ""
echo "Would you like to download offline content now?"
echo "  [1] Skip downloads"
echo "  [2] Simple English Wikipedia (~500MB)"
echo "  [3] Standard English Wikipedia (~22GB)"
echo ""
read -p "Select (1/2/3): " dl_choice

case "$dl_choice" in
    2)
        info "Downloading Simple English Wikipedia..."
        wget -O "$DATA_DIR/ZIM/wikipedia_simple.zim" \
            "https://download.kiwix.org/zim/wikipedia/wikipedia_en_simple_all_maxi_2024-01.zim" \
            2>/dev/null && success "Wikipedia downloaded" || warn "Download failed"
        systemctl start kiwix 2>/dev/null || true
        ;;
    3)
        info "Downloading Standard English Wikipedia (~22GB)..."
        warn "This will take a while..."
        wget -O "$DATA_DIR/ZIM/wikipedia_en.zim" \
            "https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_nopic_2024-01.zim" \
            2>/dev/null && success "Wikipedia downloaded" || warn "Download failed"
        systemctl start kiwix 2>/dev/null || true
        ;;
esac

# ==============================================================================
# COMPLETE
# ==============================================================================

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    🎉 HomeLab Native Installation Complete!                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

IP=$(hostname -I | awk '{print $1}')

info "Your services are running natively (no Docker):"
echo -e "  ${GREEN}Open WebUI${NC}    http://$IP:3000  (AI Chat)"
echo -e "  ${GREEN}Kiwix${NC}         http://$IP:8081  (Offline Wikipedia)"
echo -e "  ${GREEN}Ollama API${NC}    http://$IP:11434 (LLM API)"
echo ""

info "Management commands:"
echo "  homelab status     # Check services"
echo "  homelab start      # Start services"
echo "  homelab stop       # Stop services"
echo "  homelab chat       # Chat with AI"
echo "  homelab models     # List AI models"
echo "  ollama pull <name> # Download new models"
echo ""

info "Data locations:"
echo "  ZIM files:   $DATA_DIR/ZIM/"
echo "  AI models:   ~/.ollama/models/"
echo "  Config:      $HOMELAB_DIR/config/"
echo ""

warn "For more services (Jellyfin, monitoring, blockchain),"
warn "consider using Docker: ./bootstrap.sh"
echo ""

success "Happy homelabbing! 🏠"
