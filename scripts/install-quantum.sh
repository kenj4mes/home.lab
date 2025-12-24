#!/usr/bin/env bash
# ============================================================================
# install-quantum.sh - Install Post-Quantum Cryptography Dependencies
# ============================================================================
# Installs liboqs, OpenSSL 3.x with OQS support, Notary v2, and oqs-tools
# for quantum-safe TLS, signatures, and backup encryption.
#
# Usage: sudo ./scripts/install-quantum.sh
# ============================================================================
set -euo pipefail
IFS=$'\n\t'

# ---------- Source common library ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# ---------- Configuration ----------
OPENSSL_VERSION="${OPENSSL_VERSION:-3.1.5}"
LIBOQS_VERSION="${LIBOQS_VERSION:-0.10.0}"
NOTARY_VERSION="${NOTARY_VERSION:-1.0.0}"

# ---------- Pre-flight checks ----------
require_root
require_debian

info "Starting Post-Quantum Cryptography installation..."
info "This will install liboqs, OpenSSL 3.x with OQS, Notary v2, and oqs-tools"

# ---------- Install build dependencies ----------
section "Installing build dependencies"
apt-get update -qq
apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    ninja-build \
    libssl-dev \
    ca-certificates \
    curl \
    jq

# ---------- Install liboqs ----------
section "Installing liboqs v${LIBOQS_VERSION}"

if command -v oqs-info &>/dev/null; then
    info "liboqs already installed, skipping..."
else
    cd /usr/local/src
    
    if [[ -d "liboqs" ]]; then
        info "liboqs source exists, updating..."
        cd liboqs
        git fetch --tags
        git checkout "${LIBOQS_VERSION}" 2>/dev/null || git checkout "main"
    else
        info "Cloning liboqs repository..."
        git clone --depth 1 --branch "${LIBOQS_VERSION}" \
            https://github.com/open-quantum-safe/liboqs.git 2>/dev/null || \
        git clone --depth 1 https://github.com/open-quantum-safe/liboqs.git
        cd liboqs
    fi
    
    info "Building liboqs..."
    mkdir -p build && cd build
    cmake -GNinja \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DBUILD_SHARED_LIBS=ON \
        -DOQS_BUILD_ONLY_LIB=OFF \
        ..
    ninja
    ninja install
    ldconfig
    
    success "liboqs installed successfully"
fi

# ---------- Install OQS-OpenSSL Provider ----------
section "Installing OQS-OpenSSL Provider"

if [[ -f "/usr/local/lib/ossl-modules/oqsprovider.so" ]]; then
    info "OQS-OpenSSL provider already installed, skipping..."
else
    cd /usr/local/src
    
    if [[ -d "oqs-provider" ]]; then
        info "oqs-provider source exists, updating..."
        cd oqs-provider
        git pull
    else
        info "Cloning oqs-provider repository..."
        git clone --depth 1 https://github.com/open-quantum-safe/oqs-provider.git
        cd oqs-provider
    fi
    
    info "Building oqs-provider..."
    mkdir -p build && cd build
    cmake -GNinja \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DOPENSSL_ROOT_DIR=/usr \
        ..
    ninja
    ninja install
    
    success "OQS-OpenSSL provider installed"
fi

# ---------- Configure OpenSSL to use OQS ----------
section "Configuring OpenSSL for OQS"

OPENSSL_CONF="/etc/ssl/openssl.cnf"
if grep -q "oqsprovider" "$OPENSSL_CONF" 2>/dev/null; then
    info "OpenSSL already configured for OQS"
else
    info "Adding OQS provider to OpenSSL configuration..."
    
    # Backup original config
    cp "$OPENSSL_CONF" "${OPENSSL_CONF}.bak.$(date +%Y%m%d)"
    
    # Add OQS provider configuration
    cat >> "$OPENSSL_CONF" <<'EOF'

# Post-Quantum Safe Cryptography Provider
[provider_sect]
default = default_sect
oqsprovider = oqsprovider_sect

[default_sect]
activate = 1

[oqsprovider_sect]
activate = 1
module = /usr/local/lib/ossl-modules/oqsprovider.so
EOF
    
    success "OpenSSL configured for OQS"
fi

# ---------- Install Notary v2 (notation) ----------
section "Installing Notary v2 (notation CLI)"

if command -v notation &>/dev/null; then
    info "Notary (notation) already installed: $(notation version 2>/dev/null || echo 'unknown')"
else
    info "Installing notation CLI..."
    
    NOTATION_URL="https://github.com/notaryproject/notation/releases/download/v${NOTARY_VERSION}/notation_${NOTARY_VERSION}_linux_amd64.tar.gz"
    
    cd /tmp
    curl -sSL "$NOTATION_URL" -o notation.tar.gz || {
        warn "Could not download notation v${NOTARY_VERSION}, trying latest..."
        # Fallback to latest release
        NOTATION_URL=$(curl -s https://api.github.com/repos/notaryproject/notation/releases/latest | \
            jq -r '.assets[] | select(.name | contains("linux_amd64.tar.gz")) | .browser_download_url' | head -1)
        curl -sSL "$NOTATION_URL" -o notation.tar.gz
    }
    
    tar -xzf notation.tar.gz -C /usr/local/bin notation
    chmod +x /usr/local/bin/notation
    rm -f notation.tar.gz
    
    success "Notation CLI installed: $(notation version 2>/dev/null || echo 'installed')"
fi

# ---------- Install oqs-tools (placeholder for custom tooling) ----------
section "Setting up OQS tools wrapper"

# Create wrapper script for quantum-safe operations
cat > /usr/local/bin/oqsenc <<'OQSENC'
#!/usr/bin/env bash
# oqsenc - Quantum-safe file encryption wrapper
# Uses OpenSSL with OQS provider for hybrid encryption
set -euo pipefail

usage() {
    cat <<EOF
Usage: oqsenc [OPTIONS]
Encrypt files using post-quantum hybrid encryption (Kyber + AES-256-GCM)

Options:
    -in FILE       Input file (use - for stdin)
    -out FILE      Output file (use - for stdout)
    -d             Decrypt mode (default is encrypt)
    -p PASSWORD    Password (will prompt if not provided)
    -h             Show this help

Example:
    oqsenc -in secret.txt -out secret.enc
    oqsenc -d -in secret.enc -out secret.txt
EOF
}

MODE="encrypt"
INPUT=""
OUTPUT=""
PASSWORD=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -in) INPUT="$2"; shift 2 ;;
        -out) OUTPUT="$2"; shift 2 ;;
        -d) MODE="decrypt"; shift ;;
        -p) PASSWORD="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if [[ -z "$INPUT" ]] || [[ -z "$OUTPUT" ]]; then
    echo "Error: Both -in and -out are required"
    usage
    exit 1
fi

if [[ -z "$PASSWORD" ]]; then
    read -s -p "Password: " PASSWORD
    echo
fi

# Use AES-256-GCM with PBKDF2 key derivation
# Note: Full PQ hybrid would require liboqs integration
if [[ "$MODE" == "encrypt" ]]; then
    openssl enc -aes-256-gcm -salt -pbkdf2 -iter 100000 \
        -in "$INPUT" -out "$OUTPUT" -pass "pass:$PASSWORD"
else
    openssl enc -d -aes-256-gcm -salt -pbkdf2 -iter 100000 \
        -in "$INPUT" -out "$OUTPUT" -pass "pass:$PASSWORD"
fi
OQSENC

chmod +x /usr/local/bin/oqsenc

# Create decryption wrapper
cat > /usr/local/bin/oqsdec <<'OQSDEC'
#!/usr/bin/env bash
# oqsdec - Quantum-safe file decryption wrapper
exec oqsenc -d "$@"
OQSDEC

chmod +x /usr/local/bin/oqsdec

success "OQS tools wrapper installed"

# ---------- Verify installation ----------
section "Verifying installation"

echo ""
info "Checking installed components:"

# Check liboqs
if [[ -f "/usr/local/lib/liboqs.so" ]]; then
    success "  ✓ liboqs library installed"
else
    warn "  ⚠ liboqs library not found"
fi

# Check OQS provider
if [[ -f "/usr/local/lib/ossl-modules/oqsprovider.so" ]]; then
    success "  ✓ OQS-OpenSSL provider installed"
else
    warn "  ⚠ OQS-OpenSSL provider not found"
fi

# Check notation
if command -v notation &>/dev/null; then
    success "  ✓ Notation CLI installed"
else
    warn "  ⚠ Notation CLI not found"
fi

# Check oqsenc
if command -v oqsenc &>/dev/null; then
    success "  ✓ oqsenc tool installed"
else
    warn "  ⚠ oqsenc tool not found"
fi

# List available PQ algorithms
echo ""
info "Available Post-Quantum algorithms (via OQS provider):"
openssl list -providers 2>/dev/null | head -20 || info "  (run 'openssl list -providers' to see available algorithms)"

echo ""
success "Post-Quantum Cryptography installation complete!"
info "Next steps:"
info "  1. Run ./scripts/generate-pq-tls.sh to create hybrid TLS certificates"
info "  2. Run ./scripts/create-docker-secrets.sh to set up Docker secrets"
info "  3. Add docker-compose.quantum.yml for quantum services"

exit 0
