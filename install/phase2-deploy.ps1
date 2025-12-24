<#
.SYNOPSIS
    Phase 2: Configure Proxmox host via SSH
.DESCRIPTION
    Deploys configuration scripts to Proxmox and executes them
.PARAMETER ProxmoxIP
    IP address of the Proxmox host
.PARAMETER Username
    SSH username (default: root)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProxmoxIP,
    [string]$Username = "root"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

Write-Host @"

+==============================================================================+
|                     Phase 2: Configure Proxmox Host                           |
+==============================================================================+

"@ -ForegroundColor Blue

Write-Host "Target: $Username@$ProxmoxIP" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# Check SSH availability
# ==============================================================================

Write-Host "Testing SSH connection..." -ForegroundColor Cyan

# Check if ssh is available
$sshAvailable = Get-Command ssh -ErrorAction SilentlyContinue
if (-not $sshAvailable) {
    Write-Host "SSH not found. Please enable OpenSSH in Windows Features." -ForegroundColor Red
    Write-Host "Settings > Apps > Optional Features > Add OpenSSH Client" -ForegroundColor Yellow
    exit 1
}

# ==============================================================================
# Copy scripts to Proxmox
# ==============================================================================

Write-Host "Copying scripts to Proxmox..." -ForegroundColor Cyan

# Create remote directory
ssh "${Username}@${ProxmoxIP}" "mkdir -p /root/homelab-setup"

# Copy the setup scripts
scp "$RepoRoot\scripts\setup-zfs.sh" "${Username}@${ProxmoxIP}:/root/homelab-setup/"
scp "$ScriptDir\proxmox-post-install.sh" "${Username}@${ProxmoxIP}:/root/homelab-setup/"

Write-Host "[OK] Scripts copied" -ForegroundColor Green

# ==============================================================================
# Execute Proxmox post-install script
# ==============================================================================

Write-Host ""
Write-Host "Executing Proxmox configuration..." -ForegroundColor Cyan
Write-Host "(This will remove subscription nag and enable IOMMU)" -ForegroundColor Yellow
Write-Host ""

ssh "${Username}@${ProxmoxIP}" "chmod +x /root/homelab-setup/*.sh && /root/homelab-setup/proxmox-post-install.sh"

# ==============================================================================
# ZFS Pool Setup
# ==============================================================================

Write-Host ""
Write-Host "ZFS Pool Configuration" -ForegroundColor Cyan
Write-Host ""

$setupZFS = Read-Host "Do you want to create ZFS pools now? (y/N)"
if ($setupZFS -eq 'y' -or $setupZFS -eq 'Y') {
    Write-Host ""
    Write-Host "This will create:" -ForegroundColor Yellow
    Write-Host "  - fast-pool: Mirror of SSDs for VMs/configs"
    Write-Host "  - bulk-pool: RAIDZ1 of HDDs for media storage"
    Write-Host ""
    Write-Host "[WARN]️  WARNING: This will DESTROY data on the selected disks!" -ForegroundColor Red
    Write-Host ""
    
    # Show available disks
    Write-Host "Available disks on Proxmox:" -ForegroundColor Cyan
    ssh "${Username}@${ProxmoxIP}" "lsblk -d -o NAME,SIZE,TYPE,MODEL"
    Write-Host ""
    
    $confirm = Read-Host "Continue with ZFS setup? (type YES to confirm)"
    if ($confirm -eq "YES") {
        ssh "${Username}@${ProxmoxIP}" "/root/homelab-setup/setup-zfs.sh"
    } else {
        Write-Host "ZFS setup skipped" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "[OK] Phase 2 complete" -ForegroundColor Green
Write-Host ""
Write-Host "Proxmox is configured. You may need to reboot for IOMMU changes." -ForegroundColor Yellow
Write-Host "Access Proxmox at: https://${ProxmoxIP}:8006" -ForegroundColor Cyan
