#!/usr/bin/env bash
# ============================================================================
# create-docker-secrets.sh - Create Docker Secrets for HomeLab
# ============================================================================
# Generates cryptographically secure Docker secrets for all database passwords
# and sensitive configuration values.
#
# Usage: sudo ./scripts/create-docker-secrets.sh [--force]
# ============================================================================
set -euo pipefail
IFS=$'\n\t'

# ---------- Source common library ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# ---------- Configuration ----------
FORCE="${FORCE:-false}"
SECRET_LENGTH="${SECRET_LENGTH:-32}"

# List of secrets to create
declare -A SECRETS=(
    ["bookstack_root_pwd"]="BookStack MySQL root password"
    ["bookstack_user_pwd"]="BookStack MySQL user password"
    ["base_db_pwd"]="Base blockchain PostgreSQL password"
    ["grafana_admin_pwd"]="Grafana admin password"
    ["portainer_admin_pwd"]="Portainer admin password"
    ["ollama_api_key"]="Ollama API key (optional)"
    ["npm_db_pwd"]="Nginx Proxy Manager database password"
)

# ---------- Parse arguments ----------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --force|-f) FORCE="true"; shift ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --force, -f    Recreate secrets even if they exist"
            echo "  --help, -h     Show this help message"
            echo ""
            echo "Secrets created:"
            for secret in "${!SECRETS[@]}"; do
                echo "  - ${secret}: ${SECRETS[$secret]}"
            done
            exit 0
            ;;
        *) error "Unknown option: $1"; exit 1 ;;
    esac
done

# ---------- Pre-flight checks ----------
require_root

# Check if Docker is running
if ! docker info &>/dev/null; then
    error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if we're in swarm mode (required for secrets)
if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
    info "Docker Swarm is not initialized. Initializing..."
    docker swarm init --advertise-addr 127.0.0.1 2>/dev/null || \
        docker swarm init 2>/dev/null || {
            warn "Could not initialize Docker Swarm"
            warn "Docker secrets require Swarm mode. Using file-based secrets instead."
            USE_FILE_SECRETS="true"
        }
fi

USE_FILE_SECRETS="${USE_FILE_SECRETS:-false}"

# ---------- Generate secrets ----------
section "Creating Docker Secrets"

# Create secrets directory for file-based fallback
SECRETS_DIR="${CONFIG_PATH:-/opt/homelab/config}/secrets"
mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

generate_secret() {
    # Use quantum RNG if available, otherwise fall back to openssl
    if command -v curl &>/dev/null && curl -s --connect-timeout 2 http://quantum-rng:5000/random/32 &>/dev/null; then
        curl -s "http://quantum-rng:5000/random/${SECRET_LENGTH}" | jq -r .hex 2>/dev/null || \
            openssl rand -hex "$SECRET_LENGTH"
    else
        openssl rand -hex "$SECRET_LENGTH"
    fi
}

create_secret() {
    local name="$1"
    local description="$2"  # Used for logging context
    local secret_value
    
    # Log the description if verbose mode (future enhancement)
    : "${description}"  # Silence SC2034 - variable is for documentation
    
    secret_value=$(generate_secret)
    
    if [[ "$USE_FILE_SECRETS" == "true" ]]; then
        # File-based secrets
        local secret_file="${SECRETS_DIR}/${name}"
        
        if [[ -f "$secret_file" ]] && [[ "$FORCE" != "true" ]]; then
            info "  ✓ ${name} already exists (skipped)"
            return 0
        fi
        
        echo -n "$secret_value" > "$secret_file"
        chmod 600 "$secret_file"
        success "  ✓ ${name} created (file-based)"
        
    else
        # Docker secrets
        if docker secret inspect "$name" &>/dev/null; then
            if [[ "$FORCE" == "true" ]]; then
                info "  Removing existing secret: ${name}"
                docker secret rm "$name" 2>/dev/null || true
            else
                info "  ✓ ${name} already exists (skipped)"
                return 0
            fi
        fi
        
        echo -n "$secret_value" | docker secret create "$name" - &>/dev/null && \
            success "  ✓ ${name} created" || \
            error "  ✗ Failed to create ${name}"
    fi
}

info "Generating cryptographically secure secrets..."
echo ""

for secret in "${!SECRETS[@]}"; do
    create_secret "$secret" "${SECRETS[$secret]}"
done

# ---------- Create reference file ----------
section "Creating secrets reference"

REFERENCE_FILE="${SECRETS_DIR}/README.txt"
cat > "$REFERENCE_FILE" <<EOF
# Docker Secrets Reference
# Generated: $(date -Iseconds)
# 
# This file lists all Docker secrets created for HomeLab.
# The actual secret values are stored securely by Docker (Swarm mode)
# or in individual files in this directory (file-based mode).
#
# Mode: $(if [[ "$USE_FILE_SECRETS" == "true" ]]; then echo "File-based"; else echo "Docker Swarm"; fi)
#
# Secrets:
EOF

for secret in "${!SECRETS[@]}"; do
    echo "#   ${secret} - ${SECRETS[$secret]}" >> "$REFERENCE_FILE"
done

cat >> "$REFERENCE_FILE" <<EOF
#
# To view a secret value (Swarm mode):
#   docker secret inspect --format='{{.Spec.Data}}' <secret_name> | base64 -d
#
# To view a secret value (file-based):
#   cat ${SECRETS_DIR}/<secret_name>
#
# To recreate all secrets:
#   sudo ./scripts/create-docker-secrets.sh --force
#
# SECURITY NOTES:
#   - Never commit secret values to version control
#   - Rotate secrets quarterly
#   - Back up secrets securely (encrypted)
EOF

chmod 600 "$REFERENCE_FILE"

# ---------- List created secrets ----------
section "Secret inventory"

if [[ "$USE_FILE_SECRETS" == "true" ]]; then
    info "File-based secrets in ${SECRETS_DIR}:"
    for f in "${SECRETS_DIR}"/*; do
        [[ -f "$f" ]] && [[ "$(basename "$f")" != "README"* ]] && echo "  $(ls -la "$f")"
    done
else
    info "Docker secrets:"
    docker secret ls | sed 's/^/  /'
fi

# ---------- Summary ----------
echo ""
success "Docker secrets created successfully!"
echo ""
info "Usage in docker-compose.yml:"
echo ""
if [[ "$USE_FILE_SECRETS" == "true" ]]; then
    cat <<EOF
  secrets:
    bookstack_root_pwd:
      file: ${SECRETS_DIR}/bookstack_root_pwd
    bookstack_user_pwd:
      file: ${SECRETS_DIR}/bookstack_user_pwd
    base_db_pwd:
      file: ${SECRETS_DIR}/base_db_pwd
EOF
else
    cat <<EOF
  secrets:
    bookstack_root_pwd:
      external: true
    bookstack_user_pwd:
      external: true
    base_db_pwd:
      external: true
EOF
fi

echo ""
info "Service configuration:"
cat <<EOF
  services:
    bookstack-db:
      environment:
        - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/bookstack_root_pwd
        - MYSQL_PASSWORD_FILE=/run/secrets/bookstack_user_pwd
      secrets:
        - bookstack_root_pwd
        - bookstack_user_pwd
EOF

exit 0
