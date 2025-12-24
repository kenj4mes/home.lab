<#
.SYNOPSIS
    HomeLab Complete Orchestrator - Guides through all installation phases
.DESCRIPTION
    HomeLab - Windows Orchestrator
    Automates the entire HomeLab setup from Proxmox to running services
.PARAMETER ProxmoxIP
    IP address of the Proxmox host
.PARAMETER VMIP
    IP address of the Debian VM (auto-detected if not specified)
.PARAMETER Profile
    Download profile: minimal, standard, or full
.PARAMETER SkipPhase0
    Skip Phase 0 (Proxmox ISO download)
.PARAMETER SkipPhase1
    Skip Phase 1 (Proxmox installation - always manual)
.EXAMPLE
    .\orchestrator.ps1
    .\orchestrator.ps1 -ProxmoxIP "192.168.1.10" -DownloadProfile "standard"
#>

param(
    [string]$ProxmoxIP,
    [string]$VMIP,
    [ValidateSet("minimal", "standard", "full")]
    [string]$DownloadProfile = "standard",
    [switch]$SkipPhase0,
    [switch]$SkipPhase1,
    [switch]$SkipPhase2,
    [switch]$SkipPhase3,
    [switch]$SkipPhase4,
    [string]$LogPath = "C:\HomeLab\logs\orchestrator.log"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogDir = Split-Path -Parent $LogPath

# ==============================================================================
# HELPERS
# ==============================================================================

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    $logEntry | Out-File -FilePath $LogPath -Append -Encoding UTF8
    
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        "PHASE" { "Magenta" }
        default { "Cyan" }
    }
    
    if ($Level -eq "PHASE") {
        Write-Host "`n$Message" -ForegroundColor $color
    }
    else {
        $prefix = switch ($Level) {
            "SUCCESS" { "[OK] " }
            "WARN" { "[WARN] " }
            "ERROR" { "[ERR] " }
            default { "[INFO] " }
        }
        Write-Host "  $prefix$Message" -ForegroundColor $color
    }
}

# ==============================================================================
# BANNER
# ==============================================================================

Clear-Host
Write-Log "========================================" -Level PHASE
Write-Log "      HomeLab Proxmox Orchestrator      " -Level PHASE
Write-Log "========================================" -Level PHASE
Write-Log "Profile: $DownloadProfile"
Write-Log "Log:      $LogPath"

# ==============================================================================
# PHASE 0: Prepare Installation Media
# ==============================================================================

if (-not $SkipPhase0) {
    Write-Log "PHASE 0: Prepare Installation Media" -Level PHASE
    if (Test-Path "$ScriptDir\phase0-prepare.ps1") {
        $response = Read-Host "  Do you need to create a Proxmox bootable USB? (y/N)"
        if ($response -match "^[Yy]$") {
            Write-Log "Running Phase 0 script..."
            & "$ScriptDir\phase0-prepare.ps1"
            Write-Log "Proxmox USB ready. Please install Proxmox on your server." -Level WARN
            Read-Host "  Press Enter after installation is complete to continue..."
        }
    }
    else {
        Write-Log "phase0-prepare.ps1 not found, skipping" -Level WARN
    }
}

# ==============================================================================
# PHASE 1: Proxmox Installation (Manual)
# ==============================================================================

if (-not $SkipPhase1) {
    Write-Log "PHASE 1: Proxmox Installation" -Level PHASE
    Write-Log "Ensure Proxmox is installed on your server with static IP."
    $response = Read-Host "  Is Proxmox installed and running? (y/N)"
    if ($response -notmatch "^[Yy]$") {
        Write-Log "Please complete Proxmox installation before proceeding." -Level ERROR
        exit 1
    }
}

# Get Proxmox IP
if (-not $ProxmoxIP) {
    $ProxmoxIP = Read-Host "`n  Enter Proxmox IP address"
}

# Validate connectivity
Write-Log "Testing connection to Proxmox at $ProxmoxIP..."
if (-not (Test-Connection -ComputerName $ProxmoxIP -Count 1 -Quiet)) {
    Write-Log "Cannot reach Proxmox at $ProxmoxIP. Check network/IP." -Level ERROR
    exit 1
}
Write-Log "Proxmox reachable" -Level SUCCESS

# ==============================================================================
# PHASE 2: Configure Proxmox Host
# ==============================================================================

if (-not $SkipPhase2) {
    Write-Log "PHASE 2: Configure Proxmox Host" -Level PHASE
    if (Test-Path "$ScriptDir\phase2-deploy.ps1") {
        Write-Log "Configuring Proxmox (Repos, IOMMU, ZFS)..."
        & "$ScriptDir\phase2-deploy.ps1" -ProxmoxIP $ProxmoxIP
        Write-Log "Phase 2 complete" -Level SUCCESS
    }
    else {
        Write-Log "phase2-deploy.ps1 not found, skipping" -Level WARN
    }
}

# ==============================================================================
# PHASE 3: Create Debian VM
# ==============================================================================

if (-not $SkipPhase3) {
    Write-Log "PHASE 3: Create Debian VM" -Level PHASE
    if (Test-Path "$ScriptDir\phase3-create-vm.ps1") {
        Write-Log "Creating optimized Debian 12 VM..."
        $results = & "$ScriptDir\phase3-create-vm.ps1" -ProxmoxIP $ProxmoxIP
        if ($results -and $results.VMIP) { $VMIP = $results.VMIP }
        Write-Log "Phase 3 complete" -Level SUCCESS
    }
    else {
        Write-Log "phase3-create-vm.ps1 not found, skipping" -Level WARN
    }
}

# Get VM IP
if (-not $VMIP) {
    $VMIP = Read-Host "`n  Enter Debian VM IP address"
}

# ==============================================================================
# PHASE 4: Deploy Services
# ==============================================================================

if (-not $SkipPhase4) {
    Write-Log "PHASE 4: Deploy HomeLab Services" -Level PHASE
    if (Test-Path "$ScriptDir\phase4-deploy.ps1") {
        Write-Log "Deploying Docker, Ollama, and Services to $VMIP..."
        & "$ScriptDir\phase4-deploy.ps1" -VMIP $VMIP -DownloadProfile $DownloadProfile
        Write-Log "Phase 4 complete" -Level SUCCESS
    }
    else {
        Write-Log "phase4-deploy.ps1 not found, skipping" -Level WARN
    }
}

# ==============================================================================
# COMPLETE
# ==============================================================================

Write-Log "========================================" -Level PHASE
Write-Log "      ORCHESTRATION COMPLETE!           " -Level PHASE
Write-Log "========================================" -Level PHASE

Write-Log "Your HomeLab is ready at $VMIP" -Level SUCCESS
Write-Log "Access services via http://$VMIP:PORT"
Write-Log "Review logs at $LogPath"
