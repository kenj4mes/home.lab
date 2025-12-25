#!/bin/bash
#
# SOVEREIGN AGENT - One-Click Launcher (Linux/macOS)
#
# Usage:
#   ./start.sh              # Full agent mode
#   ./start.sh --demo       # Demo mode (no wallet required)
#   ./start.sh --cli        # Interactive CLI
#   ./start.sh --server     # API server mode
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo -e "${CYAN}"
    echo "  ███████╗ ██████╗██╗  ██╗ ██████╗ "
    echo "  ██╔════╝██╔════╝██║  ██║██╔═══██╗"
    echo "  █████╗  ██║     ███████║██║   ██║"
    echo "  ██╔══╝  ██║     ██╔══██║██║   ██║"
    echo "  ███████╗╚██████╗██║  ██║╚██████╔╝"
    echo "  ╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝ "
    echo -e "${NC}"
    echo -e "  ${GREEN}SOVEREIGN AGENT${NC}"
    echo -e "  One-Click Launcher"
    echo ""
}

find_python() {
    # Try common Python locations
    for py in "$SCRIPT_DIR/.venv/bin/python" \
              "$SCRIPT_DIR/../.venv/bin/python" \
              "$(which python3 2>/dev/null)" \
              "$(which python 2>/dev/null)"; do
        if [[ -x "$py" ]]; then
            echo "$py"
            return
        fi
    done
    echo ""
}

setup_environment() {
    echo -e "${YELLOW}[1/4] Checking Python...${NC}"
    
    PYTHON=$(find_python)
    
    if [[ -z "$PYTHON" ]]; then
        echo -e "  Creating virtual environment..."
        python3 -m venv "$SCRIPT_DIR/.venv"
        PYTHON="$SCRIPT_DIR/.venv/bin/python"
    fi
    
    echo -e "  ${GREEN}Using: $PYTHON${NC}"
    
    echo -e "${YELLOW}[2/4] Checking dependencies...${NC}"
    
    if ! $PYTHON -c "import structlog; import pydantic; import dotenv" 2>/dev/null; then
        echo -e "  Installing core dependencies..."
        $PYTHON -m pip install --quiet python-dotenv pydantic pydantic-settings structlog httpx rich aiohttp requests
        
        if [[ -f "$SCRIPT_DIR/requirements-core.txt" ]]; then
            $PYTHON -m pip install --quiet -r "$SCRIPT_DIR/requirements-core.txt" 2>/dev/null || true
        fi
    fi
    
    echo -e "  ${GREEN}Dependencies OK${NC}"
    
    echo -e "${YELLOW}[3/4] Checking configuration...${NC}"
    
    if [[ ! -f "$SCRIPT_DIR/.env" ]] && [[ -f "$SCRIPT_DIR/.env.example" ]]; then
        cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
        echo -e "  Created .env from example"
    fi
    
    echo -e "  ${GREEN}Configuration OK${NC}"
    
    echo -e "${YELLOW}[4/4] Ready to launch${NC}"
    echo ""
}

# Main
print_banner
setup_environment "$@"

echo -e "${CYAN}Launching...${NC}"
echo ""

$PYTHON "$SCRIPT_DIR/run.py" "$@"
