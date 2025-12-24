# IMSI Catcher Detection

GSM IMSI catcher detection tool for identifying rogue cell towers and Stingray devices.

## ⚠️ Legal Warning

**For authorized security research ONLY.** This tool passively monitors GSM frequencies which may be regulated in your jurisdiction.

## Features

- GSM cell tower detection and logging
- IMSI broadcast monitoring
- Rogue tower identification
- Signal strength analysis
- Geographic mapping support

## Requirements

- **SDR Hardware**: RTL-SDR V3 or HackRF One
- **Antenna**: GSM band antenna (850/900/1800/1900 MHz)
- **Drivers**: rtl-sdr, gr-gsm

## Deployment

### Docker Compose (Recommended)

```bash
cd home.lab
docker compose -f docker/docker-compose.sdr.yml up -d imsi-catcher
```

### Notes

- Requires `--privileged` mode for USB device access
- Uses host networking for real-time RF access
- Must pass through SDR device (`/dev/bus/usb`)

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `SDR_DEVICE` | `rtlsdr` | SDR hardware type |
| `GSM_BAND` | `900` | GSM band to monitor |
| `GAIN` | `40` | RF gain (0-50) |

## How It Works

1. Scans GSM frequencies for cell tower broadcasts
2. Decodes System Information messages (SI1-SI4)
3. Compares LAC/CID against known legitimate towers
4. Alerts on suspicious characteristics:
   - Unusual signal strength
   - Encryption downgrade requests
   - Unknown tower IDs
   - Location inconsistencies

## Related Documentation

- [SDR.md](../../docs/SDR.md) - SDR security research guide
- [Rayhunter](../rayhunter/) - EFF's IMSI catcher detector
