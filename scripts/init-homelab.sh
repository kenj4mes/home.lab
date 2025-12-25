#!/usr/bin/env bash
# ==============================================================================
# 🚀 HomeLab Complete Setup Script
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# This is the ONE script to rule them all.
# It will:
#   1. Install Docker & Dependencies
#   2. Install Ollama & Models
#   3. Create directory structure
#   4. Download all required content (ZIMs, models)
#   5. Start all services
#
# Usage:
#   chmod +x init-homelab.sh
#   sudo ./init-homelab.sh [--minimal|--standard|--full]
#
# Profiles:
#   --minimal   ~5 GB  - Basic services, small LLM, Simple Wikipedia
#   --standard  ~50 GB - Full services, good LLMs, English Wikipedia (DEFAULT)
#   --full      ~250 GB - Everything, all LLMs, complete Wikipedia + more
# ==============================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ollama.sh"

# Initialize logging
init_logging "init-homelab"

# Default configuration
PROFILE="${1:-standard}"
PROFILE="${PROFILE#--}"  # Remove -- prefix if present

# Load .env if exists
if [[ -f "${SCRIPT_DIR}/../docker/.env" ]]; then
    debug "Loading existing .env file"
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/../docker/.env"
fi

# Default paths
MEDIA_PATH="${MEDIA_PATH:-/srv/homelab/data}"
CONFIG_PATH="${CONFIG_PATH:-/srv/homelab/config}"
TZ="${TZ:-America/New_York}"
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

# ==============================================================================
# CHECKS
# ==============================================================================

print_banner
info "Starting HomeLab Complete Setup"
info "Profile:     $PROFILE"
info "Config Path: $CONFIG_PATH"
info "Media Path:  $MEDIA_PATH"

# Must run as root
require_root

# Check disk space
phase "Pre-flight Checks"
case $PROFILE in
    minimal)  REQUIRED_GB=10 ;;
    standard) REQUIRED_GB=60 ;;
    full)     REQUIRED_GB=300 ;;
esac

check_disk_space "$REQUIRED_GB" "$MEDIA_PATH" || {
    if ! confirm "Insufficient disk space. Continue anyway?"; then
        exit 0
    fi
}

# ==============================================================================
# PHASE 1: Install Docker
# ==============================================================================

phase "PHASE 1: Docker Installation"

if command_exists docker; then
    success "Docker already installed ($(get_docker_version))"
else
    info "Installing Docker..."
    
    # Detect package manager
    PKG_MGR=$(detect_package_manager)
    
    case "$PKG_MGR" in
        apt)
            apt-get update
            apt-get install -y ca-certificates curl gnupg lsb-release
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL "https://download.docker.com/linux/$(detect_distro)/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(detect_distro) $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        dnf|yum)
            $PKG_MGR -y install dnf-plugins-core
            dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            $PKG_MGR -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *)
            error "Unsupported package manager: $PKG_MGR"
            error "Please install Docker manually: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
    
    systemctl enable docker
    systemctl start docker
    success "Docker installed successfully"
fi

# Add user to docker group
if [[ -n "$SUDO_USER" ]]; then
    usermod -aG docker "$SUDO_USER" 2>/dev/null || true
fi

# ==============================================================================
# PHASE 2: Install Ollama
# ==============================================================================

phase "PHASE 2: Ollama Installation"

if ollama_ensure_running; then
    success "Ollama ready ($(get_ollama_version))"
else
    error "Ollama setup failed"
    exit 1
fi

# ==============================================================================
# PHASE 3: Create Directory Structure
# ==============================================================================

phase "PHASE 3: Creating Directory Structure"

directories=(
    "${MEDIA_PATH}/Movies"
    "${MEDIA_PATH}/Series"
    "${MEDIA_PATH}/Music"
    "${MEDIA_PATH}/Photos"
    "${MEDIA_PATH}/Books"
    "${MEDIA_PATH}/Downloads"
    "${MEDIA_PATH}/ZIM"
    "${CONFIG_PATH}/jellyfin/config"
    "${CONFIG_PATH}/qbittorrent/config"
    "${CONFIG_PATH}/bookstack/config"
    "${CONFIG_PATH}/nginx/data"
    "${CONFIG_PATH}/nginx/letsencrypt"
    "${CONFIG_PATH}/nginx/ssl"
    "${CONFIG_PATH}/ollama"
    "${CONFIG_PATH}/portainer"
    "${CONFIG_PATH}/open-webui"
    "${CONFIG_PATH}/base-node"
    "${CONFIG_PATH}/base-wallet"
    "${CONFIG_PATH}/base-db"
    "${CONFIG_PATH}/prometheus"
    "${CONFIG_PATH}/grafana"
    "${CONFIG_PATH}/loki"
    "${CONFIG_PATH}/secrets"
    "${CONFIG_PATH}/backups"
)

for dir in "${directories[@]}"; do
    ensure_dir "$dir"
done

# Set permissions
chown -R "${PUID}:${PGID}" "${MEDIA_PATH}" "${CONFIG_PATH}" 2>/dev/null || true
success "Directory structure ready"

# ==============================================================================
# PHASE 4: Download Content
# ==============================================================================

phase "PHASE 4: Downloading Content"

# Run the download scripts
if [[ -f "${SCRIPT_DIR}/download-all.sh" ]]; then
    info "Starting ZIM content download..."
    bash "${SCRIPT_DIR}/download-all.sh" --"${PROFILE}" --skip-ollama <<< "y"
fi

if [[ -f "${SCRIPT_DIR}/download-models.sh" ]]; then
    info "Starting Ollama models download..."
    bash "${SCRIPT_DIR}/download-models.sh" --profile "${PROFILE}"
fi

# ==============================================================================
# PHASE 5: Configure Environment
# ==============================================================================

phase "PHASE 5: Configuring Environment"

if [[ -f "${SCRIPT_DIR}/env-generator.sh" ]]; then
    bash "${SCRIPT_DIR}/env-generator.sh"
else
    warn "env-generator.sh not found, skipping"
fi

# ==============================================================================
# PHASE 6: Post-Quantum Security (Optional)
# ==============================================================================

phase "PHASE 6: Post-Quantum Security Setup"

INSTALL_QUANTUM="${INSTALL_QUANTUM:-auto}"

# Auto-detect: install quantum on full profile or if explicitly requested
if [[ "$PROFILE" == "full" ]] || [[ "$INSTALL_QUANTUM" == "true" ]]; then
    INSTALL_QUANTUM="true"
elif [[ "$INSTALL_QUANTUM" == "auto" ]]; then
    if confirm "Install post-quantum security features? (PQ TLS, QRNG, Quantum Simulator)"; then
        INSTALL_QUANTUM="true"
    else
        INSTALL_QUANTUM="false"
    fi
fi

if [[ "$INSTALL_QUANTUM" == "true" ]]; then
    # Install quantum dependencies
    if [[ -f "${SCRIPT_DIR}/install-quantum.sh" ]]; then
        info "Installing post-quantum cryptography dependencies..."
        bash "${SCRIPT_DIR}/install-quantum.sh" || warn "Quantum install had issues, continuing..."
    fi
    
    # Generate PQ TLS certificates
    if [[ -f "${SCRIPT_DIR}/generate-pq-tls.sh" ]]; then
        info "Generating hybrid TLS certificates..."
        bash "${SCRIPT_DIR}/generate-pq-tls.sh" --domain "proxy.local" || warn "PQ TLS generation had issues"
    fi
    
    # Create Docker secrets
    if [[ -f "${SCRIPT_DIR}/create-docker-secrets.sh" ]]; then
        info "Creating Docker secrets..."
        bash "${SCRIPT_DIR}/create-docker-secrets.sh" || warn "Docker secrets creation had issues"
    fi
    
    # Create Notary signing key
    if [[ -f "${SCRIPT_DIR}/create-notary-secret.sh" ]]; then
        info "Creating Notary signing key..."
        bash "${SCRIPT_DIR}/create-notary-secret.sh" || warn "Notary key creation had issues"
    fi
    
    success "Post-quantum security setup complete"
else
    info "Skipping post-quantum security setup"
    info "You can run './scripts/install-quantum.sh' later to enable"
fi

# ==============================================================================
# PHASE 6.5: Web3 & Agent Stack (Optional)
# ==============================================================================

phase "PHASE 6.5: Web3 & Agent Development Stack"

INSTALL_WEB3="${INSTALL_WEB3:-auto}"
INSTALL_AGENTS="${INSTALL_AGENTS:-auto}"
INSTALL_TRELLIS="${INSTALL_TRELLIS:-false}"

# Web3 stack
if [[ "$PROFILE" == "full" ]] || [[ "$INSTALL_WEB3" == "true" ]]; then
    INSTALL_WEB3="true"
elif [[ "$INSTALL_WEB3" == "auto" ]]; then
    if confirm "Install Web3 development stack? (Hardhat, Foundry, Base SDKs)"; then
        INSTALL_WEB3="true"
    else
        INSTALL_WEB3="false"
    fi
fi

if [[ "$INSTALL_WEB3" == "true" ]]; then
    if [[ -f "${SCRIPT_DIR}/install-web3.sh" ]]; then
        info "Installing Web3 development stack..."
        bash "${SCRIPT_DIR}/install-web3.sh" --offline-cache || warn "Web3 install had issues"
    fi
    success "Web3 stack installed"
fi

# Agent stack
if [[ "$PROFILE" == "full" ]] || [[ "$INSTALL_AGENTS" == "true" ]]; then
    INSTALL_AGENTS="true"
elif [[ "$INSTALL_AGENTS" == "auto" ]]; then
    if confirm "Install AI Agent framework? (LangGraph, CrewAI, MCP)"; then
        INSTALL_AGENTS="true"
    else
        INSTALL_AGENTS="false"
    fi
fi

if [[ "$INSTALL_AGENTS" == "true" ]]; then
    if [[ -f "${SCRIPT_DIR}/install-agents.sh" ]]; then
        info "Installing AI Agent framework..."
        bash "${SCRIPT_DIR}/install-agents.sh" --offline-cache || warn "Agent install had issues"
    fi
    success "Agent framework installed"
fi

# Ev0 Sovereign Agent (autonomous AI with wallet)
INSTALL_EV0="${INSTALL_EV0:-auto}"
if [[ "$PROFILE" == "full" ]] || [[ "$INSTALL_EV0" == "true" ]]; then
    INSTALL_EV0="true"
elif [[ "$INSTALL_EV0" == "auto" ]]; then
    if confirm "Install Ev0 Sovereign Agent? (autonomous AI with self-custody wallet, x402 payments)"; then
        INSTALL_EV0="true"
    else
        INSTALL_EV0="false"
    fi
fi

if [[ "$INSTALL_EV0" == "true" ]]; then
    info "Ev0 Sovereign Agent will be started via docker-compose.ev0.yml"
    success "Ev0 Sovereign Agent enabled"
fi

# Sentry MCP (AI debugging integration)
INSTALL_SENTRY_MCP="${INSTALL_SENTRY_MCP:-auto}"
if [[ "$PROFILE" == "full" ]] || [[ "$INSTALL_SENTRY_MCP" == "true" ]]; then
    INSTALL_SENTRY_MCP="true"
elif [[ "$INSTALL_SENTRY_MCP" == "auto" ]]; then
    if confirm "Install Sentry MCP? (AI debugging integration for VS Code/Cursor/Claude)"; then
        INSTALL_SENTRY_MCP="true"
    else
        INSTALL_SENTRY_MCP="false"
    fi
fi

if [[ "$INSTALL_SENTRY_MCP" == "true" ]]; then
    info "Sentry MCP will be started via docker-compose.sentry-mcp.yml"
    success "Sentry MCP enabled"
fi

# TRELLIS.2 (GPU required, manual opt-in)
if [[ "$INSTALL_TRELLIS" == "true" ]]; then
    if lspci | grep -i nvidia &> /dev/null; then
        if [[ -f "${SCRIPT_DIR}/install-trellis.sh" ]]; then
            info "Installing TRELLIS.2 (Image-to-3D)..."
            bash "${SCRIPT_DIR}/install-trellis.sh" || warn "TRELLIS install had issues"
        fi
        success "TRELLIS.2 installed"
    else
        warn "TRELLIS.2 requires NVIDIA GPU, skipping"
    fi
fi

# ==============================================================================
# PHASE 7: Start Services
# ==============================================================================

phase "PHASE 7: Starting Services"

cd "${SCRIPT_DIR}/../docker" || { error "Failed to change to docker directory"; exit 1; }

info "Pulling Docker images..."
docker compose pull

info "Starting core containers..."
docker compose up -d

# Start Base blockchain services if full profile
if [[ "$PROFILE" == "full" ]] || [[ "${ENABLE_BASE:-false}" == "true" ]]; then
    info "Starting Base blockchain services..."
    docker compose -f docker-compose.base.yml pull 2>/dev/null || true
    docker compose -f docker-compose.base.yml up -d 2>/dev/null || warn "Base services not started"
fi

# Start Quantum services if enabled
if [[ "$INSTALL_QUANTUM" == "true" ]]; then
    info "Building and starting quantum services..."
    docker compose -f docker-compose.quantum.yml build 2>/dev/null || warn "Quantum build had issues"
    docker compose -f docker-compose.quantum.yml up -d 2>/dev/null || warn "Quantum services not started"
fi

# Start monitoring if standard or full profile
if [[ "$PROFILE" == "standard" ]] || [[ "$PROFILE" == "full" ]]; then
    info "Starting monitoring stack..."
    docker compose -f docker-compose.monitoring.yml pull 2>/dev/null || true
    docker compose -f docker-compose.monitoring.yml up -d 2>/dev/null || warn "Monitoring services not started"
fi

# Start Web3 development services if enabled
if [[ "$INSTALL_WEB3" == "true" ]]; then
    info "Starting Web3 development services..."
    docker compose -f docker-compose.dev.yml build 2>/dev/null || warn "Dev build had issues"
    docker compose -f docker-compose.dev.yml up -d anvil 2>/dev/null || warn "Anvil not started"
fi

# Start Agent services if enabled
if [[ "$INSTALL_AGENTS" == "true" ]]; then
    info "Starting Agent orchestrator..."
    docker compose -f docker-compose.agents.yml build 2>/dev/null || warn "Agent build had issues"
    docker compose -f docker-compose.agents.yml up -d 2>/dev/null || warn "Agent services not started"
fi

# Start TRELLIS if enabled and GPU available
if [[ "$INSTALL_TRELLIS" == "true" ]] && lspci | grep -i nvidia &> /dev/null; then
    info "Starting TRELLIS.2 3D generation..."
    docker compose -f docker-compose.dev.yml up -d trellis-3d 2>/dev/null || warn "TRELLIS not started (GPU required)"
fi

# Start Ev0 Sovereign Agent if enabled
if [[ "$INSTALL_EV0" == "true" ]]; then
    info "Starting Ev0 Sovereign Agent..."
    docker compose -f docker-compose.ev0.yml build 2>/dev/null || warn "Ev0 build had issues"
    docker compose -f docker-compose.ev0.yml up -d 2>/dev/null || warn "Ev0 services not started"
fi

# Start Sentry MCP if enabled
if [[ "$INSTALL_SENTRY_MCP" == "true" ]]; then
    info "Starting Sentry MCP server..."
    docker compose -f docker-compose.sentry-mcp.yml up -d 2>/dev/null || warn "Sentry MCP not started"
fi

# Wait for services
info "Waiting for services to initialize..."
sleep 10

# Health check services
info "Running health checks..."
for service in jellyfin open-webui portainer nginx-proxy; do
    if docker ps --format '{{.Names}}' | grep -q "$service"; then
        success "  ✓ $service is running"
    else
        warn "  ⚠ $service not detected"
    fi
done

# Check quantum services if installed
if [[ "$INSTALL_QUANTUM" == "true" ]]; then
    for service in quantum-rng quantum-simulator; do
        if docker ps --format '{{.Names}}' | grep -q "$service"; then
            success "  ✓ $service is running"
        else
            warn "  ⚠ $service not detected"
        fi
    done
fi

# Check Web3 services if installed
if [[ "$INSTALL_WEB3" == "true" ]]; then
    for service in anvil hardhat-dev; do
        if docker ps --format '{{.Names}}' | grep -q "$service"; then
            success "  ✓ $service is running"
        else
            warn "  ⚠ $service not detected"
        fi
    done
fi

# Check Agent services if installed
if [[ "$INSTALL_AGENTS" == "true" ]]; then
    for service in agent-orchestrator chromadb; do
        if docker ps --format '{{.Names}}' | grep -q "$service"; then
            success "  ✓ $service is running"
        else
            warn "  ⚠ $service not detected"
        fi
    done
fi

# Check Ev0 services if installed
if [[ "$INSTALL_EV0" == "true" ]]; then
    for service in ev0-agent ev0-server; do
        if docker ps --format '{{.Names}}' | grep -q "$service"; then
            success "  ✓ $service is running"
        else
            warn "  ⚠ $service not detected"
        fi
    done
fi

# Check Sentry MCP if installed
if [[ "$INSTALL_SENTRY_MCP" == "true" ]]; then
    if docker ps --format '{{.Names}}' | grep -q "sentry-mcp"; then
        success "  ✓ sentry-mcp is running"
    else
        warn "  ⚠ sentry-mcp not detected"
    fi
fi

# Show status
echo ""
info "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -25

# ==============================================================================
# COMPLETE
# ==============================================================================

echo ""
success "HOMELAB SETUP COMPLETE!"
echo ""

# Get IP address
IP=$(hostname -I | awk '{print $1}')

info "Your services are now running:"
echo -e "  ${GREEN}Jellyfin${NC}      http://${IP}:8096"
echo -e "  ${GREEN}Open WebUI${NC}    http://${IP}:3000"
echo -e "  ${GREEN}Portainer${NC}     http://${IP}:9000"
echo -e "  ${GREEN}Nginx Proxy${NC}   http://${IP}:81"
echo -e "  ${GREEN}BookStack${NC}     http://${IP}:8082"
echo -e "  ${GREEN}Kiwix${NC}         http://${IP}:8081"

# Show monitoring if started
if [[ "$PROFILE" == "standard" ]] || [[ "$PROFILE" == "full" ]]; then
    echo ""
    info "Monitoring Stack:"
    echo -e "  ${GREEN}Prometheus${NC}    http://${IP}:9090"
    echo -e "  ${GREEN}Grafana${NC}       http://${IP}:3100"
fi

# Show blockchain if started
if [[ "$PROFILE" == "full" ]] || [[ "${ENABLE_BASE:-false}" == "true" ]]; then
    echo ""
    info "Blockchain Services:"
    echo -e "  ${GREEN}Base RPC${NC}      http://${IP}:8545"
    echo -e "  ${GREEN}Explorer${NC}      http://${IP}:4000"
    echo -e "  ${GREEN}Wallet API${NC}    http://${IP}:5000"
fi

# Show quantum if installed
if [[ "$INSTALL_QUANTUM" == "true" ]]; then
    echo ""
    info "Quantum Services:"
    echo -e "  ${GREEN}Quantum RNG${NC}   http://${IP}:5001"
    echo -e "  ${GREEN}Q-Simulator${NC}   http://${IP}:5002"
    echo ""
    info "Quantum-safe features enabled:"
    echo -e "  ${GREEN}✓${NC} Hybrid TLS certificates (Kyber-768 + ECDSA)"
    echo -e "  ${GREEN}✓${NC} Docker secrets (cryptographically secure)"
    echo -e "  ${GREEN}✓${NC} Quantum RNG for entropy"
    echo -e "  ${GREEN}✓${NC} Quantum circuit simulator"
fi

# Show Web3 if installed
if [[ "$INSTALL_WEB3" == "true" ]]; then
    echo ""
    info "Web3 Development:"
    echo -e "  ${GREEN}Anvil Node${NC}    http://${IP}:8547"
    echo -e "  ${GREEN}Hardhat${NC}       http://${IP}:8545"
    echo ""
    info "Web3 tools available:"
    echo -e "  ${GREEN}✓${NC} Hardhat + Foundry"
    echo -e "  ${GREEN}✓${NC} Base network configs"
    echo -e "  ${GREEN}✓${NC} OpenZeppelin contracts"
fi

# Show Agents if installed
if [[ "$INSTALL_AGENTS" == "true" ]]; then
    echo ""
    info "Agent Services:"
    echo -e "  ${GREEN}Orchestrator${NC}  http://${IP}:5004"
    echo -e "  ${GREEN}ChromaDB${NC}      http://${IP}:8000"
    echo ""
    info "Agent frameworks:"
    echo -e "  ${GREEN}✓${NC} LangGraph (reasoning)"
    echo -e "  ${GREEN}✓${NC} CrewAI (multi-agent)"
    echo -e "  ${GREEN}✓${NC} MCP (HomeLab integration)"
fi

# Show TRELLIS if installed
if [[ "$INSTALL_TRELLIS" == "true" ]]; then
    echo ""
    info "3D Generation:"
    echo -e "  ${GREEN}TRELLIS.2${NC}     http://${IP}:5003"
    echo -e "  ${GREEN}Web UI${NC}        http://${IP}:7860"
fi

# Show Ev0 if installed
if [[ "$INSTALL_EV0" == "true" ]]; then
    echo ""
    info "Ev0 Sovereign Agent:"
    echo -e "  ${GREEN}Agent API${NC}     http://${IP}:8787"
    echo -e "  ${GREEN}MCP Server${NC}    stdio://ev0-mcp"
    echo ""
    info "Ev0 capabilities:"
    echo -e "  ${GREEN}✓${NC} Autonomous OODA loop execution"
    echo -e "  ${GREEN}✓${NC} Self-custody wallet (Base L2)"
    echo -e "  ${GREEN}✓${NC} x402 agent-to-agent payments"
    echo -e "  ${GREEN}✓${NC} Collective intelligence swarm"
    echo -e "  ${GREEN}✓${NC} DePIN oracle services"
fi

# Show Sentry MCP if installed
if [[ "$INSTALL_SENTRY_MCP" == "true" ]]; then
    echo ""
    info "Sentry MCP:"
    echo -e "  ${GREEN}MCP Server${NC}    stdio://sentry-mcp"
    echo ""
    info "Sentry MCP features:"
    echo -e "  ${GREEN}✓${NC} AI-powered error analysis"
    echo -e "  ${GREEN}✓${NC} Root cause detection"
    echo -e "  ${GREEN}✓${NC} VS Code / Cursor / Claude integration"
fi
echo ""

warn "Next Steps:"
echo "  1. View credentials in output above or scripts/env-generator.sh logs"
echo "  2. Change ALL default passwords immediately"
echo "  3. See docs/SECURITY.md for hardening guide"
if [[ "$INSTALL_QUANTUM" == "true" ]]; then
    echo "  4. See docs/QUANTUM.md for quantum features guide"
fi
echo ""

if [[ -n "$SUDO_USER" ]]; then
    warn "Remember: Log out and back in as $SUDO_USER for docker group to take effect"
fi
