#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# 📱 HomeLab Android Installer (Termux)
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure for Android
#
# Prerequisites:
#   1. Install Termux from F-Droid (NOT Play Store - it's outdated)
#      https://f-droid.org/packages/com.termux/
#   2. Grant storage permission: termux-setup-storage
#
# Usage:
#   pkg install curl
#   curl -sSL https://raw.githubusercontent.com/kenj4mes/home.lab/main/install/install-android.sh | bash
#
# Or manually:
#   chmod +x install-android.sh
#   ./install-android.sh
#
# Note: Android has limitations - this installs a subset of HomeLab services
#       optimized for mobile. Full server functionality requires a proper server.
# ==============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
info() { echo -e "${BLUE}ℹ${NC}  $1"; }
success() { echo -e "${GREEN}✓${NC}  $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
error() { echo -e "${RED}✗${NC}  $1" >&2; }

# Configuration
HOMELAB_DIR="$HOME/homelab"

# Banner
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    📱 HomeLab Android Installer                               ║
║                                                                              ║
║  Portable AI + Knowledge + Dev Tools for Android                             ║
║  Powered by Termux                                                           ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# ==============================================================================
# Check Environment
# ==============================================================================

echo -e "${CYAN}━━━ Checking Environment ━━━${NC}"

# Check if running in Termux
if [[ ! -d "/data/data/com.termux" ]]; then
    error "This script must be run in Termux!"
    echo ""
    echo "Install Termux from F-Droid (NOT Play Store):"
    echo "  https://f-droid.org/packages/com.termux/"
    echo ""
    exit 1
fi
success "Running in Termux"

# Check storage permission
if [[ ! -d "$HOME/storage" ]]; then
    warn "Storage permission not granted"
    echo ""
    echo "Run this command first:"
    echo "  termux-setup-storage"
    echo ""
    echo "Then run this installer again."
    exit 1
fi
success "Storage permission granted"

# Check available space
available_mb=$(df -m "$HOME" | tail -1 | awk '{print $4}')
if [[ $available_mb -lt 2000 ]]; then
    warn "Low storage: ${available_mb}MB available, 2GB+ recommended"
fi

# ==============================================================================
# Install Packages
# ==============================================================================

echo ""
echo -e "${CYAN}━━━ Installing Packages ━━━${NC}"

info "Updating package repository..."
pkg update -y

info "Installing core packages..."
pkg install -y \
    git \
    curl \
    wget \
    python \
    nodejs \
    openssh \
    jq \
    vim \
    tmux \
    2>/dev/null

success "Core packages installed"

# Install Python packages
info "Installing Python AI packages..."
pip install --upgrade pip 2>/dev/null || true
pip install \
    transformers \
    torch \
    langchain \
    langchain-community \
    chromadb \
    sentence-transformers \
    2>/dev/null || warn "Some Python packages failed (normal on Android)"

success "Python packages installed"

# ==============================================================================
# Install Ollama (ARM64)
# ==============================================================================

echo ""
echo -e "${CYAN}━━━ Installing Ollama ━━━${NC}"

# Check architecture
arch=$(uname -m)
if [[ "$arch" != "aarch64" ]]; then
    warn "Ollama works best on ARM64 devices"
fi

# Ollama doesn't have official Android support, but we can use the API
info "Ollama doesn't run natively on Android"
info "You can connect to a remote Ollama server instead"
echo ""
echo "  Option 1: Run Ollama on your computer/server"
echo "            export OLLAMA_HOST=http://YOUR_SERVER:11434"
echo ""
echo "  Option 2: Use llama.cpp for local inference (advanced)"
echo "            pkg install cmake clang"
echo ""

# Create helper script for remote Ollama
mkdir -p "$HOMELAB_DIR/scripts"
cat > "$HOMELAB_DIR/scripts/connect-ollama.sh" << 'OLLAMA_SCRIPT'
#!/bin/bash
# Connect to remote Ollama server

if [[ -z "$1" ]]; then
    echo "Usage: connect-ollama.sh <server-ip>"
    echo "Example: connect-ollama.sh 192.168.1.100"
    exit 1
fi

export OLLAMA_HOST="http://$1:11434"
echo "Connected to Ollama at $OLLAMA_HOST"

# Test connection
if curl -s "$OLLAMA_HOST/api/tags" &>/dev/null; then
    echo "✓ Connection successful!"
    echo ""
    echo "Available models:"
    curl -s "$OLLAMA_HOST/api/tags" | jq -r '.models[].name' 2>/dev/null || echo "  (none)"
else
    echo "✗ Connection failed. Is Ollama running on $1?"
fi
OLLAMA_SCRIPT
chmod +x "$HOMELAB_DIR/scripts/connect-ollama.sh"

success "Ollama connection script created"

# ==============================================================================
# Clone HomeLab
# ==============================================================================

echo ""
echo -e "${CYAN}━━━ Setting Up HomeLab ━━━${NC}"

if [[ -d "$HOMELAB_DIR" ]]; then
    info "Updating existing installation..."
    cd "$HOMELAB_DIR"
    git pull 2>/dev/null || warn "Update failed, continuing"
else
    info "Cloning HomeLab..."
    git clone --depth 1 https://github.com/kenj4mes/home.lab.git "$HOMELAB_DIR" || {
        error "Clone failed"
        exit 1
    }
fi

cd "$HOMELAB_DIR"
success "HomeLab ready at $HOMELAB_DIR"

# ==============================================================================
# Create Mobile-Optimized Tools
# ==============================================================================

echo ""
echo -e "${CYAN}━━━ Creating Mobile Tools ━━━${NC}"

# Create AI chat script (works with remote Ollama)
cat > "$HOMELAB_DIR/scripts/ai-chat.py" << 'AICHAT'
#!/usr/bin/env python3
"""
Simple AI Chat for Android/Termux
Connects to remote Ollama server
"""
import os
import sys
import json

try:
    import requests
except ImportError:
    print("Installing requests...")
    os.system("pip install requests")
    import requests

OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
MODEL = os.environ.get("OLLAMA_MODEL", "llama3.2")

def chat(prompt):
    try:
        response = requests.post(
            f"{OLLAMA_HOST}/api/generate",
            json={"model": MODEL, "prompt": prompt, "stream": False},
            timeout=120
        )
        return response.json().get("response", "No response")
    except Exception as e:
        return f"Error: {e}"

def main():
    print(f"🤖 AI Chat (Model: {MODEL})")
    print(f"   Server: {OLLAMA_HOST}")
    print("   Type 'quit' to exit\n")
    
    while True:
        try:
            user_input = input("You: ").strip()
            if user_input.lower() in ["quit", "exit", "q"]:
                break
            if not user_input:
                continue
            
            print("AI: ", end="", flush=True)
            response = chat(user_input)
            print(response)
            print()
        except KeyboardInterrupt:
            break
    
    print("\nGoodbye! 👋")

if __name__ == "__main__":
    main()
AICHAT
chmod +x "$HOMELAB_DIR/scripts/ai-chat.py"

# Create offline knowledge viewer
cat > "$HOMELAB_DIR/scripts/offline-wiki.py" << 'WIKI'
#!/usr/bin/env python3
"""
Offline Wikipedia viewer for Android
Requires ZIM file downloaded separately
"""
import os
import sys

try:
    from libzim.reader import Archive
except ImportError:
    print("ZIM reader not available on Android")
    print("Use Kiwix Android app instead:")
    print("  https://play.google.com/store/apps/details?id=org.kiwix.kiwixmobile")
    sys.exit(1)

# For full offline Wikipedia, download ZIM file and use Kiwix app
print("For offline Wikipedia on Android, use Kiwix app:")
print("  https://play.google.com/store/apps/details?id=org.kiwix.kiwixmobile")
WIKI
chmod +x "$HOMELAB_DIR/scripts/offline-wiki.py"

# Create quick launcher
cat > "$HOMELAB_DIR/homelab" << 'LAUNCHER'
#!/bin/bash
# HomeLab Mobile Launcher

HOMELAB_DIR="$HOME/homelab"
cd "$HOMELAB_DIR"

case "$1" in
    chat)
        python scripts/ai-chat.py
        ;;
    connect)
        source scripts/connect-ollama.sh "$2"
        ;;
    ssh)
        # Start SSH server for remote access
        sshd
        echo "SSH server started on port 8022"
        echo "Connect with: ssh -p 8022 $(whoami)@$(hostname -I | awk '{print $1}')"
        ;;
    serve)
        # Start simple HTTP server
        python -m http.server 8080 -d "$HOMELAB_DIR"
        ;;
    update)
        git pull
        ;;
    *)
        echo "HomeLab Mobile Commands:"
        echo "  homelab chat           - AI chat (requires Ollama server)"
        echo "  homelab connect <ip>   - Connect to Ollama server"
        echo "  homelab ssh            - Start SSH server for remote access"
        echo "  homelab serve          - Start HTTP file server"
        echo "  homelab update         - Update HomeLab"
        echo ""
        echo "For full features, run HomeLab on a proper server"
        echo "and connect from your Android device."
        ;;
esac
LAUNCHER
chmod +x "$HOMELAB_DIR/homelab"

# Add to PATH
if ! grep -q "homelab" "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/homelab:$PATH"' >> "$HOME/.bashrc"
fi

success "Mobile tools created"

# ==============================================================================
# Download Offline Content (Optional)
# ==============================================================================

echo ""
echo -e "${CYAN}━━━ Offline Content ━━━${NC}"

echo ""
echo "Would you like to download offline content?"
echo "  [1] Skip (recommended - use Kiwix app for Wikipedia)"
echo "  [2] Download Simple English Wikipedia (~500MB)"
echo ""
read -p "Select (1/2): " dl_choice

if [[ "$dl_choice" == "2" ]]; then
    mkdir -p "$HOMELAB_DIR/data/ZIM"
    info "Downloading Simple English Wikipedia..."
    wget -O "$HOMELAB_DIR/data/ZIM/wikipedia_simple.zim" \
        "https://download.kiwix.org/zim/wikipedia/wikipedia_en_simple_all_mini_2024-01.zim" \
        2>/dev/null || warn "Download failed - try manually"
fi

# ==============================================================================
# Complete
# ==============================================================================

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    🎉 HomeLab Android Setup Complete!                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

info "Installed to: $HOMELAB_DIR"
echo ""
info "Quick Start:"
echo "  homelab chat              # AI chat (needs Ollama server)"
echo "  homelab connect <ip>      # Connect to your Ollama server"
echo "  homelab ssh               # Enable SSH access to phone"
echo ""

info "Recommended Android Apps:"
echo "  📚 Kiwix         - Offline Wikipedia (Play Store)"
echo "  🤖 Ollama (web)  - Connect to your server's Open WebUI"
echo "  📁 Termux:Widget - Shortcuts to HomeLab commands"
echo ""

warn "Note: For full server functionality, run HomeLab on a proper"
warn "      Linux/Windows/Mac machine and connect from Android."
echo ""

success "Run 'source ~/.bashrc' to enable homelab command"
