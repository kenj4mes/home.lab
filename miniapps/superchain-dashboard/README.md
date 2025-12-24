# Superchain Dashboard

Static HTML dashboard displaying status of all 31 OP-Stack L2 nodes in the Superchain ecosystem.

## Features

- Real-time node status (syncing, synced, offline)
- Chain info (Chain ID, RPC endpoints, block height)
- Quick links to explorers and bridges
- Responsive design for mobile/desktop

## Deployment

### Docker Compose (Recommended)

```bash
cd home.lab
docker compose -f docker/docker-compose.superchain.yml up -d superchain-dashboard
```

### Standalone Docker

```bash
docker build -t superchain-dashboard .
docker run -d -p 8600:80 superchain-dashboard
```

## Access

- **URL**: http://localhost:8600
- **No authentication required**

## Supported Chains

| Chain | Chain ID | Status Endpoint |
|-------|----------|-----------------|
| Base | 8453 | :8545 |
| OP Mainnet | 10 | :8555 |
| Unichain | 130 | :8565 |
| Mode | 34443 | :8575 |
| World Chain | 480 | :8585 |
| Lisk | 1135 | :8595 |

## Customization

Edit `html/index.html` to add/remove chains or modify the UI.

## Related Documentation

- [SUPERCHAIN.md](../../docs/SUPERCHAIN.md) - Full ecosystem documentation
- [docker-compose.superchain.yml](../../docker/docker-compose.superchain.yml) - L2 node configurations
