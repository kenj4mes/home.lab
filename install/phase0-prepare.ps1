<#
.SYNOPSIS
    Phase 0: Download Proxmox ISO and prepare bootable USB
.DESCRIPTION
    Downloads the latest Proxmox VE ISO and helps create a bootable USB
#>

$ErrorActionPreference = "Stop"
$DownloadDir = "$env:USERPROFILE\Downloads\HomeLab"

# Create download directory
New-Item -ItemType Directory -Force -Path $DownloadDir | Out-Null

Write-Host @"

+==============================================================================+
|                     Phase 0: Prepare Installation Media                       |
+==============================================================================+

"@ -ForegroundColor Blue

# ==============================================================================
# Download Proxmox ISO
# ==============================================================================

$ProxmoxVersion = "8.3"
$ProxmoxISO = "proxmox-ve_${ProxmoxVersion}-1.iso"
$ProxmoxURL = "https://enterprise.proxmox.com/iso/$ProxmoxISO"
$ISOPath = "$DownloadDir\$ProxmoxISO"

if (Test-Path $ISOPath) {
    Write-Host "[OK] Proxmox ISO already downloaded: $ISOPath" -ForegroundColor Green
} else {
    Write-Host "Downloading Proxmox VE $ProxmoxVersion ISO..." -ForegroundColor Cyan
    Write-Host "  URL: $ProxmoxURL"
    Write-Host "  This may take a while (~1.2 GB)..."
    Write-Host ""
    
    try {
        # Use BITS for better download experience
        Start-BitsTransfer -Source $ProxmoxURL -Destination $ISOPath -DisplayName "Proxmox VE ISO"
        Write-Host "[OK] Downloaded: $ISOPath" -ForegroundColor Green
    } catch {
        Write-Host "BITS transfer failed, trying WebClient..." -ForegroundColor Yellow
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($ProxmoxURL, $ISOPath)
        Write-Host "[OK] Downloaded: $ISOPath" -ForegroundColor Green
    }
}

# ==============================================================================
# Download Rufus
# ==============================================================================

$RufusURL = "https://github.com/pbatard/rufus/releases/download/v4.6/rufus-4.6p.exe"
$RufusPath = "$DownloadDir\rufus.exe"

if (Test-Path $RufusPath) {
    Write-Host "[OK] Rufus already downloaded" -ForegroundColor Green
} else {
    Write-Host "Downloading Rufus (USB creator)..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $RufusURL -OutFile $RufusPath
    Write-Host "[OK] Downloaded Rufus" -ForegroundColor Green
}

# ==============================================================================
# Instructions
# ==============================================================================

Write-Host @"

+==============================================================================+
|                           Ready to Create USB                                 |
+==============================================================================+

Files downloaded to: $DownloadDir

NEXT STEPS:
1. Insert a USB drive (8GB+ recommended)
2. Rufus will open automatically
3. Select your USB drive
4. Select the Proxmox ISO
5. Click START (use DD mode if prompted)
6. Wait for completion

"@ -ForegroundColor Yellow

$response = Read-Host "Open Rufus now? (Y/n)"
if ($response -ne 'n' -and $response -ne 'N') {
    Start-Process $RufusPath
    Write-Host ""
    Write-Host "Rufus opened. Please:" -ForegroundColor Cyan
    Write-Host "  1. Select your USB drive"
    Write-Host "  2. Click SELECT and choose: $ISOPath"
    Write-Host "  3. Click START"
    Write-Host "  4. If prompted, select 'Write in DD Image mode'"
    Write-Host ""
}

Write-Host @"

After creating the USB:
1. Insert USB into your server
2. Boot from USB (may need to change BIOS boot order)
3. Follow Proxmox installer
4. Note the IP address after installation
5. Return here and continue to Phase 2

"@ -ForegroundColor Green

# Open download folder
Start-Process explorer.exe -ArgumentList $DownloadDir
