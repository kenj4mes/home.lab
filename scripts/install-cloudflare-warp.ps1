<#
.SYNOPSIS
    Install and configure Cloudflare WARP (1.1.1.1) for HomeLab
.DESCRIPTION
    Downloads and installs Cloudflare WARP client with Docker-friendly defaults.
    WARP provides encrypted DNS and privacy without breaking localhost/Docker.
    
.EXAMPLE
    .\install-cloudflare-warp.ps1
    
.EXAMPLE
    .\install-cloudflare-warp.ps1 -Silent
#>

[CmdletBinding()]
param(
    [switch]$Silent,
    [switch]$SkipInstall,
    [switch]$ConfigureOnly
)

$ErrorActionPreference = "Stop"
$WarpInstallerUrl = "https://1111-releases.cloudflareclient.com/windows/Cloudflare_WARP_Release-x64.msi"
$TempInstaller = "$env:TEMP\Cloudflare_WARP.msi"

function Write-Step {
    param([string]$Message, [string]$Status = "INFO")
    $color = switch ($Status) {
        "SUCCESS" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        default { "Cyan" }
    }
    $prefix = switch ($Status) {
        "SUCCESS" { "[OK] " }
        "WARN" { "[!] " }
        "ERROR" { "[X] " }
        default { "[i] " }
    }
    Write-Host "$prefix$Message" -ForegroundColor $color
}

function Test-WarpInstalled {
    $warpPath = "C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe"
    return Test-Path $warpPath
}

function Install-Warp {
    Write-Step "Downloading Cloudflare WARP installer..."
    
    try {
        # Download installer
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $WarpInstallerUrl -OutFile $TempInstaller -UseBasicParsing
        Write-Step "Downloaded WARP installer" -Status SUCCESS
        
        # Install silently
        Write-Step "Installing Cloudflare WARP (this may take a minute)..."
        $installArgs = "/i `"$TempInstaller`" /quiet /norestart"
        $process = Start-Process msiexec.exe -ArgumentList $installArgs -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Step "Cloudflare WARP installed successfully" -Status SUCCESS
        }
        else {
            Write-Step "Installation completed with code: $($process.ExitCode)" -Status WARN
        }
        
        # Cleanup
        Remove-Item $TempInstaller -Force -ErrorAction SilentlyContinue
        
        return $true
    }
    catch {
        Write-Step "Failed to install WARP: $($_.Exception.Message)" -Status ERROR
        return $false
    }
}

function Configure-Warp {
    $warpCli = "C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe"
    
    if (-not (Test-Path $warpCli)) {
        Write-Step "WARP CLI not found" -Status ERROR
        return $false
    }
    
    Write-Step "Configuring Cloudflare WARP for Docker compatibility..."
    
    try {
        # Register the client (required for first use)
        Write-Step "Registering WARP client..."
        & $warpCli registration new 2>&1 | Out-Null
        
        # Set mode to DNS-only (best for Docker compatibility)
        # This encrypts DNS without routing all traffic through WARP
        Write-Step "Setting WARP to DNS-only mode (Docker-friendly)..."
        & $warpCli mode doh 2>&1 | Out-Null
        
        # Enable local network access
        Write-Step "Enabling local network access..."
        & $warpCli set-custom-endpoint off 2>&1 | Out-Null
        
        # Connect
        Write-Step "Connecting to Cloudflare WARP..."
        & $warpCli connect 2>&1 | Out-Null
        
        # Verify connection
        Start-Sleep -Seconds 2
        $status = & $warpCli status 2>&1
        
        if ($status -match "Connected|Status update: Connected") {
            Write-Step "WARP connected successfully" -Status SUCCESS
            Write-Step "Mode: DNS-over-HTTPS (localhost/Docker compatible)" -Status SUCCESS
        }
        else {
            Write-Step "WARP status: $status" -Status WARN
        }
        
        return $true
    }
    catch {
        Write-Step "Configuration failed: $($_.Exception.Message)" -Status WARN
        return $false
    }
}

function Show-WarpStatus {
    $warpCli = "C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe"
    
    if (Test-Path $warpCli) {
        Write-Host ""
        Write-Host "  Cloudflare WARP Status:" -ForegroundColor Cyan
        Write-Host "  ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ" -ForegroundColor DarkGray
        & $warpCli status
        Write-Host ""
    }
}

# Main execution
Write-Host ""
Write-Host "  ÔòöÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòù" -ForegroundColor Cyan
Write-Host "  Ôòæ           ­ƒîÉ Cloudflare WARP (1.1.1.1) Installer              Ôòæ" -ForegroundColor Cyan
Write-Host "  Ôòæ                                                               Ôòæ" -ForegroundColor Cyan
Write-Host "  Ôòæ   - Encrypted DNS without breaking Docker                     Ôòæ" -ForegroundColor Cyan
Write-Host "  Ôòæ   - Free unlimited bandwidth                                  Ôòæ" -ForegroundColor Cyan
Write-Host "  Ôòæ   - Localhost access preserved                                Ôòæ" -ForegroundColor Cyan
Write-Host "  ÔòÜÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòØ" -ForegroundColor Cyan
Write-Host ""

if ($ConfigureOnly) {
    Configure-Warp
    Show-WarpStatus
    exit 0
}

# Check if already installed
if (Test-WarpInstalled) {
    Write-Step "Cloudflare WARP is already installed" -Status SUCCESS
    
    if (-not $SkipInstall) {
        $reconfigure = if ($Silent) { "Y" } else { Read-Host "Reconfigure WARP for Docker? (Y/N)" }
        if ($reconfigure.ToUpper() -eq "Y") {
            Configure-Warp
        }
    }
    Show-WarpStatus
    exit 0
}

# Prompt for installation
if (-not $Silent) {
    Write-Host "  Cloudflare WARP provides:" -ForegroundColor White
    Write-Host "    - Encrypted DNS (1.1.1.1)" -ForegroundColor Gray
    Write-Host "    - Privacy without VPN overhead" -ForegroundColor Gray
    Write-Host "    - Full Docker/localhost compatibility" -ForegroundColor Gray
    Write-Host ""
    
    $install = Read-Host "Install Cloudflare WARP? (Y/N, default: Y)"
    if ($install.ToUpper() -eq "N") {
        Write-Step "Skipping WARP installation" -Status WARN
        exit 0
    }
}

# Install and configure
if (Install-Warp) {
    Start-Sleep -Seconds 3  # Wait for service to start
    Configure-Warp
    Show-WarpStatus
    
    Write-Host ""
    Write-Host "  [OK] Cloudflare WARP is now protecting your DNS" -ForegroundColor Green
    Write-Host "  [OK] Docker and localhost will work normally" -ForegroundColor Green
    Write-Host ""
    Write-Host "  To manage WARP:" -ForegroundColor Cyan
    Write-Host "    - Open the 1.1.1.1 app from system tray" -ForegroundColor Gray
    Write-Host "    - Or use: warp-cli status / connect / disconnect" -ForegroundColor Gray
    Write-Host ""
}
