# 🏗️ HomeLab Architecture

> Comprehensive technical architecture based on enterprise infrastructure patterns

## Design Philosophy

| Principle | Implementation |
|-----------|----------------|
| **Infrastructure as Code** | All configs in Git, reproducible deployments |
| **Horizontal Scalability** | Scale-out with SFF nodes vs scale-up |
| **Defense in Depth** | Multiple security layers, zero trust networking |
| **Observability First** | Metrics, logs, and traces for all services |
| **Offline Capable** | Works fully air-gapped once data is cached |

## System Layers

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Layer 4: Applications                          │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│  │ Ollama  │ │ Jellyfin│ │ Kiwix   │ │ Grafana │ │ ArgoCD  │       │
│  │  LLMs   │ │  Media  │ │  Wiki   │ │ Monitor │ │  GitOps │       │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘       │
├─────────────────────────────────────────────────────────────────────┤
│                    Layer 3: Platform Services                        │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│  │ Pi-Hole │ │  Nginx  │ │Keycloak │ │  Vault  │ │Prometheus│      │
│  │   DNS   │ │  Proxy  │ │   SSO   │ │ Secrets │ │ Metrics │       │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘       │
├─────────────────────────────────────────────────────────────────────┤
│                   Layer 2: Container Runtime                         │
│  ┌───────────────────────────┐  ┌───────────────────────────────┐  │
│  │     Docker Compose        │  │        Kubernetes              │  │
│  │  (Development/Simple)     │  │   (Production/Scaling)         │  │
│  └───────────────────────────┘  └───────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────────┤
│                 Layer 1: Physical Infrastructure                     │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│  │ SFF Node│ │ SFF Node│ │ SFF Node│ │   NAS   │ │ Switch  │       │
│  │ i5/32GB │ │ i5/32GB │ │ i5/32GB │ │ Storage │ │  10GbE  │       │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘       │
└─────────────────────────────────────────────────────────────────────┘
```

## Network Topology

### VLAN Segmentation

| VLAN ID | Name | Purpose | Firewall Rules |
|---------|------|---------|----------------|
| 10 | Management | IPMI, Switch, Router | Locked down |
| 20 | Server/Lab | Compute nodes, VMs | Internal only |
| 30 | User/Trusted | Trusted devices | Internet + Lab |
| 40 | IoT/Untrusted | Smart devices | Internet only |
| 50 | Storage | NFS/iSCSI traffic | Non-routable |

### DNS Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Client DNS    │────▶│    Pi-Hole      │────▶│   Upstream DNS  │
│    Request      │     │  (Ad Blocking)  │     │  (Cloudflare)   │
└─────────────────┘     └────────┬────────┘     └─────────────────┘
                                 │
                                 ▼ (*.lab.local)
                        ┌─────────────────┐
                        │   Authoritative │
                        │   DNS (GoZones) │
                        └─────────────────┘
```

## Storage Tiers

| Tier | Use Case | Technology | Performance |
|------|----------|------------|-------------|
| **Tier 0** | Boot/OS, ephemeral | Local NVMe | Highest |
| **Tier 1** | Persistent block (DBs) | Longhorn/Ceph | High |
| **Tier 2** | Bulk data, backups | NAS (NFS/SMB) | Moderate |

## Security Architecture

### Zero Trust Model

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Identity   │───▶│   Policy     │───▶│   Access     │
│  (Keycloak)  │    │  (Network    │    │  (Service)   │
│              │    │   Policies)  │    │              │
└──────────────┘    └──────────────┘    └──────────────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Secrets    │    │   Audit      │    │   Encrypt    │
│   (Vault)    │    │   (Loki)     │    │   (TLS/PQ)   │
└──────────────┘    └──────────────┘    └──────────────┘
```

### Secret Management

| Secret Type | Storage | Rotation | Access |
|-------------|---------|----------|--------|
| API Keys | Vault KV | Manual | Policy-based |
| DB Passwords | Vault Dynamic | Automatic (1hr) | On-demand |
| TLS Certs | Vault PKI | Automatic (90d) | cert-manager |
| SSH Keys | Vault SSH | Per-session | Signed certs |

## GitOps Workflow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Git Push  │────▶│   ArgoCD    │────▶│  Kubernetes │
│  (Source)   │     │  (Observe)  │     │   (Live)    │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                           ▼ (Diff detected)
                    ┌─────────────┐
                    │    Sync     │
                    │  (Desired   │
                    │   = Live)   │
                    └─────────────┘
```

## Observability Stack

| Component | Purpose | Data |
|-----------|---------|------|
| **Prometheus** | Metrics collection | Time-series |
| **Grafana** | Visualization | Dashboards |
| **Loki** | Log aggregation | Structured logs |
| **Alertmanager** | Notification routing | Alerts |
| **Promtail** | Log shipping | Log forwarding |

### Critical Alerts

| Alert | Severity | Threshold | Action |
|-------|----------|-----------|--------|
| NodeDown | Critical | 1 min | Page on-call |
| DiskFull | Critical | <10% | Immediate cleanup |
| HighCPU | Warning | >85% 5min | Investigation |
| HighMemory | Warning | >85% 5min | Investigation |
| CertExpiring | Warning | <14 days | Renew cert |

## Disaster Recovery

### Backup Strategy

| Data Type | Frequency | Retention | Tool |
|-----------|-----------|-----------|------|
| Cluster State | Daily | 30 days | Velero |
| Databases | Hourly | 3 days | Velero + Hooks |
| Configs | Weekly | 90 days | Velero |
| Media | On-change | Forever | Restic to NAS |

### Recovery Procedures

1. **Partial Failure** - ArgoCD auto-heals from Git
2. **Node Failure** - Kubernetes reschedules pods
3. **Cluster Failure** - Velero restore to new cluster
4. **Site Failure** - Restore from off-site S3 backup

## Scaling Model

### Current Capacity (3x SFF Nodes)

| Resource | Total | Reserved | Available |
|----------|-------|----------|-----------|
| CPU | 12 cores | 4 cores | 8 cores |
| Memory | 96 GB | 16 GB | 80 GB |
| Storage | 3 TB NVMe | 500 GB | 2.5 TB |

### Expansion Path

1. **Add Node** - Plug in SFF, PXE boot, auto-join cluster
2. **Add Storage** - Longhorn auto-discovers new disks
3. **Add GPU** - NVIDIA device plugin for AI workloads

## Component Inventory

### Hardware Reference

| Component | Model | Specs | Qty |
|-----------|-------|-------|-----|
| Compute | Lenovo M700 SFF | i5-6600T, 32GB, 1TB NVMe | 3-4 |
| Network | 10GbE Switch | 8-port SFP+ | 1 |
| Storage | Synology NAS | 4-bay, 32TB | 1 |

### Software Versions

| Category | Component | Version |
|----------|-----------|---------|
| OS | Fedora CoreOS | Latest |
| Container | Docker | 24.x |
| Orchestration | Kubernetes | 1.29+ |
| GitOps | ArgoCD | 2.9+ |
| Monitoring | Prometheus | 2.48+ |
| Identity | Keycloak | 23+ |
| Secrets | Vault | 1.15+ |

## Cybernetic Evolution (Experimental)

The next phase of infrastructure evolution introduces **self-regulating systems** that observe, reason, and act autonomously. See [EXPERIMENTAL.md](EXPERIMENTAL.md) for details.

### The Five Pillars

| Pillar | Component | Function |
|--------|-----------|----------|
| 🧠 **Cognitive** | LangFlow | Agentic AI orchestration |
| 💥 **Resilience** | Chaos Mesh | Fault injection testing |
| ⚡ **Observability** | Kepler | eBPF energy monitoring |
| 🏗️ **Platform** | Kratix | X-as-a-Service via Promises |
| 💰 **Finance** | Rotki | Sovereign crypto analytics |

### The Cybernetic Loop

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CYBERNETIC FEEDBACK LOOP                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐         │
│   │ SENSE   │───▶│ ANALYZE │───▶│ DECIDE  │───▶│  ACT    │         │
│   │ Kepler  │    │ Prom/   │    │LangFlow │    │ Kratix/ │         │
│   │ (eBPF)  │    │ Rotki   │    │  (AI)   │    │ Chaos   │         │
│   └─────────┘    └─────────┘    └─────────┘    └─────────┘         │
│        │                                              │             │
│        └──────────────── FEEDBACK ───────────────────┘             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

This transforms the homelab from a **passive hosting platform** into an **active, self-governing organism** that:

1. **Senses** its physical state (energy, resources, performance)
2. **Analyzes** patterns and anomalies (AI + metrics)
3. **Decides** on corrective actions (LLM reasoning)
4. **Acts** to maintain equilibrium (platform automation, controlled chaos)

## References

- [khuedoan/homelab](https://github.com/khuedoan/homelab) - Fully automated homelab
- [kenmoini/homelab](https://github.com/kenmoini/homelab) - Red Hat ecosystem homelab
- [CNCF Landscape](https://landscape.cncf.io/) - Cloud Native technologies
- [AWS Well-Architected](https://aws.amazon.com/architecture/well-architected/) - Framework principles
- [Chaos Mesh](https://chaos-mesh.org/) - CNCF chaos engineering
- [Kepler Project](https://sustainable-computing.io/) - Kubernetes energy efficiency
- [Kratix](https://kratix.io/) - Platform engineering framework
