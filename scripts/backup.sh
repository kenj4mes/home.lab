#!/usr/bin/env bash
# ============================================================================
# backup.sh - HomeLab Backup Script with Quantum-Safe Encryption
# ============================================================================
# Creates encrypted backups of all HomeLab data including:
# - ZFS snapshots (configs and storage pools)
# - Docker volumes
# - Database dumps
# - Configuration files
#
# Supports quantum-safe encryption via oqsenc (AES-256-GCM with PBKDF2)
#
# Usage: sudo ./scripts/backup.sh [OPTIONS]
#
# Options:
#   --full          Full backup (all data)
#   --config        Config-only backup
#   --encrypt       Enable encryption (default: off)
#   --pq            Use post-quantum encryption (requires oqsenc)
#   --destination   Backup destination directory
#   --retention     Days to keep backups (default: 30)
#
# ============================================================================
set -euo pipefail
IFS=$'\n\t'

# ---------- Source common library ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    # shellcheck source=lib/common.sh
    source "$SCRIPT_DIR/lib/common.sh"
else
    # Minimal fallback
    info() { echo "[INFO] $1"; }
    warn() { echo "[WARN] $1"; }
    error() { echo "[ERROR] $1"; }
    success() { echo "[OK] $1"; }
    section() { echo ""; echo "=== $1 ==="; }
fi

# ---------- Configuration ----------
BACKUP_TYPE="${BACKUP_TYPE:-full}"
ENCRYPT="${ENCRYPT:-false}"
PQ_ENCRYPT="${PQ_ENCRYPT:-false}"
BACKUP_DEST="${BACKUP_DEST:-/opt/homelab/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
DATE=$(date +%Y-%m-%d_%H%M%S)
BACKUP_DIR="${BACKUP_DEST}/${DATE}"

# Paths
CONFIG_PATH="${CONFIG_PATH:-/opt/homelab/config}"
DOCKER_PATH="${DOCKER_PATH:-/opt/homelab/docker}"

# ZFS pools (if available)
CONFIG_POOL="${CONFIG_POOL:-config-pool}"
STORAGE_POOL="${STORAGE_POOL:-storage-pool}"

# Encryption password (from env or prompt)
BACKUP_PASSWORD="${BACKUP_PASSWORD:-}"

# ---------- Parse arguments ----------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --full) BACKUP_TYPE="full"; shift ;;
        --config) BACKUP_TYPE="config"; shift ;;
        --encrypt) ENCRYPT="true"; shift ;;
        --pq|--quantum) PQ_ENCRYPT="true"; ENCRYPT="true"; shift ;;
        --destination) BACKUP_DEST="$2"; BACKUP_DIR="${BACKUP_DEST}/${DATE}"; shift 2 ;;
        --retention) RETENTION_DAYS="$2"; shift 2 ;;
        --password) BACKUP_PASSWORD="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --full          Full backup (default)"
            echo "  --config        Config-only backup"
            echo "  --encrypt       Enable AES-256 encryption"
            echo "  --pq, --quantum Use post-quantum encryption (oqsenc)"
            echo "  --destination   Backup directory (default: /opt/homelab/backups)"
            echo "  --retention N   Keep backups for N days (default: 30)"
            echo "  --password PWD  Encryption password (or set BACKUP_PASSWORD env)"
            exit 0
            ;;
        *) error "Unknown option: $1"; exit 1 ;;
    esac
done

# ---------- Pre-flight checks ----------
info "HomeLab Backup Script"
info "Date: ${DATE}"
info "Type: ${BACKUP_TYPE}"
info "Destination: ${BACKUP_DEST}"
info "Encryption: ${ENCRYPT} (PQ: ${PQ_ENCRYPT})"

# Create backup directory
mkdir -p "$BACKUP_DIR"/{configs,databases,volumes,snapshots}

# Check for encryption requirements
if [[ "$ENCRYPT" == "true" ]]; then
    if [[ -z "$BACKUP_PASSWORD" ]]; then
        read -s -p "Enter backup encryption password: " BACKUP_PASSWORD
        echo ""
        if [[ -z "$BACKUP_PASSWORD" ]]; then
            error "Password required for encryption"
            exit 1
        fi
    fi
    
    if [[ "$PQ_ENCRYPT" == "true" ]]; then
        if ! command -v oqsenc &>/dev/null; then
            warn "oqsenc not found, falling back to standard encryption"
            warn "Run install-quantum.sh to enable post-quantum encryption"
            PQ_ENCRYPT="false"
        fi
    fi
fi

# ---------- Encryption helper ----------
encrypt_file() {
    local input="$1"
    local output="${input}.enc"
    
    if [[ "$ENCRYPT" != "true" ]]; then
        return 0
    fi
    
    if [[ "$PQ_ENCRYPT" == "true" ]]; then
        # Post-quantum encryption with oqsenc
        oqsenc -in "$input" -out "$output" -p "$BACKUP_PASSWORD" && rm -f "$input"
        info "  Encrypted with post-quantum algorithm: ${output}"
    else
        # Standard AES-256-GCM encryption
        openssl enc -aes-256-gcm -salt -pbkdf2 -iter 100000 \
            -in "$input" -out "$output" -pass "pass:${BACKUP_PASSWORD}" && rm -f "$input"
        info "  Encrypted with AES-256-GCM: ${output}"
    fi
}

# ---------- ZFS Snapshots ----------
backup_zfs() {
    section "ZFS Snapshots"
    
    if ! command -v zfs &>/dev/null; then
        warn "ZFS not available, skipping ZFS snapshots"
        return 0
    fi
    
    # Create recursive snapshots
    for pool in "$CONFIG_POOL" "$STORAGE_POOL"; do
        if zfs list "$pool" &>/dev/null; then
            SNAPSHOT_NAME="${pool}@backup-${DATE}"
            info "Creating snapshot: ${SNAPSHOT_NAME}"
            
            zfs snapshot -r "$SNAPSHOT_NAME" && \
                success "Snapshot created: ${SNAPSHOT_NAME}" || \
                warn "Failed to create snapshot: ${SNAPSHOT_NAME}"
            
            # Export snapshot to file (for config pool only, storage is too large)
            if [[ "$pool" == "$CONFIG_POOL" ]]; then
                SNAPSHOT_FILE="${BACKUP_DIR}/snapshots/${pool}-${DATE}.zfs"
                info "Exporting snapshot to: ${SNAPSHOT_FILE}"
                zfs send -R "$SNAPSHOT_NAME" > "$SNAPSHOT_FILE" 2>/dev/null || \
                    warn "Failed to export snapshot"
                
                if [[ -f "$SNAPSHOT_FILE" ]]; then
                    encrypt_file "$SNAPSHOT_FILE"
                fi
            fi
        else
            info "Pool not found: ${pool}"
        fi
    done
}

# ---------- Docker Volumes ----------
backup_volumes() {
    section "Docker Volumes"
    
    if ! command -v docker &>/dev/null; then
        warn "Docker not available, skipping volume backup"
        return 0
    fi
    
    # Get list of volumes
    local volumes
    volumes=$(docker volume ls -q 2>/dev/null || true)
    
    if [[ -z "$volumes" ]]; then
        info "No Docker volumes found"
        return 0
    fi
    
    for vol in $volumes; do
        info "Backing up volume: ${vol}"
        
        VOLUME_FILE="${BACKUP_DIR}/volumes/${vol}-${DATE}.tar.gz"
        
        # Use Alpine container to create tarball of volume
        docker run --rm \
            -v "${vol}:/source:ro" \
            -v "${BACKUP_DIR}/volumes:/backup" \
            alpine:latest \
            tar -czf "/backup/${vol}-${DATE}.tar.gz" -C /source . 2>/dev/null && \
            success "Volume backed up: ${vol}" || \
            warn "Failed to backup volume: ${vol}"
        
        if [[ -f "$VOLUME_FILE" ]]; then
            encrypt_file "$VOLUME_FILE"
        fi
    done
}

# ---------- Database Dumps ----------
backup_databases() {
    section "Database Dumps"
    
    if ! command -v docker &>/dev/null; then
        warn "Docker not available, skipping database backup"
        return 0
    fi
    
    # BookStack MySQL
    if docker ps --format '{{.Names}}' | grep -q "bookstack-db"; then
        info "Dumping BookStack database..."
        DUMP_FILE="${BACKUP_DIR}/databases/bookstack-${DATE}.sql"
        
        docker exec bookstack-db mysqldump -u root \
            --password="${BOOKSTACK_DB_ROOT_PASSWORD:-changeme}" \
            --all-databases > "$DUMP_FILE" 2>/dev/null && \
            success "BookStack database dumped" || \
            warn "Failed to dump BookStack database"
        
        if [[ -f "$DUMP_FILE" ]]; then
            gzip "$DUMP_FILE"
            encrypt_file "${DUMP_FILE}.gz"
        fi
    fi
    
    # Base PostgreSQL (Blockscout)
    if docker ps --format '{{.Names}}' | grep -q "base-db"; then
        info "Dumping Base database..."
        DUMP_FILE="${BACKUP_DIR}/databases/base-${DATE}.sql"
        
        docker exec base-db pg_dumpall -U blockscout > "$DUMP_FILE" 2>/dev/null && \
            success "Base database dumped" || \
            warn "Failed to dump Base database"
        
        if [[ -f "$DUMP_FILE" ]]; then
            gzip "$DUMP_FILE"
            encrypt_file "${DUMP_FILE}.gz"
        fi
    fi
}

# ---------- Configuration Files ----------
backup_configs() {
    section "Configuration Files"
    
    if [[ ! -d "$CONFIG_PATH" ]]; then
        warn "Config path not found: ${CONFIG_PATH}"
        return 0
    fi
    
    CONFIG_FILE="${BACKUP_DIR}/configs/homelab-config-${DATE}.tar.gz"
    
    info "Archiving configuration directory..."
    tar -czf "$CONFIG_FILE" \
        --exclude='*.log' \
        --exclude='*.tmp' \
        --exclude='cache/*' \
        -C "$(dirname "$CONFIG_PATH")" \
        "$(basename "$CONFIG_PATH")" 2>/dev/null && \
        success "Configuration archived" || \
        warn "Failed to archive configuration"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        encrypt_file "$CONFIG_FILE"
    fi
    
    # Backup docker-compose files separately
    if [[ -d "$DOCKER_PATH" ]]; then
        COMPOSE_FILE="${BACKUP_DIR}/configs/docker-compose-${DATE}.tar.gz"
        tar -czf "$COMPOSE_FILE" \
            -C "$(dirname "$DOCKER_PATH")" \
            "$(basename "$DOCKER_PATH")" 2>/dev/null && \
            success "Docker compose files archived" || \
            warn "Failed to archive compose files"
        
        if [[ -f "$COMPOSE_FILE" ]]; then
            encrypt_file "$COMPOSE_FILE"
        fi
    fi
}

# ---------- Cleanup old backups ----------
cleanup_old_backups() {
    section "Cleanup"
    
    info "Removing backups older than ${RETENTION_DAYS} days..."
    
    local count
    count=$(find "$BACKUP_DEST" -maxdepth 1 -type d -mtime +"$RETENTION_DAYS" 2>/dev/null | wc -l)
    
    if [[ "$count" -gt 0 ]]; then
        find "$BACKUP_DEST" -maxdepth 1 -type d -mtime +"$RETENTION_DAYS" -exec rm -rf {} \; 2>/dev/null
        success "Removed ${count} old backup(s)"
    else
        info "No old backups to remove"
    fi
}

# ---------- Create backup manifest ----------
create_manifest() {
    section "Manifest"
    
    MANIFEST="${BACKUP_DIR}/manifest.json"
    
    cat > "$MANIFEST" <<EOF
{
    "backup_id": "${DATE}",
    "timestamp": "$(date -Iseconds)",
    "type": "${BACKUP_TYPE}",
    "encrypted": ${ENCRYPT},
    "pq_encrypted": ${PQ_ENCRYPT},
    "hostname": "$(hostname)",
    "contents": {
        "configs": $(find "${BACKUP_DIR}/configs" -type f 2>/dev/null | wc -l),
        "databases": $(find "${BACKUP_DIR}/databases" -type f 2>/dev/null | wc -l),
        "volumes": $(find "${BACKUP_DIR}/volumes" -type f 2>/dev/null | wc -l),
        "snapshots": $(find "${BACKUP_DIR}/snapshots" -type f 2>/dev/null | wc -l)
    },
    "size_bytes": $(du -sb "$BACKUP_DIR" 2>/dev/null | cut -f1),
    "retention_days": ${RETENTION_DAYS}
}
EOF
    
    info "Manifest created: ${MANIFEST}"
}

# ---------- Main ----------
main() {
    info "Starting backup..."
    
    case "$BACKUP_TYPE" in
        full)
            backup_zfs
            backup_volumes
            backup_databases
            backup_configs
            ;;
        config)
            backup_configs
            ;;
        *)
            error "Unknown backup type: ${BACKUP_TYPE}"
            exit 1
            ;;
    esac
    
    create_manifest
    cleanup_old_backups
    
    # Calculate total size
    TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    
    echo ""
    success "Backup completed successfully!"
    echo ""
    info "Backup location: ${BACKUP_DIR}"
    info "Total size: ${TOTAL_SIZE}"
    info "Encryption: ${ENCRYPT} (PQ: ${PQ_ENCRYPT})"
    
    if [[ "$ENCRYPT" == "true" ]]; then
        echo ""
        warn "IMPORTANT: Store your encryption password securely!"
        warn "Without it, you cannot restore encrypted backups."
    fi
}

main "$@"
