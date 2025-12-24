<#
.SYNOPSIS
    Install Hugging Face CLI and Core Libraries
.DESCRIPTION
    Sets up the complete Hugging Face ecosystem for HomeLab:
    - huggingface-cli (model downloads, authentication)
    - transformers (NLP models)
    - diffusers (image/video generation)
    - accelerate (GPU optimization)
    - datasets (data loading)
    - tokenizers (fast tokenization)
    - safetensors (secure model format)
    
.EXAMPLE
    .\install-huggingface.ps1
    
.EXAMPLE
    .\install-huggingface.ps1 -Login -CacheDir "D:\HF_Cache"
#>

[CmdletBinding()]
param(
    [switch]$Login,
    [switch]$Offline,
    [string]$CacheDir = "",
    [switch]$Minimal,
    [switch]$Full
)

$ErrorActionPreference = "Stop"

$HF_PACKAGES = @{
    Core = @("huggingface_hub", "transformers", "safetensors", "tokenizers")
    Diffusion = @("diffusers", "accelerate", "invisible-watermark")
    Audio = @("torchaudio", "soundfile", "librosa")
    Datasets = @("datasets", "evaluate")
    Vision = @("timm", "albumentations")
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

function Test-PythonInstalled {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        $version = python --version 2>&1
        return $version -match "Python 3\.(9|10|11|12)"
    }
    return $false
}

function Install-Package {
    param([string]$Package)
    try {
        pip install --upgrade $Package 2>&1 | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

Write-Host ""
Write-Host "  ================================================================" -ForegroundColor Cyan
Write-Host "              Hugging Face Ecosystem Installer                   " -ForegroundColor Cyan
Write-Host "  ================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Step "Checking Python installation..." -Status PHASE

if (-not (Test-PythonInstalled)) {
    Write-Step "Python 3.9+ required. Install from https://python.org" -Status ERROR
    exit 1
}

$pyVersion = python --version
Write-Step "Found: $pyVersion" -Status SUCCESS

Write-Step "Upgrading pip..." -Status PHASE
python -m pip install --upgrade pip 2>&1 | Out-Null
Write-Step "pip upgraded" -Status SUCCESS

$packages = @()

if ($Minimal) {
    $packages = $HF_PACKAGES.Core
    Write-Step "Minimal install: Core packages only" -Status INFO
}
elseif ($Full) {
    foreach ($category in $HF_PACKAGES.Keys) {
        $packages += $HF_PACKAGES[$category]
    }
    Write-Step "Full install: All Hugging Face packages" -Status INFO
}
else {
    $packages = $HF_PACKAGES.Core + $HF_PACKAGES.Diffusion
    Write-Step "Standard install: Core + Diffusion packages" -Status INFO
}

Write-Step "Installing PyTorch (CUDA 12.1)..." -Status PHASE
try {
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 2>&1 | Out-Null
    Write-Step "PyTorch installed with CUDA 12.1 support" -Status SUCCESS
}
catch {
    Write-Step "PyTorch install failed, trying CPU version..." -Status WARN
    pip install torch torchvision torchaudio 2>&1 | Out-Null
    Write-Step "PyTorch installed (CPU only)" -Status WARN
}

Write-Step "Installing Hugging Face packages..." -Status PHASE

$successCount = 0
$failCount = 0

foreach ($package in $packages) {
    Write-Host "    Installing $package..." -NoNewline -ForegroundColor Gray
    if (Install-Package -Package $package) {
        Write-Host " OK" -ForegroundColor Green
        $successCount++
    }
    else {
        Write-Host " FAILED" -ForegroundColor Red
        $failCount++
    }
}

if ($failCount -eq 0) {
    Write-Step "Packages installed: $successCount success" -Status SUCCESS
}
else {
    Write-Step "Packages installed: $successCount success, $failCount failed" -Status WARN
}

if ($CacheDir) {
    Write-Step "Setting cache directory..." -Status PHASE
    [System.Environment]::SetEnvironmentVariable("HF_HOME", $CacheDir, "User")
    [System.Environment]::SetEnvironmentVariable("TRANSFORMERS_CACHE", "$CacheDir\hub", "User")
    [System.Environment]::SetEnvironmentVariable("HUGGINGFACE_HUB_CACHE", "$CacheDir\hub", "User")
    Write-Step "Cache set to: $CacheDir" -Status SUCCESS
}
else {
    $defaultCache = Join-Path $env:USERPROFILE ".cache\huggingface"
    Write-Step "Using default cache: $defaultCache" -Status INFO
}

if ($Offline) {
    Write-Step "Enabling offline mode..." -Status PHASE
    [System.Environment]::SetEnvironmentVariable("HF_HUB_OFFLINE", "1", "User")
    [System.Environment]::SetEnvironmentVariable("TRANSFORMERS_OFFLINE", "1", "User")
    Write-Step "Offline mode enabled" -Status SUCCESS
}

if ($Login) {
    Write-Step "Logging in to Hugging Face..." -Status PHASE
    Write-Host ""
    Write-Host "  Get your token from: https://huggingface.co/settings/tokens" -ForegroundColor Yellow
    Write-Host ""
    huggingface-cli login
}

Write-Step "Verifying installation..." -Status PHASE

$verified = @()
$failed = @()

$testImports = @(
    @{Module = "transformers"; Test = "python -c `"import transformers; print(transformers.__version__)`""},
    @{Module = "diffusers"; Test = "python -c `"import diffusers; print(diffusers.__version__)`""},
    @{Module = "huggingface_hub"; Test = "huggingface-cli --version"}
)

foreach ($import in $testImports) {
    try {
        $result = Invoke-Expression $import.Test 2>&1
        if ($LASTEXITCODE -eq 0) {
            $verified += "$($import.Module): $result"
        }
        else {
            $failed += $import.Module
        }
    }
    catch {
        $failed += $import.Module
    }
}

Write-Host ""
Write-Host "  ================================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Hugging Face Installation Complete" -ForegroundColor Green
Write-Host ""

if ($verified.Count -gt 0) {
    Write-Host "  Verified:" -ForegroundColor Cyan
    foreach ($v in $verified) {
        Write-Host "    [OK] $v" -ForegroundColor Green
    }
}

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "  Failed:" -ForegroundColor Red
    foreach ($f in $failed) {
        Write-Host "    [X] $f" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "  Quick Start Commands:" -ForegroundColor Cyan
Write-Host "    huggingface-cli login              # Authenticate" -ForegroundColor Gray
Write-Host "    huggingface-cli download MODEL     # Download model" -ForegroundColor Gray
Write-Host "    huggingface-cli scan-cache         # View cached models" -ForegroundColor Gray
Write-Host "    huggingface-cli delete-cache       # Clean cache" -ForegroundColor Gray
Write-Host ""
Write-Host "  Recommended Models for HomeLab:" -ForegroundColor Cyan
Write-Host "    huggingface-cli download stabilityai/stable-diffusion-xl-base-1.0" -ForegroundColor Gray
Write-Host "    huggingface-cli download openai/whisper-large-v3" -ForegroundColor Gray
Write-Host "    huggingface-cli download facebook/musicgen-medium" -ForegroundColor Gray
Write-Host ""
