# x402 Server (Gatekeeper)

Cloudflare Worker implementation of the x402 protocol for AI agent commerce.

## Quick Start

```bash
# Install dependencies
npm install

# Local development
npm run dev

# Deploy to Cloudflare
npm run deploy
```

## Configuration

Create a `.dev.vars` file for local development:

```
MY_WALLET=0xYourWalletAddressHere
JWT_SECRET=your-256-bit-secret
```

For production, set these in the Cloudflare dashboard or `wrangler.toml`.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | API info |
| GET | `/buy-pass` | Purchase 24h token (402 → payment → JWT) |
| GET | `/data` | Protected premium content |
| POST | `/invite` | Generate guest pass (OG only) |
| POST | `/tip` | Dynamic tip payment |
| GET | `/dashboard` | Visual status page |
| GET | `/health` | Health check |

## Headers

| Header | Description |
|--------|-------------|
| `x-client-id` | Your agent ID (for OG pricing) |
| `Authorization` | `Bearer <token>` for authenticated requests |
| `x-tip-amount` | Amount for `/tip` endpoint |

## Testing

```bash
# Get API info
curl https://your-gateway.workers.dev/

# Try to access data (will get 401)
curl https://your-gateway.workers.dev/data

# Buy a pass (will trigger 402 → payment flow)
curl -H "x-client-id: og-member-001" https://your-gateway.workers.dev/buy-pass
```

## Docker Deployment

For local development without Cloudflare Workers, use the docker gateway:

```bash
cd ../docker/x402-gateway
docker build -t x402-gateway .
docker run -p 3402:3000 \
  -e MY_WALLET=0x... \
  -e JWT_SECRET=your-secret \
  x402-gateway
```

## Protocol Flow

```
┌──────────────┐     GET /data      ┌──────────────┐
│   Client     │ ────────────────► │   Gateway    │
│              │                    │              │
│              │ ◄──────────────── │              │
│              │   401 Unauthorized │              │
│              │                    │              │
│              │   GET /buy-pass    │              │
│              │ ────────────────► │              │
│              │                    │              │
│              │ ◄──────────────── │              │
│              │   402 + Quote      │              │
│              │                    │              │
│              │   X-PAYMENT        │              │
│              │ ────────────────► │              │
│              │                    │    ┌──────┐  │
│              │ ◄──────────────── │    │ Base │  │
│              │   200 + JWT        │    └──────┘  │
│              │                    │              │
│              │   GET /data        │              │
│              │   + Bearer JWT     │              │
│              │ ────────────────► │              │
│              │                    │              │
│              │ ◄──────────────── │              │
│              │   200 + Data       │              │
└──────────────┘                    └──────────────┘
```
