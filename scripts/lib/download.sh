#!/usr/bin/env bash
# ==============================================================================
# 📥 HomeLab Download Library - Robust File Downloads with Verification
# ==============================================================================
# HomeLab - Self-Hosted Infrastructure
#
# Source this file to access download helper functions:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/download.sh"
#
# Provides:
#   - download_with_retry() - Download with automatic retry and resume
#   - download_with_checksum() - Download and verify SHA256
#   - parallel_download() - Download multiple files in parallel
#   - get_remote_size() - Get file size before downloading
# ==============================================================================

# Get script directory and source common library
DOWNLOAD_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${DOWNLOAD_LIB_DIR}/common.sh"

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Default retry settings
DOWNLOAD_MAX_RETRIES="${DOWNLOAD_MAX_RETRIES:-3}"
DOWNLOAD_RETRY_DELAY="${DOWNLOAD_RETRY_DELAY:-5}"
DOWNLOAD_TIMEOUT="${DOWNLOAD_TIMEOUT:-300}"

# Checksum directory
CHECKSUM_DIR="${CHECKSUM_DIR:-${DOWNLOAD_LIB_DIR}/../checksums}"

# ==============================================================================
# CORE DOWNLOAD FUNCTIONS
# ==============================================================================

# Get remote file size in bytes
get_remote_size() {
    local url="$1"
    local size=0
    
    if command_exists curl; then
        size=$(curl -sI "$url" 2>/dev/null | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
    elif command_exists wget; then
        size=$(wget --spider --server-response "$url" 2>&1 | grep -i "content-length" | awk '{print $2}' | tail -1)
    fi
    
    echo "${size:-0}"
}

# Format bytes to human readable
format_bytes() {
    local bytes="$1"
    
    if [[ -z "$bytes" || "$bytes" -eq 0 ]]; then
        echo "0 B"
        return
    fi
    
    if command_exists numfmt; then
        numfmt --to=iec-i --suffix=B "$bytes" 2>/dev/null || echo "${bytes} B"
    else
        if [[ "$bytes" -ge 1073741824 ]]; then
            echo "$((bytes / 1073741824)) GB"
        elif [[ "$bytes" -ge 1048576 ]]; then
            echo "$((bytes / 1048576)) MB"
        elif [[ "$bytes" -ge 1024 ]]; then
            echo "$((bytes / 1024)) KB"
        else
            echo "${bytes} B"
        fi
    fi
}

# Download file with retry and resume support
download_with_retry() {
    local url="$1"
    local dest_dir="$2"
    local filename="${3:-$(basename "$url")}"
    local target="${dest_dir}/${filename}"
    
    local retry=0
    local success=false
    
    # Create destination directory
    ensure_dir "$dest_dir"
    
    # Check if file already exists and is complete
    if [[ -f "$target" ]]; then
        local local_size
        local_size=$(stat -c%s "$target" 2>/dev/null || stat -f%z "$target" 2>/dev/null || echo 0)
        local remote_size
        remote_size=$(get_remote_size "$url")
        
        if [[ "$local_size" -gt 0 && "$local_size" -eq "$remote_size" ]]; then
            info "Already downloaded: $filename ($(format_bytes "$local_size"))"
            return 0
        elif [[ "$local_size" -gt 0 ]]; then
            info "Resuming partial download: $filename ($(format_bytes "$local_size") of $(format_bytes "$remote_size"))"
        fi
    fi
    
    # Show target size
    local remote_size
    remote_size=$(get_remote_size "$url")
    if [[ "$remote_size" -gt 0 ]]; then
        info "Downloading: $filename ($(format_bytes "$remote_size"))"
    else
        info "Downloading: $filename"
    fi
    
    while [[ $retry -lt $DOWNLOAD_MAX_RETRIES ]]; do
        if command_exists wget; then
            wget -c -q --show-progress --timeout="$DOWNLOAD_TIMEOUT" -O "$target" "$url" && success=true && break
        elif command_exists curl; then
            curl -L -C - --connect-timeout "$DOWNLOAD_TIMEOUT" -o "$target" "$url" && success=true && break
        else
            error "Neither wget nor curl available"
            return 1
        fi
        
        ((retry++))
        if [[ $retry -lt $DOWNLOAD_MAX_RETRIES ]]; then
            warn "Download failed, retrying in ${DOWNLOAD_RETRY_DELAY}s... (attempt $((retry + 1))/$DOWNLOAD_MAX_RETRIES)"
            sleep "$DOWNLOAD_RETRY_DELAY"
        fi
    done
    
    if $success; then
        success "Downloaded: $filename"
        return 0
    else
        error "Failed to download after $DOWNLOAD_MAX_RETRIES attempts: $filename"
        rm -f "$target"  # Remove partial file
        return 1
    fi
}

# Download file and verify SHA256 checksum
download_with_checksum() {
    local url="$1"
    local dest_dir="$2"
    local expected_checksum="${3:-}"
    local filename="${4:-$(basename "$url")}"
    local target="${dest_dir}/${filename}"
    
    # Try to find checksum file if not provided
    if [[ -z "$expected_checksum" ]]; then
        local checksum_file="${CHECKSUM_DIR}/${filename}.sha256"
        if [[ -f "$checksum_file" ]]; then
            expected_checksum=$(cat "$checksum_file" | awk '{print $1}')
            debug "Loaded checksum from: $checksum_file"
        fi
    fi
    
    # Download the file
    if ! download_with_retry "$url" "$dest_dir" "$filename"; then
        return 1
    fi
    
    # Verify checksum if provided
    if [[ -n "$expected_checksum" ]]; then
        info "Verifying checksum for: $filename"
        
        local actual_checksum
        if command_exists sha256sum; then
            actual_checksum=$(sha256sum "$target" | awk '{print $1}')
        elif command_exists shasum; then
            actual_checksum=$(shasum -a 256 "$target" | awk '{print $1}')
        else
            warn "No SHA256 tool available, skipping verification"
            return 0
        fi
        
        if [[ "$actual_checksum" == "$expected_checksum" ]]; then
            success "Checksum verified: $filename"
        else
            error "Checksum mismatch for: $filename"
            error "  Expected: $expected_checksum"
            error "  Actual:   $actual_checksum"
            rm -f "$target"
            return 1
        fi
    fi
    
    return 0
}

# ==============================================================================
# BATCH DOWNLOAD FUNCTIONS
# ==============================================================================

# Download multiple files in parallel
parallel_download() {
    local dest_dir="$1"
    shift
    local urls=("$@")
    
    local max_parallel="${DOWNLOAD_PARALLEL:-4}"
    local pids=()
    local failed=0
    
    ensure_dir "$dest_dir"
    
    for url in "${urls[@]}"; do
        # Limit parallel downloads
        while [[ ${#pids[@]} -ge $max_parallel ]]; do
            # Wait for any child to finish
            wait -n 2>/dev/null || true
            # Clean up finished processes
            local new_pids=()
            for pid in "${pids[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    new_pids+=("$pid")
                fi
            done
            pids=("${new_pids[@]}")
        done
        
        # Start download in background
        (download_with_retry "$url" "$dest_dir") &
        pids+=($!)
    done
    
    # Wait for all remaining downloads
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            ((failed++))
        fi
    done
    
    if [[ $failed -gt 0 ]]; then
        warn "$failed download(s) failed"
        return 1
    fi
    
    return 0
}

# Download files from a manifest (CSV format: url,checksum)
download_from_manifest() {
    local manifest_file="$1"
    local dest_dir="$2"
    
    if [[ ! -f "$manifest_file" ]]; then
        error "Manifest file not found: $manifest_file"
        return 1
    fi
    
    local failed=0
    
    while IFS=',' read -r url checksum || [[ -n "$url" ]]; do
        # Skip empty lines and comments
        [[ -z "$url" || "$url" =~ ^# ]] && continue
        
        if ! download_with_checksum "$url" "$dest_dir" "$checksum"; then
            ((failed++))
        fi
    done < "$manifest_file"
    
    if [[ $failed -gt 0 ]]; then
        warn "$failed file(s) failed to download from manifest"
        return 1
    fi
    
    success "All files from manifest downloaded successfully"
    return 0
}

# ==============================================================================
# ZIM-SPECIFIC DOWNLOADS
# ==============================================================================

# Kiwix ZIM download base URL
KIWIX_BASE_URL="https://download.kiwix.org/zim"

# Download a Kiwix ZIM file
download_zim() {
    local category="$1"  # e.g., "wikipedia", "stack_exchange"
    local filename="$2"  # e.g., "wikipedia_en_all_nopic_2024-06.zim"
    local dest_dir="${3:-${MEDIA_PATH:-/srv/Tumadre}/ZIM}"
    
    local url="${KIWIX_BASE_URL}/${category}/${filename}"
    
    download_with_retry "$url" "$dest_dir" "$filename"
}

# Create Kiwix library.xml from downloaded ZIM files
create_kiwix_library() {
    local zim_dir="${1:-${MEDIA_PATH:-/srv/Tumadre}/ZIM}"
    local library_file="${zim_dir}/library.xml"
    
    if [[ ! -d "$zim_dir" ]]; then
        warn "ZIM directory not found: $zim_dir"
        return 1
    fi
    
    info "Generating Kiwix library index..."
    
    cat > "$library_file" << 'HEADER'
<?xml version="1.0" encoding="UTF-8"?>
<library version="20110515">
HEADER
    
    local count=0
    for zimfile in "$zim_dir"/*.zim; do
        if [[ -f "$zimfile" ]]; then
            local filename
            filename=$(basename "$zimfile")
            echo "  <book path=\"/zim/${filename}\"/>" >> "$library_file"
            ((count++))
        fi
    done
    
    echo '</library>' >> "$library_file"
    
    success "Created library.xml with $count ZIM file(s)"
    return 0
}
