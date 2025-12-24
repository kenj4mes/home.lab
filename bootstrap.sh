#!/usr/bin/env bash
# ==============================================================================
# 🌐 HomeLab Bootstrap - Quick Install
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Run this on any supported Linux system (Debian, Ubuntu, Fedora, Arch):
#   curl -sSL https://raw.githubusercontent.com/your-repo/main/bootstrap.sh | sudo bash
#
# Usage:
#   sudo ./bootstrap.sh [--minimal|--standard|--full]
# ==============================================================================

# Strict mode
set -euo pipefail

# Get script directory if local, or temporary if remote
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="/tmp/homelab-bootstrap"
    mkdir -p "$SCRIPT_DIR"
fi

# Define temporary library file if not exists
# (bootstrap might be run before cloned, so we need some basic logging)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC}  $1"; }
success() { echo -e "${GREEN}✓${NC}  $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
error() { echo -e "${RED}✗${NC}  $1" >&2; }

# Parse arguments
PROFILE="${1:-standard}"
PROFILE="${PROFILE#--}"

# Banner
echo -e "${BLUE}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    🔱 HomeLab Bootstrap - Quick Install                       ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Must run as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
   exit 1
fi

# ==============================================================================
# STEP 1: Dependencies
# ==============================================================================

info "Installing core dependencies..."

# Detect package manager
if command -v apt-get &>/dev/null; then
    apt-get update -qq
    apt-get install -y -qq git curl wget jq
elif command -v dnf &>/dev/null; then
    dnf -y install git curl wget jq
elif command -v pacman &>/dev/null; then
    pacman -Sy --noconfirm git curl wget jq
else
    warn "Unsupported package manager. Please ensure git, curl, wget, and jq are installed."
fi

# ==============================================================================
# STEP 2: Clone Repository
# ==============================================================================

HOMELAB_DIR="/opt/homelab"

if [[ -d "$HOMELAB_DIR" ]]; then
    info "HomeLab directory exists at $HOMELAB_DIR. Updating..."
    cd "$HOMELAB_DIR"
    git pull 2>/dev/null || warn "git pull failed, continuing with existing files"
else
    info "Downloading HomeLab repository to $HOMELAB_DIR..."
    git clone --depth 1 https://github.com/your-repo/homelab.git "$HOMELAB_DIR" || {
        error "Failed to clone repository"
        exit 1
    }
fi

cd "$HOMELAB_DIR"

# Make scripts executable
chmod +x scripts/*.sh scripts/lib/*.sh 2>/dev/null || true

# ==============================================================================
# STEP 3: Run Init
# ==============================================================================

info "Running HomeLab setup (Profile: $PROFILE)..."

if [[ -f "./scripts/init-homelab.sh" ]]; then
    sudo ./scripts/init-homelab.sh --"$PROFILE"
else
    error "Setup script not found: ./scripts/init-homelab.sh"
    exit 1
fi

# ==============================================================================
# STEP 4: Complete
# ==============================================================================

echo ""
success "Bootstrap complete!"
info "You can now use 'make' command if installed or the unified CLI 'homelab.ps1' on Windows."
info "Access your services at http://$(hostname -I | awk '{print $1}'):PORT"
echo ""
