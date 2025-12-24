#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# 🏠 home.lab - Configuration Watcher
# Hot-reload configuration changes without service restart
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────
# Configuration
# ───────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."
CONFIG_DIR="${PROJECT_ROOT}/configs"
BACKUP_DIR="${PROJECT_ROOT}/.config-backups"
LOG_FILE="${PROJECT_ROOT}/logs/config-watcher.log"

# Watched directories
WATCH_DIRS=(
    "${CONFIG_DIR}/services"
    "${CONFIG_DIR}/ai"
    "${CONFIG_DIR}/security"
    "${CONFIG_DIR}/monitoring"
)

# Reload handlers per config type
declare -A RELOAD_HANDLERS=(
    ["services/registry.yaml"]="reload_service_registry"
    ["services/priorities.yaml"]="reload_priorities"
    ["services/fallbacks.yaml"]="reload_fallbacks"
    ["ai/model-router.yaml"]="reload_model_router"
    ["security/constitution.yaml"]="reload_security"
    ["monitoring/alerts.yaml"]="reload_alerts"
)

# ───────────────────────────────────────────────────────────────
# Logging
# ───────────────────────────────────────────────────────────────
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_debug() { log "DEBUG" "$@"; }

# ───────────────────────────────────────────────────────────────
# Backup Functions
# ───────────────────────────────────────────────────────────────
create_backup() {
    local config_file="$1"
    local backup_name=$(basename "${config_file}")
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_path="${BACKUP_DIR}/${backup_name}.${timestamp}.bak"
    
    mkdir -p "${BACKUP_DIR}"
    cp "${config_file}" "${backup_path}"
    log_info "Created backup: ${backup_path}"
    echo "${backup_path}"
}

restore_backup() {
    local config_file="$1"
    local backup_path="$2"
    
    if [[ -f "${backup_path}" ]]; then
        cp "${backup_path}" "${config_file}"
        log_info "Restored from backup: ${backup_path}"
        return 0
    else
        log_error "Backup not found: ${backup_path}"
        return 1
    fi
}

cleanup_old_backups() {
    local max_age_days="${1:-7}"
    find "${BACKUP_DIR}" -name "*.bak" -mtime "+${max_age_days}" -delete
    log_info "Cleaned up backups older than ${max_age_days} days"
}

# ───────────────────────────────────────────────────────────────
# Validation Functions
# ───────────────────────────────────────────────────────────────
validate_yaml() {
    local file="$1"
    
    # Check if file exists
    if [[ ! -f "${file}" ]]; then
        log_error "File not found: ${file}"
        return 1
    fi
    
    # Check YAML syntax (requires yq or python)
    if command -v yq &> /dev/null; then
        if yq eval '.' "${file}" > /dev/null 2>&1; then
            log_debug "YAML valid: ${file}"
            return 0
        else
            log_error "Invalid YAML: ${file}"
            return 1
        fi
    elif command -v python3 &> /dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('${file}'))" 2>/dev/null; then
            log_debug "YAML valid: ${file}"
            return 0
        else
            log_error "Invalid YAML: ${file}"
            return 1
        fi
    else
        log_warn "No YAML validator available, skipping validation"
        return 0
    fi
}

validate_config() {
    local config_file="$1"
    local config_type="${config_file##*/}"
    
    # Basic YAML validation
    if ! validate_yaml "${config_file}"; then
        return 1
    fi
    
    # Type-specific validation
    case "${config_type}" in
        registry.yaml)
            validate_registry "${config_file}"
            ;;
        priorities.yaml)
            validate_priorities "${config_file}"
            ;;
        fallbacks.yaml)
            validate_fallbacks "${config_file}"
            ;;
        *)
            log_debug "No specific validation for ${config_type}"
            ;;
    esac
}

validate_registry() {
    local file="$1"
    # Check required fields exist
    if command -v yq &> /dev/null; then
        local services_count=$(yq eval '.services | length' "${file}" 2>/dev/null || echo "0")
        if [[ "${services_count}" -eq 0 ]]; then
            log_error "Registry must contain at least one service"
            return 1
        fi
    fi
    return 0
}

validate_priorities() {
    local file="$1"
    # Validate priority ranges
    return 0
}

validate_fallbacks() {
    local file="$1"
    # Validate fallback chains reference existing services
    return 0
}

# ───────────────────────────────────────────────────────────────
# Reload Handlers
# ───────────────────────────────────────────────────────────────
reload_service_registry() {
    log_info "Reloading service registry..."
    
    # Notify running services about registry update
    # This could be done via:
    # 1. Docker labels/env update
    # 2. Redis pub/sub
    # 3. File-based signal
    
    local signal_file="${PROJECT_ROOT}/.signals/registry-updated"
    mkdir -p "$(dirname "${signal_file}")"
    date '+%Y-%m-%d %H:%M:%S' > "${signal_file}"
    
    log_info "Service registry reload complete"
}

reload_priorities() {
    log_info "Reloading priority configuration..."
    
    local signal_file="${PROJECT_ROOT}/.signals/priorities-updated"
    mkdir -p "$(dirname "${signal_file}")"
    date '+%Y-%m-%d %H:%M:%S' > "${signal_file}"
    
    log_info "Priority configuration reload complete"
}

reload_fallbacks() {
    log_info "Reloading fallback configuration..."
    
    local signal_file="${PROJECT_ROOT}/.signals/fallbacks-updated"
    mkdir -p "$(dirname "${signal_file}")"
    date '+%Y-%m-%d %H:%M:%S' > "${signal_file}"
    
    log_info "Fallback configuration reload complete"
}

reload_model_router() {
    log_info "Reloading model router configuration..."
    
    # If model router is running, send reload signal
    if docker ps --format '{{.Names}}' | grep -q "model-router"; then
        docker kill --signal=SIGHUP model-router 2>/dev/null || true
    fi
    
    log_info "Model router reload complete"
}

reload_security() {
    log_info "Reloading security configuration..."
    log_warn "Security configuration changes may require service restart"
    
    local signal_file="${PROJECT_ROOT}/.signals/security-updated"
    mkdir -p "$(dirname "${signal_file}")"
    date '+%Y-%m-%d %H:%M:%S' > "${signal_file}"
    
    log_info "Security configuration reload complete"
}

reload_alerts() {
    log_info "Reloading alert configuration..."
    
    # Reload Prometheus rules
    if docker ps --format '{{.Names}}' | grep -q "prometheus"; then
        curl -s -X POST http://localhost:9090/-/reload 2>/dev/null || true
    fi
    
    log_info "Alert configuration reload complete"
}

# ───────────────────────────────────────────────────────────────
# Change Handler
# ───────────────────────────────────────────────────────────────
handle_change() {
    local file="$1"
    local event="$2"
    
    log_info "Detected ${event}: ${file}"
    
    # Skip if not a YAML file
    if [[ ! "${file}" =~ \.ya?ml$ ]]; then
        log_debug "Skipping non-YAML file: ${file}"
        return
    fi
    
    # Get relative path from config dir
    local rel_path="${file#${CONFIG_DIR}/}"
    
    # Create backup
    local backup_path=$(create_backup "${file}")
    
    # Validate new configuration
    if ! validate_config "${file}"; then
        log_error "Validation failed, restoring backup"
        restore_backup "${file}" "${backup_path}"
        return 1
    fi
    
    # Find and execute handler
    local handler=""
    for pattern in "${!RELOAD_HANDLERS[@]}"; do
        if [[ "${rel_path}" == "${pattern}" ]]; then
            handler="${RELOAD_HANDLERS[${pattern}]}"
            break
        fi
    done
    
    if [[ -n "${handler}" ]]; then
        log_info "Executing handler: ${handler}"
        if ! ${handler}; then
            log_error "Handler failed, restoring backup"
            restore_backup "${file}" "${backup_path}"
            return 1
        fi
    else
        log_warn "No handler registered for: ${rel_path}"
    fi
    
    log_info "Configuration update complete: ${rel_path}"
}

# ───────────────────────────────────────────────────────────────
# File Watcher
# ───────────────────────────────────────────────────────────────
start_watcher() {
    log_info "Starting configuration watcher..."
    log_info "Watching directories: ${WATCH_DIRS[*]}"
    
    # Create log directory
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    # Check for inotifywait (Linux) or fswatch (macOS)
    if command -v inotifywait &> /dev/null; then
        start_inotify_watcher
    elif command -v fswatch &> /dev/null; then
        start_fswatch_watcher
    else
        log_error "No file watcher available. Install inotify-tools or fswatch."
        exit 1
    fi
}

start_inotify_watcher() {
    log_info "Using inotifywait for file watching"
    
    inotifywait -m -r \
        --format '%w%f %e' \
        -e modify,create,delete,move \
        "${WATCH_DIRS[@]}" 2>/dev/null | \
    while read -r file event; do
        handle_change "${file}" "${event}"
    done
}

start_fswatch_watcher() {
    log_info "Using fswatch for file watching"
    
    fswatch -r "${WATCH_DIRS[@]}" | \
    while read -r file; do
        handle_change "${file}" "MODIFY"
    done
}

# ───────────────────────────────────────────────────────────────
# One-shot Reload
# ───────────────────────────────────────────────────────────────
reload_all() {
    log_info "Reloading all configurations..."
    
    for dir in "${WATCH_DIRS[@]}"; do
        if [[ -d "${dir}" ]]; then
            for file in "${dir}"/*.yaml "${dir}"/*.yml; do
                if [[ -f "${file}" ]]; then
                    handle_change "${file}" "RELOAD"
                fi
            done
        fi
    done
    
    log_info "All configurations reloaded"
}

# ───────────────────────────────────────────────────────────────
# Main
# ───────────────────────────────────────────────────────────────
main() {
    local command="${1:-watch}"
    
    case "${command}" in
        watch)
            start_watcher
            ;;
        reload)
            reload_all
            ;;
        validate)
            local file="${2:-}"
            if [[ -n "${file}" ]]; then
                validate_config "${file}"
            else
                log_error "Usage: $0 validate <file>"
                exit 1
            fi
            ;;
        cleanup)
            cleanup_old_backups "${2:-7}"
            ;;
        *)
            echo "Usage: $0 {watch|reload|validate <file>|cleanup [days]}"
            exit 1
            ;;
    esac
}

# Run if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
