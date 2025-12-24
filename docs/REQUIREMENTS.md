# ==============================================================================
# 📋 Requirements Matrix
# ==============================================================================

# Requirements Matrix

Complete mapping of A.2 Critical Software Versions & Tools.

## 🖥️ Operating Systems

| OS | Version | Status | Notes |
|----|---------|--------|-------|
| RHEL | 8.x, 9.x | ✅ Supported | Enterprise production |
| Fedora | 38+ | ✅ Supported | Development/testing |
| Ubuntu | 22.04 LTS | ✅ Supported | Recommended for homelab |
| Debian | 12 (Bookworm) | ✅ Supported | Stable alternative |

## 🤖 Automation

| Tool | Required Version | Location | Install |
|------|-----------------|----------|---------|
| Ansible Core | 2.14+ | `ansible/` | `pip install ansible-core` |
| Ansible Tower/AWX | 22+ | External | [AWX Install Guide](https://github.com/ansible/awx) |

**Playbooks provided:**
- `ansible/playbooks/site.yml` - Master orchestration
- `ansible/roles/common/` - Base system config
- `ansible/roles/docker/` - Docker installation
- `ansible/roles/kubernetes/` - K8s cluster setup

## 🐳 Container Runtime

| Runtime | Required Version | Purpose | Location |
|---------|-----------------|---------|----------|
| Docker CE | 24.0+ | Docker Compose workloads | `ansible/roles/docker/` |
| containerd | 1.7+ | K8s container runtime | `ansible/roles/kubernetes/common/` |
| CRI-O | 1.29+ | K8s container runtime (alt) | Ansible role included |
| Podman | 4.5+ | Rootless containers | Manual install |

## 🌐 Networking

| Component | Purpose | Location | Status |
|-----------|---------|----------|--------|
| Cilium | CNI + eBPF networking | `k8s/infrastructure/cilium.yaml` | ✅ Configured |
| Calico | CNI alternative | Not included | ➖ Optional |
| MetalLB | Bare metal load balancer | `k8s/infrastructure/metallb.yaml` | ✅ Configured |

**Cilium Features:**
- eBPF-based networking (no iptables)
- L7 policy enforcement
- Hubble observability
- Transparent encryption

## 💾 Storage

| Solution | Purpose | Location | Status |
|----------|---------|----------|--------|
| Longhorn | Distributed block storage | `k8s/infrastructure/longhorn.yaml` | ✅ Configured |
| Rook-Ceph | Enterprise storage | Not included | ➖ Optional |
| ODF | OpenShift Data Foundation | N/A | ❌ OpenShift only |

**Longhorn Features:**
- Distributed replicated storage
- Scheduled snapshots & backups
- S3-compatible backup target
- Web UI for management

## 🌐 Ingress

| Controller | Purpose | Location | Status |
|------------|---------|----------|--------|
| NGINX Ingress | HTTP/HTTPS routing | `k8s/infrastructure/ingress-nginx.yaml` | ✅ Configured |
| Traefik | Cloud-native routing | `k8s/infrastructure/traefik.yaml` | ✅ Configured |

**Choose one based on needs:**
- **NGINX**: Traditional, well-documented, wide compatibility
- **Traefik**: Native K8s CRDs, automatic cert management, dashboard

## 🔍 DNS

| Service | Purpose | Location | Status |
|---------|---------|----------|--------|
| Pi-hole | Ad-blocking DNS | `docker/docker-compose.pihole.yml` | ✅ Configured |
| Bind9 | Authoritative DNS | Not included | ➖ Optional |
| ExternalDNS | K8s DNS automation | Not included | ➖ Optional |

## 🔐 Certificates

| Tool | Purpose | Location | Status |
|------|---------|----------|--------|
| Cert-Manager | Automated TLS certs | `k8s/infrastructure/cert-manager.yaml` | ✅ Configured |
| Step-CA | Private CA | Not included | ➖ Optional |

**Issuers configured:**
- Let's Encrypt Production
- Let's Encrypt Staging
- Self-signed (air-gapped)
- HomeLab CA (internal PKI)

## 📊 Monitoring

| Component | Purpose | Location | Status |
|-----------|---------|----------|--------|
| Prometheus | Metrics collection | `docker/docker-compose.monitoring.yml` | ✅ Configured |
| Grafana | Visualization | `docker/docker-compose.monitoring.yml` | ✅ Configured |
| Alertmanager | Alert routing | `configs/alertmanager/alertmanager.yml` | ✅ Configured |
| Loki | Log aggregation | `docker/docker-compose.monitoring.yml` | ✅ Configured |
| Promtail | Log shipping | `docker/docker-compose.monitoring.yml` | ✅ Configured |

## 🔄 GitOps & DR

| Tool | Purpose | Location | Status |
|------|---------|----------|--------|
| ArgoCD | GitOps deployment | `k8s/argocd/` | ✅ Configured |
| Velero | K8s backup/restore | `k8s/velero/` | ✅ Configured |

## 🔐 Secrets & Identity

| Tool | Purpose | Location | Status |
|------|---------|----------|--------|
| HashiCorp Vault | Secrets management | `docker/docker-compose.vault.yml` | ✅ Configured |
| Keycloak | SSO/Identity | `docker/docker-compose.identity.yml` | ✅ Configured |
| OAuth2 Proxy | Auth proxy | `docker/docker-compose.identity.yml` | ✅ Configured |

---

## 📁 File Locations Summary

```
home.lab/
├── ansible/                    # Automation playbooks
│   ├── inventory.example.yml   # Host inventory
│   ├── playbooks/site.yml      # Master playbook
│   └── roles/                  # Ansible roles
├── docker/                     # Docker Compose files
│   ├── docker-compose.yml      # Main services
│   ├── docker-compose.monitoring.yml
│   ├── docker-compose.identity.yml
│   └── docker-compose.vault.yml
├── k8s/                        # Kubernetes manifests
│   ├── infrastructure/         # Core infra (CNI, storage, ingress)
│   ├── argocd/                # GitOps config
│   ├── velero/                # Backup schedules
│   ├── policies/              # Network policies
│   └── quotas/                # Resource quotas
├── configs/                    # Configuration files
│   ├── alertmanager/
│   ├── prometheus/
│   ├── grafana/
│   └── vault/
└── docs/                       # Documentation
    ├── INSTALLATION.md        # This guide
    └── REQUIREMENTS.md        # Requirements matrix
```

---

## ✅ Compliance Checklist

| Requirement | Status | Evidence |
|-------------|--------|----------|
| OS: RHEL 8/9, Fedora 38+, Ubuntu 22.04 | ✅ | Ansible roles support all |
| Ansible Core 2.14+ | ✅ | `ansible/` directory |
| Container Runtime: CRI-O, Podman 4.5+ | ✅ | K8s roles support both |
| CNI: Calico or Cilium | ✅ | Cilium configured |
| Load Balancer: MetalLB | ✅ | `k8s/infrastructure/metallb.yaml` |
| Storage: Rook-Ceph, Longhorn, ODF | ✅ | Longhorn configured |
| Ingress: NGINX, Traefik | ✅ | Both configured |
| DNS: Pi-hole, Bind9, ExternalDNS | ✅ | Pi-hole configured |
| Certificates: Cert-Manager, Step-CA | ✅ | Cert-Manager configured |
| Monitoring: Prometheus, Grafana 9+, Alertmanager | ✅ | Full stack configured |
