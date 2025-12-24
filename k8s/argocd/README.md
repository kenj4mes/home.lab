# ArgoCD GitOps Configuration

Kubernetes GitOps deployment with ArgoCD.

## Files

| File | Description |
|------|-------------|
| `applications.yaml` | ArgoCD Application resources for HomeLab services |
| `project.yaml` | ArgoCD Project with RBAC and source restrictions |
| `config.yaml` | ArgoCD ConfigMap customizations |

## Installation

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Apply HomeLab configuration
kubectl apply -f .

# Access UI
kubectl port-forward svc/argocd-server -n argocd 8443:443
```

## Customization

Update `applications.yaml` with your fork's repository URL:
```yaml
# CUSTOMIZE: Replace <your-github-username> with your GitHub username
repoURL: https://github.com/<your-github-username>/home.lab.git
```

## Applications

| Application | Path | Namespace |
|-------------|------|-----------|
| homelab-core | k8s/core | default |
| homelab-monitoring | k8s/monitoring | monitoring |
| homelab-ai | k8s/ai | ai |
| homelab-security | k8s/security | security |

## Related

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Guide](../../docs/GITOPS.md)
