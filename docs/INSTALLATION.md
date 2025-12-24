# ==============================================================================
# 🛠️ Infrastructure Installation Guide
# ==============================================================================

# Infrastructure Installation Guide

Complete guide for installing all required infrastructure components.

## 📋 Prerequisites

### Minimum Requirements

| Component | Specification |
|-----------|---------------|
| **OS** | RHEL 8/9, Fedora 38+, Ubuntu 22.04 LTS |
| **CPU** | 4 cores (8+ recommended) |
| **RAM** | 16GB (32GB+ for K8s cluster) |
| **Storage** | 100GB SSD minimum |
| **Network** | Static IP or DHCP reservation |

### Software Requirements

| Tool | Version | Purpose |
|------|---------|---------|
| Ansible | 2.14+ | Automation |
| Docker | 24.0+ | Containers |
| kubectl | 1.29+ | K8s CLI |
| Helm | 3.14+ | K8s packages |

---

## 🐳 Docker Installation

### Ubuntu/Debian

```bash
# Remove old versions
sudo apt remove docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt update
sudo apt install -y ca-certificates curl gnupg

# Add Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### RHEL/Fedora

```bash
# Remove old versions
sudo dnf remove docker docker-client docker-client-latest docker-common \
  docker-latest docker-latest-logrotate docker-logrotate docker-engine

# Add repository
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Install Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

---

## ☸️ Kubernetes Installation

### Option 1: kubeadm (Production)

```bash
# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# Install Kubernetes packages (Ubuntu)
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Initialize cluster (control plane only)
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Option 2: k3s (Lightweight)

```bash
# Single node
curl -sfL https://get.k3s.io | sh -

# Configure kubectl
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

---

## 🔌 Helm Installation

```bash
# Download and install
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add common repos
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add jetstack https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

---

## 🌐 Cilium CNI

```bash
# Install Cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
curl -L --fail --remote-name-all \
  https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz

# Install Cilium to cluster
cilium install --version 1.15.0

# Verify installation
cilium status
cilium connectivity test
```

---

## ⚖️ MetalLB

```bash
# Install via Helm
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb --namespace metallb-system --create-namespace

# Apply IP address pool configuration
kubectl apply -f k8s/infrastructure/metallb.yaml
```

---

## 💾 Longhorn Storage

```bash
# Prerequisites
sudo apt install -y open-iscsi nfs-common  # Ubuntu
sudo dnf install -y iscsi-initiator-utils nfs-utils  # RHEL

# Install via Helm
helm repo add longhorn https://charts.longhorn.io
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system --create-namespace \
  --set defaultSettings.defaultReplicaCount=2

# Access UI
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
```

---

## 🔐 Cert-Manager

```bash
# Install via Helm
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true

# Apply cluster issuers
kubectl apply -f k8s/infrastructure/cert-manager.yaml

# Verify
kubectl get clusterissuers
```

---

## 🌐 Ingress NGINX

```bash
# Install via Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.metrics.enabled=true

# Verify
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

---

## 📊 Monitoring Stack

```bash
# Install Prometheus + Grafana + Alertmanager
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Access Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Default: admin / prom-operator
```

---

## 🔄 ArgoCD

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access UI
kubectl port-forward svc/argocd-server -n argocd 8443:443

# Apply HomeLab applications
kubectl apply -f k8s/argocd/
```

---

## 🔄 Velero (Backup)

```bash
# Install Velero CLI
wget https://github.com/vmware-tanzu/velero/releases/download/v1.13.0/velero-v1.13.0-linux-amd64.tar.gz
tar -xvf velero-v1.13.0-linux-amd64.tar.gz
sudo mv velero-v1.13.0-linux-amd64/velero /usr/local/bin/

# Install to cluster (with MinIO backend)
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.9.0 \
  --bucket homelab-backups \
  --secret-file ./credentials-velero \
  --backup-location-config region=minio,s3ForcePathStyle=true,s3Url=http://minio:9000

# Apply schedules
kubectl apply -f k8s/velero/
```

---

## 🔐 HashiCorp Vault

```bash
# Install via Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault \
  --namespace vault --create-namespace \
  --set server.dev.enabled=true  # Remove for production

# Initialize (production)
kubectl exec -n vault vault-0 -- vault operator init

# Access UI
kubectl port-forward -n vault svc/vault 8200:8200
```

---

## ✅ Verification Checklist

```bash
# Check all pods
kubectl get pods -A

# Check storage classes
kubectl get storageclasses

# Check ingress
kubectl get ingress -A

# Check certificates
kubectl get certificates -A

# Check ArgoCD apps
kubectl get applications -n argocd
```

---

## 📚 Next Steps

1. [Configure DNS with Pi-hole](../docker/docker-compose.pihole.yml) - See Pi-hole compose file
2. [Set up Monitoring Dashboards](../configs/grafana/dashboards/) - Grafana dashboard configs
3. [Deploy Applications with ArgoCD](GITOPS.md) - GitOps workflow guide
4. [Configure Backups with Velero](../k8s/velero/README.md) - Velero backup schedules
