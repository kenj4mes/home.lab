#!/usr/bin/env bash
# ==============================================================================
# 📦 HomeLab Common Library - Shared Functions for All Scripts
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Source this file at the top of any Bash script:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
#
# Provides:
#   - Structured logging (info, warn, error, success)
#   - Error trapping with line-level reporting
#   - Idempotency helpers
#   - Download with verification
#   - Color output
# ==============================================================================

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# ==============================================================================
# COLORS
# ==============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m' # No Color

# ==============================================================================
# LOGGING
# ==============================================================================

# Log directory and file
LOG_DIR="${LOG_DIR:-/var/log/homelab}"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/homelab.log}"

# Initialize logging
init_logging() {
    local script_name="${1:-$(basename "$0")}"
    LOG_FILE="${LOG_DIR}/${script_name%.sh}.log"
    
    # Create log directory if it doesn't exist
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || {
            # Fallback to /tmp if we can't create in /var/log
            LOG_DIR="/tmp/homelab-logs"
            LOG_FILE="${LOG_DIR}/${script_name%.sh}.log"
            mkdir -p "$LOG_DIR"
        }
    fi
    
    # Start log file
    echo "" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    echo "Script: $script_name" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
}

# Core logging function
_log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Write to log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Write to stdout with color
    case "$level" in
        INFO)    echo -e "${BLUE}ℹ${NC}  $message" ;;
        SUCCESS) echo -e "${GREEN}✓${NC}  $message" ;;
        WARN)    echo -e "${YELLOW}⚠${NC}  $message" ;;
        ERROR)   echo -e "${RED}✗${NC}  $message" >&2 ;;
        DEBUG)   [[ "${DEBUG:-0}" == "1" ]] && echo -e "${CYAN}➤${NC}  $message" ;;
    esac
}

# Logging shortcuts
info()    { _log "INFO" "$1"; }
success() { _log "SUCCESS" "$1"; }
warn()    { _log "WARN" "$1"; }
error()   { _log "ERROR" "$1"; }
debug()   { _log "DEBUG" "$1"; }

# Phase header for visual separation
phase() {
    local title="$1"
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}  $title${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    _log "INFO" "=== PHASE: $title ==="
}

# ==============================================================================
# ERROR HANDLING
# ==============================================================================

# Trap handler for errors
_error_handler() {
    local exit_code=$?
    local line_no=$1
    local command="${BASH_COMMAND}"
    
    error "Command failed at line $line_no: $command (exit code: $exit_code)"
    
    # Print stack trace
    local i=0
    echo -e "${RED}Stack trace:${NC}" >&2
    while caller $i; do
        ((i++))
    done | while read -r line sub file; do
        echo -e "  ${CYAN}$file:$line${NC} in ${YELLOW}$sub${NC}" >&2
    done
    
    exit "$exit_code"
}

# Enable error trapping
enable_error_trap() {
    trap '_error_handler $LINENO' ERR
}

# ==============================================================================
# IDEMPOTENCY HELPERS
# ==============================================================================

# Check if a command/binary exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Check if a directory exists
dir_exists() {
    [[ -d "$1" ]]
}

# Check if a file exists
file_exists() {
    [[ -f "$1" ]]
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        debug "Created directory: $dir"
    fi
}

# Run a command only if a file doesn't exist
run_if_missing() {
    local flag_file="$1"
    shift
    local cmd=("$@")
    
    if [[ -f "$flag_file" ]]; then
        debug "Skipping (flag exists): $flag_file"
        return 0
    fi
    
    "${cmd[@]}"
    touch "$flag_file"
}

# ==============================================================================
# DOWNLOAD HELPERS
# ==============================================================================

# Download file with resume support
download_file() {
    local url="$1"
    local dest="$2"
    local filename
    filename=$(basename "$url")
    local target="${dest}/${filename}"
    
    if [[ -f "$target" ]]; then
        info "Already exists: $filename"
        return 0
    fi
    
    info "Downloading: $filename"
    debug "URL: $url"
    
    # Try wget first, fallback to curl
    if command_exists wget; then
        wget -c -q --show-progress -O "$target" "$url" || {
            warn "wget failed, trying curl..."
            curl -L -C - -o "$target" "$url"
        }
    elif command_exists curl; then
        curl -L -C - -o "$target" "$url"
    else
        error "Neither wget nor curl available"
        return 1
    fi
    
    success "Downloaded: $filename"
}

# Verify file checksum (SHA256)
verify_checksum() {
    local file="$1"
    local expected="$2"
    
    if [[ ! -f "$file" ]]; then
        error "File not found: $file"
        return 1
    fi
    
    local actual
    actual=$(sha256sum "$file" | cut -d' ' -f1)
    
    if [[ "$actual" == "$expected" ]]; then
        success "Checksum verified: $(basename "$file")"
        return 0
    else
        error "Checksum mismatch for $(basename "$file")"
        error "  Expected: $expected"
        error "  Actual:   $actual"
        return 1
    fi
}

# ==============================================================================
# SYSTEM DETECTION
# ==============================================================================

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

# Detect package manager
detect_package_manager() {
    if command_exists apt-get; then
        echo "apt"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists yum; then
        echo "yum"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists apk; then
        echo "apk"
    else
        echo "unknown"
    fi
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Require root or exit
require_root() {
    if ! is_root; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# ==============================================================================
# VERSION CHECKING
# ==============================================================================

# Get Docker version
get_docker_version() {
    if command_exists docker; then
        docker --version | grep -oP 'version \K[0-9.]+'
    else
        echo ""
    fi
}

# Get Ollama version
get_ollama_version() {
    if command_exists ollama; then
        ollama --version 2>/dev/null | grep -oP 'version is \K[0-9.]+' || echo "installed"
    else
        echo ""
    fi
}

# Compare versions (returns 0 if $1 >= $2)
version_gte() {
    local v1="$1"
    local v2="$2"
    [[ "$(printf '%s\n' "$v1" "$v2" | sort -V | head -n1)" == "$v2" ]]
}

# ==============================================================================
# DISK SPACE
# ==============================================================================

# Get available disk space in GB
get_available_space_gb() {
    local path="${1:-/}"
    df -BG "$path" 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G'
}

# Check if enough space is available
check_disk_space() {
    local required_gb="$1"
    local path="${2:-/}"
    local available
    available=$(get_available_space_gb "$path")
    
    if [[ "$available" -lt "$required_gb" ]]; then
        warn "Low disk space: ${available}GB available, ${required_gb}GB recommended"
        return 1
    else
        info "Disk space OK: ${available}GB available (${required_gb}GB needed)"
        return 0
    fi
}

# ==============================================================================
# USER INTERACTION
# ==============================================================================

# Confirm with user (returns 0 for yes, 1 for no)
confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-n}"
    local response
    
    if [[ "$default" == "y" ]]; then
        read -rp "$prompt (Y/n): " response
        [[ -z "$response" || "$response" =~ ^[Yy] ]]
    else
        read -rp "$prompt (y/N): " response
        [[ "$response" =~ ^[Yy] ]]
    fi
}

# ==============================================================================
# BANNER
# ==============================================================================

# Print HomeLab banner
print_banner() {
    echo -e "${MAGENTA}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║   ██╗  ██╗ ██████╗ ███╗   ███╗███████╗██╗      █████╗ ██████╗                ║
║   ██║  ██║██╔═══██╗████╗ ████║██╔════╝██║     ██╔══██╗██╔══██╗               ║
║   ███████║██║   ██║██╔████╔██║█████╗  ██║     ███████║██████╔╝               ║
║   ██╔══██║██║   ██║██║╚██╔╝██║██╔══╝  ██║     ██╔══██║██╔══██╗               ║
║   ██║  ██║╚██████╔╝██║ ╚═╝ ██║███████╗███████╗██║  ██║██████╔╝               ║
║   ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═════╝                ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ==============================================================================
# AUTO-INIT
# ==============================================================================

# Automatically enable error trap when sourced
enable_error_trap
