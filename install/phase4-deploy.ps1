<#
.SYNOPSIS
    Phase 4: Deploy all services to Debian VM
.DESCRIPTION
    Copies HomeLab files to VM and runs the complete setup
.PARAMETER VMIP
    IP address of the Debian VM
.PARAMETER Username
    SSH username (default: homelab)
.PARAMETER DownloadProfile
    Download profile selection: minimal, standard, or full
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$VMIP,
    [string]$Username = "homelab",
    [ValidateSet("minimal", "standard", "full")]
    [string]$DownloadProfile = "standard"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

Write-Host @"

+==============================================================================+
|                     Phase 4: Deploy Services                                  |
+==============================================================================+

"@ -ForegroundColor Blue

Write-Host "Target:  $Username@$VMIP" -ForegroundColor Cyan
Write-Host "Profile: $DownloadProfile" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# Wait for SSH
# ==============================================================================

Write-Host "Waiting for SSH to become available..." -ForegroundColor Cyan

$maxAttempts = 30
$attempt = 0
$sshReady = $false

while ($attempt -lt $maxAttempts -and -not $sshReady) {
    $attempt++
    try {
        $result = ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${Username}@${VMIP}" "echo ready" 2>$null
        if ($result -eq "ready") {
            $sshReady = $true
        }
    } catch {
        Write-Host "  Attempt $attempt/$maxAttempts..." -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }
}

if (-not $sshReady) {
    Write-Host "Could not connect to VM. Please check:" -ForegroundColor Red
    Write-Host "  - VM is running"
    Write-Host "  - IP address is correct"
    Write-Host "  - SSH is enabled"
    Write-Host "  - Credentials are correct (default: homelab/homelab)"
    exit 1
}

Write-Host "[OK] SSH connection established" -ForegroundColor Green

# ==============================================================================
# Copy Files to VM
# ==============================================================================

Write-Host ""
Write-Host "Copying HomeLab files to VM..." -ForegroundColor Cyan

# Create remote directory
ssh "${Username}@${VMIP}" "mkdir -p ~/homelab"

# Copy all files
scp -r "$RepoRoot\docker" "${Username}@${VMIP}:~/homelab/"
scp -r "$RepoRoot\scripts" "${Username}@${VMIP}:~/homelab/"
scp -r "$RepoRoot\configs" "${Username}@${VMIP}:~/homelab/"
scp -r "$RepoRoot\docs" "${Username}@${VMIP}:~/homelab/"
scp "$RepoRoot\README.md" "${Username}@${VMIP}:~/homelab/"

Write-Host "[OK] Files copied" -ForegroundColor Green

# ==============================================================================
# Run Init Script
# ==============================================================================

Write-Host ""
Write-Host "Running HomeLab initialization..." -ForegroundColor Cyan
Write-Host "Profile: $DownloadProfile" -ForegroundColor Yellow
Write-Host ""
Write-Host "This will install Docker, Ollama, and all services." -ForegroundColor Yellow
Write-Host "Downloads may take a while depending on your connection." -ForegroundColor Yellow
Write-Host ""

# Make scripts executable and run
ssh "${Username}@${VMIP}" @"
cd ~/homelab
chmod +x scripts/*.sh
echo '$Username' | sudo -S ./scripts/init-homelab.sh --$DownloadProfile
"@

# ==============================================================================
# Get Final Status
# ==============================================================================

Write-Host ""
Write-Host "Checking service status..." -ForegroundColor Cyan

$status = ssh "${Username}@${VMIP}" "docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null || echo 'Docker not ready'"
Write-Host $status

Write-Host ""
Write-Host "[OK] Phase 4 complete" -ForegroundColor Green
Write-Host ""
Write-Host "Services available at:" -ForegroundColor Cyan
Write-Host "  Jellyfin:    http://${VMIP}:8096"
Write-Host "  Kiwix:       http://${VMIP}:8081"
Write-Host "  BookStack:   http://${VMIP}:8082"
Write-Host "  Open WebUI:  http://${VMIP}:3000"
Write-Host "  Portainer:   http://${VMIP}:9000"
