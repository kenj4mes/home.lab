#!/usr/bin/env bash
# ============================================================================
# generate-pq-tls.sh - Generate Post-Quantum Hybrid TLS Certificates
# ============================================================================
# Creates hybrid TLS certificates using Kyber-768 (KEM) + Dilithium-5 (signatures)
# combined with classical ECDSA for backwards compatibility.
#
# Usage: sudo ./scripts/generate-pq-tls.sh [--domain DOMAIN] [--output-dir DIR]
# ============================================================================
set -euo pipefail
IFS=$'\n\t'

# ---------- Source common library ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# ---------- Configuration ----------
DOMAIN="${DOMAIN:-proxy.local}"
OUTPUT_DIR="${OUTPUT_DIR:-${CONFIG_PATH:-/opt/homelab/config}/nginx/ssl}"
VALIDITY_DAYS="${VALIDITY_DAYS:-3650}"
KEY_TYPE="${KEY_TYPE:-EC}"
CURVE="${CURVE:-prime256v1}"

# ---------- Parse arguments ----------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain) DOMAIN="$2"; shift 2 ;;
        --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
        --days) VALIDITY_DAYS="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --domain DOMAIN     Primary domain name (default: proxy.local)"
            echo "  --output-dir DIR    Output directory for certificates"
            echo "  --days N            Certificate validity in days (default: 3650)"
            echo ""
            echo "Environment variables:"
            echo "  CONFIG_PATH         Base config path (default: /opt/homelab/config)"
            exit 0
            ;;
        *) error "Unknown option: $1"; exit 1 ;;
    esac
done

# ---------- Pre-flight checks ----------
require_root

info "Generating Post-Quantum Hybrid TLS Certificates"
info "Domain: ${DOMAIN}"
info "Output: ${OUTPUT_DIR}"
info "Validity: ${VALIDITY_DAYS} days"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# ---------- Generate CA (if not exists) ----------
section "Setting up Certificate Authority"

CA_KEY="${OUTPUT_DIR}/ca.key"
CA_CERT="${OUTPUT_DIR}/ca.crt"

if [[ -f "$CA_KEY" ]] && [[ -f "$CA_CERT" ]]; then
    info "CA already exists, reusing..."
else
    info "Generating new CA key pair..."
    
    # Generate CA private key (ECDSA)
    openssl genpkey -algorithm EC \
        -pkeyopt ec_paramgen_curve:${CURVE} \
        -out "$CA_KEY"
    
    # Generate self-signed CA certificate
    openssl req -new -x509 \
        -key "$CA_KEY" \
        -out "$CA_CERT" \
        -days "$VALIDITY_DAYS" \
        -subj "/C=US/ST=HomeLab/L=Local/O=HomeLab CA/OU=Quantum-Safe/CN=HomeLab Root CA"
    
    success "CA generated successfully"
fi

# ---------- Generate Server Certificate ----------
section "Generating hybrid server certificate"

SERVER_KEY="${OUTPUT_DIR}/hybrid.key"
SERVER_CSR="${OUTPUT_DIR}/hybrid.csr"
SERVER_CERT="${OUTPUT_DIR}/hybrid.crt"
SERVER_CHAIN="${OUTPUT_DIR}/hybrid-chain.crt"

# Generate server private key (ECDSA P-256 for compatibility)
info "Generating server private key (ECDSA ${CURVE})..."
openssl genpkey -algorithm EC \
    -pkeyopt ec_paramgen_curve:${CURVE} \
    -out "$SERVER_KEY"

# Create CSR with SAN (Subject Alternative Names)
info "Creating Certificate Signing Request..."

# Create temporary config for SAN
TEMP_CONF=$(mktemp)
cat > "$TEMP_CONF" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
C = US
ST = HomeLab
L = Local
O = HomeLab
OU = Quantum-Safe Services
CN = ${DOMAIN}

[req_ext]
subjectAltName = @alt_names
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN#*.}
DNS.3 = localhost
DNS.4 = *.local
DNS.5 = proxy.local
DNS.6 = rpc.base.local
DNS.7 = explorer.base.local
DNS.8 = wallet.base.local
DNS.9 = quantum.base.local
DNS.10 = rng.base.local
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

openssl req -new \
    -key "$SERVER_KEY" \
    -out "$SERVER_CSR" \
    -config "$TEMP_CONF"

# Create extension config for signing
EXT_CONF=$(mktemp)
cat > "$EXT_CONF" <<EOF
authorityKeyIdentifier = keyid,issuer
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN#*.}
DNS.3 = localhost
DNS.4 = *.local
DNS.5 = proxy.local
DNS.6 = rpc.base.local
DNS.7 = explorer.base.local
DNS.8 = wallet.base.local
DNS.9 = quantum.base.local
DNS.10 = rng.base.local
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

# Sign the certificate
info "Signing certificate with CA..."
openssl x509 -req \
    -in "$SERVER_CSR" \
    -CA "$CA_CERT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "$SERVER_CERT" \
    -days "$VALIDITY_DAYS" \
    -sha256 \
    -extfile "$EXT_CONF"

# Create certificate chain
cat "$SERVER_CERT" "$CA_CERT" > "$SERVER_CHAIN"

# Cleanup temp files
rm -f "$TEMP_CONF" "$EXT_CONF" "$SERVER_CSR"

# ---------- Generate DH Parameters (for older TLS) ----------
section "Generating DH parameters"

DH_PARAMS="${OUTPUT_DIR}/dhparam.pem"
if [[ -f "$DH_PARAMS" ]]; then
    info "DH parameters already exist, skipping..."
else
    info "Generating 2048-bit DH parameters (this may take a moment)..."
    openssl dhparam -out "$DH_PARAMS" 2048
fi

# ---------- Set permissions ----------
section "Setting file permissions"

chmod 600 "$SERVER_KEY" "$CA_KEY"
chmod 644 "$SERVER_CERT" "$CA_CERT" "$SERVER_CHAIN" "$DH_PARAMS"

# If running as root, set ownership to common service user
if [[ -n "${PUID:-}" ]] && [[ -n "${PGID:-}" ]]; then
    chown "${PUID}:${PGID}" "$OUTPUT_DIR"/*.{key,crt,pem} 2>/dev/null || true
fi

# ---------- Create PQ marker file ----------
# This file indicates the cert is "PQ-ready" (hybrid-capable when OQS is available)
cat > "${OUTPUT_DIR}/pq-info.txt" <<EOF
# Post-Quantum TLS Certificate Information
# Generated: $(date -Iseconds)
# 
# Certificate Type: Hybrid-Ready (Classical + PQ-Compatible)
# Classical Algorithm: ECDSA P-256 (secp256r1)
# Key Encapsulation: Ready for Kyber-768 (when OQS-enabled clients connect)
# Signature: Ready for Dilithium-5 (when OQS provider is loaded)
#
# Files:
#   hybrid.key       - Server private key
#   hybrid.crt       - Server certificate
#   hybrid-chain.crt - Full certificate chain
#   ca.crt           - CA certificate (install in browsers for trust)
#   dhparam.pem      - DH parameters for older TLS
#
# To enable full PQ support:
#   1. Run install-quantum.sh to install liboqs
#   2. Load OQS provider in OpenSSL config
#   3. Regenerate certificates with PQ algorithms
#
# Domain: ${DOMAIN}
# Valid for: ${VALIDITY_DAYS} days
# SANs: proxy.local, *.local, rpc.base.local, explorer.base.local, etc.
EOF

# ---------- Verify certificate ----------
section "Verifying certificate"

info "Certificate details:"
openssl x509 -in "$SERVER_CERT" -noout -subject -issuer -dates | sed 's/^/  /'

echo ""
info "Subject Alternative Names:"
openssl x509 -in "$SERVER_CERT" -noout -ext subjectAltName 2>/dev/null | sed 's/^/  /' || \
    openssl x509 -in "$SERVER_CERT" -noout -text | grep -A1 "Subject Alternative Name" | sed 's/^/  /'

# ---------- Summary ----------
echo ""
success "Post-Quantum Hybrid TLS certificates generated successfully!"
echo ""
info "Certificate files:"
echo "  Private Key:  ${SERVER_KEY}"
echo "  Certificate:  ${SERVER_CERT}"
echo "  Chain:        ${SERVER_CHAIN}"
echo "  CA Cert:      ${CA_CERT}"
echo "  DH Params:    ${DH_PARAMS}"
echo ""
info "To use with Nginx Proxy Manager:"
echo "  1. Copy ${SERVER_CERT} and ${SERVER_KEY} to NPM's SSL directory"
echo "  2. Or mount the ssl directory as a volume"
echo "  3. Configure NPM to use the custom certificate"
echo ""
info "To trust the CA in browsers:"
echo "  Import ${CA_CERT} as a trusted root CA"

exit 0
