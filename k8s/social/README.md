# 📱 Social Media Stack

Self-hosted social media automation, privacy-respecting frontends, and content aggregation.

## 📦 Components Overview

### Automation & Bots

| Service | Purpose | URL |
|---------|---------|-----|
| **n8n** | Workflow automation for social posting | n8n.homelab.local |
| **Farcaster Hub** | Self-hosted Farcaster node | farcaster.homelab.local |

### Privacy Frontends

| Service | Replaces | URL |
|---------|----------|-----|
| **Invidious** | YouTube | youtube.homelab.local |
| **Nitter** | Twitter/X | twitter.homelab.local |
| **Libreddit** | Reddit | reddit.homelab.local |
| **MeTube** | YouTube downloads | metube.homelab.local |

### Content Aggregation

| Service | Purpose | URL |
|---------|---------|-----|
| **FreshRSS** | RSS/Atom feeds | rss.homelab.local |
| **Shaarli** | Bookmarks & links | links.homelab.local |
| **Wallabag** | Read-it-later | wallabag.homelab.local |

## 🚀 Quick Start

### Deploy All

```bash
# Create namespaces and deploy
kubectl apply -f farcaster.yaml
kubectl apply -f n8n.yaml
kubectl apply -f media-frontends.yaml
kubectl apply -f aggregators.yaml
```

### Deploy Specific Stack

```bash
# Just Farcaster for Web3 social
kubectl apply -f farcaster.yaml

# Just privacy frontends
kubectl apply -f media-frontends.yaml
```

## 🔧 Configuration

### 1. Update Secrets

Before deploying, update `CHANGEME_*` values:

```bash
# Generate secrets
openssl rand -hex 32  # For HMAC keys
openssl rand -base64 24  # For passwords
```

### 2. API Keys Required

| Platform | Where to Get | Required For |
|----------|--------------|--------------|
| Twitter/X | developer.twitter.com | n8n posting |
| Reddit | reddit.com/prefs/apps | n8n posting |
| YouTube | console.cloud.google.com | Data API |
| Telegram | t.me/BotFather | Notifications |
| Alchemy/Infura | alchemy.com | Farcaster Hub |

### 3. DNS Entries

Add to your DNS/Pi-hole:

```
farcaster.homelab.local -> <ingress-ip>
n8n.homelab.local       -> <ingress-ip>
youtube.homelab.local   -> <ingress-ip>
twitter.homelab.local   -> <ingress-ip>
reddit.homelab.local    -> <ingress-ip>
metube.homelab.local    -> <ingress-ip>
rss.homelab.local       -> <ingress-ip>
links.homelab.local     -> <ingress-ip>
wallabag.homelab.local  -> <ingress-ip>
```

## 🌐 Farcaster Integration

### What is Farcaster?

Farcaster is a decentralized social protocol built on Ethereum/Optimism. Running your own Hub gives you:

- Full data sovereignty
- Direct protocol access
- No rate limits
- Build custom clients

### Hub Requirements

- **Storage**: 200GB+ (grows over time)
- **RAM**: 8GB recommended
- **RPC**: Ethereum + Optimism RPC endpoints (Alchemy, Infura)

### Posting to Farcaster

```bash
# Using Farcaster SDK in n8n (JavaScript node)
const { Signer, makeMessageHash } = require('@farcaster/hub-nodejs');

// Your mnemonic creates the signer
const signer = Signer.fromMnemonic(process.env.FARCASTER_MNEMONIC);

// Post a cast
const cast = {
  text: "Hello from my homelab! 🏠",
  embedsDeprecated: [],
  mentions: [],
  mentionsPositions: []
};
```

## 🐦 Twitter/X Automation

### n8n Twitter Workflows

1. **Auto-post**: Schedule tweets from RSS feeds
2. **Monitor mentions**: Get notified of mentions
3. **Cross-post**: Farcaster → Twitter sync
4. **Archive**: Save your timeline

### Example: RSS to Twitter

```json
{
  "nodes": [
    {
      "name": "RSS Feed",
      "type": "n8n-nodes-base.rssFeedRead",
      "parameters": {
        "url": "https://base.mirror.xyz/feed"
      }
    },
    {
      "name": "Twitter",
      "type": "n8n-nodes-base.twitter",
      "parameters": {
        "text": "📰 {{ $json.title }}\n\n{{ $json.link }}"
      }
    }
  ]
}
```

## 📺 YouTube Archiving

### MeTube Usage

1. Access https://metube.homelab.local
2. Paste YouTube URL
3. Select quality
4. Download starts automatically

### Batch Downloads

```bash
# SSH into metube pod
kubectl exec -n media-frontends -it deploy/metube -- /bin/sh

# Download playlist
yt-dlp --config-location /etc/yt-dlp.conf "https://youtube.com/playlist?list=..."
```

### Auto-Archive Channels

Create n8n workflow:
1. RSS trigger on YouTube channel
2. Extract video URL
3. Call MeTube API
4. Store in local library

## 🔖 Content Management

### FreshRSS Subscriptions

Recommended feeds for Base/Crypto:

```
Base Blog:      https://base.mirror.xyz/feed
Coinbase Blog:  https://blog.coinbase.com/feed
Vitalik:        https://vitalik.eth.limo/feed.xml
```

### Wallabag Integration

Save articles for offline reading:

1. Install browser extension
2. Configure API endpoint
3. One-click save

### Shaarli Bookmarks

Tag and organize links:

- `#base` - Base ecosystem links
- `#farcaster` - Web3 social
- `#dev` - Development resources

## 📊 Resource Requirements

| Stack | Min RAM | Recommended | Storage |
|-------|---------|-------------|---------|
| Farcaster | 4GB | 8GB | 200GB |
| n8n | 512MB | 2GB | 10GB |
| Frontends | 1GB | 2GB | 20GB |
| Aggregators | 512MB | 1GB | 15GB |
| **Total** | **6GB** | **13GB** | **245GB** |

## 🔐 Security Notes

1. **API keys in Secrets** - Never in ConfigMaps
2. **HTTPS everywhere** - Cert-Manager handles TLS
3. **Network policies** - Isolate social stack
4. **No external deps** - Privacy frontends don't phone home

## 🔗 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Social Automation Stack                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   FreshRSS  │───▶│    n8n      │───▶│  Twitter/X  │         │
│  │  (RSS Feeds)│    │ (Automation)│    │   Reddit    │         │
│  └─────────────┘    └──────┬──────┘    │  Farcaster  │         │
│                            │           └─────────────┘         │
│                            ▼                                    │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │  Wallabag   │    │  Shaarli    │    │   MeTube    │         │
│  │ (Read Later)│    │ (Bookmarks) │    │ (Downloads) │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                  Privacy Frontends                          ││
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐                  ││
│  │  │Invidious │  │  Nitter  │  │ Libreddit│                  ││
│  │  │(YouTube) │  │(Twitter) │  │ (Reddit) │                  ││
│  │  └──────────┘  └──────────┘  └──────────┘                  ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                  Farcaster Stack                            ││
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐                  ││
│  │  │   Hub    │─▶│Replicator│─▶│PostgreSQL│                  ││
│  │  │  (Node)  │  │  (Sync)  │  │  (Data)  │                  ││
│  │  └──────────┘  └──────────┘  └──────────┘                  ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 📚 Related Docs

- [BASE_ECOSYSTEM.md](../../docs/BASE_ECOSYSTEM.md) - Base network reference links
- [n8n Documentation](https://docs.n8n.io/) - Workflow automation
- [Farcaster Docs](https://docs.farcaster.xyz/) - Protocol documentation
