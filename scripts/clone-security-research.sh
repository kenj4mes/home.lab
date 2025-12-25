#!/bin/bash
#
# Clone all security research repositories for offline access
# Downloads 28+ advanced security research tools
#
# Usage: ./clone-security-research.sh [target-dir] [--shallow]
#

set -e

TARGET_DIR="${1:-./security-research}"
SHALLOW="${2:---shallow}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Statistics
TOTAL=0
SUCCESS=0
FAIL=0
SKIP=0

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[SKIP]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_category() { echo -e "\n${MAGENTA}[$1]${NC}"; echo "------------------------------------------------------------"; }

clone_repo() {
    local url="$1"
    local name="$2"
    local category="$3"
    local desc="$4"
    
    local repo_path="$TARGET_DIR/$category/$name"
    
    TOTAL=$((TOTAL + 1))
    
    if [ -d "$repo_path" ]; then
        log_warn "$name already exists"
        SKIP=$((SKIP + 1))
        return
    fi
    
    mkdir -p "$(dirname "$repo_path")"
    
    echo -e "  ${GREEN}[CLONE]${NC} $name - $desc"
    
    local clone_args="clone"
    if [ "$SHALLOW" == "--shallow" ]; then
        clone_args="clone --depth 1"
    fi
    
    if git $clone_args "$url" "$repo_path" 2>/dev/null; then
        SUCCESS=$((SUCCESS + 1))
    else
        log_error "Failed to clone $name"
        FAIL=$((FAIL + 1))
    fi
}

# Create target directory
mkdir -p "$TARGET_DIR"
TARGET_DIR=$(cd "$TARGET_DIR" && pwd)

echo "============================================================"
echo " Security Research Repository Cloner"
echo " Target: $TARGET_DIR"
echo "============================================================"

# =============================================================================
# 1. Advanced Cellular & Baseband (5G/LTE)
# =============================================================================
log_category "CELLULAR"
clone_repo "https://github.com/asset-group/Sni5Gect-5GNR-sniffing-and-exploitation" "Sni5Gect" "cellular" "5G NR sniffing and injection"
clone_repo "https://github.com/FirmWire/FirmWire" "FirmWire" "cellular" "Baseband emulation for Samsung/MediaTek"
clone_repo "https://github.com/SysSec-KAIST/LTESniffer" "LTESniffer" "cellular" "LTE PDCCH decoding and interception"
clone_repo "https://github.com/srsran/srsRAN_Project" "srsRAN-Project" "cellular" "Open-source 5G RAN"
clone_repo "https://github.com/open5gs/open5gs" "Open5GS" "cellular" "Open-source 5G core network"

# =============================================================================
# 2. Satellite & Space Security (SATCOM)
# =============================================================================
log_category "SATELLITE"
clone_repo "https://github.com/KULeuven-COSIC/Starlink-FI" "Starlink-FI" "satellite" "Voltage fault injection for Starlink"
clone_repo "https://github.com/muccc/gr-iridium" "gr-iridium" "satellite" "GNU Radio Iridium decoder"
clone_repo "https://github.com/muccc/iridium-toolkit" "iridium-toolkit" "satellite" "Iridium protocol analysis"
clone_repo "https://github.com/SatDump/SatDump" "SatDump" "satellite" "Generic satellite data decoder"
clone_repo "https://github.com/onekey-sec/unblob" "Unblob" "satellite" "Universal firmware extraction"

# =============================================================================
# 3. Hardware Assurance & Fault Injection
# =============================================================================
log_category "HARDWARE"
clone_repo "https://github.com/zt-chen/voltpillager" "VoltPillager" "hardware" "Intel SVID voltage injection"
clone_repo "https://github.com/newaetech/chipshouter-picoemp" "PicoEMP" "hardware" "Low-cost EM fault injection"
clone_repo "https://github.com/fraktalcyber/lfi-rig" "LFI-Rig" "hardware" "Laser fault injection hardware"
clone_repo "https://github.com/Riscure/Jlsca" "Jlsca" "hardware" "Side-channel analysis in Julia"
clone_repo "https://github.com/newaetech/chipwhisperer" "ChipWhisperer" "hardware" "Hardware security platform"

# =============================================================================
# 4. RF Warfare & Cyber-Physical Systems
# =============================================================================
log_category "RF-WARFARE"
clone_repo "https://github.com/ainfosec/FISSURE" "FISSURE" "rf-warfare" "Unified RF analysis framework"
clone_repo "https://github.com/seemoo-lab/uwb-sniffer" "GhostPeak-UWB" "rf-warfare" "UWB distance attacks"
clone_repo "https://github.com/momalab/icsfuzz" "ICSFuzz" "rf-warfare" "CODESYS PLC fuzzer"
clone_repo "https://github.com/jamores/eth-scapy-someip" "eth-scapy-someip" "rf-warfare" "Automotive SOME/IP"
clone_repo "https://github.com/alphafox02/DragonOS" "DragonOS" "rf-warfare" "SDR Linux distribution"
clone_repo "https://github.com/TorchDSP/torchsig" "TorchSig" "rf-warfare" "Deep learning for RF"

# =============================================================================
# 5. AI/ML Security & Post-Quantum
# =============================================================================
log_category "AI-SECURITY"
clone_repo "https://github.com/NVIDIA/garak" "Garak" "ai-security" "LLM vulnerability scanner"
clone_repo "https://github.com/Azure/counterfit" "Counterfit" "ai-security" "ML adversarial attacks"
clone_repo "https://github.com/vmarribas/VerMFi" "VerMFi" "ai-security" "PQC mask verification"
clone_repo "https://github.com/Trusted-AI/adversarial-robustness-toolbox" "ART" "ai-security" "Adversarial robustness"
clone_repo "https://github.com/QData/TextAttack" "TextAttack" "ai-security" "NLP adversarial attacks"

# =============================================================================
# 6. Firmware & Binary Analysis
# =============================================================================
log_category "FIRMWARE"
clone_repo "https://github.com/redballoonsecurity/ofrak" "OFRAK" "firmware" "Firmware RE and modification"
clone_repo "https://github.com/ReFirmLabs/binwalk" "Binwalk" "firmware" "Firmware extraction"
clone_repo "https://github.com/e-m-b-a/emba" "EMBA" "firmware" "Embedded firmware analyzer"

# Create manifest
cat > "$TARGET_DIR/MANIFEST.json" << EOF
{
  "generated": "$(date -Iseconds)",
  "total_repositories": $TOTAL,
  "cloned": $SUCCESS,
  "skipped": $SKIP,
  "failed": $FAIL
}
EOF

# Create README
cat > "$TARGET_DIR/README.md" << 'EOF'
# Security Research Repositories

This directory contains cloned security research tools for offline access.

## Categories

| Category | Description |
|----------|-------------|
| cellular | 5G/LTE baseband exploitation |
| satellite | SATCOM interception & analysis |
| hardware | Fault injection & side-channel |
| rf-warfare | RF spectrum & ICS security |
| ai-security | LLM/ML adversarial testing |
| firmware | Binary analysis & extraction |

## Legal Warning

⚠️ **These tools are for authorized security research only.**

Many tools require specialized hardware and may have legal restrictions.
EOF

# Summary
echo ""
echo "============================================================"
echo " Clone Summary"
echo "============================================================"
echo "  Total Repositories: $TOTAL"
echo -e "  Cloned:             ${GREEN}$SUCCESS${NC}"
echo -e "  Skipped:            ${YELLOW}$SKIP${NC}"
echo -e "  Failed:             ${RED}$FAIL${NC}"
echo ""
echo "  Target: $TARGET_DIR"
echo ""
