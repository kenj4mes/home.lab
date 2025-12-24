#!/usr/bin/env bash
# ==============================================================================
# 🔐 HomeLab Environment Generator - Secure Secret Generation
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Generates a .env file from .env.example with secure random secrets.
# Safe to run multiple times - preserves existing values.
#
# Usage:
#   ./env-generator.sh [OPTIONS]
#
# Options:
#   --force    Overwrite existing .env file
#   --show     Display generated values (insecure, for debugging)
# ==============================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMELAB_DIR="$(dirname "$SCRIPT_DIR")"

# Source common library
source "${SCRIPT_DIR}/lib/common.sh"

# Initialize logging
init_logging "env-generator"

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# shellcheck disable=SC2034  # ENV_EXAMPLE used for reference/future features
ENV_EXAMPLE="${HOMELAB_DIR}/docker/.env.example"
ENV_FILE="${HOMELAB_DIR}/docker/.env"
FORCE=false
SHOW=false

# ==============================================================================
# PARSE ARGUMENTS
# ==============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --force) FORCE=true; shift ;;
        --show)  SHOW=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--force] [--show]"
            echo "  --force  Overwrite existing .env file"
            echo "  --show   Display generated values"
            exit 0
            ;;
        *) error "Unknown option: $1"; exit 1 ;;
    esac
done

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# Generate a random secret of specified length
generate_secret() {
    local length="${1:-32}"
    openssl rand -base64 "$length" | tr -d '/+=' | head -c "$length"
}

# Generate a random hex string
generate_hex() {
    local length="${1:-32}"
    openssl rand -hex "$((length / 2))"
}

# ==============================================================================
# MAIN
# ==============================================================================

print_banner
echo -e "${CYAN}  Environment Generator${NC}"
echo ""

# Check if .env already exists
if [[ -f "$ENV_FILE" && "$FORCE" != true ]]; then
    warn ".env file already exists at: $ENV_FILE"
    info "Use --force to overwrite, or edit manually"
    exit 0
fi

info "Generating secure .env file..."

# Generate all secrets
DB_ROOT_PASS=$(generate_secret 24)
DB_USER_PASS=$(generate_secret 24)
PIHOLE_PASS=$(generate_secret 16)
BASE_DB_PASS=$(generate_secret 24)
BASE_EXPLORER_SECRET=$(generate_secret 48)

# Create the .env file
cat > "$ENV_FILE" << EOF
# ==============================================================================
# HomeLab Environment Configuration
# ==============================================================================
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# 
# ⚠️  This file contains SECRETS - do not commit to version control!
# ==============================================================================

# ------------------------------------------------------------------------------
# GENERAL SETTINGS
# ------------------------------------------------------------------------------
TZ=America/New_York
PUID=1000
PGID=1000

# ------------------------------------------------------------------------------
# STORAGE PATHS
# ------------------------------------------------------------------------------
# Linux defaults (change for your system)
CONFIG_PATH=/srv/FlashBang
MEDIA_PATH=/srv/Tumadre

# Windows alternatives (uncomment if using Docker Desktop on Windows)
# CONFIG_PATH=C:/HomeLab/config
# MEDIA_PATH=C:/HomeLab/data

# ------------------------------------------------------------------------------
# JELLYFIN
# ------------------------------------------------------------------------------
JELLYFIN_URL=http://localhost:8096

# ------------------------------------------------------------------------------
# BOOKSTACK
# ------------------------------------------------------------------------------
BOOKSTACK_URL=http://localhost:8082
BOOKSTACK_DB_ROOT_PASSWORD=${DB_ROOT_PASS}
BOOKSTACK_DB_PASSWORD=${DB_USER_PASS}

# ------------------------------------------------------------------------------
# PI-HOLE (if using docker-compose.pihole.yml)
# ------------------------------------------------------------------------------
PIHOLE_PASSWORD=${PIHOLE_PASS}

# ------------------------------------------------------------------------------
# BASE BLOCKCHAIN (if using docker-compose.base.yml)
# ------------------------------------------------------------------------------
BASE_NETWORK=base-mainnet
BASE_SYNC_MODE=light
BASE_CHAIN_ID=8453
BASE_DB_PASSWORD=${BASE_DB_PASS}
BASE_EXPLORER_SECRET=${BASE_EXPLORER_SECRET}

# Base RPC URL (for Open-WebUI integration)
BASE_RPC_URL=http://base-node:8545

# Private key for wallet CLI (leave empty for read-only mode)
# Generate with: ./scripts/download-models.sh --model phi3 first, then ask the AI!
BASE_WALLET_PRIVATE_KEY=

# ------------------------------------------------------------------------------
# OPTIONAL: NVIDIA GPU
# ------------------------------------------------------------------------------
# Uncomment to enable GPU support for Jellyfin and Ollama
# NVIDIA_VISIBLE_DEVICES=all
# NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
EOF

success "Environment file created: $ENV_FILE"

if [[ "$SHOW" == true ]]; then
    warn "Generated secrets (DO NOT SHARE):"
    echo ""
    echo "  BOOKSTACK_DB_ROOT_PASSWORD: $DB_ROOT_PASS"
    echo "  BOOKSTACK_DB_PASSWORD:      $DB_USER_PASS"
    echo "  PIHOLE_PASSWORD:            $PIHOLE_PASS"
    echo "  BASE_DB_PASSWORD:           $BASE_DB_PASS"
    echo ""
fi

info "Next steps:"
echo "  1. Review and customize: nano $ENV_FILE"
echo "  2. Start services: docker compose up -d"
echo "  3. Access Portainer at http://localhost:9000"
echo ""

warn "Remember: Never commit .env to version control!"
