# Base Wallet CLI

REST API for Ethereum/Base L2 wallet operations including key generation, balance queries, and transaction signing.

## Features

- HD wallet generation (BIP-39/BIP-44)
- Balance queries (ETH, ERC-20 tokens)
- Transaction signing and broadcasting
- Multi-chain support (Base, OP, Ethereum)
- Secure key storage with encryption

## ⚠️ Security Warning

**This service handles private keys. Never expose to public internet without proper security measures.**

## Deployment

### Docker Compose (Recommended)

```bash
cd home.lab
docker compose -f docker/docker-compose.base.yml up -d wallet-api
```

### Standalone Docker

```bash
docker build -t base-wallet-cli .
docker run -d -p 5000:5000 \
  -e RPC_URL=http://base-node:8545 \
  base-wallet-cli
```

## API Usage

### Generate New Wallet

```bash
curl -X POST http://localhost:5000/wallet/new
```

Response:
```json
{
  "address": "0x...",
  "mnemonic": "word1 word2 ... word12"
}
```

### Check Balance

```bash
curl http://localhost:5000/wallet/balance/0xYOUR_ADDRESS
```

### Send Transaction

```bash
curl -X POST http://localhost:5000/wallet/send \
  -H "Content-Type: application/json" \
  -d '{
    "from": "0xSENDER",
    "to": "0xRECIPIENT",
    "amount": "0.1",
    "privateKey": "0x..."
  }'
```

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/wallet/new` | POST | Generate new HD wallet |
| `/wallet/balance/:address` | GET | Get ETH balance |
| `/wallet/send` | POST | Send ETH transaction |
| `/wallet/sign` | POST | Sign message/transaction |
| `/health` | GET | Health check |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RPC_URL` | `http://localhost:8545` | Ethereum RPC endpoint |
| `CHAIN_ID` | `8453` | Chain ID (8453 = Base) |
| `PORT` | `5000` | API port |

## Related Documentation

- [BASE.md](../../docs/BASE.md) - Base L2 integration guide
- [WEB3.md](../../docs/WEB3.md) - Web3 development guide
- [docker-compose.base.yml](../../docker/docker-compose.base.yml) - Blockchain stack
