<#
.SYNOPSIS
    Clone all security research repositories for offline access
.DESCRIPTION
    Downloads 18 advanced security research tools covering:
    - Cellular & Baseband (5G/LTE)
    - Satellite & Space Security (SATCOM)
    - Hardware Assurance & Fault Injection
    - RF Warfare & Cyber-Physical Systems
    - AI/ML Security & Post-Quantum
.PARAMETER TargetDir
    Target directory for cloned repositories (default: ./security-research)
.PARAMETER Shallow
    Use shallow clones to save space (default: true)
.EXAMPLE
    .\clone-security-research.ps1 -TargetDir "C:\security-research"
#>

param(
    [string]$TargetDir = ".\security-research",
    [switch]$Shallow = $true,
    [switch]$IncludeLFS = $false
)

$ErrorActionPreference = "Continue"

# Repository catalog organized by category
$Repositories = @{
    # =========================================================================
    # 1. Advanced Cellular & Baseband (5G/LTE)
    # =========================================================================
    "cellular" = @(
        @{
            Name = "Sni5Gect"
            Url = "https://github.com/asset-group/Sni5Gect-5GNR-sniffing-and-exploitation"
            Description = "5G NR sniffing and injection framework (5Ghoul exploits)"
            Hardware = "USRP B210/x310"
        },
        @{
            Name = "FirmWire"
            Url = "https://github.com/FirmWire/FirmWire"
            Description = "Full-system baseband emulation for Samsung/MediaTek"
            Hardware = "None (emulation)"
        },
        @{
            Name = "LTESniffer"
            Url = "https://github.com/SysSec-KAIST/LTESniffer"
            Description = "Real-time LTE PDCCH decoding and traffic interception"
            Hardware = "USRP B210"
        },
        @{
            Name = "srsRAN-Project"
            Url = "https://github.com/srsran/srsRAN_Project"
            Description = "Open-source 5G RAN implementation"
            Hardware = "USRP B210/x310"
        },
        @{
            Name = "Open5GS"
            Url = "https://github.com/open5gs/open5gs"
            Description = "Open-source 5G core network implementation"
            Hardware = "None (software)"
        }
    )

    # =========================================================================
    # 2. Satellite & Space Security (SATCOM)
    # =========================================================================
    "satellite" = @(
        @{
            Name = "Starlink-FI"
            Url = "https://github.com/KULeuven-COSIC/Starlink-FI"
            Description = "Voltage fault injection for Starlink terminals"
            Hardware = "RP2040 modchip, Starlink terminal"
        },
        @{
            Name = "gr-iridium"
            Url = "https://github.com/muccc/gr-iridium"
            Description = "GNU Radio Iridium satellite decoder"
            Hardware = "RTL-SDR, USRP, HackRF"
        },
        @{
            Name = "iridium-toolkit"
            Url = "https://github.com/muccc/iridium-toolkit"
            Description = "Iridium protocol analysis and voice reassembly"
            Hardware = "None (post-processing)"
        },
        @{
            Name = "SatDump"
            Url = "https://github.com/SatDump/SatDump"
            Description = "Generic satellite data decoder (NOAA, Meteor, etc.)"
            Hardware = "RTL-SDR, SDRPlay, Airspy"
        },
        @{
            Name = "Unblob"
            Url = "https://github.com/onekey-sec/unblob"
            Description = "Universal firmware extraction (satellite, IoT, etc.)"
            Hardware = "None (software)"
        }
    )

    # =========================================================================
    # 3. Hardware Assurance & Fault Injection
    # =========================================================================
    "hardware" = @(
        @{
            Name = "VoltPillager"
            Url = "https://github.com/zt-chen/voltpillager"
            Description = "Intel SVID bus voltage injection for SGX attacks"
            Hardware = "Teensy, target motherboard"
        },
        @{
            Name = "PicoEMP"
            Url = "https://github.com/newaetech/chipshouter-picoemp"
            Description = "Low-cost electromagnetic fault injection"
            Hardware = "Raspberry Pi Pico, HV components"
        },
        @{
            Name = "LFI-Rig"
            Url = "https://github.com/fraktalcyber/lfi-rig"
            Description = "Laser fault injection hardware designs"
            Hardware = "Laser diode, XY stage, optics"
        },
        @{
            Name = "Jlsca"
            Url = "https://github.com/Riscure/Jlsca"
            Description = "High-performance side-channel analysis in Julia"
            Hardware = "Oscilloscope, power probes"
        },
        @{
            Name = "ChipWhisperer"
            Url = "https://github.com/newaetech/chipwhisperer"
            Description = "Open-source hardware security platform"
            Hardware = "ChipWhisperer board"
        }
    )

    # =========================================================================
    # 4. RF Warfare & Cyber-Physical Systems
    # =========================================================================
    "rf-warfare" = @(
        @{
            Name = "FISSURE"
            Url = "https://github.com/ainfosec/FISSURE"
            Description = "Unified RF analysis framework with ML classification"
            Hardware = "USRP, HackRF, RTL-SDR, PlutoSDR"
        },
        @{
            Name = "GhostPeak-UWB"
            Url = "https://github.com/seemoo-lab/uwb-sniffer"
            Description = "UWB sniffing and distance-shortening attacks"
            Hardware = "DW1000/DW3000 dev board"
        },
        @{
            Name = "ICSFuzz"
            Url = "https://github.com/momalab/icsfuzz"
            Description = "CODESYS runtime fuzzer for PLCs"
            Hardware = "Target PLC or emulator"
        },
        @{
            Name = "eth-scapy-someip"
            Url = "https://github.com/jamores/eth-scapy-someip"
            Description = "Scapy extension for automotive SOME/IP"
            Hardware = "Automotive ethernet tap"
        },
        @{
            Name = "DragonOS"
            Url = "https://github.com/alphafox02/DragonOS"
            Description = "SDR-focused Linux distribution"
            Hardware = "Various SDRs"
        },
        @{
            Name = "TorchSig"
            Url = "https://github.com/TorchDSP/torchsig"
            Description = "Deep learning for RF signal processing"
            Hardware = "GPU recommended"
        }
    )

    # =========================================================================
    # 5. AI/ML Security & Post-Quantum
    # =========================================================================
    "ai-security" = @(
        @{
            Name = "Garak"
            Url = "https://github.com/NVIDIA/garak"
            Description = "LLM vulnerability scanner (nmap for LLMs)"
            Hardware = "None (API-based)"
        },
        @{
            Name = "Counterfit"
            Url = "https://github.com/Azure/counterfit"
            Description = "ML model adversarial attack framework"
            Hardware = "None (software)"
        },
        @{
            Name = "VerMFi"
            Url = "https://github.com/vmarribas/VerMFi"
            Description = "Masked implementation verification for PQC"
            Hardware = "None (verification tool)"
        },
        @{
            Name = "ART"
            Url = "https://github.com/Trusted-AI/adversarial-robustness-toolbox"
            Description = "IBM Adversarial Robustness Toolbox"
            Hardware = "GPU recommended"
        },
        @{
            Name = "TextAttack"
            Url = "https://github.com/QData/TextAttack"
            Description = "NLP adversarial attack framework"
            Hardware = "GPU recommended"
        }
    )

    # =========================================================================
    # 6. Firmware & Binary Analysis
    # =========================================================================
    "firmware" = @(
        @{
            Name = "OFRAK"
            Url = "https://github.com/redballoonsecurity/ofrak"
            Description = "Firmware reverse engineering and modification"
            Hardware = "None (software)"
        },
        @{
            Name = "Binwalk"
            Url = "https://github.com/ReFirmLabs/binwalk"
            Description = "Firmware analysis and extraction tool"
            Hardware = "None (software)"
        },
        @{
            Name = "EMBA"
            Url = "https://github.com/e-m-b-a/emba"
            Description = "Embedded firmware analyzer"
            Hardware = "None (software)"
        }
    )
}

# Create target directory
$TargetPath = Resolve-Path -Path $TargetDir -ErrorAction SilentlyContinue
if (-not $TargetPath) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    $TargetPath = Resolve-Path -Path $TargetDir
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Security Research Repository Cloner" -ForegroundColor Cyan
Write-Host " Target: $TargetPath" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Statistics
$TotalRepos = 0
$SuccessCount = 0
$FailCount = 0
$SkipCount = 0

# Clone function
function Clone-Repository {
    param(
        [string]$Url,
        [string]$Name,
        [string]$Category,
        [string]$Description
    )
    
    $RepoPath = Join-Path $TargetPath $Category $Name
    
    if (Test-Path $RepoPath) {
        Write-Host "  [SKIP] " -ForegroundColor Yellow -NoNewline
        Write-Host "$Name already exists"
        return "skip"
    }
    
    $ParentPath = Split-Path $RepoPath -Parent
    if (-not (Test-Path $ParentPath)) {
        New-Item -ItemType Directory -Path $ParentPath -Force | Out-Null
    }
    
    Write-Host "  [CLONE] " -ForegroundColor Green -NoNewline
    Write-Host "$Name - $Description"
    
    $CloneArgs = @("clone")
    if ($Shallow) {
        $CloneArgs += "--depth"
        $CloneArgs += "1"
    }
    $CloneArgs += $Url
    $CloneArgs += $RepoPath
    
    $Process = Start-Process -FilePath "git" -ArgumentList $CloneArgs -Wait -PassThru -NoNewWindow -RedirectStandardError "NUL"
    
    if ($Process.ExitCode -eq 0) {
        return "success"
    } else {
        Write-Host "    [ERROR] Failed to clone $Name" -ForegroundColor Red
        return "fail"
    }
}

# Process each category
foreach ($Category in $Repositories.Keys) {
    Write-Host ""
    Write-Host "[$($Category.ToUpper())]" -ForegroundColor Magenta
    Write-Host ("-" * 60)
    
    foreach ($Repo in $Repositories[$Category]) {
        $TotalRepos++
        $Result = Clone-Repository -Url $Repo.Url -Name $Repo.Name -Category $Category -Description $Repo.Description
        
        switch ($Result) {
            "success" { $SuccessCount++ }
            "fail" { $FailCount++ }
            "skip" { $SkipCount++ }
        }
    }
}

# Create manifest file
$ManifestPath = Join-Path $TargetPath "MANIFEST.json"
$Manifest = @{
    generated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    total_repositories = $TotalRepos
    categories = $Repositories.Keys | ForEach-Object { $_ }
    repositories = $Repositories
}
$Manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $ManifestPath

# Create README
$ReadmePath = Join-Path $TargetPath "README.md"
@"
# Security Research Repositories

This directory contains cloned security research tools for offline access.

## Categories

| Category | Description | Repos |
|----------|-------------|-------|
| cellular | 5G/LTE baseband exploitation | $($Repositories["cellular"].Count) |
| satellite | SATCOM interception & analysis | $($Repositories["satellite"].Count) |
| hardware | Fault injection & side-channel | $($Repositories["hardware"].Count) |
| rf-warfare | RF spectrum & ICS security | $($Repositories["rf-warfare"].Count) |
| ai-security | LLM/ML adversarial testing | $($Repositories["ai-security"].Count) |
| firmware | Binary analysis & extraction | $($Repositories["firmware"].Count) |

## Legal Warning

⚠️ **These tools are for authorized security research only.**

Many tools require specialized hardware and may have legal restrictions:
- Cellular tools require licensed spectrum access
- SDR transmission requires amateur radio license or research authorization
- Hardware attacks require physical access authorization
- AI security tools should only target systems you own or have permission to test

## Generated

$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@ | Set-Content -Path $ReadmePath

# Summary
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Clone Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Total Repositories: $TotalRepos"
Write-Host "  Cloned:             $SuccessCount" -ForegroundColor Green
Write-Host "  Skipped:            $SkipCount" -ForegroundColor Yellow
Write-Host "  Failed:             $FailCount" -ForegroundColor Red
Write-Host ""
Write-Host "  Manifest: $ManifestPath"
Write-Host "  Target:   $TargetPath"
Write-Host ""
