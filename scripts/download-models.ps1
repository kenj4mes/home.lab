# Download Ollama Models for Offline Use
# Stores models in home.lab/data/ollama/ for portability

param(
    [string]$ModelPath = "$PSScriptRoot\..\data\ollama",
    [switch]$MinimalSet,
    [switch]$FullSet
)

# Resolve to absolute path
$ModelPath = [System.IO.Path]::GetFullPath($ModelPath)
$env:OLLAMA_MODELS = $ModelPath

# Ensure Ollama is installed
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Ollama not installed. Install from https://ollama.ai" -ForegroundColor Red
    exit 1
}

Write-Host @"
========================================
  OLLAMA MODEL DOWNLOADER
  Offline AI for HomeLab
========================================
Model Storage: $ModelPath

"@

# Model tiers
$MinimalModels = @(
    @{name="llama3.2:3b"; size="2.0GB"; desc="Fast local chat"},
    @{name="nomic-embed-text"; size="274MB"; desc="Embeddings for RAG"},
    @{name="codellama:7b"; size="3.8GB"; desc="Code generation"}
)

$StandardModels = @(
    @{name="llama3.1:8b"; size="4.7GB"; desc="Balanced performance"},
    @{name="mistral:7b"; size="4.1GB"; desc="Fast reasoning"},
    @{name="phi3:mini"; size="2.3GB"; desc="Microsoft compact"},
    @{name="qwen2.5:7b"; size="4.4GB"; desc="Multilingual"},
    @{name="deepseek-coder:6.7b"; size="3.8GB"; desc="Code specialist"}
)

$FullModels = @(
    @{name="llama3.1:70b"; size="40GB"; desc="Maximum intelligence"},
    @{name="codellama:70b"; size="40GB"; desc="Expert coding"},
    @{name="mixtral:8x7b"; size="26GB"; desc="MoE architecture"},
    @{name="llama3.2-vision:11b"; size="7.9GB"; desc="Vision + text"}
)

# Determine which models to download
$ModelsToDownload = @()
if ($MinimalSet) {
    $ModelsToDownload = $MinimalModels
    Write-Host "[MODE] Minimal Set - Essential models only" -ForegroundColor Yellow
} elseif ($FullSet) {
    $ModelsToDownload = $MinimalModels + $StandardModels + $FullModels
    Write-Host "[MODE] Full Set - All models (~130GB)" -ForegroundColor Yellow
} else {
    $ModelsToDownload = $MinimalModels + $StandardModels
    Write-Host "[MODE] Standard Set - Recommended models (~25GB)" -ForegroundColor Yellow
}

# Calculate total size
Write-Host "`nModels to download:"
foreach ($m in $ModelsToDownload) {
    Write-Host "  - $($m.name) ($($m.size)) - $($m.desc)"
}

Write-Host "`nStarting downloads...`n"

$success = 0
$failed = 0

foreach ($m in $ModelsToDownload) {
    Write-Host "[PULL] $($m.name)..." -ForegroundColor Cyan
    $result = ollama pull $m.name 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "       OK" -ForegroundColor Green
        $success++
    } else {
        Write-Host "       FAILED: $result" -ForegroundColor Red
        $failed++
    }
}

Write-Host @"

========================================
  DOWNLOAD COMPLETE
  Success: $success | Failed: $failed
========================================
Models stored in: $ModelPath
To use: Set OLLAMA_MODELS=$ModelPath

"@
