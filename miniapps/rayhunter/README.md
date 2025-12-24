# Rayhunter

EFF's IMSI catcher detection tool for identifying cell-site simulators (Stingrays).

## ⚠️ Legal Notice

This is the Electronic Frontier Foundation's open-source IMSI catcher detector. It performs passive monitoring only.

## Features

- Cell tower tracking and logging
- Anomaly detection for suspicious towers
- Web interface for real-time monitoring
- Mobile-friendly dashboard
- Export logs for analysis

## Requirements

- **Device**: Raspberry Pi 4 or Linux PC
- **Modem**: Qualcomm-based 4G modem (Orbic Speed, similar)
- **No SDR required** - uses cellular modem directly

## Deployment

### Docker Compose (Recommended)

```bash
cd home.lab
docker compose -f docker/docker-compose.sdr.yml up -d rayhunter
```

### Standalone Docker

```bash
docker build -t rayhunter .
docker run -d --privileged -p 8580:8580 rayhunter
```

## Access

- **URL**: http://localhost:8580
- **No authentication required**

## How It Works

Unlike SDR-based tools, Rayhunter uses a standard cellular modem to:

1. Connect to nearby cell towers normally
2. Log all tower interactions and handoffs
3. Detect suspicious behavior patterns:
   - Forced encryption downgrades
   - Unusual tower identifiers
   - Rapid tower switching
   - Signal strength anomalies

## Supported Modems

| Modem | Interface | Status |
|-------|-----------|--------|
| Orbic Speed | USB | Supported |
| Quectel EC25 | USB | Experimental |
| Sierra MC7455 | USB | Experimental |

## Related Documentation

- [SDR.md](../../docs/SDR.md) - SDR security research guide
- [EFF Rayhunter](https://github.com/EFForg/rayhunter) - Official repository
