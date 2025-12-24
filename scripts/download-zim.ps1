# Download Kiwix ZIM Files for Offline Knowledge
# Stores ZIM files in home.lab/data/zim/ for portability

param(
    [string]$ZimPath = "C:\home.lab\data\zim",
    [switch]$WikipediaOnly,
    [switch]$DevDocs,
    [switch]$All
)

Write-Host @"
========================================
  KIWIX ZIM DOWNLOADER
  Offline Knowledge for HomeLab
========================================
ZIM Storage: $ZimPath

"@

# Ensure directory exists
if (-not (Test-Path $ZimPath)) {
    New-Item -ItemType Directory -Path $ZimPath -Force | Out-Null
}

# ZIM file definitions
$WikipediaZims = @(
    @{
        name = "wikipedia_en_all_mini"
        url = "https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_mini_2024-01.zim"
        size = "10GB"
        desc = "Wikipedia English - Mini (text only)"
    },
    @{
        name = "wikipedia_en_all_nopic"
        url = "https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_nopic_2024-01.zim"
        size = "50GB"
        desc = "Wikipedia English - No Pictures"
    }
)

$DevDocsZims = @(
    @{
        name = "stack_exchange"
        url = "https://download.kiwix.org/zim/stack_exchange/stackoverflow.com_en_all_2024-01.zim"
        size = "35GB"
        desc = "Stack Overflow - Full archive"
    },
    @{
        name = "mdnwebdocs"
        url = "https://download.kiwix.org/zim/other/mdnwebdocs.org_en_2024-01.zim"
        size = "2.5GB"
        desc = "MDN Web Docs - Full"
    }
)

$OtherZims = @(
    @{
        name = "gutenberg"
        url = "https://download.kiwix.org/zim/gutenberg/gutenberg_en_all_2024-01.zim"
        size = "60GB"
        desc = "Project Gutenberg - 60k+ books"
    },
    @{
        name = "wikibooks"
        url = "https://download.kiwix.org/zim/wikibooks/wikibooks_en_all_2024-01.zim"
        size = "1GB"
        desc = "Wikibooks - Free textbooks"
    }
)

# Determine which ZIMs to download
$ZimsToDownload = @()
if ($WikipediaOnly) {
    $ZimsToDownload = $WikipediaZims
    Write-Host "[MODE] Wikipedia Only" -ForegroundColor Yellow
} elseif ($DevDocs) {
    $ZimsToDownload = $DevDocsZims
    Write-Host "[MODE] Developer Docs" -ForegroundColor Yellow
} elseif ($All) {
    $ZimsToDownload = $WikipediaZims + $DevDocsZims + $OtherZims
    Write-Host "[MODE] All ZIMs (~160GB)" -ForegroundColor Yellow
} else {
    $ZimsToDownload = @($WikipediaZims[0]) + @($DevDocsZims[1])
    Write-Host "[MODE] Minimal Set (~12GB)" -ForegroundColor Yellow
}

Write-Host "`nZIMs to download:"
foreach ($z in $ZimsToDownload) {
    Write-Host "  - $($z.name) ($($z.size)) - $($z.desc)"
}

Write-Host "`n[NOTE] ZIM files are large. Ensure sufficient disk space."
Write-Host "[NOTE] Download URLs may need updating - check kiwix.org/download`n"

$confirm = Read-Host "Proceed with download? (Y/N)"
if ($confirm.ToUpper() -ne "Y") {
    Write-Host "[CANCELLED]" -ForegroundColor Yellow
    exit
}

$success = 0
$failed = 0

foreach ($z in $ZimsToDownload) {
    $destFile = Join-Path $ZimPath "$($z.name).zim"
    
    if (Test-Path $destFile) {
        Write-Host "[SKIP] $($z.name) - already exists" -ForegroundColor Yellow
        $success++
        continue
    }
    
    Write-Host "[DOWNLOAD] $($z.name) ($($z.size))..." -ForegroundColor Cyan
    Write-Host "           URL: $($z.url)"
    
    try {
        # Use BITS for large file transfer
        $job = Start-BitsTransfer -Source $z.url -Destination $destFile -Asynchronous -DisplayName $z.name
        
        while ($job.JobState -eq "Transferring" -or $job.JobState -eq "Connecting") {
            $pct = if ($job.BytesTotal -gt 0) { [math]::Round(($job.BytesTransferred / $job.BytesTotal) * 100, 1) } else { 0 }
            $transferred = [math]::Round($job.BytesTransferred / 1GB, 2)
            $total = [math]::Round($job.BytesTotal / 1GB, 2)
            Write-Progress -Activity "Downloading $($z.name)" -Status "$transferred GB / $total GB" -PercentComplete $pct
            Start-Sleep -Seconds 2
        }
        
        if ($job.JobState -eq "Transferred") {
            Complete-BitsTransfer -BitsJob $job
            Write-Progress -Activity "Downloading $($z.name)" -Completed
            Write-Host "           OK" -ForegroundColor Green
            $success++
        } else {
            Remove-BitsTransfer -BitsJob $job -ErrorAction SilentlyContinue
            Write-Host "           FAILED: $($job.JobState)" -ForegroundColor Red
            $failed++
        }
    }
    catch {
        Write-Host "           FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    }
}

Write-Host @"

========================================
  DOWNLOAD COMPLETE
  Success: $success | Failed: $failed
========================================
ZIMs stored in: $ZimPath

To use with Kiwix:
  docker compose -f docker/docker-compose.base.yml up kiwix -d
  Browse: http://localhost:8084

"@
