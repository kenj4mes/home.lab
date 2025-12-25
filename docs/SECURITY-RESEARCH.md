# 🔬 Security Research Stack

> **Advanced Signal Intelligence, Hardware Assurance, and AI Security Tools**

⚠️ **Legal Warning**: These tools are for authorized security research only. Many require specialized hardware and may have legal restrictions. Always ensure proper authorization before testing any systems.

---

## 📋 Overview

The Security Research Stack provides a comprehensive suite of tools for:

| Category | Description | Tools |
|----------|-------------|-------|
| **AI/ML Security** | LLM vulnerability scanning, adversarial ML | Garak, Counterfit, ART |
| **RF & Spectrum** | Signal classification, protocol ID | FISSURE, TorchSig, Signal Classifier |
| **Cellular** | 5G/LTE security research | Sni5Gect, FirmWire, LTESniffer |
| **Satellite** | SATCOM interception & analysis | gr-iridium, SatDump, Starlink-FI |
| **Firmware** | Binary analysis & extraction | Unblob, OFRAK, EMBA |
| **Hardware** | Fault injection, side-channel | PicoEMP, VoltPillager, Jlsca |
| **ICS/SCADA** | Industrial protocol fuzzing | ICSFuzz, Modbus/S7 |
| **Automotive** | Vehicle network analysis | SOME/IP, UDS, UWB |

---

## 🚀 Quick Start

### Start Security Research Services

```powershell
# Windows - Start AI security tools
docker compose -f docker/docker-compose.security-research.yml --profile ai-security up -d

# Start firmware analysis
docker compose -f docker/docker-compose.security-research.yml --profile firmware-analysis up -d

# Start RF analysis (requires GPU for ML classification)
docker compose -f docker/docker-compose.security-research.yml --profile rf-analysis up -d

# Start all profiles
docker compose -f docker/docker-compose.security-research.yml --profile ai-security --profile firmware-analysis --profile rf-analysis up -d
```

### Clone All Research Repositories (Offline Access)

```powershell
# Windows
.\scripts\clone-security-research.ps1 -TargetDir ".\security-research"

# Linux/macOS
./scripts/clone-security-research.sh ./security-research
```

### Access Dashboard

Open http://localhost:5610 for the unified Security Research Dashboard.

---

## 🛡️ AI/ML Security Tools

### Garak - LLM Vulnerability Scanner

**Port**: 5600 | **"nmap for LLMs"**

Garak probes Large Language Models for vulnerabilities including:
- Prompt injection attacks
- Jailbreak attempts (DAN, DUDE, etc.)
- Encoding bypasses (Base64, ROT13, Hex)
- Data leakage
- Hallucination detection
- Toxicity and harmful content

#### API Usage

```bash
# Start an LLM scan against Ollama
curl -X POST http://localhost:5600/scan \
  -H "Content-Type: application/json" \
  -d '{
    "model_type": "ollama",
    "model_name": "llama2",
    "api_base": "http://ollama:11434",
    "probes": ["promptinject", "dan"],
    "generations": 5
  }'

# Check scan status
curl http://localhost:5600/scan/{scan_id}

# Get full report
curl http://localhost:5600/scan/{scan_id}/report
```

#### Supported Model Types
| Type | Description | Required Config |
|------|-------------|-----------------|
| `ollama` | Local Ollama models | `api_base` |
| `openai` | OpenAI API | `OPENAI_API_KEY` env |
| `huggingface` | Hugging Face models | Model name |
| `rest` | Custom REST API | `api_base`, `api_key` |

### Counterfit - ML Model Security

**Port**: 5601

Microsoft's framework for assessing ML model security:
- Evasion attacks
- Poisoning attacks
- Model inversion
- Membership inference

### Adversarial Robustness Toolbox (ART)

IBM's comprehensive adversarial ML library (in cloned repos):
- Attack implementations
- Defense mechanisms
- Robustness metrics
- Certified defenses

---

## 📡 RF & Spectrum Analysis

### Signal Classifier

**Port**: 5604 | **ML-based RF Signal Classification**

Classifies RF signals by modulation and protocol:

```bash
# Upload IQ data for classification
curl -X POST http://localhost:5604/classify \
  -F "file=@capture.raw" \
  -F "sample_rate=2400000" \
  -F "center_freq=2437000000"

# Response
{
  "classification_id": "abc123",
  "modulation": "OFDM",
  "modulation_confidence": 0.87,
  "protocol": "wifi_2.4ghz",
  "protocol_confidence": 0.92,
  "signal_features": {
    "snr_db": 22.5,
    "bandwidth_hz": 20000000,
    "power_dbm": -45.2
  }
}
```

#### Supported Modulations
- **Amplitude**: OOK, 4ASK, 8ASK
- **Phase**: BPSK, QPSK, 8PSK, 16PSK, 32PSK
- **Quadrature**: 16QAM, 32QAM, 64QAM, 128QAM, 256QAM
- **Frequency**: 2FSK, 4FSK, 8FSK, 16FSK, GMSK
- **Multicarrier**: OFDM

#### Protocol Signatures
| Protocol | Frequency Range | Bandwidth |
|----------|-----------------|-----------|
| WiFi 2.4GHz | 2400-2500 MHz | 20-40 MHz |
| WiFi 5GHz | 5150-5850 MHz | 40-160 MHz |
| Bluetooth | 2400-2483 MHz | 1 MHz |
| ZigBee | 2400-2500 MHz | 2 MHz |
| LTE Band 7 | 2500-2690 MHz | 10-20 MHz |
| 5G n78 | 3300-3800 MHz | 100 MHz |
| LoRaWAN | 868-928 MHz | 125-500 kHz |
| ADS-B | 1090 MHz | 1 MHz |
| GPS L1 | 1575.42 MHz | 2 MHz |

### FISSURE Integration

FISSURE (Frequency Independent SDR-based Signal Understanding and Reverse Engineering) is a unified RF framework. Due to its GUI requirements, we provide an API wrapper for headless operation.

**Cloned Repository**: `security-research/rf-warfare/FISSURE`

Full FISSURE requires:
- Linux with X11
- Compatible SDR (USRP, HackRF, RTL-SDR, PlutoSDR)
- GNU Radio 3.10+

### TorchSig

Deep learning library for RF signal processing (in cloned repos):
- Modulation classification
- Signal detection
- Interference mitigation
- Synthetic data generation

---

## 🔧 Firmware Analysis

### Firmware Analyzer API

**Port**: 5602 | **Universal Firmware Extraction**

Combines Unblob and Binwalk for comprehensive firmware analysis:

```bash
# Upload firmware for analysis
curl -X POST http://localhost:5602/upload \
  -F "file=@firmware.bin"

# Response
{
  "analysis_id": "xyz789",
  "status": "queued",
  "sha256": "a1b2c3..."
}

# Check status
curl http://localhost:5602/analysis/xyz789

# List extracted files
curl http://localhost:5602/analysis/xyz789/files

# Download specific file
curl http://localhost:5602/analysis/xyz789/file/etc/passwd
```

#### Security Findings

The analyzer automatically identifies security-relevant files:

| Category | Patterns |
|----------|----------|
| **Credentials** | passwd, shadow, .pem, .key, .crt |
| **Config** | *.conf, *.cfg, *.ini, *.json, *.yaml |
| **Scripts** | *.sh, *.py, init.d/*, rc.d/* |
| **Binaries** | busybox, dropbear, telnetd, sshd |
| **Web** | *.php, *.cgi, htdocs/*, www/* |
| **Database** | *.db, *.sqlite, *.sql |

### OFRAK (Cloned)

Open Firmware Reverse Analysis Konsole - firmware modification:
- Unpack → Modify → Repack workflow
- Automatic offset/CRC recalculation
- Binary patching and backdoor insertion

### EMBA (Cloned)

Embedded firmware security analyzer:
- Automated vulnerability scanning
- CVE detection
- Hardcoded credential detection
- Binary analysis

---

## 📱 Cellular & Baseband (5G/LTE)

> ⚠️ **Legal Notice**: Cellular interception requires proper authorization. Transmission on licensed spectrum requires appropriate licenses.

### Sni5Gect (Cloned)

5G NR sniffing and injection framework with 5Ghoul exploits:

| Exploit | CVE | Attack Vector |
|---------|-----|---------------|
| RRC Setup Crash | CVE-2023-20702 | Malformed RRC Setup |
| MTK Crash | CVE-2023-32843 | RLC bearer config |
| Downgrade | - | Registration Reject |
| Identity Request | - | SUCI/IMSI extraction |
| Auth Replay | CVD-2024-0096 | T3520 timer exhaustion |

**Hardware Required**: USRP B210/x310

### FirmWire (Cloned)

Full-system baseband emulation:
- Samsung Shannon baseband
- MediaTek basebands
- Instrumented fuzzing
- Root-cause analysis

**Hardware Required**: None (software emulation)

### LTESniffer (Cloned)

Real-time LTE traffic interception:
- PDCCH blind decoding
- RNTI tracking
- Uplink/Downlink capture
- IMSI collection

**Hardware Required**: USRP B210

---

## 🛰️ Satellite & SATCOM

### gr-iridium (Cloned)

GNU Radio Iridium satellite decoder:
- Burst detection
- QPSK demodulation
- Doppler correction
- Voice/pager extraction

**Hardware Required**: RTL-SDR, USRP, HackRF, Airspy

### iridium-toolkit (Cloned)

Iridium protocol analysis:
- Voice reassembly
- Pager decoding
- Traffic analysis
- Geolocation

### SatDump (Cloned)

Multi-satellite decoder:
- NOAA APT/HRPT
- Meteor-M LRPT
- GOES HRIT/GRB
- Elektro-L
- FengYun

### Starlink-FI (Cloned)

Voltage fault injection for Starlink terminals:
- RP2040-based modchip
- Secure boot bypass
- Firmware extraction

**Hardware Required**: RP2040, Starlink terminal, MOSFET driver

---

## ⚡ Hardware Security

### PicoEMP (Cloned)

Low-cost Electromagnetic Fault Injection:
- Raspberry Pi Pico-based
- <$30 build cost
- Sufficient for many IoT SoCs
- Code readout protection bypass

**Hardware Required**: Raspberry Pi Pico, HV components

### VoltPillager (Cloned)

Intel SGX voltage attacks:
- SVID bus injection
- Teensy-based
- Bypasses software patches
- SGX enclave compromise

**Hardware Required**: Teensy, target motherboard

### Jlsca (Cloned)

High-performance side-channel analysis:
- Julia-based (fast!)
- Differential Power Analysis (DPA)
- Correlation Power Analysis (CPA)
- High-order attacks
- Masking evaluation

**Hardware Required**: Oscilloscope, power probes

### ChipWhisperer (Cloned)

Complete hardware security platform:
- Side-channel analysis
- Fault injection
- Glitch attacks
- Open-source hardware

---

## 🏭 ICS/SCADA Security

### ICSFuzz (Cloned)

CODESYS runtime fuzzer:
- Native PLC code fuzzing
- Control logic testing
- Memory corruption detection
- I/O manipulation

**Hardware Required**: Target PLC or CODESYS runtime

### Protocol Support

| Protocol | Port | Tool |
|----------|------|------|
| Modbus TCP | 502 | Scapy, Nmap |
| S7Comm | 102 | Snap7, s7scan |
| EtherNet/IP | 44818 | pycomm3 |
| DNP3 | 20000 | dnp3-master |
| BACnet | 47808 | bacpypes |

---

## 🚗 Automotive Security

### SOME/IP Analysis (eth-scapy-someip)

Scapy extension for automotive ethernet:
- Service discovery fuzzing
- RPC packet crafting
- MitM attacks
- Protocol analysis

### UWB Security (GhostPeak)

Ultra-Wideband distance-shortening attacks:
- Leading edge injection
- Secure ranging bypass
- Car key attacks
- Access control bypass

**Hardware Required**: DW1000/DW3000 development board

---

## 📊 Service Ports Reference

| Service | Port | Profile | Description |
|---------|------|---------|-------------|
| Garak | 5600 | ai-security | LLM vulnerability scanner |
| Counterfit | 5601 | ai-security | ML adversarial testing |
| Firmware Analyzer | 5602 | firmware-analysis | Firmware extraction API |
| FISSURE API | 5603 | rf-analysis | RF signal analysis |
| Signal Classifier | 5604 | rf-analysis | ML signal classification |
| ICS Fuzzer | 5605 | ics-security | ICS protocol fuzzing |
| Automotive Analyzer | 5606 | automotive-security | Vehicle protocol analysis |
| SCA Analyzer | 5607 | hardware-security | Side-channel analysis |
| Security Dashboard | 5610 | (default) | Unified dashboard |

---

## 🔒 Security Considerations

### Network Isolation

```bash
# Create isolated network for security research
docker network create --driver bridge \
  --opt com.docker.network.bridge.enable_icc=false \
  security-research-isolated
```

### Data Handling

- All firmware samples stored in `/firmware` volume
- Extracted files in `/extracted` volume
- RF captures in `/captures` volume
- Reports in `/app/data/reports`

### Legal Compliance

1. **Cellular/RF Transmission**: Requires amateur radio license or FCC experimental license
2. **Firmware Analysis**: Only analyze firmware you own or have written authorization
3. **LLM Testing**: Only test models you have access rights to
4. **Hardware Attacks**: Requires physical ownership or authorization
5. **ICS Testing**: Never test production control systems

---

## 📚 Additional Resources

### Learning Materials

- [FISSURE Documentation](https://github.com/ainfosec/FISSURE/wiki)
- [ChipWhisperer Tutorials](https://chipwhisperer.readthedocs.io/)
- [Garak Probes Documentation](https://github.com/NVIDIA/garak/blob/main/docs/probes.md)
- [TorchSig Examples](https://github.com/TorchDSP/torchsig/tree/main/examples)

### Hardware Suppliers

| Equipment | Purpose | Source |
|-----------|---------|--------|
| RTL-SDR | Budget SDR | rtl-sdr.com |
| HackRF One | TX/RX SDR | greatscottgadgets.com |
| USRP B210 | Professional SDR | ettus.com |
| ChipWhisperer | Hardware security | newae.com |
| PicoEMP | DIY fault injection | newae.com (open source) |

---

## 🔄 Updates

```bash
# Update all cloned repositories
cd security-research
for dir in */*/; do
  echo "Updating $dir..."
  (cd "$dir" && git pull)
done
```

---

*"The 2024-2025 security landscape is defined by the availability of active, integrated, and physical exploitation tools."*
