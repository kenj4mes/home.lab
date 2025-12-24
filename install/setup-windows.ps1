<#
.SYNOPSIS
    HomeLab Windows PC Setup - Run everything locally via WSL2 + Docker Desktop
.DESCRIPTION
    HomeLab - Windows Local Edition
    
    Installs and configures:
    - WSL2 (Windows Subsystem for Linux)
    - Docker Desktop
    - Ollama for Windows
    - All HomeLab containers
    - Unified CLI (homelab.ps1)
#>

param(
    [ValidateSet("minimal", "standard", "full")]
    [string]$DownloadProfile = "standard",
    [switch]$SkipWSL,
    [switch]$SkipDocker,
    [switch]$SkipOllama,
    [switch]$SkipDownloads,
    [switch]$IncludeQuantum,
    [switch]$IncludeBase,
    [switch]$IncludeMonitoring,
    [switch]$IncludeWeb3,
    [switch]$IncludeAgents,
    [switch]$IncludeTrellis,
    [switch]$All,
    [string]$LogPath = "C:\HomeLab\logs\setup.log"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LabRoot = Split-Path -Parent $ScriptDir
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
# CHECKS
# ==============================================================================

Clear-Host
Write-Log "========================================" -Level PHASE
Write-Log "      HomeLab Windows Setup             " -Level PHASE
Write-Log "========================================" -Level PHASE
Write-Log "Profile: $DownloadProfile"
Write-Log "Lab Root: $LabRoot"
Write-Log "Log:      $LogPath"

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Log "Administrator privileges required for installation." -Level ERROR
    exit 1
}

# ==============================================================================
# PHASE 1: WSL2
# ==============================================================================

Write-Log "PHASE 1: Windows Subsystem for Linux" -Level PHASE

if ($SkipWSL) {
    Write-Log "Skipping WSL setup" -Level WARN
}
else {
    try {
        $wslStatus = wsl --status 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "WSL is already installed and configured" -Level SUCCESS
        }
        else {
            Write-Log "Enabling WSL and Virtual Machine Platform..."
            dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
            dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
            
            Write-Log "Setting WSL2 as default version..."
            wsl --set-default-version 2 | Out-Null
            
            Write-Log "WSL enabled. A REBOOT MAY BE REQUIRED." -Level WARN
            $script:NeedsReboot = $true
        }
    }
    catch {
        Write-Log "Failed to configure WSL: $($_.Exception.Message)" -Level ERROR
    }
}

# ==============================================================================
# PHASE 2: Docker Desktop
# ==============================================================================

Write-Log "PHASE 2: Docker Desktop" -Level PHASE

if ($SkipDocker) {
    Write-Log "Skipping Docker installation" -Level WARN
}
else {
    $dockerInstalled = Get-Command docker -ErrorAction SilentlyContinue
    if ($dockerInstalled) {
        Write-Log "Docker is already installed ($(docker --version))" -Level SUCCESS
    }
    else {
        Write-Log "Downloading Docker Desktop..."
        $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
        Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller -UseBasicParsing
        
        Write-Log "Installing Docker Desktop..."
        $process = Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet", "--accept-license" -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            Write-Log "Docker Desktop installed successfully" -Level SUCCESS
            $script:NeedsReboot = $true
        }
        else {
            Write-Log "Docker installation failed with exit code $($process.ExitCode)" -Level ERROR
        }
    }
}

# ==============================================================================
# PHASE 3: Ollama
# ==============================================================================

Write-Log "PHASE 3: Ollama (Local LLM)" -Level PHASE

if ($SkipOllama) {
    Write-Log "Skipping Ollama installation" -Level WARN
}
else {
    $ollamaInstalled = Get-Command ollama -ErrorAction SilentlyContinue
    if ($ollamaInstalled) {
        Write-Log "Ollama is already installed" -Level SUCCESS
    }
    else {
        Write-Log "Downloading Ollama for Windows..."
        $ollamaUrl = "https://ollama.com/download/OllamaSetup.exe"
        $ollamaInstaller = "$env:TEMP\OllamaSetup.exe"
        Invoke-WebRequest -Uri $ollamaUrl -OutFile $ollamaInstaller -UseBasicParsing
        
        Write-Log "Installing Ollama..."
        Start-Process -FilePath $ollamaInstaller -ArgumentList "/S" -Wait
        Write-Log "Ollama installed" -Level SUCCESS
    }
}

# ==============================================================================
# PHASE 4: Directory Structure
# ==============================================================================

Write-Log "PHASE 4: Directory Structure" -Level PHASE

$HomeLabRoot = "C:\HomeLab"
$DataRoot = "$HomeLabRoot\data"
$ConfigRoot = "$HomeLabRoot\config"

$directories = @(
    "$DataRoot\Movies", "$DataRoot\Series", "$DataRoot\Music", "$DataRoot\Books",
    "$DataRoot\Downloads", "$DataRoot\ZIM",
    "$ConfigRoot\jellyfin", "$ConfigRoot\qbittorrent", "$ConfigRoot\bookstack",
    "$ConfigRoot\nginx", "$ConfigRoot\nginx\ssl", "$ConfigRoot\portainer", "$ConfigRoot\open-webui",
    "$ConfigRoot\ollama", "$ConfigRoot\prometheus", "$ConfigRoot\grafana",
    "$ConfigRoot\base-node", "$ConfigRoot\base-db", "$ConfigRoot\secrets", "$ConfigRoot\backups"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Log "Created directory: $dir"
    }
    else {
        Write-Log "Exists: $dir"
    }
}

# ==============================================================================
# PHASE 5: Environment & Content
# ==============================================================================

Write-Log "PHASE 5: Environment & Content" -Level PHASE

# Generate .env
if (-not (Test-Path "$LabRoot\docker\.env")) {
    Write-Log "Generating environment file..."
    $dbPass = [System.Guid]::NewGuid().ToString().Substring(0, 16)
    $rootPass = [System.Guid]::NewGuid().ToString().Substring(0, 16)
    
    $envContent = @"
TZ=America/New_York
PUID=1000
PGID=1000
CONFIG_PATH=C:/HomeLab/config
MEDIA_PATH=C:/HomeLab/data
JELLYFIN_URL=http://localhost:8096
BOOKSTACK_URL=http://localhost:8082
BOOKSTACK_DB_ROOT_PASSWORD=$rootPass
BOOKSTACK_DB_PASSWORD=$dbPass
"@
    $envContent | Out-File -FilePath "$LabRoot\docker\.env" -Encoding UTF8 -Force
    Write-Log "Created .env with secure random passwords" -Level SUCCESS
}

# Downloads
if (-not $SkipDownloads) {
    Write-Log "Starting content downloads (Profile: $DownloadProfile)..."
    
    # Run Ollama downloads
    Write-Log "Pulling Ollama models..."
    $models = switch ($DownloadProfile) {
        "minimal" { @("phi3") }
        "standard" { @("mistral", "codellama") }
        "full" { @("mistral", "codellama", "llama3.2", "deepseek-r1:7b") }
    }
    
    foreach ($m in $models) {
        Write-Log "Pulling $m..."
        ollama pull $m
    }
    
    # Kiwix ZIM downloads (Simulated or via BITS)
    Write-Log "To download ZIM files, please run the download-all.sh script in WSL if needed,"
    Write-Log "or use the provided Makefile in a bash environment."
}

# ==============================================================================
# PHASE 6: Start Services
# ==============================================================================

Write-Log "PHASE 6: Starting Services" -Level PHASE

# Check if Docker is running
try {
    docker info | Out-Null
    $dockerRunning = $true
}
catch {
    $dockerRunning = $false
}

if ($dockerRunning) {
    Push-Location "$LabRoot\docker"
    
    # Core services
    Write-Log "Starting core containers..."
    docker compose -f docker-compose.windows.yml up -d
    
    # Full profile or explicit flags enable additional services
    $installAll = ($DownloadProfile -eq "full") -or $All
    
    # Base blockchain
    if ($installAll -or $IncludeBase) {
        Write-Log "Starting Base blockchain services..."
        docker compose -f docker-compose.base.yml up -d 2>$null
    }
    
    # Monitoring stack
    if ($installAll -or $IncludeMonitoring -or $DownloadProfile -eq "standard") {
        Write-Log "Starting Monitoring stack..."
        docker compose -f docker-compose.monitoring.yml up -d 2>$null
    }
    
    # Quantum services
    if ($installAll -or $IncludeQuantum) {
        Write-Log "Building and starting Quantum services..."
        docker compose -f docker-compose.quantum.yml build 2>$null
        docker compose -f docker-compose.quantum.yml up -d 2>$null
    }
    
    # Web3 development services
    if ($installAll -or $IncludeWeb3) {
        Write-Log "Starting Web3 development services..."
        docker compose -f docker-compose.dev.yml build 2>$null
        docker compose -f docker-compose.dev.yml up -d anvil 2>$null
    }
    
    # Agent orchestrator services
    if ($installAll -or $IncludeAgents) {
        Write-Log "Starting Agent orchestrator services..."
        docker compose -f docker-compose.agents.yml build 2>$null
        docker compose -f docker-compose.agents.yml up -d 2>$null
    }
    
    # TRELLIS.2 (requires NVIDIA GPU)
    if ($IncludeTrellis) {
        Write-Log "Starting TRELLIS.2 3D generation (GPU required)..."
        docker compose -f docker-compose.dev.yml up -d trellis-3d 2>$null
    }
    
    Pop-Location
    Write-Log "HomeLab services started" -Level SUCCESS
}
else {
    Write-Log "Docker is not running. Please start Docker Desktop." -Level WARN
}

# ==============================================================================
# COMPLETE
# ==============================================================================

Write-Log "========================================" -Level PHASE
Write-Log "      SETUP COMPLETE!                   " -Level PHASE
Write-Log "========================================" -Level PHASE

if ($script:NeedsReboot) {
    Write-Log "A reboot is required for WSL/Docker changes to take effect." -Level WARN
}

Write-Log ""
Write-Log "INSTALLED SERVICES:" -Level SUCCESS
Write-Log "  Core Services:"
Write-Log "    - Jellyfin:    http://localhost:8096"
Write-Log "    - BookStack:   http://localhost:8082"
Write-Log "    - Ollama:      http://localhost:11434"
Write-Log "    - Open WebUI:  http://localhost:3000"
Write-Log "    - Kiwix:       http://localhost:8085"

if ($installAll -or $IncludeBase) {
    Write-Log ""
    Write-Log "  Base Blockchain:" -Level SUCCESS
    Write-Log "    - RPC:         http://localhost:8545"
    Write-Log "    - Explorer:    http://localhost:4000"
}

if ($installAll -or $IncludeMonitoring -or $DownloadProfile -eq "standard") {
    Write-Log ""
    Write-Log "  Monitoring Stack:" -Level SUCCESS
    Write-Log "    - Prometheus:  http://localhost:9090"
    Write-Log "    - Grafana:     http://localhost:3001"
    Write-Log "    - Loki:        http://localhost:3100"
}

if ($installAll -or $IncludeQuantum) {
    Write-Log ""
    Write-Log "  Quantum Services:" -Level SUCCESS
    Write-Log "    - QRNG:        http://localhost:5001"
    Write-Log "    - Simulator:   http://localhost:5002"
}

if ($installAll -or $IncludeWeb3) {
    Write-Log ""
    Write-Log "  Web3 Development:" -Level SUCCESS
    Write-Log "    - Anvil Node:  http://localhost:8547"
    Write-Log "    - Hardhat:     http://localhost:8545"
}

if ($installAll -or $IncludeAgents) {
    Write-Log ""
    Write-Log "  Agent Services:" -Level SUCCESS
    Write-Log "    - Orchestrator: http://localhost:5004"
    Write-Log "    - ChromaDB:    http://localhost:8000"
}

if ($IncludeTrellis) {
    Write-Log ""
    Write-Log "  3D Generation:" -Level SUCCESS
    Write-Log "    - TRELLIS.2:   http://localhost:5003"
    Write-Log "    - Web UI:      http://localhost:7860"
}

Write-Log ""
Write-Log "NEXT STEPS:" -Level PHASE
Write-Log "  1. Check status:     .\homelab.ps1 -Action status"
Write-Log "  2. View logs:        .\homelab.ps1 -Action logs"
Write-Log "  3. Stop services:    .\homelab.ps1 -Action stop"
Write-Log "  4. Start quantum:    .\homelab.ps1 -Action quantum"
Write-Log "  5. Review docs:      $LabRoot\docs"
Write-Log ""
Write-Log "For post-quantum TLS and advanced security, run in WSL:"
Write-Log "  ./scripts/install-quantum.sh && ./scripts/generate-pq-tls.sh"
