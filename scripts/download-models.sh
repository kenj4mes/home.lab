#!/usr/bin/env bash
# ==============================================================================
# 📦 HomeLab Model Downloader - Flexible Ollama Model Management
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Usage:
#   ./download-models.sh [OPTIONS]
#
# Options:
#   --group <name>       Pull all models in a group
#   --model <name>       Pull a single model
#   --list-groups        Show available groups
#   --list-models <grp>  Show models in a group
#   --parallel N         Download up to N models concurrently (default: 1)
#   --profile <name>     Quick profile: minimal, standard, full
#   -h, --help           Show this help
#
# Examples:
#   ./download-models.sh --group foundation
#   ./download-models.sh --model codellama:13b
#   ./download-models.sh --profile standard
# ==============================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/ollama.sh"

# Initialize logging
init_logging "download-models"

# ==============================================================================
# CONFIGURATION
# ==============================================================================

CATALOG="${SCRIPT_DIR}/models/catalog.json"
PARALLEL=1
GROUP=""
SINGLE_MODEL=""
PROFILE=""
LIST_GROUP=""

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# List available groups from catalog
list_groups() {
    if [[ ! -f "$CATALOG" ]]; then
        error "Catalog not found: $CATALOG"
        exit 1
    fi
    
    echo -e "${CYAN}Available model groups:${NC}"
    echo ""
    jq -r 'keys[]' "$CATALOG" | while read -r group; do
        local count
        count=$(jq -r ".\"$group\" | length" "$CATALOG")
        echo -e "  ${GREEN}$group${NC} ($count models)"
    done
    echo ""
}

# List models in a group
list_models() {
    local group="$1"
    
    if [[ ! -f "$CATALOG" ]]; then
        error "Catalog not found: $CATALOG"
        exit 1
    fi
    
    local models
    models=$(jq -r ".\"$group\" // empty" "$CATALOG")
    
    if [[ -z "$models" || "$models" == "null" ]]; then
        error "Group '$group' not found in catalog"
        exit 1
    fi
    
    echo -e "${CYAN}Models in group '$group':${NC}"
    echo ""
    jq -r ".\"$group\"[] | \"  \\(.name) (\\(.size_gb)GB) - \\(.description)\"" "$CATALOG"
    echo ""
}

# Print help
print_help() {
    cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════════════╗
║                     📦 HomeLab Model Downloader                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

Usage:
  ./download-models.sh [OPTIONS]

Options:
  --group <name>       Pull all models in a group
  --model <name>       Pull a single model (any Ollama model)
  --list-groups        Show available groups
  --list-models <grp>  Show models in a specific group
  --parallel N         Download up to N models concurrently (default: 1)
  --profile <name>     Quick profile: minimal, standard, full
  -h, --help           Show this help

Groups (from catalog.json):
  foundation   General-purpose models (phi3, mistral, gemma2)
  code         Coding-focused models (codellama, deepseek-coder)
  reasoning    Models optimized for reasoning (deepseek-r1, qwen2.5)
  multilingual Multi-language support (llama3.2, qwen2.5)
  vision       Image understanding (llava, bakllava)
  compact      Low-RAM models (phi3:mini, tinyllama)

Profiles:
  minimal      phi3 only (~2GB)
  standard     foundation + code groups (~15GB)
  full         All groups except vision (~30GB)

Examples:
  ./download-models.sh --group foundation     # Download all foundation models
  ./download-models.sh --model llama3.2       # Download a specific model
  ./download-models.sh --profile minimal      # Quick minimal setup
  ./download-models.sh --list-groups          # See all available groups
  ./download-models.sh --list-models code     # See models in 'code' group

EOF
}

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --group)
            GROUP="$2"
            shift 2
            ;;
        --model)
            SINGLE_MODEL="$2"
            shift 2
            ;;
        --list-groups)
            list_groups
            exit 0
            ;;
        --list-models)
            LIST_GROUP="$2"
            list_models "$LIST_GROUP"
            exit 0
            ;;
        --parallel)
            PARALLEL="$2"
            shift 2
            ;;
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            print_help
            exit 1
            ;;
    esac
done

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

print_banner
echo -e "${CYAN}  Model Downloader${NC}"
echo ""

# Ensure Ollama is running
if ! ollama_ensure_running; then
    error "Failed to start Ollama"
    exit 1
fi

# Handle single model download
if [[ -n "$SINGLE_MODEL" ]]; then
    info "Downloading single model: $SINGLE_MODEL"
    ollama_pull_verify "$SINGLE_MODEL"
    exit $?
fi

# Handle profile selection
if [[ -n "$PROFILE" ]]; then
    case "$PROFILE" in
        minimal)
            info "Profile: minimal (~2GB)"
            ollama_pull_verify "phi3"
            ;;
        standard)
            info "Profile: standard (~15GB)"
            info "Downloading foundation models..."
            ollama_pull_group "foundation"
            info "Downloading code models..."
            ollama_pull_group "code"
            ;;
        full)
            info "Profile: full (~30GB)"
            for grp in foundation code reasoning multilingual compact; do
                info "Downloading $grp models..."
                ollama_pull_group "$grp"
            done
            ;;
        *)
            error "Unknown profile: $PROFILE"
            error "Valid profiles: minimal, standard, full"
            exit 1
            ;;
    esac
    
    echo ""
    success "Profile '$PROFILE' download complete!"
    echo ""
    info "Installed models:"
    ollama_list_models
    echo ""
    info "Storage used: $(ollama_storage_used)"
    exit 0
fi

# Handle group download
if [[ -n "$GROUP" ]]; then
    info "Downloading models from group: $GROUP"
    
    if [[ $PARALLEL -gt 1 ]]; then
        # Parallel download using xargs
        info "Parallel mode: $PARALLEL concurrent downloads"
        jq -r ".\"$GROUP\"[].name // empty" "$CATALOG" | \
            xargs -n1 -P"$PARALLEL" -I{} bash -c 'source "'"${SCRIPT_DIR}/lib/ollama.sh"'"; ollama_pull_verify "$1"' _ {}
    else
        # Sequential download
        ollama_pull_group "$GROUP"
    fi
    
    echo ""
    success "Group '$GROUP' download complete!"
    echo ""
    info "Installed models:"
    ollama_list_models
    echo ""
    info "Storage used: $(ollama_storage_used)"
    exit 0
fi

# No action specified - show help
warn "No action specified"
print_help
exit 1
