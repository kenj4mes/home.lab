# ☸️ Kubernetes Configurations

This directory contains Kubernetes manifests for deploying HomeLab services in a K8s cluster.

## Directory Structure

```
k8s/
├── argocd/           # GitOps controller
│   ├── applications.yaml    # App definitions
│   ├── project.yaml         # RBAC for apps
│   └── config.yaml          # ArgoCD settings
├── policies/         # Network security
│   ├── default-deny-all.yaml    # Zero trust baseline
│   ├── allow-monitoring.yaml    # Prometheus access
│   └── allow-database.yaml      # DB access control
├── quotas/           # Resource management
│   ├── resource-quotas.yaml     # Namespace limits
│   └── limit-ranges.yaml        # Container limits
└── velero/           # Disaster recovery
    ├── backup-storage.yaml      # S3 config
    ├── backup-schedules.yaml    # Automated backups
    └── restore-templates.yaml   # DR procedures
```

## Quick Start

### Prerequisites

- Kubernetes cluster (k3s, kind, or managed)
- kubectl configured
- Helm 3.x (optional)

### Deploy Network Policies

```bash
# Apply zero-trust baseline
kubectl apply -f policies/

# Verify policies
kubectl get networkpolicies -A
```

### Deploy Resource Quotas

```bash
# Create namespaces first
kubectl create namespace production
kubectl create namespace development
kubectl create namespace ai
kubectl create namespace monitoring
kubectl create namespace media

# Apply quotas
kubectl apply -f quotas/
```

### Install ArgoCD (GitOps)

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply HomeLab apps
kubectl apply -f argocd/
```

### Setup Velero (Backups)

```bash
# Install Velero CLI
# See: https://velero.io/docs/main/basic-install/

# Install with AWS plugin (S3-compatible)
velero install \
  --provider aws \
  --bucket homelab-backups \
  --secret-file ./credentials-velero \
  --backup-location-config region=us-east-1,s3ForcePathStyle=true,s3Url=http://minio:9000

# Apply schedules
kubectl apply -f velero/
```

## Security Model

### Network Policies

| Policy | Effect |
|--------|--------|
| `default-deny-all` | Block all traffic by default |
| `allow-dns-egress` | Allow DNS resolution |
| `allow-monitoring` | Prometheus can scrape all pods |
| `allow-database` | Only authorized apps access DBs |

### Resource Quotas

| Namespace | CPU Limit | Memory Limit | Storage |
|-----------|-----------|--------------|---------|
| production | 16 cores | 32 GB | 100 GB |
| development | 8 cores | 16 GB | 50 GB |
| ai | 16 cores | 64 GB | 200 GB |
| media | 8 cores | 32 GB | 500 GB |
| monitoring | 4 cores | 8 GB | 50 GB |

## Backup Strategy

| Schedule | Scope | Retention | Frequency |
|----------|-------|-----------|-----------|
| daily-full | All namespaces | 30 days | 2 AM daily |
| production | Prod + databases | 7 days | Every 6 hours |
| database | DBs only | 3 days | Hourly |
| config | Configs/secrets | 90 days | Weekly |

## Useful Commands

```bash
# Check resource usage vs quotas
kubectl describe quota -n production

# View network policies
kubectl describe netpol -n default

# List ArgoCD apps
kubectl get applications -n argocd

# Check backup status
velero backup get

# Trigger manual backup
velero backup create manual-backup --include-namespaces production
```

## Documentation

- [GitOps Guide](../docs/GITOPS.md)
- [Architecture](../docs/ARCHITECTURE.md)
- [Security](../docs/SECURITY.md)
