# HomeLab Master Download Script
# Downloads all models and data for fully offline operation

param(
    [switch]$Minimal,
    [switch]$Standard,
    [switch]$Full,
    [switch]$SkipModels,
    [switch]$SkipZim,
    [switch]$SkipOllama
)

$ErrorActionPreference = 'Continue'
$ScriptRoot = $PSScriptRoot

Write-Host ''
Write-Host '  HOMELAB OFFLINE DATA DOWNLOAD' -ForegroundColor Cyan
Write-Host '  Everything for Air-Gapped Operation' -ForegroundColor Cyan
Write-Host ''

# Determine download tier
$tier = 'Standard'
if ($Minimal) { $tier = 'Minimal' }
elseif ($Full) { $tier = 'Full' }

Write-Host "  Download Tier: $tier" -ForegroundColor Yellow
Write-Host ''

# Estimated sizes
$estimates = @{
    'Minimal' = @{ ollama = '6GB'; models = '8GB'; zim = '12GB'; total = '26GB' }
    'Standard' = @{ ollama = '25GB'; models = '20GB'; zim = '50GB'; total = '95GB' }
    'Full' = @{ ollama = '130GB'; models = '50GB'; zim = '160GB'; total = '340GB' }
}

$est = $estimates[$tier]
Write-Host '  Estimated Downloads:'
Write-Host "    Ollama Models: $($est.ollama)"
Write-Host "    Creative AI:   $($est.models)"
Write-Host "    Kiwix ZIMs:    $($est.zim)"
Write-Host '    ---------------------'
Write-Host "    TOTAL:         $($est.total)"
Write-Host ''

$confirm = Read-Host '  Proceed with download? (Y/N)'
if ($confirm.ToUpper() -ne 'Y') {
    Write-Host ''
    Write-Host '  [CANCELLED]' -ForegroundColor Yellow
    exit
}

$results = @{
    ollama = 'Skipped'
    models = 'Skipped'
    zim = 'Skipped'
}

# 1. Ollama Models
if (-not $SkipOllama) {
    Write-Host ''
    Write-Host '  =======================================' -ForegroundColor Cyan
    Write-Host '  PHASE 1: Ollama LLM Models' -ForegroundColor Cyan
    Write-Host '  =======================================' -ForegroundColor Cyan
    
    $ollamaScript = Join-Path $ScriptRoot 'download-models.ps1'
    if (Test-Path $ollamaScript) {
        try {
            if ($Minimal) {
                & $ollamaScript -MinimalSet
            } elseif ($Full) {
                & $ollamaScript -FullSet
            } else {
                & $ollamaScript
            }
            $results.ollama = 'Complete'
        }
        catch {
            Write-Host "  [ERROR] Ollama download failed: $_" -ForegroundColor Red
            $results.ollama = 'Failed'
        }
    } else {
        Write-Host '  [SKIP] download-models.ps1 not found' -ForegroundColor Yellow
    }
}

# 2. Creative AI Models
if (-not $SkipModels) {
    Write-Host ''
    Write-Host '  =======================================' -ForegroundColor Cyan
    Write-Host '  PHASE 2: Creative AI Models' -ForegroundColor Cyan
    Write-Host '  =======================================' -ForegroundColor Cyan
    
    $modelsScript = Join-Path $ScriptRoot 'download-creative-models.ps1'
    if (Test-Path $modelsScript) {
        try {
            if ($Full) {
                & $modelsScript -Models @('sd', 'sd-vae', 'whisper', 'whisper-large', 'musicgen', 'bark')
            } else {
                & $modelsScript -Models @('sd', 'whisper', 'musicgen')
            }
            $results.models = 'Complete'
        }
        catch {
            Write-Host "  [ERROR] Creative models download failed: $_" -ForegroundColor Red
            $results.models = 'Failed'
        }
    } else {
        Write-Host '  [SKIP] download-creative-models.ps1 not found' -ForegroundColor Yellow
    }
}

# 3. Kiwix ZIM Files
if (-not $SkipZim) {
    Write-Host ''
    Write-Host '  =======================================' -ForegroundColor Cyan
    Write-Host '  PHASE 3: Kiwix Offline Knowledge' -ForegroundColor Cyan
    Write-Host '  =======================================' -ForegroundColor Cyan
    
    $zimScript = Join-Path $ScriptRoot 'download-zim.ps1'
    if (Test-Path $zimScript) {
        try {
            if ($Full) {
                & $zimScript -All
            } elseif ($Standard) {
                & $zimScript -DevDocs
            } else {
                & $zimScript
            }
            $results.zim = 'Complete'
        }
        catch {
            Write-Host "  [ERROR] ZIM download failed: $_" -ForegroundColor Red
            $results.zim = 'Failed'
        }
    } else {
        Write-Host '  [SKIP] download-zim.ps1 not found' -ForegroundColor Yellow
    }
}

# Summary
Write-Host ''
Write-Host '  =======================================' -ForegroundColor Cyan
Write-Host '  DOWNLOAD SUMMARY' -ForegroundColor Cyan
Write-Host '  =======================================' -ForegroundColor Cyan
Write-Host ''
Write-Host "  Ollama Models:  $($results.ollama)"
Write-Host "  Creative AI:    $($results.models)"
Write-Host "  Kiwix ZIMs:     $($results.zim)"
Write-Host ''
Write-Host '  Data Directory: C:\home.lab\data\' -ForegroundColor Gray
Write-Host ''
Write-Host '  HomeLab is now ready for offline operation!' -ForegroundColor Green
Write-Host ''
