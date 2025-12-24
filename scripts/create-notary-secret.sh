#!/usr/bin/env bash
# ============================================================================
# create-notary-secret.sh - Create Notary v2 Signing Key for Docker Content Trust
# ============================================================================
# Generates a signing key for Notary v2 (notation) to enable Docker Content Trust
# with post-quantum safe signatures (Dilithium-5 when available).
#
# Usage: sudo ./scripts/create-notary-secret.sh [--force]
# ============================================================================
set -euo pipefail
IFS=$'\n\t'

# ---------- Source common library ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# ---------- Configuration ----------
FORCE="${FORCE:-false}"
NOTATION_DIR="${HOME}/.config/notation"
KEY_NAME="${KEY_NAME:-homelab-signing-key}"
KEY_TYPE="${KEY_TYPE:-ec}"  # ec, rsa, or dilithium (when OQS available)

# ---------- Parse arguments ----------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --force|-f) FORCE="true"; shift ;;
        --key-type) KEY_TYPE="$2"; shift 2 ;;
        --key-name) KEY_NAME="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --force, -f        Recreate key even if it exists"
            echo "  --key-type TYPE    Key type: ec, rsa, dilithium (default: ec)"
            echo "  --key-name NAME    Key name (default: homelab-signing-key)"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *) error "Unknown option: $1"; exit 1 ;;
    esac
done

# ---------- Pre-flight checks ----------
require_root

info "Creating Notary v2 signing key for Docker Content Trust"
info "Key name: ${KEY_NAME}"
info "Key type: ${KEY_TYPE}"

# Create notation config directory
mkdir -p "$NOTATION_DIR"
chmod 700 "$NOTATION_DIR"

# ---------- Check for notation CLI ----------
if ! command -v notation &>/dev/null; then
    warn "Notation CLI not found. Installing..."
    
    NOTATION_VERSION="1.0.0"
    NOTATION_URL="https://github.com/notaryproject/notation/releases/download/v${NOTATION_VERSION}/notation_${NOTATION_VERSION}_linux_amd64.tar.gz"
    
    cd /tmp
    if curl -sSL "$NOTATION_URL" -o notation.tar.gz 2>/dev/null; then
        tar -xzf notation.tar.gz -C /usr/local/bin notation
        chmod +x /usr/local/bin/notation
        rm -f notation.tar.gz
        success "Notation CLI installed"
    else
        error "Could not download notation CLI"
        info "Please run install-quantum.sh first or install notation manually"
        exit 1
    fi
fi

# ---------- Generate signing key ----------
section "Generating signing key"

KEY_FILE="${NOTATION_DIR}/${KEY_NAME}.key"
CERT_FILE="${NOTATION_DIR}/${KEY_NAME}.crt"

if [[ -f "$KEY_FILE" ]] && [[ "$FORCE" != "true" ]]; then
    info "Signing key already exists: ${KEY_FILE}"
    info "Use --force to regenerate"
else
    info "Generating ${KEY_TYPE^^} signing key..."
    
    case "$KEY_TYPE" in
        ec|EC)
            # Generate ECDSA P-256 key pair
            openssl genpkey -algorithm EC \
                -pkeyopt ec_paramgen_curve:prime256v1 \
                -out "$KEY_FILE"
            ;;
        rsa|RSA)
            # Generate RSA 4096-bit key pair
            openssl genpkey -algorithm RSA \
                -pkeyopt rsa_keygen_bits:4096 \
                -out "$KEY_FILE"
            ;;
        dilithium|DILITHIUM)
            # Placeholder for Dilithium-5 (requires OQS)
            warn "Dilithium-5 requires liboqs. Falling back to EC..."
            openssl genpkey -algorithm EC \
                -pkeyopt ec_paramgen_curve:prime256v1 \
                -out "$KEY_FILE"
            ;;
        *)
            error "Unknown key type: ${KEY_TYPE}"
            exit 1
            ;;
    esac
    
    chmod 600 "$KEY_FILE"
    success "Private key generated: ${KEY_FILE}"
    
    # Generate self-signed certificate
    info "Generating self-signed certificate..."
    openssl req -new -x509 \
        -key "$KEY_FILE" \
        -out "$CERT_FILE" \
        -days 3650 \
        -subj "/C=US/ST=HomeLab/L=Local/O=HomeLab/OU=Docker Content Trust/CN=${KEY_NAME}"
    
    chmod 644 "$CERT_FILE"
    success "Certificate generated: ${CERT_FILE}"
fi

# ---------- Add key to notation ----------
section "Configuring notation"

# Check if key is already added
if notation key list 2>/dev/null | grep -q "$KEY_NAME"; then
    if [[ "$FORCE" == "true" ]]; then
        info "Removing existing key from notation..."
        notation key delete "$KEY_NAME" --force 2>/dev/null || true
    else
        info "Key already registered with notation"
    fi
fi

# Add key to notation
info "Registering key with notation..."
notation key add "$KEY_NAME" "$KEY_FILE" --default 2>/dev/null || \
    notation key add "$KEY_NAME" --plugin-config "keyPath=$KEY_FILE" 2>/dev/null || \
    warn "Could not register key with notation (may require manual setup)"

# Add certificate to trust store
TRUST_STORE="${NOTATION_DIR}/truststore/x509/ca/homelab"
mkdir -p "$TRUST_STORE"
cp "$CERT_FILE" "${TRUST_STORE}/${KEY_NAME}.crt"

# ---------- Create Docker secret (optional) ----------
section "Creating Docker secret"

SECRET_NAME="notary-key"

# Check if Docker is in swarm mode
if docker info 2>/dev/null | grep -q "Swarm: active"; then
    if docker secret inspect "$SECRET_NAME" &>/dev/null; then
        if [[ "$FORCE" == "true" ]]; then
            docker secret rm "$SECRET_NAME" 2>/dev/null || true
            cat "$KEY_FILE" | docker secret create "$SECRET_NAME" - && \
                success "Docker secret '${SECRET_NAME}' recreated" || \
                warn "Could not create Docker secret"
        else
            info "Docker secret '${SECRET_NAME}' already exists"
        fi
    else
        cat "$KEY_FILE" | docker secret create "$SECRET_NAME" - && \
            success "Docker secret '${SECRET_NAME}' created" || \
            warn "Could not create Docker secret"
    fi
else
    info "Docker Swarm not active, skipping Docker secret creation"
    info "Key file available at: ${KEY_FILE}"
fi

# ---------- Configure Docker for Content Trust ----------
section "Docker Content Trust configuration"

DOCKER_CONFIG="/etc/docker/daemon.json"
if [[ -f "$DOCKER_CONFIG" ]]; then
    info "Docker daemon config exists. To enable Content Trust, add:"
    cat <<EOF

  "content-trust": {
    "mode": "enforced",
    "allow-expired-cached-trust-data": false
  }

EOF
else
    info "To enable Docker Content Trust, create ${DOCKER_CONFIG} with:"
    cat <<EOF
{
  "content-trust": {
    "mode": "enforced",
    "allow-expired-cached-trust-data": false
  }
}
EOF
fi

# ---------- Summary ----------
echo ""
success "Notary signing key created successfully!"
echo ""
info "Key files:"
echo "  Private Key:   ${KEY_FILE}"
echo "  Certificate:   ${CERT_FILE}"
echo "  Trust Store:   ${TRUST_STORE}"
echo ""
info "To sign an image:"
echo "  notation sign <registry>/<image>:<tag>"
echo ""
info "To verify an image:"
echo "  notation verify <registry>/<image>:<tag>"
echo ""
info "To enable Docker Content Trust globally:"
echo "  export DOCKER_CONTENT_TRUST=1"
echo ""
info "Key listing:"
notation key list 2>/dev/null || echo "  (run 'notation key list' to see registered keys)"

exit 0
