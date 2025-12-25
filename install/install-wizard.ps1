<#
.SYNOPSIS
    HomeLab Install Wizard - Interactive Setup with Component Selection
.DESCRIPTION
    Interactive installation wizard for HomeLab infrastructure.
    Provides folder selection, component selection, and guided setup.
    
    Features:
    - Interactive folder selection dialog
    - Component-based installation (Core, AI, Blockchain, SDR, etc.)
    - Automatic dependency copying
    - Progress tracking and validation
    
.EXAMPLE
    .\install-wizard.ps1
    
.EXAMPLE
    .\install-wizard.ps1 -Silent -InstallPath "D:\HomeLab" -Components @("Core", "AI")
#>

[CmdletBinding()]
param(
    [switch]$Silent,
    [string]$InstallPath,
    [string[]]$Components,
    [string]$DependencyPath,
    [switch]$SkipDocker,
    [switch]$SkipOllama,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ScriptVersion = "2.3.0"
$SubfolderName = "HomeLab"

# ==============================================================================
# CONFIGURATION
# ==============================================================================

$script:Config = @{
    DefaultInstallPath = "C:\HomeLab"
    RequiredDiskSpaceGB = 50
    Components = @{
        "Core" = @{
            Name = "Core Services"
            Description = "Jellyfin, BookStack, Kiwix, qBittorrent, Nginx, Portainer"
            Required = $true
            DiskSpaceGB = 5
            ComposeFiles = @("docker-compose.windows.yml")
        }
        "AI" = @{
            Name = "Local AI (Ollama + Open WebUI)"
            Description = "Run LLMs locally with ChatGPT-like interface"
            Required = $false
            DiskSpaceGB = 20
            ComposeFiles = @("docker-compose.windows.yml")
        }
        "Monitoring" = @{
            Name = "Monitoring Stack"
            Description = "Prometheus, Grafana, Loki for observability"
            Required = $false
            DiskSpaceGB = 2
            ComposeFiles = @("docker-compose.monitoring.yml")
        }
        "Blockchain" = @{
            Name = "Base L2 Blockchain"
            Description = "Base node, Blockscout explorer, wallet API"
            Required = $false
            DiskSpaceGB = 100
            ComposeFiles = @("docker-compose.base.yml")
        }
        "Web3" = @{
            Name = "Web3 Development"
            Description = "Hardhat 3, Foundry, Anvil local testnet"
            Required = $false
            DiskSpaceGB = 5
            ComposeFiles = @("docker-compose.dev.yml")
        }
        "Agents" = @{
            Name = "AI Agents Platform"
            Description = "LangGraph, CrewAI, ChromaDB, n8n automation"
            Required = $false
            DiskSpaceGB = 5
            ComposeFiles = @("docker-compose.agents.yml")
        }
        "Quantum" = @{
            Name = "Quantum Computing"
            Description = "Quantum simulator, QRNG, post-quantum TLS"
            Required = $false
            DiskSpaceGB = 2
            ComposeFiles = @("docker-compose.quantum.yml")
        }
        "SDR" = @{
            Name = "SDR & Radio Security"
            Description = "IMSI Catcher, Rayhunter, LTESniffer, srsRAN 5G"
            Required = $false
            DiskSpaceGB = 10
            ComposeFiles = @("docker-compose.sdr.yml")
            Warning = "⚠️ Requires SDR hardware (RTL-SDR, HackRF, USRP)"
        }
        "Matrix" = @{
            Name = "Matrix Synapse (Secure Chat)"
            Description = "Self-hosted encrypted messaging with Element"
            Required = $false
            DiskSpaceGB = 3
            ComposeFiles = @("docker-compose.matrix.yml")
        }
        "Creative" = @{
            Name = "Creative AI Studio"
            Description = "Stable Diffusion, ComfyUI, Bark TTS, MusicGen, Video Diffusion"
            Required = $false
            DiskSpaceGB = 50
            ComposeFiles = @("docker-compose.creative.yml")
            Warning = "⚠️ Requires NVIDIA GPU with 8GB+ VRAM (24GB for video)"
        }
        "HuggingFace" = @{
            Name = "Hugging Face Ecosystem"
            Description = "transformers, diffusers, accelerate, huggingface-cli for model downloads"
            Required = $false
            DiskSpaceGB = 2
            ComposeFiles = @()
            Scripts = @("scripts/install-huggingface.ps1")
        }
        "PQTLS" = @{
            Name = "Post-Quantum TLS Security"
            Description = "PQ-TLS reverse proxy (Kyber768) + HashiCorp Vault"
            Required = $false
            DiskSpaceGB = 1
            ComposeFiles = @("docker-compose.pqtls.yml")
        }
        "TRELLIS" = @{
            Name = "TRELLIS.2 3D Generation"
            Description = "Image-to-3D model generation"
            Required = $false
            DiskSpaceGB = 15
            ComposeFiles = @("docker-compose.dev.yml")
            Warning = "⚠️ Requires NVIDIA GPU with 24GB+ VRAM"
        }
        "Superchain" = @{
            Name = "Superchain Ecosystem"
            Description = "31 OP-Stack L2 nodes (Base, OP, Unichain, Mode, World, Lisk)"
            Required = $false
            DiskSpaceGB = 100
            ComposeFiles = @("docker-compose.superchain.yml")
            Warning = "⚠️ Requires L1 RPC (Alchemy/Infura) - ~500GB per synced chain"
        }
        "Experimental" = @{
            Name = "Experimental Stack (Cybernetic Pillars)"
            Description = "LangFlow AI, Rotki DeFi, Scaphandre energy, n8n workflows, Dozzle logs"
            Required = $false
            DiskSpaceGB = 5
            ComposeFiles = @("docker-compose.experimental.yml")
            Warning = "⚠️ Bleeding-edge tools for advanced users"
        }
        "Social" = @{
            Name = "Social Media Stack"
            Description = "Farcaster hub, Nitter, Invidious, Teddit, n8n automation"
            Required = $false
            DiskSpaceGB = 10
            ComposeFiles = @("docker-compose.social.yml")
            Warning = "⚠️ Some APIs require keys (Twitter, YouTube)"
        }
        "Identity" = @{
            Name = "Identity & SSO"
            Description = "Keycloak SSO, OAuth2 Proxy for centralized authentication"
            Required = $false
            DiskSpaceGB = 2
            ComposeFiles = @("docker-compose.identity.yml")
        }
        "GitHubProfile" = @{
            Name = "GitHub Profile Analytics"
            Description = "S+ rank stats, trophies, snake animation, WakaTime, metrics workflows"
            Required = $false
            DiskSpaceGB = 0
            ComposeFiles = @()
            Scripts = @("scripts/setup-github-profile.ps1")
        }
        "SecurityResearch" = @{
            Name = "Security Research Stack"
            Description = "Garak LLM scanner, Counterfit ML, firmware analysis, RF classification"
            Required = $false
            DiskSpaceGB = 5
            ComposeFiles = @("docker-compose.security-research.yml")
            Scripts = @("scripts/clone-security-research.ps1")
            Warning = "⚠️ For authorized security research only - check local laws"
        }
    }
    DownloadableAssets = @{
        "ZIM" = @{
            Name = "Wikipedia Offline (ZIM)"
            Description = "Wikipedia, Stack Overflow for offline access"
            SizeGB = 22
            Script = "scripts/download-all.sh"
            PSScript = "scripts/download-zim.ps1"
        }
        "Models" = @{
            Name = "Ollama LLM Models"
            Description = "Llama 3.2, DeepSeek-R1, Mistral, CodeLlama"
            SizeGB = 26
            Script = "scripts/download-models.sh"
            PSScript = "scripts/download-models.ps1"
        }
        "CreativeAI" = @{
            Name = "Creative AI Models"
            Description = "SDXL, Whisper, Bark TTS, MusicGen"
            SizeGB = 50
            Script = "scripts/download-creative-models.ps1"
        }
        "SecurityResearch" = @{
            Name = "Security Research Repositories"
            Description = "28 security research tools (LTESniffer, Garak, etc.)"
            SizeGB = 2
            Script = "scripts/clone-security-research.ps1"
        }
    }
}

# ==============================================================================
# UI HELPERS
# ==============================================================================

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                                  ║" -ForegroundColor Cyan
    Write-Host "  ║   ██╗  ██╗ ██████╗ ███╗   ███╗███████╗██╗      █████╗ ██████╗    ║" -ForegroundColor Cyan
    Write-Host "  ║   ██║  ██║██╔═══██╗████╗ ████║██╔════╝██║     ██╔══██╗██╔══██╗   ║" -ForegroundColor Cyan
    Write-Host "  ║   ███████║██║   ██║██╔████╔██║█████╗  ██║     ███████║██████╔╝   ║" -ForegroundColor Cyan
    Write-Host "  ║   ██╔══██║██║   ██║██║╚██╔╝██║██╔══╝  ██║     ██╔══██║██╔══██╗   ║" -ForegroundColor Cyan
    Write-Host "  ║   ██║  ██║╚██████╔╝██║ ╚═╝ ██║███████╗███████╗██║  ██║██████╔╝   ║" -ForegroundColor Cyan
    Write-Host "  ║   ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═════╝    ║" -ForegroundColor Cyan
    Write-Host "  ║                                                                  ║" -ForegroundColor Cyan
    Write-Host "  ║              🏠 Install Wizard v$ScriptVersion                          ║" -ForegroundColor Cyan
    Write-Host "  ║                                                                  ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message, [string]$Status = "INFO")
    $color = switch ($Status) {
        "SUCCESS" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        "PHASE" { "Magenta" }
        default { "Cyan" }
    }
    $prefix = switch ($Status) {
        "SUCCESS" { "  [OK] " }
        "WARN" { "  [!] " }
        "ERROR" { "  [X] " }
        "PHASE" { "`n  >> " }
        default { "  [i] " }
    }
    Write-Host "$prefix$Message" -ForegroundColor $color
}

function Show-FolderBrowser {
    param([string]$Description = "Select installation folder")
    
    Add-Type -AssemblyName System.Windows.Forms
    $browser = New-Object System.Windows.Forms.FolderBrowserDialog
    $browser.Description = $Description
    $browser.RootFolder = [System.Environment+SpecialFolder]::MyComputer
    $browser.SelectedPath = $script:Config.DefaultInstallPath
    $browser.ShowNewFolderButton = $true
    
    $result = $browser.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $browser.SelectedPath
    }
    return $null
}

function Show-ComponentSelector {
    $selectedComponents = @()
    $components = $script:Config.Components.GetEnumerator() | Sort-Object { $_.Value.Required } -Descending
    
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "  │                    COMPONENT SELECTION                          │" -ForegroundColor White
    Write-Host "  └─────────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    
    $index = 1
    $componentMap = @{}
    
    foreach ($comp in $components) {
        $componentMap[$index] = $comp.Key
        $required = if ($comp.Value.Required) { "[REQUIRED]" } else { "[Optional]" }
        $reqColor = if ($comp.Value.Required) { "Yellow" } else { "Gray" }
        $warning = if ($comp.Value.Warning) { "`n       $($comp.Value.Warning)" } else { "" }
        
        Write-Host "  [$index] " -NoNewline -ForegroundColor Cyan
        Write-Host "$($comp.Value.Name) " -NoNewline -ForegroundColor White
        Write-Host $required -ForegroundColor $reqColor
        Write-Host "       $($comp.Value.Description)" -ForegroundColor Gray
        Write-Host "       Disk: ~$($comp.Value.DiskSpaceGB) GB" -ForegroundColor DarkGray
        if ($warning) { Write-Host $warning -ForegroundColor Yellow }
        Write-Host ""
        $index++
    }
    
    Write-Host "  ─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  [A] Select ALL components" -ForegroundColor Green
    Write-Host "  [R] Required only (minimal install)" -ForegroundColor Yellow
    Write-Host "  [C] Custom selection" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = Read-Host "  Select option (A/R/C)"
    
    switch ($choice.ToUpper()) {
        "A" {
            $selectedComponents = $script:Config.Components.Keys
        }
        "R" {
            $selectedComponents = $script:Config.Components.GetEnumerator() | 
                Where-Object { $_.Value.Required } | 
                ForEach-Object { $_.Key }
        }
        "C" {
            Write-Host ""
            Write-Host "  Enter component numbers separated by commas (e.g., 1,2,5,6):" -ForegroundColor Cyan
            $selections = Read-Host "  Components"
            $numbers = $selections -split "," | ForEach-Object { [int]$_.Trim() }
            
            foreach ($num in $numbers) {
                if ($componentMap.ContainsKey($num)) {
                    $selectedComponents += $componentMap[$num]
                }
            }
            
            # Always include required components
            $script:Config.Components.GetEnumerator() | 
                Where-Object { $_.Value.Required } | 
                ForEach-Object { 
                    if ($selectedComponents -notcontains $_.Key) {
                        $selectedComponents += $_.Key
                    }
                }
        }
        default {
            # Default to required only
            $selectedComponents = $script:Config.Components.GetEnumerator() | 
                Where-Object { $_.Value.Required } | 
                ForEach-Object { $_.Key }
        }
    }
    
    return $selectedComponents
}

function Show-Summary {
    param(
        [string]$InstallPath,
        [string[]]$SelectedComponents,
        [string]$DependencyPath
    )
    
    $totalDisk = 0
    $script:Config.Components.GetEnumerator() | 
        Where-Object { $SelectedComponents -contains $_.Key } |
        ForEach-Object { $totalDisk += $_.Value.DiskSpaceGB }
    
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "  │                    INSTALLATION SUMMARY                         │" -ForegroundColor White
    Write-Host "  └─────────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    Write-Host "  Install Path:     " -NoNewline -ForegroundColor Gray
    Write-Host $InstallPath -ForegroundColor White
    Write-Host "  Dependencies:     " -NoNewline -ForegroundColor Gray
    Write-Host $(if ($DependencyPath) { $DependencyPath } else { "(none)" }) -ForegroundColor White
    Write-Host "  Estimated Disk:   " -NoNewline -ForegroundColor Gray
    Write-Host "~$totalDisk GB" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Selected Components:" -ForegroundColor Gray
    
    foreach ($comp in $SelectedComponents) {
        $info = $script:Config.Components[$comp]
        $icon = if ($info.Required) { "★" } else { "○" }
        Write-Host "    $icon $($info.Name)" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "  ─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    
    $confirm = Read-Host "  Proceed with installation? (Y/N)"
    return $confirm.ToUpper() -eq "Y"
}

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

function Test-Prerequisites {
    Write-Step "Checking prerequisites..." -Status PHASE
    
    # Check admin
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Step "Administrator privileges required" -Status ERROR
        return $false
    }
    Write-Step "Running as Administrator" -Status SUCCESS
    
    # Check Git LFS
    $gitLfs = Get-Command git-lfs -ErrorAction SilentlyContinue
    if ($gitLfs) {
        Write-Step "Git LFS is installed" -Status SUCCESS
    }
    else {
        Write-Step "Git LFS not found - required for data files" -Status WARN
        Write-Host "    Install with: winget install Git.Git.LFS" -ForegroundColor Yellow
    }
    
    # Check Docker
    if (-not $SkipDocker) {
        $docker = Get-Command docker -ErrorAction SilentlyContinue
        if ($docker) {
            try {
                docker info 2>&1 | Out-Null
                Write-Step "Docker is installed and running" -Status SUCCESS
            }
            catch {
                Write-Step "Docker is installed but not running" -Status WARN
            }
        }
        else {
            Write-Step "Docker not found - will be installed" -Status WARN
        }
    }
    
    # Check disk space
    $drive = (Split-Path $InstallPath -Qualifier)
    $diskInfo = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$drive'"
    $freeGB = [math]::Round($diskInfo.FreeSpace / 1GB, 2)
    
    if ($freeGB -lt $script:Config.RequiredDiskSpaceGB) {
        Write-Step "Insufficient disk space: ${freeGB}GB free, need $($script:Config.RequiredDiskSpaceGB)GB" -Status ERROR
        return $false
    }
    Write-Step "Disk space OK: ${freeGB}GB free" -Status SUCCESS
    
    return $true
}

function Copy-HomelabFiles {
    param([string]$DestPath)
    
    Write-Step "Copying HomeLab files..." -Status PHASE
    
    $sourceDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.ScriptName)
    if (-not $sourceDir) {
        $sourceDir = $PSScriptRoot
        if ($sourceDir -like "*\install") {
            $sourceDir = Split-Path -Parent $sourceDir
        }
    }
    
    # If we're running from the source, copy everything
    if (Test-Path "$sourceDir\docker") {
        Write-Step "Copying from: $sourceDir"
        
        # Copy main directories
        $dirs = @("docker", "scripts", "configs", "miniapps", "docs", "install", "terraform")
        foreach ($dir in $dirs) {
            $src = Join-Path $sourceDir $dir
            $dst = Join-Path $DestPath $dir
            if (Test-Path $src) {
                Copy-Item -Path $src -Destination $dst -Recurse -Force
                Write-Step "Copied: $dir" -Status SUCCESS
            }
        }
        
        # Copy root files
        $files = @("homelab.ps1", "Makefile", "bootstrap.sh", "README.md", "CONTRIBUTING.md", "CHANGELOG.md")
        foreach ($file in $files) {
            $src = Join-Path $sourceDir $file
            if (Test-Path $src) {
                Copy-Item -Path $src -Destination $DestPath -Force
            }
        }
        Write-Step "Copied root files" -Status SUCCESS
    }
    else {
        Write-Step "Source files not found at $sourceDir" -Status ERROR
        return $false
    }
    
    return $true
}

function Copy-Dependencies {
    param(
        [string]$SourcePath,
        [string]$DestPath,
        [string[]]$SelectedComponents
    )
    
    if (-not $SourcePath -or -not (Test-Path $SourcePath)) {
        Write-Step "No dependency path specified, skipping" -Status WARN
        return $true
    }
    
    Write-Step "Copying dependencies from: $SourcePath" -Status PHASE
    
    # Copy ZIM files
    $zimFiles = Get-ChildItem -Path $SourcePath -Filter "*.zim" -ErrorAction SilentlyContinue
    if ($zimFiles) {
        $zimDest = Join-Path $DestPath "data\ZIM"
        if (-not (Test-Path $zimDest)) {
            New-Item -ItemType Directory -Path $zimDest -Force | Out-Null
        }
        foreach ($zim in $zimFiles) {
            Write-Step "Copying ZIM: $($zim.Name) ($('{0:N2}' -f ($zim.Length / 1GB)) GB)"
            Copy-Item -Path $zim.FullName -Destination $zimDest -Force
        }
        Write-Step "ZIM files copied" -Status SUCCESS
    }
    
    # Copy SDR tools if selected
    if ($SelectedComponents -contains "SDR") {
        $sdrTools = @{
            "IMSI-catcher-master" = "miniapps\imsi-catcher\src"
            "rayhunter-main" = "miniapps\rayhunter\src"
            "LTESniffer-main" = "miniapps\ltesniffer\src"
            "srsRAN_Project-main" = "miniapps\srsran\src"
        }
        
        foreach ($tool in $sdrTools.GetEnumerator()) {
            $src = Join-Path $SourcePath $tool.Key
            $dst = Join-Path $DestPath $tool.Value
            if (Test-Path $src) {
                Write-Step "Copying SDR tool: $($tool.Key)"
                if (-not (Test-Path $dst)) {
                    New-Item -ItemType Directory -Path $dst -Force | Out-Null
                }
                Copy-Item -Path "$src\*" -Destination $dst -Recurse -Force
                Write-Step "Copied: $($tool.Key)" -Status SUCCESS
            }
        }
    }
    
    # Copy Matrix/Synapse config if selected
    if ($SelectedComponents -contains "Matrix") {
        $matrixSrc = Join-Path $SourcePath "matrix.grapheneos.org-main"
        if (Test-Path $matrixSrc) {
            $matrixDst = Join-Path $DestPath "configs\synapse"
            if (-not (Test-Path $matrixDst)) {
                New-Item -ItemType Directory -Path $matrixDst -Force | Out-Null
            }
            Copy-Item -Path "$matrixSrc\synapse\*" -Destination $matrixDst -Recurse -Force -ErrorAction SilentlyContinue
            Write-Step "Copied Matrix/Synapse configs" -Status SUCCESS
        }
    }
    
    # Copy Open-WebUI source if exists
    $openWebUISrc = Join-Path $SourcePath "open-webui-main"
    if (Test-Path $openWebUISrc) {
        $openWebUIDst = Join-Path $DestPath "miniapps\open-webui"
        Write-Step "Copying Open-WebUI source..."
        if (-not (Test-Path $openWebUIDst)) {
            New-Item -ItemType Directory -Path $openWebUIDst -Force | Out-Null
        }
        Copy-Item -Path "$openWebUISrc\*" -Destination $openWebUIDst -Recurse -Force
        Write-Step "Copied Open-WebUI source" -Status SUCCESS
    }
    
    # Copy DragonOS image if exists
    $dragonImg = Get-ChildItem -Path $SourcePath -Filter "DragonOS*.img" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($dragonImg) {
        $imgDst = Join-Path $DestPath "data\SDR"
        if (-not (Test-Path $imgDst)) {
            New-Item -ItemType Directory -Path $imgDst -Force | Out-Null
        }
        Write-Step "Copying DragonOS image: $($dragonImg.Name) ($('{0:N2}' -f ($dragonImg.Length / 1GB)) GB)"
        Copy-Item -Path $dragonImg.FullName -Destination $imgDst -Force
        Write-Step "Copied DragonOS image" -Status SUCCESS
    }
    
    # Copy Creative AI reference architecture if exists
    $refArchSrc = Join-Path $SourcePath "Below is a ready-to-run reference.md"
    if (Test-Path $refArchSrc) {
        $docsDst = Join-Path $DestPath "docs\reference"
        if (-not (Test-Path $docsDst)) {
            New-Item -ItemType Directory -Path $docsDst -Force | Out-Null
        }
        Copy-Item -Path $refArchSrc -Destination (Join-Path $docsDst "creative-stack-reference.md") -Force
        Write-Step "Copied Creative Stack reference architecture" -Status SUCCESS
    }
    
    # Copy AudioCraft/MusicGen source if exists
    $musicgenSrc = Join-Path $SourcePath "audiocraft-main"
    if (Test-Path $musicgenSrc) {
        $musicgenDst = Join-Path $DestPath "miniapps\musicgen\src"
        if (-not (Test-Path $musicgenDst)) {
            New-Item -ItemType Directory -Path $musicgenDst -Force | Out-Null
        }
        Copy-Item -Path "$musicgenSrc\*" -Destination $musicgenDst -Recurse -Force
        Write-Step "Copied AudioCraft (MusicGen) source" -Status SUCCESS
    }
    
    # Copy Bark TTS source if exists
    $barkSrc = Join-Path $SourcePath "bark-main"
    if (Test-Path $barkSrc) {
        $barkDst = Join-Path $DestPath "miniapps\bark-tts\src"
        if (-not (Test-Path $barkDst)) {
            New-Item -ItemType Directory -Path $barkDst -Force | Out-Null
        }
        Copy-Item -Path "$barkSrc\*" -Destination $barkDst -Recurse -Force
        Write-Step "Copied Bark TTS source" -Status SUCCESS
    }
    
    # Copy ComfyUI source if exists
    $comfyuiSrc = Join-Path $SourcePath "ComfyUI-main"
    if (Test-Path $comfyuiSrc) {
        $comfyuiDst = Join-Path $DestPath "miniapps\comfyui\src"
        if (-not (Test-Path $comfyuiDst)) {
            New-Item -ItemType Directory -Path $comfyuiDst -Force | Out-Null
        }
        Copy-Item -Path "$comfyuiSrc\*" -Destination $comfyuiDst -Recurse -Force
        Write-Step "Copied ComfyUI source" -Status SUCCESS
    }
    
    # Copy Stable Diffusion WebUI source if exists
    $sdSrc = Join-Path $SourcePath "stable-diffusion-webui-main"
    if (Test-Path $sdSrc) {
        $sdDst = Join-Path $DestPath "miniapps\stable-diffusion\src"
        if (-not (Test-Path $sdDst)) {
            New-Item -ItemType Directory -Path $sdDst -Force | Out-Null
        }
        Copy-Item -Path "$sdSrc\*" -Destination $sdDst -Recurse -Force
        Write-Step "Copied Stable Diffusion WebUI source" -Status SUCCESS
    }
    
    return $true
}

function Initialize-Environment {
    param([string]$InstallPath)
    
    Write-Step "Initializing environment..." -Status PHASE
    
    $dockerDir = Join-Path $InstallPath "docker"
    $envFile = Join-Path $dockerDir ".env"
    
    if (-not (Test-Path $envFile)) {
        # Generate secure passwords
        $dbPass = [System.Guid]::NewGuid().ToString().Substring(0, 16)
        $rootPass = [System.Guid]::NewGuid().ToString().Substring(0, 16)
        $matrixPass = [System.Guid]::NewGuid().ToString().Substring(0, 16)
        $grafanaPass = [System.Guid]::NewGuid().ToString().Substring(0, 16)
        
        $envContent = @"
# ==============================================================================
# HomeLab Environment Configuration
# Generated by Install Wizard v$ScriptVersion on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# ==============================================================================

# Timezone
TZ=America/New_York

# User/Group IDs
PUID=1000
PGID=1000

# Paths (Windows format)
CONFIG_PATH=$InstallPath\config
MEDIA_PATH=$InstallPath\data
ZIM_PATH=$InstallPath\data\ZIM
AUDIO_PATH=$InstallPath\data\audio
VIDEO_OUTPUT_PATH=$InstallPath\data\videos

# Service URLs
JELLYFIN_URL=http://localhost:8096
BOOKSTACK_URL=http://localhost:8082
WEBUI_URL=http://localhost:3000

# Database Passwords (auto-generated)
BOOKSTACK_DB_ROOT_PASSWORD=$rootPass
BOOKSTACK_DB_PASSWORD=$dbPass
MATRIX_DB_PASSWORD=$matrixPass
GRAFANA_ADMIN_PASSWORD=$grafanaPass

# Ollama
OLLAMA_HOST=http://host.docker.internal:11434

# Creative AI Services
SD_CONFIG_PATH=$InstallPath\config\stable-diffusion
COMFYUI_CONFIG_PATH=$InstallPath\config\comfyui
BARK_SMALL_MODEL=false
BARK_USE_GPU=true
MUSICGEN_MODEL=small
WHISPER_MODEL=base
SVD_MODEL=svd-xt

# Post-Quantum TLS
PQNGINX_CONFIG_PATH=$InstallPath\config\pq-nginx
PQNGINX_CERTS_PATH=$InstallPath\config\pq-nginx\certs
VAULT_DEV_TOKEN=$([System.Guid]::NewGuid().ToString().Substring(0, 16))
VAULT_CONFIG_PATH=$InstallPath\config\vault

# SDR (optional - set if using DragonOS)
# DRAGONOS_IMG=$InstallPath\data\SDR\DragonOS_Pi64_Beta42.img
"@
        $envContent | Out-File -FilePath $envFile -Encoding UTF8 -Force
        Write-Step "Generated .env with secure passwords" -Status SUCCESS
    }
    else {
        Write-Step ".env already exists, skipping" -Status WARN
    }
    
    # Create data directories
    $dataDirs = @(
        "config\jellyfin", "config\bookstack", "config\nginx", "config\portainer",
        "config\prometheus", "config\grafana", "config\synapse", "config\ollama",
        "config\pq-nginx\conf.d", "config\pq-nginx\certs", "config\pq-nginx\html",
        "config\vault", "config\stable-diffusion", "config\comfyui",
        "data\Movies", "data\Series", "data\Music", "data\Books", "data\Downloads",
        "data\ZIM", "data\SDR", "data\models", "data\audio", "data\videos", "logs"
    )
    
    foreach ($dir in $dataDirs) {
        $fullPath = Join-Path $InstallPath $dir
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        }
    }
    Write-Step "Created data directories" -Status SUCCESS
    
    return $true
}

function Start-Installation {
    param(
        [string]$InstallPath,
        [string[]]$SelectedComponents
    )
    
    Write-Step "Starting selected services..." -Status PHASE
    
    $dockerDir = Join-Path $InstallPath "docker"
    Push-Location $dockerDir
    
    try {
        # Start core services first
        if ($SelectedComponents -contains "Core" -or $SelectedComponents -contains "AI") {
            Write-Step "Starting Core + AI services..."
            docker compose -f docker-compose.windows.yml up -d 2>&1 | Out-Null
            Write-Step "Core services started" -Status SUCCESS
        }
        
        # Start additional stacks based on selection
        $stackMap = @{
            "Monitoring" = "docker-compose.monitoring.yml"
            "Blockchain" = "docker-compose.base.yml"
            "Web3" = "docker-compose.dev.yml"
            "Agents" = "docker-compose.agents.yml"
            "Quantum" = "docker-compose.quantum.yml"
            "SDR" = "docker-compose.sdr.yml"
            "Matrix" = "docker-compose.matrix.yml"
            "Creative" = "docker-compose.creative.yml"
            "PQTLS" = "docker-compose.pqtls.yml"
            "Social" = "docker-compose.social.yml"
            "Identity" = "docker-compose.identity.yml"
            "Experimental" = "docker-compose.experimental.yml"
            "Superchain" = "docker-compose.superchain.yml"
        }
        
        foreach ($stack in $stackMap.GetEnumerator()) {
            if ($SelectedComponents -contains $stack.Key) {
                $composeFile = $stack.Value
                if (Test-Path $composeFile) {
                    Write-Step "Starting $($stack.Key) services..."
                    
                    # Special handling for GPU-required services
                    if ($stack.Key -eq "Creative") {
                        $gpuAvailable = $false
                        try {
                            $nvidiaTest = docker run --rm --gpus all nvidia/cuda:12.1-base nvidia-smi 2>&1
                            if ($LASTEXITCODE -eq 0) { $gpuAvailable = $true }
                        } catch { }
                        
                        if ($gpuAvailable) {
                            docker compose -f $composeFile --profile gpu up -d 2>&1 | Out-Null
                        } else {
                            Write-Step "GPU not available, starting Creative services without GPU acceleration" -Status WARN
                            docker compose -f $composeFile up -d 2>&1 | Out-Null
                        }
                    } else {
                        docker compose -f $composeFile up -d 2>&1 | Out-Null
                    }
                    Write-Step "$($stack.Key) started" -Status SUCCESS
                }
            }
        }
    }
    catch {
        Write-Step "Error starting services: $($_.Exception.Message)" -Status ERROR
    }
    finally {
        Pop-Location
    }
    
    return $true
}

function Start-DependencyDownloads {
    param(
        [string]$InstallPath,
        [string[]]$SelectedComponents
    )
    
    Write-Step "Starting dependency downloads..." -Status PHASE
    
    $scriptsDir = Join-Path $InstallPath "scripts"
    
    # Download ZIM files for Core
    if ($SelectedComponents -contains "Core") {
        Write-Host ""
        Write-Host "  Which Wikipedia version would you like?" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [1] Simple English (~500MB) - Quick download, basic content" -ForegroundColor Gray
        Write-Host "  [2] Standard English (~22GB) - Most articles, no media" -ForegroundColor Gray
        Write-Host "  [3] Full English (~111GB) - Complete with images" -ForegroundColor Yellow
        Write-Host "  [4] Skip - Download later" -ForegroundColor DarkGray
        Write-Host ""
        $zimChoice = Read-Host "  Select (1/2/3/4, default: 2)"
        
        $zimDir = Join-Path $InstallPath "data\ZIM"
        if (-not (Test-Path $zimDir)) {
            New-Item -ItemType Directory -Path $zimDir -Force | Out-Null
        }
        
        switch ($zimChoice) {
            "1" {
                Write-Step "Downloading Simple English Wikipedia (~500MB)..."
                $zimUrl = "https://download.kiwix.org/zim/wikipedia/wikipedia_en_simple_all_maxi_2024-01.zim"
                $zimDest = Join-Path $zimDir "wikipedia_en_simple.zim"
                try {
                    Start-BitsTransfer -Source $zimUrl -Destination $zimDest -DisplayName "Wikipedia Simple"
                    Write-Step "Wikipedia (Simple) downloaded" -Status SUCCESS
                }
                catch {
                    try {
                        Invoke-WebRequest -Uri $zimUrl -OutFile $zimDest -UseBasicParsing
                        Write-Step "Wikipedia (Simple) downloaded" -Status SUCCESS
                    }
                    catch {
                        Write-Step "Download failed - try manually" -Status WARN
                    }
                }
            }
            "3" {
                Write-Step "Downloading Full English Wikipedia (~111GB)..."
                Write-Host "    ⚠️ This will take several hours!" -ForegroundColor Yellow
                $zimUrl = "https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_maxi_2024-01.zim"
                $zimDest = Join-Path $zimDir "wikipedia_en_all_maxi.zim"
                try {
                    Start-BitsTransfer -Source $zimUrl -Destination $zimDest -DisplayName "Wikipedia Full" -Priority Low
                    Write-Step "Wikipedia (Full 111GB) downloaded" -Status SUCCESS
                }
                catch {
                    Write-Step "Large file download failed - use torrent or browser" -Status WARN
                    Write-Host "    Download manually: $zimUrl" -ForegroundColor Gray
                }
            }
            "4" {
                Write-Step "Skipping ZIM download - run later with download-zim.ps1" -Status WARN
            }
            default {
                Write-Step "Downloading Standard English Wikipedia (~22GB)..."
                $zimUrl = "https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_nopic_2024-01.zim"
                $zimDest = Join-Path $zimDir "wikipedia_en_nopic.zim"
                try {
                    Start-BitsTransfer -Source $zimUrl -Destination $zimDest -DisplayName "Wikipedia Standard"
                    Write-Step "Wikipedia (Standard) downloaded" -Status SUCCESS
                }
                catch {
                    Write-Step "Download failed - try manually or use torrent" -Status WARN
                    Write-Host "    Download: $zimUrl" -ForegroundColor Gray
                }
            }
        }
        
        # Also offer Stack Overflow
        Write-Host ""
        $dlStack = Read-Host "  Also download Stack Overflow (~5GB)? (Y/N, default: N)"
        if ($dlStack.ToUpper() -eq "Y") {
            Write-Step "Downloading Stack Overflow (~5GB)..."
            $stackUrl = "https://download.kiwix.org/zim/stack_exchange/stackoverflow.com_en_all_2024-01.zim"
            $stackDest = Join-Path $zimDir "stackoverflow.zim"
            try {
                Start-BitsTransfer -Source $stackUrl -Destination $stackDest -DisplayName "Stack Overflow"
                Write-Step "Stack Overflow downloaded" -Status SUCCESS
            }
            catch {
                Write-Step "Stack Overflow download failed" -Status WARN
            }
        }
    }
    
    # Download Ollama models for AI
    if ($SelectedComponents -contains "AI") {
        Write-Step "Downloading Ollama models (~26GB)..."
        Write-Host "    Models will be pulled when Ollama starts" -ForegroundColor Gray
        Write-Host "    Run: ollama pull llama3.2 mistral deepseek-coder" -ForegroundColor Gray
        Write-Step "Ollama models queued for download on first run" -Status SUCCESS
    }
    
    # Download Creative AI models
    if ($SelectedComponents -contains "Creative") {
        $creativeScript = Join-Path $scriptsDir "download-creative-models.ps1"
        if (Test-Path $creativeScript) {
            Write-Step "Downloading Creative AI models (~50GB)..."
            Write-Host "    This will take a while..." -ForegroundColor Gray
            try {
                & $creativeScript -TargetPath (Join-Path $InstallPath "data\models")
                Write-Step "Creative AI models downloaded" -Status SUCCESS
            }
            catch {
                Write-Step "Creative model download failed - run manually later" -Status WARN
                Write-Host "    Run: .\scripts\download-creative-models.ps1" -ForegroundColor Yellow
            }
        }
    }
    
    # Clone Security Research repos
    if ($SelectedComponents -contains "SecurityResearch") {
        $securityScript = Join-Path $scriptsDir "clone-security-research.ps1"
        if (Test-Path $securityScript) {
            Write-Step "Cloning security research repositories (~2GB)..."
            try {
                & $securityScript -TargetDir (Join-Path $InstallPath "security-research")
                Write-Step "Security research repos cloned" -Status SUCCESS
            }
            catch {
                Write-Step "Security research clone failed - run manually later" -Status WARN
                Write-Host "    Run: .\scripts\clone-security-research.ps1" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Step "Dependency downloads complete" -Status SUCCESS
}

# ==============================================================================
# MAIN WIZARD FLOW
# ==============================================================================

function Start-InstallWizard {
    Show-Banner
    
    # Step 1: Folder Selection
    Write-Host "  STEP 1: Choose Installation Location" -ForegroundColor Magenta
    Write-Host "  ─────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    
    if (-not $InstallPath) {
        Write-Host "  [1] Default: $($script:Config.DefaultInstallPath)" -ForegroundColor Cyan
        Write-Host "  [2] Browse for folder..." -ForegroundColor Cyan
        Write-Host "  [3] Enter path manually" -ForegroundColor Cyan
        Write-Host ""
        
        $choice = Read-Host "  Select option (1/2/3)"
        
        switch ($choice) {
            "1" { $InstallPath = $script:Config.DefaultInstallPath }
            "2" { 
                $InstallPath = Show-FolderBrowser -Description "Select HomeLab installation folder"
                if (-not $InstallPath) {
                    Write-Step "No folder selected, using default" -Status WARN
                    $InstallPath = $script:Config.DefaultInstallPath
                }
            }
            "3" {
                $InstallPath = Read-Host "  Enter installation path"
            }
            default { $InstallPath = $script:Config.DefaultInstallPath }
        }
    }
    
    # Create HomeLab subfolder inside selected directory
    Write-Host ""
    Write-Host "  The wizard will create a 'HomeLab' folder inside your selected location." -ForegroundColor Gray
    Write-Host "  Final path: $InstallPath\$SubfolderName" -ForegroundColor White
    Write-Host ""
    
    $useSubfolder = Read-Host "  Create HomeLab subfolder? (Y/N, default: Y)"
    if ($useSubfolder.ToUpper() -ne "N") {
        $InstallPath = Join-Path $InstallPath $SubfolderName
    }
    
    Write-Step "Final installation path: $InstallPath" -Status SUCCESS
    
    # Create install directory if needed
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-Step "Created directory: $InstallPath" -Status SUCCESS
    }
    else {
        Write-Step "Directory exists: $InstallPath" -Status WARN
        if (-not $Force) {
            $overwrite = Read-Host "  Overwrite existing installation? (Y/N)"
            if ($overwrite.ToUpper() -ne "Y") {
                Write-Step "Installation cancelled" -Status WARN
                return
            }
        }
    }
    
    Write-Host ""
    
    # Step 2: Dependency Path
    Write-Host "  STEP 2: Dependencies (Optional)" -ForegroundColor Magenta
    Write-Host "  ─────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Do you have a dependencies folder with ZIM files, SDR tools, etc.?" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [1] No dependencies" -ForegroundColor Cyan
    Write-Host "  [2] Browse for folder..." -ForegroundColor Cyan
    Write-Host "  [3] Enter path manually" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $DependencyPath) {
        $choice = Read-Host "  Select option (1/2/3)"
        
        switch ($choice) {
            "2" { 
                $DependencyPath = Show-FolderBrowser -Description "Select dependencies folder"
            }
            "3" {
                $DependencyPath = Read-Host "  Enter dependencies path"
            }
        }
    }
    
    if ($DependencyPath -and (Test-Path $DependencyPath)) {
        Write-Step "Dependencies path: $DependencyPath" -Status SUCCESS
    }
    else {
        Write-Step "No dependencies folder selected" -Status WARN
        $DependencyPath = $null
        
        # Offer to download dependencies
        Write-Host ""
        Write-Host "  Would you like to download required dependencies automatically?" -ForegroundColor Cyan
        Write-Host "  (This requires internet connection and may take a while)" -ForegroundColor Gray
        Write-Host ""
        $downloadDeps = Read-Host "  Download dependencies after install? (Y/N, default: N)"
        if ($downloadDeps.ToUpper() -eq "Y") {
            $script:DownloadAfterInstall = $true
        }
    }
    
    Write-Host ""
    
    # Step 3: Component Selection
    Write-Host "  STEP 3: Select Components" -ForegroundColor Magenta
    Write-Host "  ──────────────────────────" -ForegroundColor DarkGray
    
    if (-not $Components) {
        $SelectedComponents = Show-ComponentSelector
    }
    else {
        $SelectedComponents = $Components
    }
    
    # Step 4: Summary and Confirmation
    Write-Host ""
    Write-Host "  STEP 4: Confirm Installation" -ForegroundColor Magenta
    Write-Host "  ─────────────────────────────" -ForegroundColor DarkGray
    
    $proceed = Show-Summary -InstallPath $InstallPath -SelectedComponents $SelectedComponents -DependencyPath $DependencyPath
    
    if (-not $proceed) {
        Write-Host ""
        Write-Step "Installation cancelled by user" -Status WARN
        return
    }
    
    # Step 5: Execute Installation
    Write-Host ""
    Write-Host "  STEP 5: Installing..." -ForegroundColor Magenta
    Write-Host "  ──────────────────────" -ForegroundColor DarkGray
    
    # Prerequisites check
    if (-not (Test-Prerequisites)) {
        Write-Step "Prerequisites check failed" -Status ERROR
        return
    }
    
    # Copy HomeLab files
    if (-not (Copy-HomelabFiles -DestPath $InstallPath)) {
        Write-Step "Failed to copy HomeLab files" -Status ERROR
        return
    }
    
    # Copy dependencies
    if ($DependencyPath) {
        Copy-Dependencies -SourcePath $DependencyPath -DestPath $InstallPath -SelectedComponents $SelectedComponents
    }
    
    # Initialize environment
    Initialize-Environment -InstallPath $InstallPath
    
    # Start services (optional)
    Write-Host ""
    $startNow = Read-Host "  Start services now? (Y/N)"
    if ($startNow.ToUpper() -eq "Y") {
        Start-Installation -InstallPath $InstallPath -SelectedComponents $SelectedComponents
    }
    
    # Download dependencies if requested
    if ($script:DownloadAfterInstall) {
        Write-Host ""
        Write-Host "  STEP 6: Downloading Dependencies..." -ForegroundColor Magenta
        Write-Host "  ────────────────────────────────────" -ForegroundColor DarkGray
        
        Start-DependencyDownloads -InstallPath $InstallPath -SelectedComponents $SelectedComponents
    }
    
    # Final Summary
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║              🎉 INSTALLATION COMPLETE!                        ║" -ForegroundColor Green
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Installed to: $InstallPath" -ForegroundColor White
    Write-Host ""
    Write-Host "  NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "  ────────────" -ForegroundColor DarkGray
    Write-Host "  1. cd $InstallPath" -ForegroundColor Gray
    Write-Host "  2. .\homelab.ps1 -Action status    # Check services" -ForegroundColor Gray
    Write-Host "  3. .\homelab.ps1 -Action health    # Health checks" -ForegroundColor Gray
    Write-Host "  4. Open http://localhost:8096      # Jellyfin" -ForegroundColor Gray
    Write-Host "  5. Open http://localhost:3000      # Open WebUI" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  📚 Documentation: $InstallPath\docs" -ForegroundColor Cyan
    Write-Host ""
}

# ==============================================================================
# ENTRY POINT
# ==============================================================================

if ($Silent -and $InstallPath -and $Components) {
    # Silent mode - run without prompts
    Write-Step "Running in silent mode..."
    Test-Prerequisites
    Copy-HomelabFiles -DestPath $InstallPath
    if ($DependencyPath) {
        Copy-Dependencies -SourcePath $DependencyPath -DestPath $InstallPath -SelectedComponents $Components
    }
    Initialize-Environment -InstallPath $InstallPath
    Start-Installation -InstallPath $InstallPath -SelectedComponents $Components
}
else {
    # Interactive wizard
    Start-InstallWizard
}
