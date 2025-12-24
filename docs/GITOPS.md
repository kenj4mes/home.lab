# 🔄 GitOps Guide

> Declarative infrastructure management with ArgoCD

## What is GitOps?

GitOps is a paradigm where:
- **Git is the source of truth** for infrastructure state
- **Changes are made via pull requests**, not manual commands
- **Automated reconciliation** keeps live state matching Git
- **Rollback is a git revert**

## ArgoCD Setup

### 1. Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Get Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### 3. Access UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8443:443
# Visit https://localhost:8443
```

### 4. Apply HomeLab Applications

```bash
kubectl apply -f k8s/argocd/
```

## Application Structure

```
k8s/
├── argocd/           # ArgoCD configurations
│   ├── applications.yaml
│   ├── project.yaml
│   └── config.yaml
├── core/             # Core services
├── monitoring/       # Observability stack
├── ai/               # AI/LLM services
├── security/         # Security services
├── policies/         # Network policies
├── quotas/           # Resource quotas
└── velero/           # Backup configs
```

## Workflow

### Making Changes

```bash
# 1. Create branch
git checkout -b feature/add-service

# 2. Add/modify k8s manifests
vim k8s/core/new-service.yaml

# 3. Commit and push
git add .
git commit -m "Add new service"
git push origin feature/add-service

# 4. Create PR and merge
# ArgoCD detects change and syncs automatically
```

### Rollback

```bash
# Find bad commit
git log --oneline

# Revert it
git revert abc1234
git push

# ArgoCD syncs the revert automatically
```

## Sync Policies

| Policy | Behavior |
|--------|----------|
| **Manual** | Operator clicks "Sync" in UI |
| **Auto-Sync** | ArgoCD syncs on Git changes |
| **Self-Heal** | ArgoCD reverts manual cluster changes |
| **Prune** | Removes resources deleted from Git |

## Best Practices

1. **Never edit resources directly in cluster** - Git is the source
2. **Use Kustomize overlays** for environment-specific configs
3. **Encrypt secrets** with SealedSecrets or External Secrets
4. **Small, focused commits** for easier debugging
5. **Enable notifications** for sync failures
