# srsRAN 5G

Open-source 5G RAN (Radio Access Network) implementation for research and development.

## ⚠️ Legal Warning

**LICENSED USE ONLY.** Operating a cellular base station requires appropriate spectrum licenses. This is for:
- Shielded RF test environments
- Licensed research facilities  
- Educational purposes with proper containment

Unlicensed transmission is a federal crime in most countries.

## Features

- Full 5G NR gNB (base station) implementation
- SA (Standalone) and NSA mode support
- Open5GS core network integration
- Multiple UE (device) support
- Real-time metrics and logging

## Requirements

- **SDR Hardware**: USRP B200/B210, USRP X300/X310
- **RF Shielding**: Faraday cage or shielded enclosure
- **CPU**: High-performance (8+ cores, 3+ GHz)
- **Memory**: 16GB+ RAM
- **License**: Experimental radio license

## Deployment

### Docker Compose

```bash
cd home.lab
docker compose -f docker/docker-compose.sdr.yml up -d srsran
```

### Notes

- Requires UHD drivers installed on host
- Must run with host networking
- Real-time kernel recommended

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `GNB_ID` | `1` | gNB identifier |
| `TAC` | `1` | Tracking Area Code |
| `MCC` | `001` | Mobile Country Code |
| `MNC` | `01` | Mobile Network Code |
| `RF_DEVICE` | `uhd` | SDR driver |

## Architecture

```
srsRAN gNB <-> Open5GS Core <-> Internet
    |              |
   UEs         AMF/SMF/UPF
```

## Supported SDR Hardware

| Hardware | Bandwidth | TX Power | Use Case |
|----------|-----------|----------|----------|
| USRP B200 | 56 MHz | 10 dBm | Development |
| USRP B210 | 56 MHz | 10 dBm | Development |
| USRP X310 | 160 MHz | 20 dBm | Research |
| USRP N310 | 100 MHz | 20 dBm | Production |

## Related Documentation

- [SDR.md](../../docs/SDR.md) - SDR security research guide
- [srsRAN Project](https://www.srsran.com/) - Official documentation
