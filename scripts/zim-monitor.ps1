# ZIM Download Progress Monitor with Milestone Alerts
# Checks progress and alerts at 50%, 75%, 100%

$zimDir = 'C:\home.lab\data\zim'
$totalTargetMB = 22054  # Total expected size in MB
$lastMilestone = 0

$targets = @{
    'archlinux_en_all_maxi_2025-09.zim' = 30
    'security.stackexchange.com_en_all_2025-12.zim' = 419
    'askubuntu.com_en_all_2025-12.zim' = 2662
    'superuser.com_en_all_2025-12.zim' = 3788
    'electronics.stackexchange.com_en_all_2025-12.zim' = 3891
    'wikipedia_en_all_mini_2025-12.zim' = 11264
}

Write-Host "=== ZIM DOWNLOAD MONITOR ===" -ForegroundColor Cyan
Write-Host "Monitoring for 50%, 75%, 100% milestones" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor DarkGray
Write-Host ""

while ($true) {
    $totalDownloaded = 0
    $completedFiles = 0
    
    foreach ($target in $targets.GetEnumerator()) {
        $file = Get-ChildItem $zimDir -Filter $target.Key -ErrorAction SilentlyContinue
        if ($file) {
            $sizeMB = [math]::Round($file.Length / 1MB, 1)
            $totalDownloaded += $sizeMB
            if ($sizeMB -ge ($target.Value * 0.99)) { $completedFiles++ }
        }
    }
    
    $pct = [math]::Round(($totalDownloaded / $totalTargetMB) * 100, 1)
    $timestamp = Get-Date -Format 'HH:mm:ss'
    
    # Check milestones
    if ($pct -ge 50 -and $lastMilestone -lt 50) {
        $lastMilestone = 50
        [console]::beep(800, 500)
        Write-Host "`n*** 50% MILESTONE REACHED! ***" -ForegroundColor Green -BackgroundColor Black
        Write-Host "Downloaded: $([math]::Round($totalDownloaded/1024,2)) GB / $([math]::Round($totalTargetMB/1024,1)) GB" -ForegroundColor Cyan
        [console]::beep(1000, 300)
    }
    elseif ($pct -ge 75 -and $lastMilestone -lt 75) {
        $lastMilestone = 75
        [console]::beep(800, 500)
        Write-Host "`n*** 75% MILESTONE REACHED! ***" -ForegroundColor Yellow -BackgroundColor Black
        Write-Host "Downloaded: $([math]::Round($totalDownloaded/1024,2)) GB / $([math]::Round($totalTargetMB/1024,1)) GB" -ForegroundColor Cyan
        [console]::beep(1000, 300)
    }
    elseif ($pct -ge 100 -and $lastMilestone -lt 100) {
        $lastMilestone = 100
        [console]::beep(600, 200); [console]::beep(800, 200); [console]::beep(1000, 400)
        Write-Host "`n*** 100% COMPLETE! ALL DOWNLOADS FINISHED! ***" -ForegroundColor White -BackgroundColor Green
        Get-ChildItem $zimDir -Filter '*.zim' | Format-Table Name, @{N='Size(GB)';E={[math]::Round($_.Length/1GB,2)}} -AutoSize
        break
    }
    
    # Status update every 30 seconds
    Write-Host "`r[$timestamp] $pct% | $([math]::Round($totalDownloaded/1024,2)) GB | $completedFiles/6 files    " -NoNewline
    
    Start-Sleep -Seconds 30
}

Write-Host "`nMonitor stopped." -ForegroundColor Yellow
