# 🏠 HomeLab Documentation

Welcome to the HomeLab documentation—your comprehensive guide to building and operating a self-hosted infrastructure platform.

## What is HomeLab?

HomeLab is a **self-hosted infrastructure platform** that provides 50+ integrated services for:

- 🤖 **Local AI** — Run 15+ LLMs locally with Ollama
- 🎬 **Media Server** — Jellyfin, *Arr stack automation
- 📚 **Offline Knowledge** — Wikipedia, StackOverflow via Kiwix
- 🔗 **Blockchain** — 31 OP-Stack L2 node support
- 🎨 **Creative AI** — Image generation, voice synthesis, music
- 🛡️ **Security** — Post-quantum TLS, secret management

## Quick Links

<div class="grid cards" markdown>

-   :rocket: **[Quick Start](getting-started/quickstart.md)**

    Get up and running in 10 minutes

-   :building_construction: **[Architecture](architecture/overview.md)**

    Understand the system design

-   :shield: **[Security](security/identity.md)**

    Secure your deployment

-   :wrench: **[Operations](operations/monitoring.md)**

    Monitor and maintain

</div>

## Architecture Overview

```mermaid
graph TB
    subgraph "External Access"
        CF[Cloudflare Tunnel]
        TS[Tailscale VPN]
    end
    
    subgraph "Ingress Layer"
        NPM[Nginx Proxy Manager]
        PH[Pi-Hole DNS]
    end
    
    subgraph "Compute Layer"
        K8S[Kubernetes/Docker]
        OL[Ollama LLMs]
        JF[Jellyfin Media]
    end
    
    subgraph "Data Layer"
        NAS[NAS Storage]
        DB[(Databases)]
        ZIM[Kiwix ZIMs]
    end
    
    subgraph "Observability"
        PROM[Prometheus]
        GRAF[Grafana]
        ALERT[Alertmanager]
    end
    
    CF --> NPM
    TS --> NPM
    NPM --> K8S
    PH --> NPM
    K8S --> OL
    K8S --> JF
    K8S --> DB
    OL --> NAS
    JF --> NAS
    K8S --> ZIM
    K8S -.-> PROM
    PROM --> GRAF
    PROM --> ALERT
```

## Key Features

| Feature | Description |
|---------|-------------|
| **Zero Trust Networking** | Default-deny network policies, microsegmentation |
| **GitOps Ready** | ArgoCD integration for declarative deployments |
| **Observability** | Full Prometheus/Grafana/Loki stack |
| **Disaster Recovery** | Velero backups to S3-compatible storage |
| **Secrets Management** | HashiCorp Vault with dynamic secrets |
| **SSO/Identity** | Keycloak for centralized authentication |

## Getting Started

1. **Clone the repository (includes ~29GB via Git LFS):**
   ```bash
   git lfs install
   # CUSTOMIZE: Replace <your-github-username> with your GitHub username
   git clone https://github.com/<your-github-username>/home.lab.git
   cd home.lab
   ```

2. **Run the bootstrap script:**
   ```bash
   # Linux/macOS
   ./bootstrap.sh
   
   # Windows
   .\homelab.ps1
   ```

3. **Optional: Download additional models:**
   ```bash
   # Core data (ZIM, SDXL, Superchain) already included!
   ./scripts/download-models.sh  # Ollama LLMs
   ```

4. **Start services:**
   ```bash
   docker compose up -d
   ```

## Support

- 📖 [Troubleshooting Guide](operations/troubleshooting.md)
<!-- CUSTOMIZE: Replace <your-github-username> with your GitHub username -->
- 🐛 [GitHub Issues](https://github.com/<your-github-username>/home.lab/issues)
- 📜 [License](https://github.com/<your-github-username>/home.lab/blob/main/LICENSE)
