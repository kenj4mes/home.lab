<#
.SYNOPSIS
    SOVEREIGN AGENT - One-Click Launcher (Windows PowerShell)

.DESCRIPTION
    Sets up Python environment, installs dependencies, and starts the agent.

.EXAMPLE
    .\start.ps1           # Full agent mode
    .\start.ps1 -demo     # Demo mode (no wallet required)
    .\start.ps1 -cli      # Interactive CLI
    .\start.ps1 -server   # API server mode
#>

param(
    [switch]$demo,
    [switch]$cli,
    [switch]$server,
    [switch]$status
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

function Write-Banner {
    Write-Host ""
    Write-Host "  ECHO - SOVEREIGN AGENT" -ForegroundColor Cyan
    Write-Host "  =============================" -ForegroundColor Cyan
    Write-Host "  Self-Custody | Collective Intelligence | Infinite Evolution" -ForegroundColor DarkCyan
    Write-Host ""
}

function Find-Python {
    $pythonPaths = @(
        "$ScriptDir\.venv\Scripts\python.exe",
        "$ScriptDir\..\.venv\Scripts\python.exe",
        "C:\ev0\.venv\Scripts\python.exe",
        (Get-Command python -ErrorAction SilentlyContinue).Source,
        (Get-Command python3 -ErrorAction SilentlyContinue).Source
    )
    
    foreach ($path in $pythonPaths) {
        if ($path -and (Test-Path $path)) {
            return $path
        }
    }
    return $null
}

function Setup-Environment {
    Write-Host "[1/4] Checking Python..." -ForegroundColor Yellow
    
    $python = Find-Python
    
    if (-not $python) {
        Write-Host "  Python not found. Creating virtual environment..." -ForegroundColor DarkYellow
        python -m venv "$ScriptDir\.venv"
        $python = "$ScriptDir\.venv\Scripts\python.exe"
    }
    
    Write-Host "  Using: $python" -ForegroundColor Green
    
    Write-Host "[2/4] Checking dependencies..." -ForegroundColor Yellow
    
    # Test if key packages are installed
    & $python -c "import structlog; import pydantic; import dotenv" 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Installing core dependencies..." -ForegroundColor DarkYellow
        
        # Install core packages first
        & $python -m pip install -q python-dotenv pydantic pydantic-settings structlog httpx rich aiohttp requests
        
        # Then try full requirements
        if (Test-Path "$ScriptDir\requirements-core.txt") {
            & $python -m pip install -q -r "$ScriptDir\requirements-core.txt" 2>$null
        }
    }
    
    Write-Host "  Dependencies OK" -ForegroundColor Green
    
    Write-Host "[3/4] Checking configuration..." -ForegroundColor Yellow
    
    if (-not (Test-Path "$ScriptDir\.env")) {
        if (Test-Path "$ScriptDir\.env.example") {
            Copy-Item "$ScriptDir\.env.example" "$ScriptDir\.env"
            Write-Host "  Created .env from example" -ForegroundColor DarkYellow
        }
    }
    
    Write-Host "  Configuration OK" -ForegroundColor Green
    
    Write-Host "[4/4] Ready to launch" -ForegroundColor Yellow
    Write-Host ""
    
    return $python
}

# Main
Write-Banner

$python = Setup-Environment

$runArgs = @("$ScriptDir\run.py")

if ($demo)   { $runArgs += "--demo" }
if ($cli)    { $runArgs += "--cli" }
if ($server) { $runArgs += "--server" }
if ($status) { $runArgs += "--status" }

Write-Host "Launching..." -ForegroundColor Cyan
Write-Host ""

& $python $runArgs
