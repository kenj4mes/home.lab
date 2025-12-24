<#
.SYNOPSIS
    Download Creative AI Models for Offline Operation
.DESCRIPTION
    Pre-downloads large model files for Stable Diffusion, MusicGen, 
    Whisper, and other creative AI services to enable offline operation.
    
.EXAMPLE
    .\download-creative-models.ps1
    
.EXAMPLE
    .\download-creative-models.ps1 -Models @("sd", "musicgen") -OutputPath "D:\Models"
#>

[CmdletBinding()]
param(
    [string[]]$Models = @("sd", "whisper", "musicgen"),
    [string]$OutputPath = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# ==============================================================================
# CONFIGURATION
# ==============================================================================

$ModelConfig = @{
    "sd" = @{
        Name = "Stable Diffusion XL Base"
        Url = "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors"
        Size = "6.9 GB"
        VolumePath = "homelab-sd-models"
        ContainerPath = "/stable-diffusion-webui/models/Stable-diffusion"
        LocalFolder = "sd\models\Stable-diffusion"
    }
    "sd-vae" = @{
        Name = "SDXL VAE"
        Url = "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors"
        Size = "334 MB"
        VolumePath = "homelab-sd-models"
        ContainerPath = "/stable-diffusion-webui/models/VAE"
        LocalFolder = "sd\models\VAE"
    }
    "whisper" = @{
        Name = "Whisper Base Model"
        Url = "https://huggingface.co/Systran/faster-whisper-base/resolve/main/model.bin"
        Size = "150 MB"
        VolumePath = "homelab-whisper-models"
        ContainerPath = "/config/models"
        LocalFolder = "whisper\models"
    }
    "whisper-large" = @{
        Name = "Whisper Large V3"
        Url = "https://huggingface.co/Systran/faster-whisper-large-v3/resolve/main/model.bin"
        Size = "3.1 GB"
        VolumePath = "homelab-whisper-models"
        ContainerPath = "/config/models"
        LocalFolder = "whisper\models"
    }
    "musicgen" = @{
        Name = "MusicGen Small"
        Url = "https://huggingface.co/facebook/musicgen-small/resolve/main/model.safetensors"
        Size = "600 MB"
        VolumePath = "homelab-musicgen-models"
        ContainerPath = "/app/models"
        LocalFolder = "musicgen\models"
    }
    "bark" = @{
        Name = "Bark TTS"
        Url = "https://huggingface.co/suno/bark/resolve/main/text_2.pt"
        Size = "1.9 GB"
        VolumePath = "homelab-bark-models"
        ContainerPath = "/app/models"
        LocalFolder = "bark\models"
    }
}

# ==============================================================================
# FUNCTIONS
# ==============================================================================

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
        "SUCCESS" { "  ✓ " }
        "WARN" { "  ⚠ " }
        "ERROR" { "  ✗ " }
        "PHASE" { "`n  ▶ " }
        default { "  ℹ " }
    }
    Write-Host "$prefix$Message" -ForegroundColor $color
}

function Get-FileSize {
    param([string]$Url)
    try {
        $request = [System.Net.WebRequest]::Create($Url)
        $request.Method = "HEAD"
        $response = $request.GetResponse()
        $size = $response.ContentLength
        $response.Close()
        return $size
    }
    catch {
        return 0
    }
}

function Download-Model {
    param(
        [string]$Name,
        [string]$Url,
        [string]$OutputFile
    )
    
    $outputDir = Split-Path -Parent $OutputFile
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    if ((Test-Path $OutputFile) -and -not $Force) {
        Write-Step "$Name already exists, skipping (use -Force to re-download)" -Status WARN
        return $true
    }
    
    Write-Step "Downloading $Name..."
    Write-Host "       URL: $Url" -ForegroundColor DarkGray
    Write-Host "       To:  $OutputFile" -ForegroundColor DarkGray
    
    try {
        # Use BITS for better download experience
        $job = Start-BitsTransfer -Source $Url -Destination $OutputFile -Asynchronous -DisplayName $Name
        
        while ($job.JobState -eq "Transferring" -or $job.JobState -eq "Connecting") {
            $pct = if ($job.BytesTotal -gt 0) { [math]::Round(($job.BytesTransferred / $job.BytesTotal) * 100, 1) } else { 0 }
            $transferred = [math]::Round($job.BytesTransferred / 1GB, 2)
            $total = [math]::Round($job.BytesTotal / 1GB, 2)
            Write-Progress -Activity "Downloading $Name" -Status "$transferred GB / $total GB" -PercentComplete $pct
            Start-Sleep -Milliseconds 500
        }
        
        if ($job.JobState -eq "Transferred") {
            Complete-BitsTransfer -BitsJob $job
            Write-Progress -Activity "Downloading $Name" -Completed
            Write-Step "$Name downloaded successfully" -Status SUCCESS
            return $true
        }
        else {
            Remove-BitsTransfer -BitsJob $job -ErrorAction SilentlyContinue
            Write-Step "Download failed: $($job.JobState)" -Status ERROR
            return $false
        }
    }
    catch {
        Write-Step "Download error: $($_.Exception.Message)" -Status ERROR
        # Fallback to Invoke-WebRequest
        try {
            Write-Step "Retrying with Invoke-WebRequest..." -Status WARN
            Invoke-WebRequest -Uri $Url -OutFile $OutputFile -UseBasicParsing
            Write-Step "$Name downloaded successfully" -Status SUCCESS
            return $true
        }
        catch {
            Write-Step "Fallback download failed: $($_.Exception.Message)" -Status ERROR
            return $false
        }
    }
}

function Copy-ToDockerVolume {
    param(
        [string]$LocalFile,
        [string]$VolumeName,
        [string]$ContainerPath
    )
    
    if (-not (Test-Path $LocalFile)) {
        Write-Step "Local file not found: $LocalFile" -Status ERROR
        return $false
    }
    
    $fileName = Split-Path -Leaf $LocalFile
    
    Write-Step "Copying to Docker volume: $VolumeName"
    
    try {
        # Create temp container to access volume
        docker run --rm -v "${VolumeName}:${ContainerPath}" -v "${LocalFile}:/src/${fileName}" alpine cp "/src/${fileName}" "${ContainerPath}/${fileName}" 2>&1 | Out-Null
        Write-Step "Copied to $VolumeName" -Status SUCCESS
        return $true
    }
    catch {
        Write-Step "Failed to copy to volume: $($_.Exception.Message)" -Status ERROR
        return $false
    }
}

# ==============================================================================
# MAIN
# ==============================================================================

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║            🎨 Creative AI Model Downloader                       ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Determine output path
if (-not $OutputPath) {
    $OutputPath = Join-Path $PSScriptRoot "..\data\models"
}

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Step "Model storage: $OutputPath" -Status PHASE

# Calculate total size
$totalSize = 0
foreach ($model in $Models) {
    if ($ModelConfig.ContainsKey($model)) {
        $sizeStr = $ModelConfig[$model].Size
        if ($sizeStr -match "(\d+\.?\d*)\s*(GB|MB)") {
            $num = [double]$Matches[1]
            $unit = $Matches[2]
            if ($unit -eq "GB") { $totalSize += $num }
            else { $totalSize += $num / 1024 }
        }
    }
}

Write-Host "  Selected models: $($Models -join ', ')" -ForegroundColor Gray
Write-Host "  Estimated download: ~$([math]::Round($totalSize, 1)) GB" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "  Proceed with download? (Y/N)"
if ($confirm.ToUpper() -ne "Y") {
    Write-Step "Download cancelled" -Status WARN
    exit
}

# Download each model
$successCount = 0
$failCount = 0

foreach ($model in $Models) {
    if (-not $ModelConfig.ContainsKey($model)) {
        Write-Step "Unknown model: $model" -Status WARN
        continue
    }
    
    $config = $ModelConfig[$model]
    Write-Step "Processing: $($config.Name) ($($config.Size))" -Status PHASE
    
    $localFolder = Join-Path $OutputPath $config.LocalFolder
    $fileName = Split-Path -Leaf $config.Url
    $localFile = Join-Path $localFolder $fileName
    
    if (Download-Model -Name $config.Name -Url $config.Url -OutputFile $localFile) {
        # Optionally copy to Docker volume
        $copyToVolume = Read-Host "  Copy to Docker volume '$($config.VolumePath)'? (Y/N)"
        if ($copyToVolume.ToUpper() -eq "Y") {
            Copy-ToDockerVolume -LocalFile $localFile -VolumeName $config.VolumePath -ContainerPath $config.ContainerPath
        }
        $successCount++
    }
    else {
        $failCount++
    }
}

# Summary
Write-Host ""
Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Download Summary:" -ForegroundColor Cyan
Write-Host "    ✓ Successful: $successCount" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "    ✗ Failed: $failCount" -ForegroundColor Red
}
Write-Host ""
Write-Host "  Models saved to: $OutputPath" -ForegroundColor Gray
Write-Host ""

# List available models
Write-Host "  Available models (use -Models parameter):" -ForegroundColor Cyan
foreach ($key in $ModelConfig.Keys | Sort-Object) {
    $config = $ModelConfig[$key]
    Write-Host "    - $key : $($config.Name) ($($config.Size))" -ForegroundColor Gray
}
Write-Host ""
