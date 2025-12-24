<#
.SYNOPSIS
    Clone all Superchain ecosystem repositories into a single folder.
.DESCRIPTION
    Downloads OP-Stack and Superchain ecosystem node repositories
    into a unified superchain/ directory.
.PARAMETER DestinationPath
    Target folder for cloning (default: ./superchain)
.PARAMETER ShallowClone
    Use --depth 1 for faster cloning
.PARAMETER SkipExisting
    Skip repos that already exist
.PARAMETER IncludeOptional
    Include optional chains (Celo, Boba, Fraxtal)
#>

param(
    [string]$DestinationPath = ".\superchain",
    [switch]$IncludeOptional,
    [switch]$ShallowClone,
    [switch]$SkipExisting
)

$ErrorActionPreference = "Continue"

# Repository list
$CoreRepos = @(
    @{ Name = "optimism"; Url = "https://github.com/ethereum-optimism/optimism.git"; Category = "Core"; Ecosystem = "OP Mainnet"; Notes = "Core OP-Stack" }
    @{ Name = "superchain-registry"; Url = "https://github.com/ethereum-optimism/superchain-registry.git"; Category = "Core"; Ecosystem = "Registry"; Notes = "Chain configs" }
    @{ Name = "ink-node"; Url = "https://github.com/inkonchain/node.git"; Category = "Finance"; Ecosystem = "Ink"; Notes = "Ink node" }
    @{ Name = "unichain-node"; Url = "https://github.com/Uniswap/unichain-node.git"; Category = "Finance"; Ecosystem = "Unichain"; Notes = "Uniswap L2" }
    @{ Name = "mode-rollup-node"; Url = "https://github.com/mode-network/rollup-node.git"; Category = "Finance"; Ecosystem = "Mode"; Notes = "Mode rollup" }
    @{ Name = "base-node"; Url = "https://github.com/base/node.git"; Category = "Finance"; Ecosystem = "Base"; Notes = "Coinbase L2" }
    @{ Name = "superseed-node"; Url = "https://github.com/superseed-xyz/node.git"; Category = "Finance"; Ecosystem = "Superseed"; Notes = "Superseed" }
    @{ Name = "world-chain"; Url = "https://github.com/worldcoin/world-chain.git"; Category = "General"; Ecosystem = "World Chain"; Notes = "Worldcoin L2" }
    @{ Name = "lisk-node"; Url = "https://github.com/LiskHQ/lisk-node.git"; Category = "General"; Ecosystem = "Lisk"; Notes = "Lisk L2" }
    @{ Name = "mint-node"; Url = "https://github.com/Mint-Blockchain/mint-node.git"; Category = "Creator"; Ecosystem = "Mint"; Notes = "Mint rollup" }
    @{ Name = "shape-mcp-server"; Url = "https://github.com/shape-network/mcp-server.git"; Category = "Creator"; Ecosystem = "Shape"; Notes = "Shape MCP" }
    @{ Name = "hashkey-chain"; Url = "https://github.com/hashkey-chain/hashkey-chain.git"; Category = "General"; Ecosystem = "HashKey"; Notes = "HashKey" }
    @{ Name = "redstone-node"; Url = "https://github.com/redstone-network/redstone-node.git"; Category = "Gaming"; Ecosystem = "Redstone"; Notes = "Gaming L2" }
    @{ Name = "xe-core"; Url = "https://github.com/XeChain/xe-core.git"; Category = "Gaming"; Ecosystem = "Xterio"; Notes = "Xterio Chain" }
    @{ Name = "zora-node"; Url = "https://github.com/himanii33/zora-node.git"; Category = "Creator"; Ecosystem = "Zora"; Notes = "Community" }
    @{ Name = "bob"; Url = "https://github.com/gobobofficial/bob.git"; Category = "Finance"; Ecosystem = "BOB"; Notes = "BTC-ETH hybrid" }
    @{ Name = "funki-registry"; Url = "https://github.com/funkichain/funki-superchain-registry.git"; Category = "Creator"; Ecosystem = "Funki"; Notes = "Config" }
    @{ Name = "metal-l2-docs"; Url = "https://github.com/MetalPay/metal-l2-docs.git"; Category = "Finance"; Ecosystem = "Metal L2"; Notes = "Docs only" }
    @{ Name = "swell-v3-core"; Url = "https://github.com/SwellNetwork/v3-core-public.git"; Category = "Finance"; Ecosystem = "Swell"; Notes = "Contracts" }
    @{ Name = "epicchain-node"; Url = "https://github.com/epicchainlabs/epicchain-node.git"; Category = "Finance"; Ecosystem = "Epic Chain"; Notes = "Epic" }
    @{ Name = "silentdata-node"; Url = "https://github.com/appliedblockchain/silentdata-node.git"; Category = "Finance"; Ecosystem = "Silent Data"; Notes = "Archived" }
)

$OptionalRepos = @(
    @{ Name = "celo-node"; Url = "https://github.com/celo-org/celo-node.git"; Category = "General"; Ecosystem = "Celo"; Notes = "L1 client" }
    @{ Name = "boba-node"; Url = "https://github.com/bobanetwork/boba-node.git"; Category = "Finance"; Ecosystem = "Boba"; Notes = "Boba" }
    @{ Name = "fraxtal-node"; Url = "https://github.com/fraxtal/fraxtal-node.git"; Category = "Finance"; Ecosystem = "Fraxtal"; Notes = "Fraxtal" }
)

# Banner
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SUPERCHAIN REPOSITORY CLONER" -ForegroundColor Cyan
Write-Host "  One-Folder Build-Out" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check git
try {
    $null = git --version
} catch {
    Write-Host "ERROR: Git is not installed" -ForegroundColor Red
    exit 1
}

# Prepare paths
$DestinationPath = [System.IO.Path]::GetFullPath($DestinationPath)
if (-not (Test-Path $DestinationPath)) {
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
    Write-Host "Created: $DestinationPath" -ForegroundColor Green
}

# Build repo list
$AllRepos = @() + $CoreRepos
if ($IncludeOptional) {
    $AllRepos += $OptionalRepos
}

Write-Host "Destination: $DestinationPath" -ForegroundColor Cyan
Write-Host "Repositories: $($AllRepos.Count)" -ForegroundColor Cyan
Write-Host "Shallow Clone: $ShallowClone" -ForegroundColor Cyan
Write-Host "Skip Existing: $SkipExisting" -ForegroundColor Cyan
Write-Host ""

# Stats
$success = 0
$skipped = 0
$failed = 0
$failedList = @()

Write-Host "Starting clone operations..." -ForegroundColor Green
Write-Host ""

foreach ($repo in $AllRepos) {
    $targetDir = Join-Path $DestinationPath $repo.Name
    
    if ((Test-Path $targetDir) -and $SkipExisting) {
        Write-Host "  [SKIP] $($repo.Ecosystem) - exists" -ForegroundColor Yellow
        $skipped++
        continue
    }
    
    if (Test-Path $targetDir) {
        Remove-Item -Path $targetDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "  [CLONE] $($repo.Ecosystem) ($($repo.Category))" -ForegroundColor Cyan
    
    $cloneArgs = @("clone", "--quiet")
    if ($ShallowClone) {
        $cloneArgs += "--depth"
        $cloneArgs += "1"
    }
    $cloneArgs += $repo.Url
    $cloneArgs += $targetDir
    
    try {
        $output = & git @cloneArgs 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "          OK - $($repo.Notes)" -ForegroundColor Green
            $success++
        } else {
            Write-Host "          FAILED" -ForegroundColor Red
            $failed++
            $failedList += $repo.Name
        }
    } catch {
        Write-Host "          ERROR: $_" -ForegroundColor Red
        $failed++
        $failedList += $repo.Name
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CLONE COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Cloned:  $success" -ForegroundColor Green
Write-Host "  Skipped: $skipped" -ForegroundColor Yellow
Write-Host "  Failed:  $failed" -ForegroundColor Red

if ($failedList.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed repos:" -ForegroundColor Yellow
    foreach ($f in $failedList) {
        Write-Host "  - $f" -ForegroundColor Red
    }
}

# Disk usage
$size = (Get-ChildItem -Path $DestinationPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
if (-not $size) { $size = 0 }
$sizeGB = [math]::Round($size / 1GB, 2)
Write-Host ""
Write-Host "Disk Usage: $sizeGB GB" -ForegroundColor Cyan

# Create index
$indexPath = Join-Path $DestinationPath "SUPERCHAIN_INDEX.md"
$indexLines = @(
    "# Superchain Ecosystem Index",
    "",
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Total: $($AllRepos.Count) repositories",
    "Disk: $sizeGB GB",
    "",
    "## Repositories",
    "",
    "| Ecosystem | Folder | Category | Notes |",
    "|-----------|--------|----------|-------|"
)

foreach ($repo in $AllRepos) {
    $indexLines += "| $($repo.Ecosystem) | $($repo.Name)/ | $($repo.Category) | $($repo.Notes) |"
}

$indexLines += ""
$indexLines += "## Quick Start"
$indexLines += ""
$indexLines += "cd optimism && make op-node"
$indexLines += "cd base-node && docker-compose up -d"

Set-Content -Path $indexPath -Value ($indexLines -join "`n") -Encoding UTF8
Write-Host "Index: $indexPath" -ForegroundColor Green
Write-Host ""
Write-Host "All repos in: $DestinationPath" -ForegroundColor Green
