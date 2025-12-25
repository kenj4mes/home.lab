#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# x402 Gateway Installation Script for home.lab (Linux/macOS)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Usage:
#   ./install-x402.sh [action] [profile]
#
# Actions:
#   install    - Install and start the stack (default)
#   uninstall  - Remove the stack
#   start      - Start the stack
#   stop       - Stop the stack
#   status     - Show stack status
#   logs       - Follow logs
#   configure  - Run configuration wizard
#
# Profiles:
#   minimal    - Gateway only
#   standard   - Gateway + Ollama (default)
#   full       - All services including Echo Agent
#
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="x402"
VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${DATA_DIR:-/opt/stacks/x402}"
COMPOSE_FILE="${SCRIPT_DIR}/../docker/docker-compose.yml"
ENV_FILE="${SCRIPT_DIR}/../docker/.env"
ENV_EXAMPLE="${SCRIPT_DIR}/../docker/.env.example"

# Ports
PORT_GATEWAY=3402
PORT_OLLAMA=11434
PORT_CHROMADB=8000
PORT_ECHO=8080

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                               ║"
    echo "║   ⚡ x402 GATEWAY INSTALLER                                                   ║"
    echo "║   HTTP 402 Payment Required | Base Network | USDC                             ║"
    echo "║                                                                               ║"
    echo "║   Version: ${VERSION}                                                              ║"
    echo "║   Profile: ${PROFILE:-standard}                                                          ║"
    echo "║                                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    # Check Docker
    if command -v docker &> /dev/null; then
        echo -e "  ${GREEN}✅ Docker: $(docker --version)${NC}"
    else
        echo -e "  ${RED}❌ Docker not found. Please install Docker first.${NC}"
        exit 1
    fi
    
    # Check Docker Compose
    if docker compose version &> /dev/null; then
        echo -e "  ${GREEN}✅ Docker Compose: $(docker compose version)${NC}"
    else
        echo -e "  ${RED}❌ Docker Compose not found.${NC}"
        exit 1
    fi
    
    # Check ports
    for port in $PORT_GATEWAY $PORT_OLLAMA; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "  ${YELLOW}⚠️  Port $port is already in use${NC}"
        fi
    done
}

init_environment() {
    echo -e "\n${YELLOW}📁 Initializing environment...${NC}"
    
    # Create directories
    dirs=(
        "${DATA_DIR}/gateway"
        "${DATA_DIR}/ollama"
        "${DATA_DIR}/chromadb"
        "${DATA_DIR}/echo/data"
        "${DATA_DIR}/echo/memories"
    )
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo -e "  ${GRAY}📂 Created: $dir${NC}"
        fi
    done
    
    # Create .env if not exists
    if [ ! -f "$ENV_FILE" ]; then
        if [ -f "$ENV_EXAMPLE" ]; then
            cp "$ENV_EXAMPLE" "$ENV_FILE"
            echo -e "  ${GRAY}📄 Created .env from template${NC}"
            echo -e "  ${YELLOW}⚠️  Please edit .env with your settings!${NC}"
        else
            cat > "$ENV_FILE" << EOF
# x402 Gateway Configuration
PORT=3402
SERVER_WALLET_ADDRESS=0x...your-wallet-here
JWT_SECRET=$(openssl rand -hex 32)

# Ollama
OLLAMA_HOST=http://ollama:11434
DEFAULT_MODEL=llama3.2:latest

# ChromaDB
CHROMADB_HOST=http://chromadb:8000

# Traefik
TRAEFIK_HOST=x402.home.lab
EOF
            echo -e "  ${GRAY}📄 Created minimal .env file${NC}"
        fi
    fi
    
    echo -e "  ${GREEN}✅ Environment initialized${NC}"
}

build_images() {
    echo -e "\n${YELLOW}🔨 Building images...${NC}"
    
    gateway_dir="${SCRIPT_DIR}/../docker/x402-gateway"
    echo_dir="${SCRIPT_DIR}/../docker/agent"
    
    if [ -d "$gateway_dir" ]; then
        echo -e "  ${GRAY}🏗️  Building x402-gateway...${NC}"
        docker build -t x402-gateway:latest "$gateway_dir"
    fi
    
    if [ -d "$echo_dir" ]; then
        echo -e "  ${GRAY}🏗️  Building echo-agent...${NC}"
        docker build -t echo-agent:latest "$echo_dir"
    fi
    
    echo -e "  ${GREEN}✅ Images built${NC}"
}

start_stack() {
    local profile="${1:-standard}"
    
    echo -e "\n${YELLOW}🚀 Starting x402 stack (Profile: $profile)...${NC}"
    
    case "$profile" in
        minimal)
            docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d x402-gateway
            ;;
        standard)
            docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d x402-gateway ollama
            ;;
        full)
            docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" --profile agent up -d
            ;;
    esac
    
    echo -e "\n  ${GREEN}✅ Stack started${NC}"
    
    echo -e "\n${CYAN}📡 Access Points:${NC}"
    echo -e "  ${GRAY}• Gateway:  http://localhost:${PORT_GATEWAY}${NC}"
    echo -e "  ${GRAY}• Traefik:  https://x402.home.lab${NC}"
    
    if [ "$profile" = "standard" ] || [ "$profile" = "full" ]; then
        echo -e "  ${GRAY}• Ollama:   http://localhost:${PORT_OLLAMA}${NC}"
    fi
    
    if [ "$profile" = "full" ]; then
        echo -e "  ${GRAY}• ChromaDB: http://localhost:${PORT_CHROMADB}${NC}"
        echo -e "  ${GRAY}• Echo:     http://localhost:${PORT_ECHO}${NC}"
    fi
}

stop_stack() {
    echo -e "\n${YELLOW}🛑 Stopping x402 stack...${NC}"
    docker compose -f "$COMPOSE_FILE" down
    echo -e "  ${GREEN}✅ Stack stopped${NC}"
}

show_status() {
    echo -e "\n${CYAN}📊 x402 Stack Status:${NC}"
    docker compose -f "$COMPOSE_FILE" ps
    
    echo -e "\n${CYAN}📈 Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep -E "x402|ollama|chromadb|echo" || true
}

show_logs() {
    local service="${1:-}"
    docker compose -f "$COMPOSE_FILE" logs -f --tail 100 $service
}

uninstall_stack() {
    echo -e "\n${YELLOW}🗑️  Uninstalling x402 stack...${NC}"
    
    docker compose -f "$COMPOSE_FILE" down -v
    
    if [ "$FORCE" = "true" ]; then
        echo -e "  ${GRAY}🗑️  Removing images...${NC}"
        docker rmi x402-gateway:latest echo-agent:latest 2>/dev/null || true
        
        echo -e "  ${GRAY}🗑️  Removing data...${NC}"
        rm -rf "$DATA_DIR"
    fi
    
    echo -e "  ${GREEN}✅ Uninstall complete${NC}"
}

configure_wizard() {
    echo -e "\n${CYAN}⚙️  Configuration Wizard${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    read -p "Enter your Base wallet address (receives payments): " wallet
    
    jwt_secret=$(openssl rand -hex 32)
    
    read -p "Enter Traefik hostname (default: x402.home.lab): " traefik_host
    traefik_host="${traefik_host:-x402.home.lab}"
    
    cat > "$ENV_FILE" << EOF
# x402 Gateway Configuration
# Generated by install-x402.sh

# Server
PORT=3402
NODE_ENV=production

# Wallet (receives payments)
SERVER_WALLET_ADDRESS=${wallet}

# Security
JWT_SECRET=${jwt_secret}

# Network
BASE_RPC_URL=https://mainnet.base.org

# LLM
OLLAMA_HOST=http://ollama:11434
DEFAULT_MODEL=llama3.2:latest

# Memory
CHROMADB_HOST=http://chromadb:8000
MEMORY_COLLECTION=echo_memories

# Traefik
TRAEFIK_HOST=${traefik_host}

# Logging
LOG_LEVEL=INFO
JSON_LOGS=true
EOF

    echo -e "\n  ${GREEN}✅ Configuration saved to .env${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

ACTION="${1:-install}"
PROFILE="${2:-standard}"
FORCE="${FORCE:-false}"

banner

case "$ACTION" in
    install)
        check_prerequisites
        init_environment
        build_images
        start_stack "$PROFILE"
        ;;
    configure)
        configure_wizard
        ;;
    start)
        start_stack "$PROFILE"
        ;;
    stop)
        stop_stack
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "${3:-}"
        ;;
    uninstall)
        uninstall_stack
        ;;
    *)
        echo "Usage: $0 [install|uninstall|start|stop|status|logs|configure] [minimal|standard|full]"
        exit 1
        ;;
esac

echo -e "\n${GREEN}✨ Done!${NC}"
