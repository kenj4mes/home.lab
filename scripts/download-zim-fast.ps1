# ═══════════════════════════════════════════════════════════════════════════
#  3TEKK MAXIMUM VELOCITY ZIM DOWNLOADER
#  aria2c tuned to extract every last bit of bandwidth
# ═══════════════════════════════════════════════════════════════════════════

$zimDir = Join-Path $PSScriptRoot '..\data\zim'
$zimDir = [System.IO.Path]::GetFullPath($zimDir)
New-Item -ItemType Directory -Path $zimDir -Force | Out-Null

# Refresh PATH to get aria2c
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# ═══════════════════════════════════════════════════════════════════════════
# MAXIMUM VELOCITY SETTINGS
# ═══════════════════════════════════════════════════════════════════════════
$aria2Args = @(
    "-x16",                                    # 16 TCP streams per host (max)
    "-s16",                                    # Split into 16 parallel segments
    "-k1M",                                    # Min 1MB/segment (reduce handshake overhead)
    "-c",                                      # Continue/resume partial downloads
    "--enable-http-pipelining=true",           # Pipeline requests (latency killer)
    "--summary-interval=0",                    # No periodic status (save CPU cycles)
    "--file-allocation=none",                  # No pre-allocation (no admin needed on Windows)
    "--disk-cache=256M",                       # 256MB write buffer
    "--async-dns=true",                        # Async DNS resolution
    "--socket-recv-buffer-size=16777216",      # 16MB socket buffer
    "--connect-timeout=60",                    # Connection timeout
    "--timeout=600",                           # Transfer timeout
    "--max-tries=5",                           # Retry failed downloads
    "--retry-wait=3",                          # Wait between retries
    "--console-log-level=notice",              # Show useful progress
    "--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "  3TEKK ARIA2 MAXIMUM VELOCITY MODE" -ForegroundColor White
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "  x16 connections | x16 segments | HTTP pipelining" -ForegroundColor DarkCyan
Write-Host "  256MB disk cache | 16MB socket buffer | Async DNS" -ForegroundColor DarkCyan
Write-Host "  Pre-allocation | Auto-resume | Browser UA spoofing" -ForegroundColor DarkCyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

$downloads = @(
    @{Name='ArchLinux Wiki'; File='archlinux_en_all_maxi_2025-09.zim'; Url='https://download.kiwix.org/zim/other/archlinux_en_all_maxi_2025-09.zim'; Size='30MB'},
    @{Name='Security SE'; File='security.stackexchange.com_en_all_2025-12.zim'; Url='https://download.kiwix.org/zim/stack_exchange/security.stackexchange.com_en_all_2025-12.zim'; Size='419MB'},
    @{Name='AskUbuntu'; File='askubuntu.com_en_all_2025-12.zim'; Url='https://download.kiwix.org/zim/stack_exchange/askubuntu.com_en_all_2025-12.zim'; Size='2.6GB'},
    @{Name='SuperUser'; File='superuser.com_en_all_2025-12.zim'; Url='https://download.kiwix.org/zim/stack_exchange/superuser.com_en_all_2025-12.zim'; Size='3.7GB'},
    @{Name='Electronics SE'; File='electronics.stackexchange.com_en_all_2025-12.zim'; Url='https://download.kiwix.org/zim/stack_exchange/electronics.stackexchange.com_en_all_2025-12.zim'; Size='3.8GB'},
    @{Name='Wikipedia EN Mini'; File='wikipedia_en_all_mini_2025-12.zim'; Url='https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_mini_2025-12.zim'; Size='11GB'}
)

$i = 1
$startTime = Get-Date
foreach ($dl in $downloads) {
    $outFile = Join-Path $zimDir $dl.File
    if (Test-Path $outFile) {
        $existingMB = [math]::Round((Get-Item $outFile).Length / 1MB, 1)
        Write-Host "[$i/6] $($dl.Name) - EXISTS (${existingMB} MB)" -ForegroundColor DarkGray
    } else {
        Write-Host "[$i/6] $($dl.Name) ($($dl.Size)) - TURBO MODE" -ForegroundColor Yellow
        $dlStart = Get-Date
        
        # Build and execute aria2c command
        $argString = $aria2Args -join " "
        $cmd = "aria2c $argString -d `"$zimDir`" -o `"$($dl.File)`" `"$($dl.Url)`""
        Invoke-Expression $cmd
        
        if ($LASTEXITCODE -eq 0) {
            $dlTime = (Get-Date) - $dlStart
            $fileMB = [math]::Round((Get-Item $outFile).Length / 1MB, 1)
            $speed = [math]::Round($fileMB / $dlTime.TotalSeconds, 1)
            Write-Host "     COMPLETE: ${fileMB} MB in $([math]::Round($dlTime.TotalMinutes,1)) min (${speed} MB/s avg)" -ForegroundColor Green
        } else {
            Write-Host "     FAILED - will retry next run" -ForegroundColor Red
        }
    }
    $i++
}

Write-Host ""
Write-Host "=== ALL DOWNLOADS COMPLETE ===" -ForegroundColor Green
Get-ChildItem $zimDir -Filter '*.zim' | Format-Table Name, @{N='Size(GB)';E={[math]::Round($_.Length/1GB,2)}} -AutoSize
