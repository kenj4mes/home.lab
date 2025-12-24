#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 🚀 home.lab - Deployment Script
# Zero-downtime deployment with rollback capability
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups/deployments"
DEPLOY_TIMEOUT="${DEPLOY_TIMEOUT:-300}"
HEALTH_CHECK_RETRIES="${HEALTH_CHECK_RETRIES:-30}"
HEALTH_CHECK_INTERVAL="${HEALTH_CHECK_INTERVAL:-10}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# State
DEPLOYMENT_ID=""
ROLLBACK_NEEDED=false

# ───────────────────────────────────────────────────────────────
# Logging
# ───────────────────────────────────────────────────────────────
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ───────────────────────────────────────────────────────────────
# Pre-deployment Checks
# ───────────────────────────────────────────────────────────────
pre_deploy_checks() {
    log "Running pre-deployment checks..."
    
    # Check Docker
    if ! docker info > /dev/null 2>&1; then
        error "Docker is not running"
        exit 1
    fi
    
    # Check disk space (require at least 5GB free)
    available=$(df -BG "$PROJECT_DIR" | tail -1 | awk '{print $4}' | sed 's/G//')
    if [[ $available -lt 5 ]]; then
        error "Insufficient disk space: ${available}GB available, need 5GB"
        exit 1
    fi
    
    # Validate compose files
    for file in $(find "$PROJECT_DIR" -name "docker-compose*.yml" -type f); do
        if ! docker compose -f "$file" config > /dev/null 2>&1; then
            error "Invalid compose file: $file"
            exit 1
        fi
    done
    
    success "Pre-deployment checks passed"
}

# ───────────────────────────────────────────────────────────────
# Create Backup
# ───────────────────────────────────────────────────────────────
create_backup() {
    log "Creating deployment backup..."
    
    DEPLOYMENT_ID=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/${DEPLOYMENT_ID}"
    
    mkdir -p "$backup_path"
    
    # Backup current container states
    docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}' > "${backup_path}/containers.txt"
    
    # Backup current images
    docker images --format '{{.Repository}}:{{.Tag}}' | grep -v '<none>' > "${backup_path}/images.txt"
    
    # Backup configs
    cp -r "${PROJECT_DIR}/configs" "${backup_path}/"
    
    # Backup docker-compose files
    find "$PROJECT_DIR" -name "docker-compose*.yml" -exec cp {} "${backup_path}/" \;
    
    success "Backup created: ${backup_path}"
}

# ───────────────────────────────────────────────────────────────
# Pull Latest Images
# ───────────────────────────────────────────────────────────────
pull_images() {
    log "Pulling latest images..."
    
    cd "$PROJECT_DIR"
    
    # Pull from all compose files
    for file in $(find . -name "docker-compose.yml" -type f); do
        dir=$(dirname "$file")
        log "Pulling images from ${dir}..."
        (cd "$dir" && docker compose pull --quiet) || warn "Failed to pull some images in ${dir}"
    done
    
    success "Images pulled"
}

# ───────────────────────────────────────────────────────────────
# Deploy Services
# ───────────────────────────────────────────────────────────────
deploy_services() {
    log "Deploying services..."
    
    cd "$PROJECT_DIR"
    
    # Deploy in order of priority
    local deploy_order=(
        "miniapps/message-bus"
        "miniapps/event-store"
        "miniapps/ai-orchestrator"
    )
    
    for service_dir in "${deploy_order[@]}"; do
        if [[ -f "${service_dir}/docker-compose.yml" ]]; then
            log "Deploying ${service_dir}..."
            (cd "$service_dir" && docker compose up -d --remove-orphans) || {
                error "Failed to deploy ${service_dir}"
                ROLLBACK_NEEDED=true
                return 1
            }
            
            # Wait for service to be healthy
            if ! wait_for_health "$service_dir"; then
                error "Service ${service_dir} failed health check"
                ROLLBACK_NEEDED=true
                return 1
            fi
        fi
    done
    
    success "All services deployed"
}

# ───────────────────────────────────────────────────────────────
# Health Check
# ───────────────────────────────────────────────────────────────
wait_for_health() {
    local service_dir="$1"
    local service_name=$(basename "$service_dir")
    local retries=0
    
    log "Waiting for ${service_name} to be healthy..."
    
    while [[ $retries -lt $HEALTH_CHECK_RETRIES ]]; do
        # Check container health
        local health=$(docker inspect --format='{{.State.Health.Status}}' "homelab-${service_name}" 2>/dev/null || echo "none")
        
        if [[ "$health" == "healthy" ]]; then
            success "${service_name} is healthy"
            return 0
        elif [[ "$health" == "unhealthy" ]]; then
            error "${service_name} is unhealthy"
            return 1
        fi
        
        retries=$((retries + 1))
        sleep "$HEALTH_CHECK_INTERVAL"
    done
    
    error "${service_name} health check timed out"
    return 1
}

# ───────────────────────────────────────────────────────────────
# Rollback
# ───────────────────────────────────────────────────────────────
rollback() {
    error "Initiating rollback..."
    
    if [[ -z "$DEPLOYMENT_ID" ]]; then
        error "No deployment ID found, cannot rollback"
        exit 1
    fi
    
    local backup_path="${BACKUP_DIR}/${DEPLOYMENT_ID}"
    
    # Stop current containers
    log "Stopping current containers..."
    while IFS=$'\t' read -r name image status; do
        docker stop "$name" 2>/dev/null || true
    done < "${backup_path}/containers.txt"
    
    # Restore previous state
    log "Restoring previous state..."
    while IFS=$'\t' read -r name image status; do
        if [[ "$status" == *"Up"* ]]; then
            docker start "$name" 2>/dev/null || {
                warn "Could not restart $name, may need manual intervention"
            }
        fi
    done < "${backup_path}/containers.txt"
    
    error "Rollback completed - please verify system state manually"
}

# ───────────────────────────────────────────────────────────────
# Cleanup
# ───────────────────────────────────────────────────────────────
cleanup() {
    log "Cleaning up..."
    
    # Remove dangling images
    docker image prune -f
    
    # Remove old backups (keep last 5)
    ls -dt "${BACKUP_DIR}"/*/ 2>/dev/null | tail -n +6 | xargs -r rm -rf
    
    success "Cleanup completed"
}

# ───────────────────────────────────────────────────────────────
# Post-deployment
# ───────────────────────────────────────────────────────────────
post_deploy() {
    log "Running post-deployment tasks..."
    
    # Log deployment to event store
    curl -s -X POST "http://localhost:5101/events" \
        -H "Content-Type: application/json" \
        -d '{
            "category": "system",
            "action": "deployment",
            "actor": "deploy-script",
            "data": {"deployment_id": "'"$DEPLOYMENT_ID"'"},
            "result": "success"
        }' > /dev/null 2>&1 || warn "Could not log deployment event"
    
    success "Post-deployment completed"
}

# ───────────────────────────────────────────────────────────────
# Main
# ───────────────────────────────────────────────────────────────
main() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "              home.lab Deployment"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    trap 'if [[ "$ROLLBACK_NEEDED" == "true" ]]; then rollback; fi' EXIT
    
    pre_deploy_checks
    create_backup
    pull_images
    deploy_services
    cleanup
    post_deploy
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    success "Deployment ${DEPLOYMENT_ID} completed successfully!"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
}

# Run
main "$@"
