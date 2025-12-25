<#
.SYNOPSIS
    x402 Gateway Installation Script for home.lab
    
.DESCRIPTION
    Installs and configures the x402 payment gateway stack including:
    - x402-gateway (HTTP 402 payment middleware)
    - Ollama (local LLM inference)
    - Echo Agent (autonomous AI entity)
    - ChromaDB (vector memory)
    
.PARAMETER Action
    install, uninstall, start, stop, status, logs
    
.PARAMETER Profile
    minimal (gateway only), standard (gateway + ollama), full (all services)
    
.EXAMPLE
    .\install-x402.ps1 -Action install -Profile standard
    
.NOTES
    Part of home.lab ecosystem
    Author: 3TEKK
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('install', 'uninstall', 'start', 'stop', 'status', 'logs', 'configure')]
    [string]$Action = 'install',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('minimal', 'standard', 'full')]
    [string]$Profile = 'standard',
    
    [Parameter(Mandatory=$false)]
    [string]$DataDir = '/opt/stacks/x402',
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

$ErrorActionPreference = 'Stop'

$Config = @{
    StackName = 'x402'
    Version = '1.0.0'
    DataDir = $DataDir
    ComposeFile = Join-Path $PSScriptRoot '..\docker\docker-compose.yml'
    EnvFile = Join-Path $PSScriptRoot '..\docker\.env'
    EnvExample = Join-Path $PSScriptRoot '..\docker\.env.example'
    
    # Docker images
    Images = @{
        Gateway = 'x402-gateway:latest'
        Ollama = 'ollama/ollama:latest'
        ChromaDB = 'chromadb/chroma:latest'
        Echo = 'echo-agent:latest'
    }
    
    # Default ports
    Ports = @{
        Gateway = 3402
        Ollama = 11434
        ChromaDB = 8000
        Echo = 8080
    }
    
    # Traefik labels
    TraefikHost = 'x402.home.lab'
}

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

function Write-Banner {
    $banner = @"

╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║   ⚡ x402 GATEWAY INSTALLER                                                   ║
║   HTTP 402 Payment Required | Base Network | USDC                             ║
║                                                                               ║
║   Version: $($Config.Version)                                                        ║
║   Profile: $Profile                                                           ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

"@
    Write-Host $banner -ForegroundColor Cyan
}

function Test-Prerequisites {
    Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow
    
    # Check Docker
    try {
        $dockerVersion = docker --version
        Write-Host "  ✅ Docker: $dockerVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "  ❌ Docker not found. Please install Docker first." -ForegroundColor Red
        return $false
    }
    
    # Check Docker Compose
    try {
        $composeVersion = docker compose version
        Write-Host "  ✅ Docker Compose: $composeVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "  ❌ Docker Compose not found." -ForegroundColor Red
        return $false
    }
    
    # Check if ports are available
    foreach ($port in $Config.Ports.Values) {
        $inUse = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        if ($inUse) {
            Write-Host "  ⚠️ Port $port is already in use" -ForegroundColor Yellow
        }
    }
    
    return $true
}

function Initialize-Environment {
    Write-Host "`n📁 Initializing environment..." -ForegroundColor Yellow
    
    # Create data directories
    $dirs = @(
        "$($Config.DataDir)/gateway",
        "$($Config.DataDir)/ollama",
        "$($Config.DataDir)/chromadb",
        "$($Config.DataDir)/echo/data",
        "$($Config.DataDir)/echo/memories"
    )
    
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "  📂 Created: $dir" -ForegroundColor Gray
        }
    }
    
    # Copy .env.example if .env doesn't exist
    if (-not (Test-Path $Config.EnvFile)) {
        if (Test-Path $Config.EnvExample) {
            Copy-Item $Config.EnvExample $Config.EnvFile
            Write-Host "  📄 Created .env from template" -ForegroundColor Gray
            Write-Host "  ⚠️ Please edit .env with your settings!" -ForegroundColor Yellow
        }
        else {
            # Create minimal .env
            $envContent = @"
# x402 Gateway Configuration
PORT=3402
SERVER_WALLET_ADDRESS=0x...your-wallet-here
JWT_SECRET=$(New-Guid)

# Ollama
OLLAMA_HOST=http://ollama:11434
DEFAULT_MODEL=llama3.2:latest

# ChromaDB
CHROMADB_HOST=http://chromadb:8000

# Traefik
TRAEFIK_HOST=$($Config.TraefikHost)
"@
            Set-Content -Path $Config.EnvFile -Value $envContent
            Write-Host "  📄 Created minimal .env file" -ForegroundColor Gray
        }
    }
    
    Write-Host "  ✅ Environment initialized" -ForegroundColor Green
}

function Build-Images {
    Write-Host "`n🔨 Building images..." -ForegroundColor Yellow
    
    $gatewayDir = Join-Path $PSScriptRoot '..\docker\x402-gateway'
    $echoDir = Join-Path $PSScriptRoot '..\docker\agent'
    
    if (Test-Path $gatewayDir) {
        Write-Host "  🏗️ Building x402-gateway..." -ForegroundColor Gray
        docker build -t $Config.Images.Gateway $gatewayDir
    }
    
    if (Test-Path $echoDir) {
        Write-Host "  🏗️ Building echo-agent..." -ForegroundColor Gray
        docker build -t $Config.Images.Echo $echoDir
    }
    
    Write-Host "  ✅ Images built" -ForegroundColor Green
}

function Start-Stack {
    param([string]$Profile = 'standard')
    
    Write-Host "`n🚀 Starting x402 stack (Profile: $Profile)..." -ForegroundColor Yellow
    
    $composeArgs = @('compose', '-f', $Config.ComposeFile, '--env-file', $Config.EnvFile)
    
    switch ($Profile) {
        'minimal' {
            # Gateway only
            $composeArgs += @('up', '-d', 'x402-gateway')
        }
        'standard' {
            # Gateway + Ollama
            $composeArgs += @('up', '-d', 'x402-gateway', 'ollama')
        }
        'full' {
            # All services
            $composeArgs += @('--profile', 'agent', 'up', '-d')
        }
    }
    
    & docker @composeArgs
    
    Write-Host "`n  ✅ Stack started" -ForegroundColor Green
    
    # Show access info
    Write-Host "`n📡 Access Points:" -ForegroundColor Cyan
    Write-Host "  • Gateway:  http://localhost:$($Config.Ports.Gateway)" -ForegroundColor Gray
    Write-Host "  • Traefik:  https://$($Config.TraefikHost)" -ForegroundColor Gray
    
    if ($Profile -in @('standard', 'full')) {
        Write-Host "  • Ollama:   http://localhost:$($Config.Ports.Ollama)" -ForegroundColor Gray
    }
    
    if ($Profile -eq 'full') {
        Write-Host "  • ChromaDB: http://localhost:$($Config.Ports.ChromaDB)" -ForegroundColor Gray
        Write-Host "  • Echo:     http://localhost:$($Config.Ports.Echo)" -ForegroundColor Gray
    }
}

function Stop-Stack {
    Write-Host "`n🛑 Stopping x402 stack..." -ForegroundColor Yellow
    
    docker compose -f $Config.ComposeFile down
    
    Write-Host "  ✅ Stack stopped" -ForegroundColor Green
}

function Get-StackStatus {
    Write-Host "`n📊 x402 Stack Status:" -ForegroundColor Cyan
    
    docker compose -f $Config.ComposeFile ps
    
    Write-Host "`n📈 Resource Usage:" -ForegroundColor Cyan
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | 
        Select-String -Pattern "x402|ollama|chromadb|echo"
}

function Show-Logs {
    param([string]$Service = '')
    
    $args = @('compose', '-f', $Config.ComposeFile, 'logs', '-f', '--tail', '100')
    
    if ($Service) {
        $args += $Service
    }
    
    & docker @args
}

function Uninstall-Stack {
    Write-Host "`n🗑️ Uninstalling x402 stack..." -ForegroundColor Yellow
    
    # Stop and remove containers
    docker compose -f $Config.ComposeFile down -v
    
    if ($Force) {
        # Remove images
        Write-Host "  🗑️ Removing images..." -ForegroundColor Gray
        docker rmi $Config.Images.Gateway $Config.Images.Echo -f 2>$null
        
        # Remove data
        Write-Host "  🗑️ Removing data..." -ForegroundColor Gray
        Remove-Item -Path $Config.DataDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "  ✅ Uninstall complete" -ForegroundColor Green
}

function Show-ConfigurationWizard {
    Write-Host "`n⚙️ Configuration Wizard" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    
    # Wallet address
    $wallet = Read-Host "Enter your Base wallet address (receives payments)"
    
    # JWT Secret
    $jwtSecret = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
    
    # Traefik host
    $traefikHost = Read-Host "Enter Traefik hostname (default: x402.home.lab)"
    if (-not $traefikHost) { $traefikHost = 'x402.home.lab' }
    
    # Update .env
    $envContent = @"
# x402 Gateway Configuration
# Generated by install-x402.ps1

# Server
PORT=3402
NODE_ENV=production

# Wallet (receives payments)
SERVER_WALLET_ADDRESS=$wallet

# Security
JWT_SECRET=$jwtSecret

# Network
BASE_RPC_URL=https://mainnet.base.org

# LLM
OLLAMA_HOST=http://ollama:11434
DEFAULT_MODEL=llama3.2:latest

# Memory
CHROMADB_HOST=http://chromadb:8000
MEMORY_COLLECTION=echo_memories

# Traefik
TRAEFIK_HOST=$traefikHost

# Logging
LOG_LEVEL=INFO
JSON_LOGS=true
"@

    Set-Content -Path $Config.EnvFile -Value $envContent
    Write-Host "`n  ✅ Configuration saved to .env" -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

Write-Banner

switch ($Action) {
    'install' {
        if (-not (Test-Prerequisites)) {
            exit 1
        }
        Initialize-Environment
        Build-Images
        Start-Stack -Profile $Profile
    }
    
    'configure' {
        Show-ConfigurationWizard
    }
    
    'start' {
        Start-Stack -Profile $Profile
    }
    
    'stop' {
        Stop-Stack
    }
    
    'status' {
        Get-StackStatus
    }
    
    'logs' {
        Show-Logs
    }
    
    'uninstall' {
        Uninstall-Stack
    }
}

Write-Host "`n✨ Done!" -ForegroundColor Green
