# ═══════════════════════════════════════════════════════════════════════════
#  WINDOWS NETWORK OPTIMIZATION FOR MAXIMUM DOWNLOAD SPEED
#  Run as Administrator
# ═══════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "  WINDOWS NETWORK STACK OPTIMIZATION" -ForegroundColor White
Write-Host "  TCP tuning for maximum download throughput" -ForegroundColor DarkGray
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

# Check for admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "        Right-click PowerShell and 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/5] Enabling TCP Window Auto-Tuning..." -ForegroundColor Yellow
netsh int tcp set global autotuninglevel=normal
Write-Host "      Auto-tuning: NORMAL (dynamic window scaling)" -ForegroundColor Green

Write-Host ""
Write-Host "[2/5] Enabling Direct Cache Access (DCA)..." -ForegroundColor Yellow
netsh int tcp set global dca=enabled 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "      DCA: Not supported on this hardware" -ForegroundColor DarkGray
} else {
    Write-Host "      DCA: ENABLED" -ForegroundColor Green
}

Write-Host ""
Write-Host "[3/5] Enabling Receive-Side Scaling (RSS)..." -ForegroundColor Yellow
netsh int tcp set global rss=enabled
Write-Host "      RSS: ENABLED (multi-core network processing)" -ForegroundColor Green

Write-Host ""
Write-Host "[4/5] Enabling Chimney Offload..." -ForegroundColor Yellow
netsh int tcp set global chimney=automatic 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "      Chimney: Not available (deprecated in Win10+)" -ForegroundColor DarkGray
} else {
    Write-Host "      Chimney: AUTOMATIC" -ForegroundColor Green
}

Write-Host ""
Write-Host "[5/5] Setting Congestion Provider to CTCP (Compound TCP)..." -ForegroundColor Yellow
netsh int tcp set global congestionprovider=ctcp 2>$null
if ($LASTEXITCODE -ne 0) {
    # Windows 11 / Server 2022+ use different syntax
    netsh int tcp set supplemental template=internet congestionprovider=bbr2 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      Congestion: BBR2 (modern low-latency algorithm)" -ForegroundColor Green
    } else {
        netsh int tcp set supplemental template=internet congestionprovider=newreno 2>$null
        Write-Host "      Congestion: NewReno (fallback)" -ForegroundColor Yellow
    }
} else {
    Write-Host "      Congestion: CTCP (Compound TCP)" -ForegroundColor Green
}

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "  CURRENT TCP SETTINGS" -ForegroundColor White
Write-Host "===============================================================" -ForegroundColor Cyan
netsh int tcp show global

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
Write-Host "  OPTIMIZATION COMPLETE" -ForegroundColor White
Write-Host "  Changes take effect immediately (no reboot needed)" -ForegroundColor DarkGray
Write-Host "===============================================================" -ForegroundColor Green
