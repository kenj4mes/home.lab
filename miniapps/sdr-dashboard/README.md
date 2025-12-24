# SDR Dashboard

Unified web interface for Software Defined Radio security research tools including IMSI catcher detection, LTE analysis, and 5G monitoring.

## ⚠️ Legal Warning

**For authorized security research ONLY.** Intercepting cellular communications without authorization is illegal in most jurisdictions. Check local laws before use.

## Features

- Unified view of all SDR tools
- Real-time signal analysis display
- IMSI detection alerts
- LTE/5G cell information
- Hardware status monitoring

## Requirements

- **SDR Hardware**: RTL-SDR, HackRF One, USRP B200/B210
- **Drivers**: rtl-sdr, UHD (for USRP)
- **Host access**: Requires `--privileged` or device passthrough

## Deployment

### Docker Compose (Recommended)

```bash
cd home.lab
docker compose -f docker/docker-compose.sdr.yml up -d sdr-dashboard
```

### Standalone Docker

```bash
docker build -t sdr-dashboard .
docker run -d -p 8585:80 sdr-dashboard
```

## Access

- **URL**: http://localhost:8585
- **No authentication required**

## Integrated Tools

| Tool | Port | Description |
|------|------|-------------|
| Rayhunter | 8580 | EFF IMSI catcher detector |
| IMSI Catcher | - | GSM IMSI detection |
| LTESniffer | - | LTE traffic analysis |
| srsRAN 5G | - | 5G gNB research |

## Hardware Compatibility

| Hardware | Frequency Range | Use Case |
|----------|-----------------|----------|
| RTL-SDR V3 | 500 kHz - 1.7 GHz | GSM, LTE (some bands) |
| HackRF One | 1 MHz - 6 GHz | Full spectrum analysis |
| USRP B200 | 70 MHz - 6 GHz | Research-grade, TX capable |
| bladeRF 2.0 | 47 MHz - 6 GHz | High performance |

## Related Documentation

- [SDR.md](../../docs/SDR.md) - SDR security research guide
- [docker-compose.sdr.yml](../../docker/docker-compose.sdr.yml) - SDR stack configuration
