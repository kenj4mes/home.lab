<#
.SYNOPSIS
    HomeLab Unified CLI - Single command for all operations
.DESCRIPTION
    HomeLab - Self-Hosted Infrastructure
    
    Unified CLI for managing HomeLab services:
    - Start/stop/restart containers
    - View status and logs
    - Update images
    - Reset to clean state
.PARAMETER Action
    Action to perform: start, stop, status, logs, restart, update, reset, pull, health, quantum, base, monitoring
.PARAMETER Service
    Optional: Specific service name (e.g., jellyfin, ollama)
.PARAMETER ComposeFile
    Docker compose file to use (default: docker-compose.yml)
.PARAMETER Json
    Output status in JSON format
.PARAMETER WhatIf
    Show what would happen without making changes
.EXAMPLE
    .\homelab.ps1 -Action start
    .\homelab.ps1 -Action status -Json
    .\homelab.ps1 -Action logs -Service jellyfin
    .\homelab.ps1 -Action restart -Service ollama
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet('start', 'stop', 'status', 'logs', 'restart', 'update', 'reset', 'pull', 'health', 'quantum', 'base', 'monitoring', 'install', 'web3', 'agents', 'trellis', 'sdr', 'matrix', 'creative', 'pqtls', 'superchain')]
    [string]$Action,
    
    [Parameter(Position=1)]
    [string]$Service = '',
    
    [string]$ComposeFile = '',
    
    [switch]$Json,
    
    [switch]$Follow,
    
    [switch]$All,
    
    [int]$Tail = 100
)

# ==============================================================================
# CONFIGURATION
# ==============================================================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DockerDir = Join-Path $ScriptDir "docker"

# Determine compose file
if (-not $ComposeFile) {
    if ($env:OS -match "Windows") {
        $ComposeFile = "docker-compose.windows.yml"
    } else {
        $ComposeFile = "docker-compose.yml"
    }
}

$ComposeFilePath = Join-Path $DockerDir $ComposeFile

# Logging
$LogDir = "C:\HomeLab\logs"
$LogFile = Join-Path $LogDir "homelab-cli.log"

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
    
    switch ($Level) {
        "SUCCESS" { Write-Host "[OK] $Message" -ForegroundColor Green }
        "WARN"    { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "[ERR] $Message" -ForegroundColor Red }
        default   { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
    }
}

function Test-DockerRunning {
    try {
        $null = docker info 2>&1
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Start-DockerDesktop {
    $dockerPath = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        Write-Log "Starting Docker Desktop..."
        Start-Process $dockerPath
        
        for ($i = 0; $i -lt 30; $i++) {
            Start-Sleep -Seconds 2
            if (Test-DockerRunning) {
                Write-Log "Docker Desktop is ready" "SUCCESS"
                return $true
            }
        }
    }
    return $false
}

function Invoke-Compose {
    param([string[]]$Arguments)
    
    Push-Location $DockerDir
    try {
        $cmd = "docker compose -f $ComposeFile $($Arguments -join ' ')"
        Write-Log "Running: $cmd"
        
        if ($WhatIfPreference) {
            Write-Host "[WhatIf] Would run: $cmd" -ForegroundColor Yellow
            return
        }
        
        Invoke-Expression $cmd
    } finally {
        Pop-Location
    }
}

function Invoke-DockerCompose {
    param(
        [string]$ComposeFilePath,
        [string[]]$Arguments
    )
    # Wrapper to properly handle Docker Compose output without false exit codes
    $env:COMPOSE_PROJECT_NAME = "homelab"
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "docker"
    $pinfo.Arguments = "compose -f $ComposeFilePath $($Arguments -join ' ')"
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $pinfo
    $process.Start() | Out-Null
    
    # Read output streams
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    
    # Display combined output (Docker uses stderr for progress)
    if ($stdout) { Write-Host $stdout }
    if ($stderr) { Write-Host $stderr -ForegroundColor Cyan }
    
    return $process.ExitCode
}

function Get-ContainerStatus {
    $containers = docker compose -f (Join-Path $DockerDir $ComposeFile) ps --format json 2>$null | 
        ConvertFrom-Json -ErrorAction SilentlyContinue
    
    if ($Json) {
        if ($Service) {
            $containers | Where-Object { $_.Service -eq $Service } | ConvertTo-Json
        } else {
            $containers | ConvertTo-Json
        }
    } else {
        Write-Host ""
        Write-Host "===============================================================" -ForegroundColor Cyan
        Write-Host "                    HomeLab Container Status                    " -ForegroundColor Cyan
        Write-Host "===============================================================" -ForegroundColor Cyan
        Write-Host ""
        
        if ($containers) {
            foreach ($c in $containers) {
                $status = $c.State
                $health = if ($c.Health) { "($($c.Health))" } else { "" }
                
                $color = switch ($status) {
                    "running" { "Green" }
                    "exited"  { "Red" }
                    default   { "Yellow" }
                }
                
                Write-Host ("  {0,-20} {1,-12} {2}" -f $c.Service, $status, $health) -ForegroundColor $color
            }
        } else {
            Write-Host "  No containers found" -ForegroundColor Yellow
        }
        
        Write-Host ""
    }
}

function Get-ContainerHealth {
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host "                    Container Health Checks                     " -ForegroundColor Cyan
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $services = @{
        "Jellyfin"    = @{ Port = 8096; Path = "/health"; Method = "GET" }
        "qBittorrent" = @{ Port = 8080; Path = "/"; Method = "GET" }
        "Kiwix"       = @{ Port = 8081; Path = "/"; Method = "GET" }
        "BookStack"   = @{ Port = 8082; Path = "/"; Method = "GET" }
        "Open-WebUI"  = @{ Port = 3000; Path = "/"; Method = "GET" }
        "Portainer"   = @{ Port = 9000; Path = "/"; Method = "GET" }
        "Ollama"      = @{ Port = 11434; Path = "/api/tags"; Method = "GET" }
        "Quantum-RNG" = @{ Port = 5001; Path = "/health"; Method = "GET" }
        "Q-Simulator" = @{ Port = 5002; Path = "/health"; Method = "GET" }
        "Base-RPC"    = @{ Port = 8545; Path = "/"; Method = "JSONRPC" }
        "Prometheus"  = @{ Port = 9090; Path = "/-/healthy"; Method = "GET" }
        "Grafana"     = @{ Port = 3100; Path = "/api/health"; Method = "GET" }
        "Anvil"       = @{ Port = 8547; Path = "/"; Method = "JSONRPC" }
        "Hardhat"     = @{ Port = 8545; Path = "/"; Method = "JSONRPC" }
        "Agents"      = @{ Port = 5004; Path = "/health"; Method = "GET" }
        "ChromaDB"    = @{ Port = 8000; Path = "/api/v2/heartbeat"; Method = "GET" }
        "TRELLIS"     = @{ Port = 5003; Path = "/health"; Method = "GET" }
        "SDR-Dash"    = @{ Port = 8585; Path = "/health"; Method = "GET" }
        "Rayhunter"   = @{ Port = 8580; Path = "/health"; Method = "GET" }
        "Element"     = @{ Port = 8480; Path = "/"; Method = "GET" }
        "Synapse"     = @{ Port = 8008; Path = "/health"; Method = "GET" }
        # Creative AI Services
        "Stable-Diff" = @{ Port = 7860; Path = "/sdapi/v1/options"; Method = "GET" }
        "ComfyUI"     = @{ Port = 8188; Path = "/"; Method = "GET" }
        "Bark-TTS"    = @{ Port = 5010; Path = "/health"; Method = "GET" }
        "Whisper"     = @{ Port = 5011; Path = "/health"; Method = "GET" }
        "MusicGen"    = @{ Port = 5012; Path = "/health"; Method = "GET" }
        "Video-Diff"  = @{ Port = 5013; Path = "/health"; Method = "GET" }
        "Creative-UI" = @{ Port = 8190; Path = "/"; Method = "GET" }
        # Security Services
        "PQ-NGINX"    = @{ Port = 443; Path = "/health"; Method = "HTTPS" }
        "Vault"       = @{ Port = 8200; Path = "/v1/sys/health"; Method = "GET" }
        # Superchain Services
        "Base-L2"     = @{ Port = 8545; Path = "/"; Method = "JSONRPC" }
        "OP-Mainnet"  = @{ Port = 8555; Path = "/"; Method = "JSONRPC" }
        "Unichain"    = @{ Port = 8565; Path = "/"; Method = "JSONRPC" }
        "Mode"        = @{ Port = 8575; Path = "/"; Method = "JSONRPC" }
        "World-Chain" = @{ Port = 8585; Path = "/"; Method = "JSONRPC" }
        "Lisk-L2"     = @{ Port = 8595; Path = "/"; Method = "JSONRPC" }
        "Chain-UI"    = @{ Port = 8600; Path = "/"; Method = "GET" }
    }
    
    foreach ($svc in $services.GetEnumerator()) {
        $url = "http://localhost:$($svc.Value.Port)$($svc.Value.Path)"
        try {
            if ($svc.Value.Method -eq "JSONRPC") {
                # JSON-RPC endpoints need POST with body
                $body = '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
                $response = Invoke-WebRequest -Uri $url -Method POST -Body $body -ContentType "application/json" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            } elseif ($svc.Value.Method -eq "HTTPS") {
                # HTTPS endpoints (ignore cert errors for self-signed)
                $url = "https://localhost:$($svc.Value.Port)$($svc.Value.Path)"
                try {
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
                    $response = Invoke-WebRequest -Uri $url -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
                } finally {
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
                }
            } else {
                $response = Invoke-WebRequest -Uri $url -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            }
            Write-Host ("  {0,-15} [OK] Healthy (HTTP {1})" -f $svc.Key, $response.StatusCode) -ForegroundColor Green
        } catch {
            Write-Host ("  {0,-15} [--] Not running" -f $svc.Key) -ForegroundColor DarkGray
        }
    }
    
    Write-Host ""
}

function Start-QuantumServices {
    param([switch]$Build)
    
    Write-Log "Starting Quantum services..."
    $env:COMPOSE_IGNORE_ORPHANS = "true"
    Push-Location $DockerDir
    try {
        if ($Build) {
            docker compose -f docker-compose.quantum.yml build
        }
        docker compose -f docker-compose.quantum.yml up -d
    } finally {
        Pop-Location
    }
    Write-Log "Quantum services started" "SUCCESS"
    
    Write-Host ""
    Write-Host "Quantum Services:" -ForegroundColor Cyan
    Write-Host "  Quantum RNG:       http://localhost:5001"
    Write-Host "  Quantum Simulator: http://localhost:5002"
    Write-Host ""
    Write-Host "Quick Test:" -ForegroundColor Yellow
    Write-Host "  curl http://localhost:5001/random/32"
    Write-Host "  curl http://localhost:5002/health"
    Write-Host ""
}

function Start-BaseServices {
    Write-Log "Starting Base blockchain services..."
    $env:COMPOSE_IGNORE_ORPHANS = "true"
    Push-Location $DockerDir
    try {
        docker compose -f docker-compose.base.yml up -d
    } finally {
        Pop-Location
    }
    Write-Log "Base blockchain services started" "SUCCESS"
    
    Write-Host ""
    Write-Host "Base Blockchain Services:" -ForegroundColor Cyan
    Write-Host "  Base RPC:    http://localhost:8545"
    Write-Host "  Explorer:    http://localhost:4000"
    Write-Host "  Wallet API:  http://localhost:5000"
    Write-Host ""
}

function Start-MonitoringServices {
    Write-Log "Starting Monitoring services..."
    $env:COMPOSE_IGNORE_ORPHANS = "true"
    Push-Location $DockerDir
    try {
        docker compose -f docker-compose.monitoring.yml up -d
    } finally {
        Pop-Location
    }
    Write-Log "Monitoring services started" "SUCCESS"
    
    Write-Host ""
    Write-Host "Monitoring Services:" -ForegroundColor Cyan
    Write-Host "  Prometheus:  http://localhost:9090"
    Write-Host "  Grafana:     http://localhost:3100"
    Write-Host "  Loki:        http://localhost:3101"
    Write-Host ""
}

function Start-Web3Services {
    param([switch]$Build)
    
    Write-Log "Starting Web3 development services..."
    $env:COMPOSE_IGNORE_ORPHANS = "true"
    Push-Location $DockerDir
    try {
        if ($Build) {
            docker compose -f docker-compose.dev.yml build
        }
        docker compose -f docker-compose.dev.yml up -d
    } finally {
        Pop-Location
    }
    Write-Log "Web3 development services started" "SUCCESS"
    
    Write-Host ""
    Write-Host "Web3 Development Services:" -ForegroundColor Cyan
    Write-Host "  Anvil (Local Chain):   http://localhost:8547"
    Write-Host "  Hardhat Node:          http://localhost:8545"
    Write-Host "  Blockscout Dev:        http://localhost:4001"
    Write-Host ""
    Write-Host "Quick Commands:" -ForegroundColor Yellow
    Write-Host "  forge build            # Build contracts"
    Write-Host "  npx hardhat compile    # Compile with Hardhat"
    Write-Host "  cast send <addr> ...   # Send transactions"
    Write-Host ""
}

function Start-AgentServices {
    param([switch]$Build)
    
    Write-Log "Starting AI Agent services..."
    $env:COMPOSE_IGNORE_ORPHANS = "true"
    Push-Location $DockerDir
    try {
        if ($Build) {
            docker compose -f docker-compose.agents.yml build
        }
        docker compose -f docker-compose.agents.yml up -d
    } finally {
        Pop-Location
    }
    Write-Log "AI Agent services started" "SUCCESS"
    
    Write-Host ""
    Write-Host "AI Agent Services:" -ForegroundColor Cyan
    Write-Host "  Agent Orchestrator:  http://localhost:5004"
    Write-Host "  MCP Server:          http://localhost:5005"
    Write-Host "  ChromaDB:            http://localhost:8000"
    Write-Host ""
    Write-Host "Quick Test:" -ForegroundColor Yellow
    Write-Host "  curl -X POST http://localhost:5004/agent/run -H 'Content-Type: application/json' -d '{\"query\": \"Hello\"}'"
    Write-Host ""
}

function Start-TrellisService {
    Write-Log "Starting TRELLIS.2 3D Generation service..."
    $env:COMPOSE_IGNORE_ORPHANS = "true"
    
    # Check for GPU
    $hasGpu = $false
    try {
        $gpuInfo = docker run --rm --gpus all nvidia/cuda:12.4-base nvidia-smi 2>&1
        if ($LASTEXITCODE -eq 0) {
            $hasGpu = $true
        }
    } catch {
        $hasGpu = $false
    }
    
    if (-not $hasGpu) {
        Write-Log "WARNING: No GPU detected. TRELLIS.2 requires 24GB+ GPU VRAM." "WARN"
        $confirm = Read-Host "Continue anyway? (y/N)"
        if ($confirm -notmatch "^[Yy]") {
            Write-Log "TRELLIS startup cancelled" "WARN"
            return
        }
    }
    
    Push-Location $DockerDir
    try {
        docker compose -f docker-compose.dev.yml --profile gpu up -d trellis-3d
    } finally {
        Pop-Location
    }
    Write-Log "TRELLIS.2 service started" "SUCCESS"
    
    Write-Host ""
    Write-Host "TRELLIS.2 3D Generation:" -ForegroundColor Cyan
    Write-Host "  API Endpoint:    http://localhost:5003"
    Write-Host "  Gradio UI:       http://localhost:7860"
    Write-Host ""
    Write-Host "Quick Test:" -ForegroundColor Yellow
    Write-Host "  curl -X POST http://localhost:5003/generate -F 'image=@photo.png' -F 'format=glb'"
    Write-Host ""
}

function Start-SDRServices {
    param([switch]$Build)
    
    Write-Log "Starting SDR & Radio Security services..."
    $env:COMPOSE_IGNORE_ORPHANS = "true"
    
    Write-Host ""
    Write-Host "⚠️  LEGAL WARNING ⚠️" -ForegroundColor Red
    Write-Host "  These tools are for SECURITY RESEARCH ONLY." -ForegroundColor Yellow
    Write-Host "  Check local laws before using cellular monitoring tools." -ForegroundColor Yellow
    Write-Host "  We are not responsible for any illegal use." -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Do you understand and accept responsibility? (y/N)"
    if ($confirm -notmatch "^[Yy]") {
        Write-Log "SDR services startup cancelled" "WARN"
        return
    }
    
    Push-Location $DockerDir
    try {
        if ($Build) {
            docker compose -f docker-compose.sdr.yml --profile sdr build
        }
        docker compose -f docker-compose.sdr.yml --profile sdr up -d
    } finally {
        Pop-Location
    }
    Write-Log "SDR services started" "SUCCESS"
    
    Write-Host ""
    Write-Host "SDR & Radio Security Services:" -ForegroundColor Cyan
    Write-Host "  SDR Dashboard:     http://localhost:8585"
    Write-Host "  Rayhunter:         http://localhost:8580"
    Write-Host "  IMSI Catcher:      (host network - logs only)"
    Write-Host "  LTESniffer:        (host network - pcap output)"
    Write-Host ""
    Write-Host "Documentation:" -ForegroundColor Yellow
    Write-Host "  See docs/SDR.md for hardware requirements and usage"
    Write-Host ""
}

function Start-MatrixServices {
    Write-Log "Starting Matrix Synapse services..."
    $env:COMPOSE_IGNORE_ORPHANS = "true"
    Push-Location $DockerDir
    try {
        docker compose -f docker-compose.matrix.yml up -d
    } finally {
        Pop-Location
    }
    Write-Log "Matrix Synapse services started" "SUCCESS"
    
    Write-Host ""
    Write-Host "Matrix Communication Services:" -ForegroundColor Cyan
    Write-Host "  Element Web:    http://localhost:8480"
    Write-Host "  Synapse API:    http://localhost:8008"
    Write-Host "  Federation:     http://localhost:8448"
    Write-Host "  TURN Server:    localhost:3478/5349"
    Write-Host ""
    Write-Host "First-time Setup:" -ForegroundColor Yellow
    Write-Host "  1. Generate config: docker exec synapse /start.py generate"
    Write-Host "  2. Create user: docker exec synapse register_new_matrix_user -c /config/homeserver.yaml"
    Write-Host "  3. See docs/MATRIX.md for federation and security setup"
    Write-Host ""
}

function Start-CreativeServices {
    Write-Log "Starting Creative AI services..."
    $env:COMPOSE_IGNORE_ORPHANS = "true"
    Push-Location $DockerDir
    try {
        # Check for GPU availability
        $gpuAvailable = $false
        try {
            $nvidiaTest = docker run --rm --gpus all nvidia/cuda:12.1-base nvidia-smi 2>&1
            if ($LASTEXITCODE -eq 0) { $gpuAvailable = $true }
        } catch { }
        
        if ($gpuAvailable) {
            Write-Log "GPU detected, starting with GPU acceleration" "SUCCESS"
            docker compose -f docker-compose.creative.yml --profile gpu up -d
        } else {
            Write-Log "No GPU detected, starting in CPU mode (limited functionality)" "WARN"
            docker compose -f docker-compose.creative.yml up -d
        }
    } finally {
        Pop-Location
    }
    Write-Log "Creative AI services started" "SUCCESS"
    
    Write-Host ""
    Write-Host "Creative AI Services:" -ForegroundColor Cyan
    Write-Host "  Stable Diffusion:  http://localhost:7860   (text-to-image)"
    Write-Host "  ComfyUI:           http://localhost:8188   (node workflows)"
    Write-Host "  Bark TTS:          http://localhost:5010   (text-to-speech)"
    Write-Host "  Faster-Whisper:    http://localhost:5011   (speech-to-text)"
    Write-Host "  MusicGen:          http://localhost:5012   (AI music)"
    Write-Host "  Video Diffusion:   http://localhost:5013   (image-to-video)"
    Write-Host "  Creative Dashboard: http://localhost:8190  (unified UI)"
    Write-Host ""
    Write-Host "GPU Requirements:" -ForegroundColor Yellow
    Write-Host "  - Stable Diffusion: 4-8GB VRAM"
    Write-Host "  - Video Diffusion: 12-24GB VRAM"
    Write-Host "  - See docs/CREATIVE.md for details"
    Write-Host ""
}

function Start-PQTLSServices {
    Write-Log "Starting Post-Quantum TLS services..."
    $env:COMPOSE_IGNORE_ORPHANS = "true"
    Push-Location $DockerDir
    try {
        # Check if certificates exist
        $certPath = Join-Path $ScriptDir "configs\pq-nginx\certs\fullchain.pem"
        if (-not (Test-Path $certPath)) {
            Write-Log "Generating PQ-TLS certificates..." "INFO"
            docker compose -f docker-compose.pqtls.yml --profile setup up pq-cert-gen
        }
        
        docker compose -f docker-compose.pqtls.yml --profile pqtls up -d
    } finally {
        Pop-Location
    }
    Write-Log "Post-Quantum TLS services started" "SUCCESS"
    
    Write-Host ""
    Write-Host "Post-Quantum TLS Services:" -ForegroundColor Cyan
    Write-Host "  PQ-NGINX:     https://localhost (port 443)"
    Write-Host "  Vault:        http://localhost:8200"
    Write-Host ""
    Write-Host "Security Features:" -ForegroundColor Green
    Write-Host "  - Hybrid key exchange: X25519 + Kyber768"
    Write-Host "  - TLS 1.3 with post-quantum algorithms"
    Write-Host "  - HashiCorp Vault for secrets management"
    Write-Host ""
    Write-Host "First-time Setup:" -ForegroundColor Yellow
    Write-Host "  1. Initialize Vault: docker exec vault vault operator init"
    Write-Host "  2. Save unseal keys securely!"
    Write-Host "  3. See docs/PQTLS.md for configuration"
    Write-Host ""
}

function Start-SuperchainServices {
    param(
        [string]$Chain = "base"
    )
    
    Write-Log "Starting Superchain services ($Chain)..."
    $env:COMPOSE_IGNORE_ORPHANS = "true"
    Push-Location $DockerDir
    try {
        # Check if L1 RPC is configured
        $envFile = Join-Path $DockerDir ".env"
        if (Test-Path $envFile) {
            $envContent = Get-Content $envFile -Raw
            if ($envContent -notmatch "L1_RPC_URL") {
                Write-Log "L1_RPC_URL not configured - using public RPC (rate-limited)" "WARN"
            }
        }
        
        # Valid profiles
        $validProfiles = @("base", "op-mainnet", "unichain", "mode", "world", "lisk", "multi", "explorer", "monitoring")
        if ($Chain -notin $validProfiles) {
            $Chain = "base"
        }
        
        docker compose -f docker-compose.superchain.yml --profile $Chain up -d
    } finally {
        Pop-Location
    }
    Write-Log "Superchain services started" "SUCCESS"
    
    # Port info based on chain
    $portInfo = switch ($Chain) {
        "base"       { "RPC: 8545 | WS: 8546 | P2P: 9222" }
        "op-mainnet" { "RPC: 8555 | WS: 8556 | P2P: 9232" }
        "unichain"   { "RPC: 8565 | WS: 8566 | P2P: 9242" }
        "mode"       { "RPC: 8575 | WS: 8576 | P2P: 9252" }
        "world"      { "RPC: 8585 | WS: 8586 | P2P: 9262" }
        "lisk"       { "RPC: 8595 | WS: 8596 | P2P: 9272" }
        "multi"      { "All chains - see docs/SUPERCHAIN.md" }
        default      { "Dashboard: 8600" }
    }
    
    Write-Host ""
    Write-Host "Superchain Services ($Chain):" -ForegroundColor Cyan
    Write-Host "  $portInfo"
    Write-Host "  Dashboard:    http://localhost:8600"
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Green
    Write-Host "  Check sync:   curl -X POST http://localhost:8545 -H 'Content-Type: application/json' -d '{`"jsonrpc`":`"2.0`",`"method`":`"eth_syncing`",`"params`":[],`"id`":1}'"
    Write-Host "  Clone repos:  .\scripts\clone-superchain.ps1"
    Write-Host ""
    Write-Host "Available Profiles:" -ForegroundColor Yellow
    Write-Host "  base, op-mainnet, unichain, mode, world, lisk, multi, explorer"
    Write-Host "  Use: .\homelab.ps1 -Action superchain -Service <profile>"
    Write-Host ""
}

function Start-AllServices {
    Write-Log "Starting ALL HomeLab services..."
    $env:COMPOSE_IGNORE_ORPHANS = "true"
    Push-Location $DockerDir
    try {
        # Core services
        docker compose -f $ComposeFile up -d
        
        # Additional stacks
        docker compose -f docker-compose.base.yml up -d 2>$null
        docker compose -f docker-compose.monitoring.yml up -d 2>$null
        docker compose -f docker-compose.quantum.yml build 2>$null
        docker compose -f docker-compose.quantum.yml up -d 2>$null
        docker compose -f docker-compose.dev.yml up -d 2>$null
        docker compose -f docker-compose.agents.yml up -d 2>$null
    } finally {
        Pop-Location
    }
    Write-Log "All services started" "SUCCESS"
}

# ==============================================================================
# MAIN
# ==============================================================================

# Banner
if (-not $Json) {
    Write-Host ""
    Write-Host "+==============================================================+" -ForegroundColor Blue
    Write-Host "|                    🏠 HomeLab CLI                            |" -ForegroundColor Blue
    Write-Host "+==============================================================+" -ForegroundColor Blue
    Write-Host ""
}

# Check Docker
if (-not (Test-DockerRunning)) {
    Write-Log "Docker is not running" "WARN"
    
    if (-not (Start-DockerDesktop)) {
        Write-Log "Failed to start Docker Desktop. Please start it manually." "ERROR"
        exit 1
    }
}

# Verify compose file exists
if (-not (Test-Path $ComposeFilePath)) {
    Write-Log "Compose file not found: $ComposeFilePath" "ERROR"
    exit 1
}

# Execute action
switch ($Action) {
    'start' {
        if ($All) {
            if ($PSCmdlet.ShouldProcess("All services", "Start")) {
                Start-AllServices
            }
        } elseif ($Service) {
            Write-Log "Starting service: $Service"
            if ($PSCmdlet.ShouldProcess($Service, "Start container")) {
                Invoke-Compose @("up", "-d", $Service)
            }
        } else {
            Write-Log "Starting core services"
            if ($PSCmdlet.ShouldProcess("Core containers", "Start")) {
                Invoke-Compose @("up", "-d")
            }
        }
        Write-Log "Services started" "SUCCESS"
    }
    
    'stop' {
        if ($All) {
            Write-Log "Stopping all services..."
            Push-Location $DockerDir
            try {
                docker compose -f $ComposeFile down 2>$null
                docker compose -f docker-compose.base.yml down 2>$null
                docker compose -f docker-compose.monitoring.yml down 2>$null
                docker compose -f docker-compose.quantum.yml down 2>$null
            } finally {
                Pop-Location
            }
            Write-Log "All services stopped" "SUCCESS"
        } elseif ($Service) {
            Write-Log "Stopping service: $Service"
            if ($PSCmdlet.ShouldProcess($Service, "Stop container")) {
                Invoke-Compose @("stop", $Service)
            }
        } else {
            Write-Log "Stopping core services"
            if ($PSCmdlet.ShouldProcess("Core containers", "Stop")) {
                Invoke-Compose @("down")
            }
        }
        Write-Log "Services stopped" "SUCCESS"
    }
    
    'quantum' {
        if ($PSCmdlet.ShouldProcess("Quantum services", "Start")) {
            Start-QuantumServices -Build
        }
    }
    
    'base' {
        if ($PSCmdlet.ShouldProcess("Base blockchain services", "Start")) {
            Start-BaseServices
        }
    }
    
    'monitoring' {
        if ($PSCmdlet.ShouldProcess("Monitoring services", "Start")) {
            Start-MonitoringServices
        }
    }
    
    'web3' {
        if ($PSCmdlet.ShouldProcess("Web3 development services", "Start")) {
            Start-Web3Services -Build
        }
    }
    
    'agents' {
        if ($PSCmdlet.ShouldProcess("AI Agent services", "Start")) {
            Start-AgentServices -Build
        }
    }
    
    'trellis' {
        if ($PSCmdlet.ShouldProcess("TRELLIS.2 3D Generation", "Start")) {
            Start-TrellisService
        }
    }
    
    'sdr' {
        if ($PSCmdlet.ShouldProcess("SDR & Radio Security services", "Start")) {
            Start-SDRServices -Build
        }
    }
    
    'matrix' {
        if ($PSCmdlet.ShouldProcess("Matrix Synapse services", "Start")) {
            Start-MatrixServices
        }
    }
    
    'creative' {
        if ($PSCmdlet.ShouldProcess("Creative AI services", "Start")) {
            Start-CreativeServices
        }
    }
    
    'pqtls' {
        if ($PSCmdlet.ShouldProcess("Post-Quantum TLS services", "Start")) {
            Start-PQTLSServices
        }
    }
    
    'superchain' {
        if ($PSCmdlet.ShouldProcess("Superchain services", "Start")) {
            $chain = if ($Service) { $Service } else { "base" }
            Start-SuperchainServices -Chain $chain
        }
    }
    
    'install' {
        Write-Host ""
        Write-Host "HomeLab Full Installation" -ForegroundColor Cyan
        Write-Host "=========================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "This will start all HomeLab services including:" -ForegroundColor Yellow
        Write-Host "  - Core services (Jellyfin, Kiwix, BookStack, Ollama, etc.)"
        Write-Host "  - Monitoring stack (Prometheus, Grafana, Loki)"
        Write-Host "  - Base blockchain (RPC, Explorer, Wallet API)"
        Write-Host "  - Quantum services (QRNG, Simulator)"
        Write-Host ""
        
        if ($PSCmdlet.ShouldProcess("Full HomeLab installation", "Install and start")) {
            $confirm = Read-Host "Proceed with full installation? (y/N)"
            if ($confirm -match "^[Yy]") {
                Start-AllServices
                Get-ContainerHealth
            } else {
                Write-Log "Installation cancelled" "WARN"
            }
        }
    }
    
    'restart' {
        if ($Service) {
            Write-Log "Restarting service: $Service"
            if ($PSCmdlet.ShouldProcess($Service, "Restart container")) {
                Invoke-Compose @("restart", $Service)
            }
        } else {
            Write-Log "Restarting all services"
            if ($PSCmdlet.ShouldProcess("All containers", "Restart")) {
                Invoke-Compose @("restart")
            }
        }
        Write-Log "Services restarted" "SUCCESS"
    }
    
    'status' {
        Get-ContainerStatus
    }
    
    'health' {
        Get-ContainerHealth
    }
    
    'logs' {
        $logArgs = @("logs")
        if ($Follow) { $logArgs += "-f" }
        $logArgs += "--tail=$Tail"
        if ($Service) { $logArgs += $Service }
        
        Invoke-Compose $logArgs
    }
    
    'pull' {
        Write-Log "Pulling latest images..."
        if ($PSCmdlet.ShouldProcess("Docker images", "Pull latest")) {
            Invoke-Compose @("pull")
        }
        Write-Log "Images updated" "SUCCESS"
    }
    
    'update' {
        Write-Log "Updating services (pull + restart)..."
        if ($PSCmdlet.ShouldProcess("All services", "Update")) {
            Invoke-Compose @("pull")
            Invoke-Compose @("up", "-d")
        }
        Write-Log "Services updated" "SUCCESS"
    }
    
    'reset' {
        Write-Host ""
        Write-Host "[WARN]️  WARNING: This will delete all container data and volumes!" -ForegroundColor Red
        Write-Host ""
        
        if ($PSCmdlet.ShouldProcess("All containers and volumes", "Reset/Delete")) {
            $confirm = Read-Host "Type 'YES' to confirm reset"
            if ($confirm -eq 'YES') {
                Write-Log "Resetting HomeLab..."
                Invoke-Compose @("down", "-v")
                Invoke-Compose @("up", "-d")
                Write-Log "HomeLab reset complete" "SUCCESS"
            } else {
                Write-Log "Reset cancelled" "WARN"
            }
        }
    }
}

# Show quick tips
if (-not $Json -and $Action -in @('start', 'restart', 'update', 'install')) {
    Write-Host ""
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "Quick Access:" -ForegroundColor Yellow
    Write-Host "  Jellyfin:    http://localhost:8096"
    Write-Host "  Open WebUI:  http://localhost:3000"
    Write-Host "  Portainer:   http://localhost:9000"
    Write-Host "  BookStack:   http://localhost:8082"
    Write-Host ""
    Write-Host "Extended Services:" -ForegroundColor Yellow
    Write-Host "  .\homelab.ps1 quantum     # Start Quantum (QRNG + Simulator)"
    Write-Host "  .\homelab.ps1 base        # Start Base Blockchain"
    Write-Host "  .\homelab.ps1 monitoring  # Start Prometheus/Grafana"
    Write-Host "  .\homelab.ps1 web3        # Start Web3 Dev (Anvil/Hardhat)"
    Write-Host "  .\homelab.ps1 agents      # Start AI Agents (LangGraph/CrewAI)"
    Write-Host "  .\homelab.ps1 trellis     # Start TRELLIS.2 (Image-to-3D)"
    Write-Host "  .\homelab.ps1 start -All  # Start ALL services"
    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}
