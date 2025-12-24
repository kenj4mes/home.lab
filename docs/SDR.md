# 📡 SDR & Radio Security Research

> **⚠️ LEGAL WARNING**: These tools are for EDUCATIONAL and SECURITY RESEARCH purposes only.
> Check local laws before using cellular monitoring tools.
> We are not responsible for any illegal use of these tools.

## Overview

HomeLab includes a comprehensive Software Defined Radio (SDR) stack for cellular security research, IMSI catcher detection, and 5G network analysis.

```
╔════════════════════════════════════════════════════════════════════════════╗
║                    🔊 SDR Security Research Stack                          ║
╠════════════════════════════════════════════════════════════════════════════╣
║  IMSI Catcher    → GSM IMSI detection using RTL-SDR                       ║
║  Rayhunter       → EFF's IMSI catcher detector for mobile hotspots        ║
║  LTESniffer      → LTE downlink/uplink traffic analysis                   ║
║  srsRAN 5G       → Open-source 5G gNB base station                        ║
║  DragonOS        → SDR-focused Linux distribution tools                   ║
╚════════════════════════════════════════════════════════════════════════════╝
```

## Hardware Requirements

| Tool | Minimum Hardware | Recommended |
|------|-----------------|-------------|
| **IMSI Catcher** | RTL-SDR USB dongle (~$15) | HackRF One, BladeRF |
| **Rayhunter** | Orbic RC400L hotspot | Any supported device |
| **LTESniffer** | USRP B210 (downlink) | USRP X310 (uplink) |
| **srsRAN 5G** | USRP B210 + ZMQ | USRP X310 + 10GbE |

### CPU Requirements

LTE/5G sniffing requires significant CPU power:
- **Minimum**: Intel i5 with 4+ cores
- **Recommended**: Intel i7/i9 with 8+ physical cores
- **RAM**: 16GB minimum, 32GB recommended

## Quick Start

### Start SDR Stack

```powershell
# Windows
.\homelab.ps1 -Action sdr

# Or manually
docker compose -f docker/docker-compose.sdr.yml --profile sdr up -d
```

### Access Dashboard

Open http://localhost:8585 for the unified SDR dashboard.

## Tools

### 1. IMSI Catcher (GSM Analysis)

Detects and displays IMSI numbers from nearby GSM devices.

```bash
# Start IMSI catcher container
docker compose -f docker/docker-compose.sdr.yml up -d imsi-catcher

# View logs
docker logs -f imsi-catcher
```

**How it works:**
1. Uses `grgsm_livemon` to decode GSM signals
2. Captures IMSI, TMSI, MCC, MNC from broadcast channels
3. Logs to SQLite or MySQL database

**Usage:**
```bash
# Inside container
python3 simple_IMSI-catcher.py -s

# In another terminal
grgsm_livemon -f 925.4M  # Adjust frequency
```

### 2. Rayhunter (IMSI Catcher Detector)

EFF's tool for detecting stingrays and cell-site simulators.

```bash
# Start Rayhunter
docker compose -f docker/docker-compose.sdr.yml up -d rayhunter-web

# Access web interface
open http://localhost:8580
```

**Features:**
- Detects anomalous cell tower behavior
- Designed for easy use by non-technical users
- Minimizes false positives
- Supports Orbic RC400L and other devices

**Learn More:** https://www.eff.org/deeplinks/2025/03/meet-rayhunter-new-open-source-tool-eff-detect-cellular-spying

### 3. LTESniffer (LTE Traffic Analysis)

Open-source LTE eavesdropper for security research.

```bash
# Start LTESniffer
docker compose -f docker/docker-compose.sdr.yml --profile advanced up -d ltesniffer

# Run analysis
docker exec -it ltesniffer ./LTESniffer -A 2 -W 4 -f 1840e6 -C -m 0
```

**Modes:**
- **Downlink sniffing** (`-m 0`): Capture base station → phones
- **Uplink sniffing** (`-m 1`): Capture phones → base station (requires USRP X310)
- **Security API** (`-z 3`): Identity mapping, IMSI collecting, capability profiling

**Output:**
- `sniffer_dl_mode.pcap` - Downlink packets
- `sniffer_ul_mode.pcap` - Uplink packets
- Open in Wireshark for analysis

**Important Notes:**
- LTESniffer **CANNOT DECRYPT** encrypted traffic
- Only unencrypted control plane messages are visible
- Useful for protocol analysis and security research

### 4. srsRAN 5G gNB

Open-source 5G base station for testing and research.

```bash
# Start srsRAN gNB
docker compose -f docker/docker-compose.sdr.yml --profile 5g up -d srsran-gnb

# View configuration
docker exec -it srsran-gnb cat /app/configs/gnb.yml
```

**Use Cases:**
- Private 5G network testing
- Security research on 5G protocols
- Cellular protocol development
- Faraday cage testing environments

**Documentation:** https://docs.srsran.com/projects/project

### 5. DragonOS Tools

Container with pre-installed SDR tools from DragonOS.

```bash
# Start DragonOS container
docker compose -f docker/docker-compose.sdr.yml --profile dragonos up -d dragonos

# Access shell
docker exec -it dragonos-tools bash

# Available tools
gnuradio-companion    # GNU Radio
hackrf_info           # HackRF utilities
rtl_test              # RTL-SDR test
```

## Frequency Reference

### GSM Bands

| Band | Uplink (MHz) | Downlink (MHz) | Region |
|------|-------------|----------------|--------|
| GSM 850 | 824-849 | 869-894 | Americas |
| GSM 900 | 880-915 | 925-960 | Europe, Asia |
| GSM 1800 | 1710-1785 | 1805-1880 | Europe, Asia |
| GSM 1900 | 1850-1910 | 1930-1990 | Americas |

### LTE Bands

| Band | Uplink (MHz) | Downlink (MHz) | Common Name |
|------|-------------|----------------|-------------|
| 2 | 1850-1910 | 1930-1990 | PCS |
| 4 | 1710-1755 | 2110-2155 | AWS-1 |
| 7 | 2500-2570 | 2620-2690 | IMT-E |
| 12 | 699-716 | 729-746 | Lower 700 |
| 66 | 1710-1780 | 2110-2200 | AWS-3 |

### 5G NR Bands

| Band | Frequency Range | Bandwidth |
|------|-----------------|-----------|
| n77 | 3.3-4.2 GHz | C-Band |
| n78 | 3.3-3.8 GHz | C-Band |
| n79 | 4.4-5.0 GHz | C-Band |
| n257 | 26.5-29.5 GHz | mmWave |
| n258 | 24.25-27.5 GHz | mmWave |

## Security Considerations

### Ethical Use

1. **Only use in controlled environments** (Faraday cages, labs)
2. **Never intercept communications** without authorization
3. **Comply with local laws** (FCC, OFCOM, etc.)
4. **For research and education** only

### Legal Framework

| Region | Relevant Laws |
|--------|---------------|
| USA | Communications Act, Wiretap Act, CALEA |
| EU | GDPR, ePrivacy Directive |
| UK | Wireless Telegraphy Act, RIPA |

### Best Practices

- Use shielded environments (Faraday cages)
- Document all research activities
- Obtain proper authorization
- Report vulnerabilities responsibly

## Troubleshooting

### USB Device Not Found

```bash
# Check USB devices
lsusb

# Add udev rules for RTL-SDR
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", MODE="0666"' | \
    sudo tee /etc/udev/rules.d/rtl-sdr.rules
sudo udevadm control --reload-rules
```

### No Signal / Poor Reception

1. Check antenna connection
2. Try different frequencies
3. Use `grgsm_scanner` to find active cells
4. Adjust gain settings
5. Move to location with better signal

### USRP Not Detected

```bash
# Update USRP firmware
uhd_images_downloader

# Check connection
uhd_usrp_probe

# For X310 via 10GbE
sudo ifconfig <interface> mtu 9000
sudo sysctl -w net.core.rmem_max=33554432
```

## Resources

- [GNU Radio](https://www.gnuradio.org/)
- [srsRAN Project](https://www.srsran.com/)
- [Osmocom GSM](https://osmocom.org/projects/gr-gsm)
- [EFF Rayhunter](https://github.com/EFForg/rayhunter)
- [LTESniffer Paper](https://syssec.kaist.ac.kr/pub/2023/wisec2023_tuan.pdf)
- [DragonOS](https://sourceforge.net/projects/dragonos-10/)

## CLI Reference

```powershell
# Start all SDR services
.\homelab.ps1 -Action sdr

# Start specific profile
docker compose -f docker/docker-compose.sdr.yml --profile research up -d

# View SDR dashboard
.\homelab.ps1 -Action sdr-dashboard

# Stop SDR services
docker compose -f docker/docker-compose.sdr.yml down
```
