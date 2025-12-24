#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 🔍 home.lab - Security Audit Script
# Automated security scanning and compliance checking
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Configuration
AUDIT_DIR="${AUDIT_DIR:-/var/log/homelab/audits}"
REPORT_DIR="${REPORT_DIR:-/var/log/homelab/reports}"
SEVERITY_THRESHOLD="${SEVERITY_THRESHOLD:-medium}"
NOTIFY_SLACK="${NOTIFY_SLACK:-false}"
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/audit_${TIMESTAMP}.json"

# Initialize
mkdir -p "$AUDIT_DIR" "$REPORT_DIR"

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# ───────────────────────────────────────────────────────────────
# Container Security Audit
# ───────────────────────────────────────────────────────────────
audit_containers() {
    log "Auditing container security..."
    
    local findings=()
    
    # Check for privileged containers
    while IFS= read -r container; do
        findings+=("CRITICAL: Privileged container: $container")
    done < <(docker ps --format '{{.Names}}' | xargs -I {} docker inspect {} --format '{{.Name}}: {{.HostConfig.Privileged}}' 2>/dev/null | grep true | cut -d: -f1)
    
    # Check for containers running as root
    while IFS= read -r container; do
        user=$(docker inspect "$container" --format '{{.Config.User}}' 2>/dev/null)
        if [[ -z "$user" || "$user" == "root" || "$user" == "0" ]]; then
            findings+=("MEDIUM: Container running as root: $container")
        fi
    done < <(docker ps --format '{{.Names}}')
    
    # Check for exposed sensitive ports
    while IFS= read -r port_info; do
        if [[ "$port_info" =~ (3306|5432|6379|27017) ]]; then
            findings+=("HIGH: Database port exposed: $port_info")
        fi
    done < <(docker ps --format '{{.Ports}}' | tr ',' '\n')
    
    # Check for containers with host network
    while IFS= read -r container; do
        findings+=("MEDIUM: Container using host network: $container")
    done < <(docker ps --format '{{.Names}}' | xargs -I {} docker inspect {} --format '{{.Name}}: {{.HostConfig.NetworkMode}}' 2>/dev/null | grep host | cut -d: -f1)
    
    # Output findings
    for finding in "${findings[@]}"; do
        if [[ "$finding" =~ ^CRITICAL ]]; then
            error "$finding"
        elif [[ "$finding" =~ ^HIGH ]]; then
            warn "$finding"
        else
            log "$finding"
        fi
    done
    
    echo "${findings[@]}"
}

# ───────────────────────────────────────────────────────────────
# Image Security Audit
# ───────────────────────────────────────────────────────────────
audit_images() {
    log "Auditing container images..."
    
    local findings=()
    
    # Check for images without tags (using :latest implicitly)
    while IFS= read -r image; do
        if [[ "$image" == *":latest" || ! "$image" =~ : ]]; then
            findings+=("MEDIUM: Image using latest tag: $image")
        fi
    done < <(docker images --format '{{.Repository}}:{{.Tag}}' | grep -v '<none>')
    
    # Check for old images (older than 90 days)
    local cutoff=$(date -d '90 days ago' +%s 2>/dev/null || date -v-90d +%s)
    while IFS= read -r line; do
        image=$(echo "$line" | cut -d'|' -f1)
        created=$(echo "$line" | cut -d'|' -f2)
        created_ts=$(date -d "$created" +%s 2>/dev/null || echo 0)
        if [[ $created_ts -lt $cutoff ]]; then
            findings+=("LOW: Old image (>90 days): $image")
        fi
    done < <(docker images --format '{{.Repository}}:{{.Tag}}|{{.CreatedAt}}' | grep -v '<none>')
    
    # Check for dangling images
    dangling_count=$(docker images -f "dangling=true" -q | wc -l)
    if [[ $dangling_count -gt 0 ]]; then
        findings+=("LOW: $dangling_count dangling images found")
    fi
    
    for finding in "${findings[@]}"; do
        log "$finding"
    done
    
    echo "${findings[@]}"
}

# ───────────────────────────────────────────────────────────────
# Secret Security Audit
# ───────────────────────────────────────────────────────────────
audit_secrets() {
    log "Auditing secrets security..."
    
    local findings=()
    
    # Check for hardcoded secrets in docker-compose files
    if grep -r -E "(password|secret|api_key|token)\s*[:=]\s*['\"]?[^$]" ./docker/ ./configs/ 2>/dev/null | grep -v ".example" | grep -v ".md"; then
        findings+=("CRITICAL: Possible hardcoded secrets in configuration files")
    fi
    
    # Check for .env files with secrets
    if [[ -f ".env" ]]; then
        if grep -E "^(PASSWORD|SECRET|API_KEY|TOKEN)" .env 2>/dev/null; then
            findings+=("HIGH: Secrets in .env file - ensure proper permissions")
        fi
        
        # Check .env permissions
        perms=$(stat -c %a .env 2>/dev/null || stat -f %A .env 2>/dev/null)
        if [[ "$perms" != "600" && "$perms" != "400" ]]; then
            findings+=("MEDIUM: .env file has loose permissions: $perms (should be 600)")
        fi
    fi
    
    # Check for exposed secrets in container environment
    while IFS= read -r container; do
        if docker inspect "$container" --format '{{.Config.Env}}' 2>/dev/null | grep -iE "(password|secret|api_key)" > /dev/null; then
            findings+=("MEDIUM: Container $container has secrets in environment")
        fi
    done < <(docker ps --format '{{.Names}}')
    
    for finding in "${findings[@]}"; do
        if [[ "$finding" =~ ^CRITICAL ]]; then
            error "$finding"
        elif [[ "$finding" =~ ^HIGH ]]; then
            warn "$finding"
        else
            log "$finding"
        fi
    done
    
    echo "${findings[@]}"
}

# ───────────────────────────────────────────────────────────────
# Network Security Audit
# ───────────────────────────────────────────────────────────────
audit_network() {
    log "Auditing network security..."
    
    local findings=()
    
    # Check for containers with all ports exposed
    while IFS= read -r container; do
        ports=$(docker inspect "$container" --format '{{.HostConfig.PortBindings}}' 2>/dev/null)
        if [[ "$ports" == "map[]" || -z "$ports" ]]; then
            continue
        fi
        if [[ "$ports" =~ 0\.0\.0\.0 ]]; then
            findings+=("MEDIUM: Container $container binds to all interfaces")
        fi
    done < <(docker ps --format '{{.Names}}')
    
    # Check for default bridge network usage
    while IFS= read -r container; do
        network=$(docker inspect "$container" --format '{{.HostConfig.NetworkMode}}' 2>/dev/null)
        if [[ "$network" == "default" || "$network" == "bridge" ]]; then
            findings+=("LOW: Container $container using default bridge network")
        fi
    done < <(docker ps --format '{{.Names}}')
    
    for finding in "${findings[@]}"; do
        log "$finding"
    done
    
    echo "${findings[@]}"
}

# ───────────────────────────────────────────────────────────────
# File Permissions Audit
# ───────────────────────────────────────────────────────────────
audit_permissions() {
    log "Auditing file permissions..."
    
    local findings=()
    
    # Check for world-writable files
    while IFS= read -r file; do
        findings+=("HIGH: World-writable file: $file")
    done < <(find . -type f -perm -002 2>/dev/null | head -20)
    
    # Check for files owned by root in configs
    while IFS= read -r file; do
        findings+=("LOW: Config file owned by root: $file")
    done < <(find ./configs -type f -user root 2>/dev/null | head -20)
    
    # Check script permissions
    while IFS= read -r script; do
        if [[ ! -x "$script" ]]; then
            findings+=("LOW: Script not executable: $script")
        fi
    done < <(find ./scripts -name "*.sh" -type f 2>/dev/null)
    
    for finding in "${findings[@]}"; do
        if [[ "$finding" =~ ^HIGH ]]; then
            warn "$finding"
        else
            log "$finding"
        fi
    done
    
    echo "${findings[@]}"
}

# ───────────────────────────────────────────────────────────────
# Generate Report
# ───────────────────────────────────────────────────────────────
generate_report() {
    log "Generating security audit report..."
    
    local all_findings=()
    
    mapfile -t container_findings < <(audit_containers)
    mapfile -t image_findings < <(audit_images)
    mapfile -t secret_findings < <(audit_secrets)
    mapfile -t network_findings < <(audit_network)
    mapfile -t permission_findings < <(audit_permissions)
    
    all_findings+=("${container_findings[@]}")
    all_findings+=("${image_findings[@]}")
    all_findings+=("${secret_findings[@]}")
    all_findings+=("${network_findings[@]}")
    all_findings+=("${permission_findings[@]}")
    
    # Count by severity
    critical=$(printf '%s\n' "${all_findings[@]}" | grep -c "^CRITICAL" || echo 0)
    high=$(printf '%s\n' "${all_findings[@]}" | grep -c "^HIGH" || echo 0)
    medium=$(printf '%s\n' "${all_findings[@]}" | grep -c "^MEDIUM" || echo 0)
    low=$(printf '%s\n' "${all_findings[@]}" | grep -c "^LOW" || echo 0)
    
    # Generate JSON report
    cat > "$REPORT_FILE" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "summary": {
        "critical": $critical,
        "high": $high,
        "medium": $medium,
        "low": $low,
        "total": $((critical + high + medium + low))
    },
    "findings": $(printf '%s\n' "${all_findings[@]}" | jq -R -s 'split("\n") | map(select(length > 0))')
}
EOF
    
    log "Report saved to: $REPORT_FILE"
    
    # Summary
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    SECURITY AUDIT SUMMARY"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    [[ $critical -gt 0 ]] && error "Critical: $critical"
    [[ $high -gt 0 ]] && warn "High: $high"
    [[ $medium -gt 0 ]] && log "Medium: $medium"
    [[ $low -gt 0 ]] && log "Low: $low"
    echo ""
    
    # Exit code based on findings
    if [[ $critical -gt 0 ]]; then
        exit 2
    elif [[ $high -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# ───────────────────────────────────────────────────────────────
# Main
# ───────────────────────────────────────────────────────────────
main() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "              home.lab Security Audit"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    generate_report
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
