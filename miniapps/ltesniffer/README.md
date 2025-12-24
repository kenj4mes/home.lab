# LTESniffer

LTE downlink analyzer for passive monitoring of LTE networks.

## ⚠️ Legal Warning

**For authorized security research ONLY.** Monitoring LTE traffic may violate telecommunications laws in your jurisdiction.

## Features

- LTE cell detection and decoding
- Downlink control channel analysis
- UE (User Equipment) detection
- RNTI tracking
- PCAP export for Wireshark

## Requirements

- **SDR Hardware**: USRP B200/B210, bladeRF 2.0
- **Antenna**: LTE band antenna (700-2600 MHz)
- **Drivers**: UHD 4.0+, srsRAN libraries

## Deployment

### Docker Compose (Recommended)

```bash
cd home.lab
docker compose -f docker/docker-compose.sdr.yml up -d ltesniffer
```

### Notes

- Requires high-performance SDR (RTL-SDR insufficient)
- Uses host networking for real-time RF access
- CPU intensive - recommend 4+ cores

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `LTE_BAND` | `7` | LTE band to monitor |
| `EARFCN` | `auto` | E-UTRA channel number |
| `SAMPLE_RATE` | `23.04e6` | SDR sample rate |

## Supported Bands

| Band | Frequency | Common Carriers |
|------|-----------|-----------------|
| 2 | 1900 MHz | AT&T, T-Mobile |
| 4 | 1700/2100 MHz | AT&T, T-Mobile, Verizon |
| 7 | 2600 MHz | International |
| 12 | 700 MHz | T-Mobile |
| 13 | 700 MHz | Verizon |

## Related Documentation

- [SDR.md](../../docs/SDR.md) - SDR security research guide
- [srsRAN](../srsran/) - Full 5G gNB implementation
