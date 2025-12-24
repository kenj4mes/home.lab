#!/usr/bin/env bash
# ==============================================================================
# 🤖 HomeLab Ollama Library - Model Management Functions
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Source this file to access Ollama helper functions:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/ollama.sh"
#
# Provides:
#   - ollama_pull_verify() - Pull model with manifest verification
#   - ollama_list_models() - JSON output of installed models
#   - ollama_ensure_running() - Start Ollama if not running
# ==============================================================================

# Get script directory and source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ==============================================================================
# OLLAMA SERVICE MANAGEMENT
# ==============================================================================

# Check if Ollama is installed
ollama_installed() {
    command_exists ollama
}

# Check if Ollama service is running
ollama_running() {
    pgrep -x "ollama" > /dev/null 2>&1 || \
    curl -s http://localhost:11434/api/tags > /dev/null 2>&1
}

# Start Ollama service
ollama_start() {
    if ollama_running; then
        debug "Ollama already running"
        return 0
    fi
    
    info "Starting Ollama service..."
    
    # Try systemctl first (Linux with systemd)
    if command_exists systemctl && systemctl is-enabled ollama &>/dev/null; then
        sudo systemctl start ollama
        sleep 2
    else
        # Start manually in background
        ollama serve &>/dev/null &
        sleep 3
    fi
    
    # Verify it started
    if ollama_running; then
        success "Ollama service started"
        return 0
    else
        error "Failed to start Ollama service"
        return 1
    fi
}

# Ensure Ollama is installed and running
ollama_ensure_running() {
    if ! ollama_installed; then
        warn "Ollama not installed"
        
        if confirm "Install Ollama now?"; then
            info "Installing Ollama..."
            curl -fsSL https://ollama.com/install.sh | sh
            
            # Configure for network access on Linux
            if [[ -d /etc/systemd/system ]]; then
                sudo mkdir -p /etc/systemd/system/ollama.service.d
                sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << 'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
EOF
                sudo systemctl daemon-reload
            fi
        else
            error "Ollama required but not installed"
            return 1
        fi
    fi
    
    ollama_start
}

# ==============================================================================
# MODEL MANAGEMENT
# ==============================================================================

# Pull a model with verification
ollama_pull_verify() {
    local model="$1"
    
    if [[ -z "$model" ]]; then
        error "Model name required"
        return 1
    fi
    
    info "Pulling model: $model"
    
    # Pull the model
    if ! ollama pull "$model"; then
        error "Failed to pull model: $model"
        return 1
    fi
    
    # Verify with manifest (Ollama >= 0.2.5)
    local manifest
    manifest=$(curl -s "http://localhost:11434/api/show" -d "{\"name\":\"$model\"}" 2>/dev/null)
    
    if [[ -n "$manifest" && "$manifest" != "null" ]]; then
        # Extract size from manifest
        local size_bytes
        size_bytes=$(echo "$manifest" | grep -o '"size":[0-9]*' | head -1 | cut -d: -f2)
        
        if [[ -n "$size_bytes" && "$size_bytes" -gt 0 ]]; then
            local size_human
            size_human=$(numfmt --to=iec-i --suffix=B "$size_bytes" 2>/dev/null || echo "${size_bytes} bytes")
            success "Model $model verified (size: $size_human)"
        else
            success "Model $model pulled successfully"
        fi
    else
        success "Model $model pulled (manifest not available)"
    fi
    
    return 0
}

# List installed models
ollama_list_models() {
    if ! ollama_running; then
        error "Ollama not running"
        return 1
    fi
    
    ollama list
}

# List models in JSON format
ollama_list_models_json() {
    if ! ollama_running; then
        echo "[]"
        return 1
    fi
    
    curl -s http://localhost:11434/api/tags | jq -r '.models // []' 2>/dev/null || echo "[]"
}

# Check if a specific model is installed
ollama_model_exists() {
    local model="$1"
    ollama list 2>/dev/null | grep -q "^$model"
}

# Get model size (approximate, in GB)
ollama_model_size() {
    local model="$1"
    
    local manifest
    manifest=$(curl -s "http://localhost:11434/api/show" -d "{\"name\":\"$model\"}" 2>/dev/null)
    
    if [[ -n "$manifest" ]]; then
        local size_bytes
        size_bytes=$(echo "$manifest" | grep -o '"size":[0-9]*' | head -1 | cut -d: -f2)
        
        if [[ -n "$size_bytes" && "$size_bytes" -gt 0 ]]; then
            echo $((size_bytes / 1073741824))  # Convert to GB
            return 0
        fi
    fi
    
    echo "0"
    return 1
}

# ==============================================================================
# BATCH OPERATIONS
# ==============================================================================

# Pull multiple models
ollama_pull_models() {
    local models=("$@")
    local failed=0
    
    for model in "${models[@]}"; do
        if ! ollama_pull_verify "$model"; then
            ((failed++))
        fi
    done
    
    if [[ $failed -gt 0 ]]; then
        warn "$failed model(s) failed to download"
        return 1
    fi
    
    return 0
}

# Pull models from a group (reads from catalog.json)
ollama_pull_group() {
    local group="$1"
    local catalog="${SCRIPT_DIR}/../models/catalog.json"
    
    if [[ ! -f "$catalog" ]]; then
        error "Model catalog not found: $catalog"
        return 1
    fi
    
    local models
    models=$(jq -r ".\"$group\"[].name // empty" "$catalog" 2>/dev/null)
    
    if [[ -z "$models" ]]; then
        error "Group '$group' not found or empty in catalog"
        return 1
    fi
    
    info "Pulling models from group: $group"
    
    local failed=0
    while IFS= read -r model; do
        if ! ollama_pull_verify "$model"; then
            ((failed++))
        fi
    done <<< "$models"
    
    if [[ $failed -gt 0 ]]; then
        warn "$failed model(s) failed to download"
        return 1
    fi
    
    return 0
}

# ==============================================================================
# STORAGE STATS
# ==============================================================================

# Get total Ollama storage usage
ollama_storage_used() {
    local ollama_dir="${HOME}/.ollama/models"
    
    if [[ -d "$ollama_dir" ]]; then
        du -sh "$ollama_dir" 2>/dev/null | cut -f1
    else
        echo "0"
    fi
}
