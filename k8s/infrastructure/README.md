# ==============================================================================
# 📊 K8s Infrastructure README
# ==============================================================================

# Kubernetes Infrastructure Components

This directory contains Kubernetes manifests for core infrastructure components.

## 🏗️ Components Overview

| Component | Purpose | Installation |
|-----------|---------|--------------|
| **Cert-Manager** | Automated TLS certificate management | Helm |
| **MetalLB** | Bare metal load balancer | Helm |
| **Cilium** | eBPF-based CNI with security | Helm |
| **Longhorn** | Distributed block storage | Helm |
| **Ingress-NGINX** | HTTP/HTTPS ingress controller | Helm |
| **Traefik** | Cloud-native edge router | Helm |

## 📦 Installation Order

Install components in this order for proper dependency resolution:

```bash
# 1. CNI (Cilium) - Install first, network foundation
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --namespace kube-system \
  --set kubeProxyReplacement=true \
  --set hubble.enabled=true \
  --set hubble.ui.enabled=true

# 2. Storage (Longhorn) - Persistent volumes
helm repo add longhorn https://charts.longhorn.io
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system --create-namespace \
  --set defaultSettings.defaultReplicaCount=2

# 3. Load Balancer (MetalLB)
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb \
  --namespace metallb-system --create-namespace
# Then apply: kubectl apply -f metallb.yaml

# 4. Ingress Controller (choose one)
# Option A: NGINX
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# Option B: Traefik
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik \
  --namespace traefik --create-namespace

# 5. Certificate Manager
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true
# Then apply: kubectl apply -f cert-manager.yaml
```

## 🔧 Configuration

### MetalLB IP Range
Edit `metallb.yaml` and update the IP address pool:
```yaml
spec:
  addresses:
    - 192.168.1.200-192.168.1.250  # Your LAN range
```

### Cert-Manager Email
Edit `cert-manager.yaml` and update the ACME email:
```yaml
spec:
  acme:
    email: your-email@example.com
```

### Longhorn Backup
Edit `longhorn.yaml` and configure S3 credentials:
```yaml
stringData:
  AWS_ACCESS_KEY_ID: "your-access-key"
  AWS_SECRET_ACCESS_KEY: "your-secret-key"
```

## 📋 Verification Commands

```bash
# Check all infrastructure pods
kubectl get pods -n kube-system -l k8s-app=cilium
kubectl get pods -n longhorn-system
kubectl get pods -n metallb-system
kubectl get pods -n ingress-nginx
kubectl get pods -n cert-manager

# Check storage classes
kubectl get storageclasses

# Check load balancer IPs
kubectl get svc -A | grep LoadBalancer

# Check certificates
kubectl get certificates -A
kubectl get clusterissuers
```

## 🔗 Related Documentation

- [ArgoCD GitOps](../argocd/README.md)
- [Velero Backups](../velero/README.md)
- [Network Policies](../policies/README.md)
