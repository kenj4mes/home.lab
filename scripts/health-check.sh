#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 🏥 home.lab - Health Check Script
# Comprehensive system health verification
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
HEALTH_LOG="${HEALTH_LOG:-/var/log/homelab/health.log}"
NOTIFY_ON_FAILURE="${NOTIFY_ON_FAILURE:-true}"

# Exit codes
EXIT_HEALTHY=0
EXIT_DEGRADED=1
EXIT_CRITICAL=2

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# State tracking
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0
CRITICAL_FAILURES=()

# ───────────────────────────────────────────────────────────────
# Logging
# ───────────────────────────────────────────────────────────────
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
    CRITICAL_FAILURES+=("$1")
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++))
    ((TOTAL_CHECKS++))
}

# ───────────────────────────────────────────────────────────────
# Docker Health
# ───────────────────────────────────────────────────────────────
check_docker() {
    log "Checking Docker health..."
    
    # Docker daemon
    if docker info > /dev/null 2>&1; then
        pass "Docker daemon is running"
    else
        fail "Docker daemon is not running"
        return
    fi
    
    # Check each container
    while IFS= read -r container; do
        local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
        local health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container" 2>/dev/null)
        
        if [[ "$status" != "running" ]]; then
            fail "Container $container is $status"
        elif [[ "$health" == "unhealthy" ]]; then
            fail "Container $container is unhealthy"
        elif [[ "$health" == "healthy" || "$health" == "none" ]]; then
            pass "Container $container is healthy"
        else
            warn "Container $container health: $health"
        fi
    done < <(docker ps -a --format '{{.Names}}' | grep -E '^homelab-')
}

# ───────────────────────────────────────────────────────────────
# Service Endpoints
# ───────────────────────────────────────────────────────────────
check_endpoints() {
    log "Checking service endpoints..."
    
    local endpoints=(
        "http://localhost:5100/health:Message Bus"
        "http://localhost:5101/health:Event Store"
        "http://localhost:5200/health:AI Orchestrator"
    )
    
    for endpoint_info in "${endpoints[@]}"; do
        local url="${endpoint_info%%:*}"
        local name="${endpoint_info#*:}"
        
        local response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null || echo "000")
        
        if [[ "$response" == "200" ]]; then
            pass "$name endpoint responding"
        elif [[ "$response" == "000" ]]; then
            fail "$name endpoint unreachable"
        else
            warn "$name endpoint returned $response"
        fi
    done
}

# ───────────────────────────────────────────────────────────────
# Resource Usage
# ───────────────────────────────────────────────────────────────
check_resources() {
    log "Checking resource usage..."
    
    # CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1 2>/dev/null || echo 0)
    if [[ $cpu_usage -lt 80 ]]; then
        pass "CPU usage: ${cpu_usage}%"
    elif [[ $cpu_usage -lt 95 ]]; then
        warn "CPU usage high: ${cpu_usage}%"
    else
        fail "CPU usage critical: ${cpu_usage}%"
    fi
    
    # Memory
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}' 2>/dev/null || echo 0)
    if [[ $mem_usage -lt 80 ]]; then
        pass "Memory usage: ${mem_usage}%"
    elif [[ $mem_usage -lt 95 ]]; then
        warn "Memory usage high: ${mem_usage}%"
    else
        fail "Memory usage critical: ${mem_usage}%"
    fi
    
    # Disk
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%' 2>/dev/null || echo 0)
    if [[ $disk_usage -lt 80 ]]; then
        pass "Disk usage: ${disk_usage}%"
    elif [[ $disk_usage -lt 95 ]]; then
        warn "Disk usage high: ${disk_usage}%"
    else
        fail "Disk usage critical: ${disk_usage}%"
    fi
}

# ───────────────────────────────────────────────────────────────
# Database Connectivity
# ───────────────────────────────────────────────────────────────
check_databases() {
    log "Checking database connectivity..."
    
    # Redis
    if docker exec homelab-redis redis-cli ping 2>/dev/null | grep -q PONG; then
        pass "Redis is responding"
    else
        warn "Redis is not responding"
    fi
    
    # PostgreSQL (if running)
    if docker ps --format '{{.Names}}' | grep -q 'postgres'; then
        if docker exec homelab-postgres pg_isready -U postgres 2>/dev/null; then
            pass "PostgreSQL is responding"
        else
            warn "PostgreSQL is not responding"
        fi
    fi
}

# ───────────────────────────────────────────────────────────────
# AI Services
# ───────────────────────────────────────────────────────────────
check_ai_services() {
    log "Checking AI services..."
    
    # Ollama
    local ollama_status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://localhost:11434/api/tags" 2>/dev/null || echo "000")
    if [[ "$ollama_status" == "200" ]]; then
        pass "Ollama is responding"
        
        # Check loaded models
        local model_count=$(curl -s "http://localhost:11434/api/tags" 2>/dev/null | grep -o '"name"' | wc -l || echo 0)
        if [[ $model_count -gt 0 ]]; then
            pass "$model_count models available"
        else
            warn "No models loaded in Ollama"
        fi
    else
        warn "Ollama is not responding"
    fi
}

# ───────────────────────────────────────────────────────────────
# Network
# ───────────────────────────────────────────────────────────────
check_network() {
    log "Checking network..."
    
    # DNS
    if nslookup google.com > /dev/null 2>&1; then
        pass "DNS resolution working"
    else
        warn "DNS resolution failing"
    fi
    
    # Docker network
    if docker network inspect homelab > /dev/null 2>&1; then
        pass "Docker network 'homelab' exists"
    else
        warn "Docker network 'homelab' not found"
    fi
}

# ───────────────────────────────────────────────────────────────
# Certificates
# ───────────────────────────────────────────────────────────────
check_certificates() {
    log "Checking certificates..."
    
    # Check expiry of local certificates
    local cert_dirs=("/etc/ssl/certs" "/opt/homelab/certs")
    
    for cert_dir in "${cert_dirs[@]}"; do
        if [[ -d "$cert_dir" ]]; then
            while IFS= read -r cert; do
                local expiry=$(openssl x509 -enddate -noout -in "$cert" 2>/dev/null | cut -d= -f2)
                local expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
                local now_epoch=$(date +%s)
                local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
                
                if [[ $days_left -lt 7 ]]; then
                    fail "Certificate expires in $days_left days: $cert"
                elif [[ $days_left -lt 30 ]]; then
                    warn "Certificate expires in $days_left days: $cert"
                fi
            done < <(find "$cert_dir" -name "*.pem" -o -name "*.crt" 2>/dev/null | head -10)
        fi
    done
    
    pass "Certificate check complete"
}

# ───────────────────────────────────────────────────────────────
# Summary
# ───────────────────────────────────────────────────────────────
print_summary() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    HEALTH CHECK SUMMARY"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo -e "Total Checks: $TOTAL_CHECKS"
    echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
    echo ""
    
    if [[ $FAILED_CHECKS -gt 0 ]]; then
        echo -e "${RED}Critical Failures:${NC}"
        for failure in "${CRITICAL_FAILURES[@]}"; do
            echo "  - $failure"
        done
        echo ""
    fi
    
    # Determine overall status
    if [[ $FAILED_CHECKS -gt 0 ]]; then
        echo -e "Overall Status: ${RED}CRITICAL${NC}"
        return $EXIT_CRITICAL
    elif [[ $WARNINGS -gt 0 ]]; then
        echo -e "Overall Status: ${YELLOW}DEGRADED${NC}"
        return $EXIT_DEGRADED
    else
        echo -e "Overall Status: ${GREEN}HEALTHY${NC}"
        return $EXIT_HEALTHY
    fi
}

# ───────────────────────────────────────────────────────────────
# Notify
# ───────────────────────────────────────────────────────────────
notify_failure() {
    if [[ "$NOTIFY_ON_FAILURE" != "true" || $FAILED_CHECKS -eq 0 ]]; then
        return
    fi
    
    local message="🚨 Health Check Failed\n\nFailed: $FAILED_CHECKS\nWarnings: $WARNINGS\n\nFailures:\n"
    for failure in "${CRITICAL_FAILURES[@]}"; do
        message+="• $failure\n"
    done
    
    # Log to event store
    curl -s -X POST "http://localhost:5101/events" \
        -H "Content-Type: application/json" \
        -d '{
            "category": "system",
            "action": "health_check_failed",
            "actor": "health-check",
            "data": {
                "failed": '"$FAILED_CHECKS"',
                "warnings": '"$WARNINGS"',
                "passed": '"$PASSED_CHECKS"'
            },
            "result": "failure"
        }' > /dev/null 2>&1 || true
}

# ───────────────────────────────────────────────────────────────
# Main
# ───────────────────────────────────────────────────────────────
main() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "              home.lab Health Check"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    check_docker
    check_endpoints
    check_resources
    check_databases
    check_ai_services
    check_network
    check_certificates
    
    notify_failure
    print_summary
}

# Run
main "$@"
