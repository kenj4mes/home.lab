# 🚀 E-Stack (Enterprise 2025)

Next-generation infrastructure: WASM compute, autonomous AI agents, eBPF observability, and P2P distribution.

## 📦 Components

| Service | Category | Purpose |
|---------|----------|---------|
| **SpinKube** | Compute | WebAssembly on Kubernetes - millisecond cold starts |
| **OpenHands** | AI | Autonomous software engineer (formerly OpenDevin) |
| **Spegel** | Distribution | P2P container image caching across nodes |
| **K8sGPT** | AI Ops | AI-powered cluster troubleshooting |
| **Coroot** | Observability | Zero-config eBPF service mapping |
| **Tetragon** | Security | Kernel-level security enforcement |

## 🚀 Installation Order

**CRITICAL**: Components have dependencies. Install in order:

```bash
# 1. Prerequisites (already installed)
# - Cert-Manager (for SpinKube webhooks)
# - Longhorn (for persistent storage)
# - Ollama (for K8sGPT/OpenHands LLM)

# 2. Security & Observability (no dependencies)
kubectl apply -f tetragon.yaml    # eBPF security
kubectl apply -f coroot.yaml      # eBPF observability

# 3. Distribution
kubectl apply -f spegel.yaml      # P2P registry

# 4. AI Operations
kubectl apply -f k8sgpt.yaml      # AI SRE (requires Ollama)

# 5. AI Development
kubectl apply -f openhands.yaml   # AI agent (requires Ollama)

# 6. WASM Compute (requires additional Helm charts)
# See SpinKube section below
```

## 🌐 SpinKube - WebAssembly on Kubernetes

### Why WASM?

| Metric | Containers | WASM |
|--------|------------|------|
| Cold start | 1-10 seconds | 1-10 milliseconds |
| Image size | 100s MB | 1-10 MB |
| Memory overhead | High | Minimal |
| Security | Namespace isolation | Sandboxed by default |

### Installation (Helm Required)

```bash
# 1. Ensure cert-manager is installed
kubectl get pods -n cert-manager

# 2. Install Runtime Class Manager (kwasm)
helm repo add kwasm http://kwasm.sh/kwasm-operator/
helm install kwasm-operator kwasm/kwasm-operator \
  --namespace kwasm --create-namespace \
  --set kwasmOperator.installerImage=ghcr.io/spinframework/containerd-shim-spin/node-installer:v0.22.0

# 3. Annotate nodes to install WASM shim
kubectl annotate node --all kwasm.sh/kwasm-node=true

# 4. Wait for provisioning
kubectl get nodes --show-labels | grep kwasm-provisioned

# 5. Install Spin Operator
kubectl apply -f https://github.com/spinkube/spin-operator/releases/download/v0.6.1/spin-operator.crds.yaml
helm install spin-operator oci://ghcr.io/spinframework/charts/spin-operator \
  --namespace spin-operator --create-namespace --version 0.6.1

# 6. Apply shim executor and example app
kubectl apply -f spinkube.yaml
```

### Deploy Your First WASM App

```yaml
apiVersion: core.spinoperator.dev/v1alpha1
kind: SpinApp
metadata:
  name: my-wasm-app
spec:
  image: "your-registry/your-spin-app:latest"
  replicas: 3
  executor: containerd-shim-spin
```

## 🤖 OpenHands - Autonomous AI Agent

### What It Does

OpenHands is an AI software engineer that can:
- Clone repositories
- Write and modify code
- Run tests
- Fix bugs
- Deploy applications

### Architecture

```
┌─────────────────────────────────────────┐
│            OpenHands Pod                │
├─────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    │
│  │  OpenHands  │◀──▶│   Docker    │    │
│  │    Agent    │    │     in      │    │
│  │   (LLM)     │    │   Docker    │    │
│  └──────┬──────┘    └──────┬──────┘    │
│         │                   │           │
│         └───────┬───────────┘           │
│                 ▼                       │
│         ┌─────────────┐                 │
│         │  Workspace  │                 │
│         │   Volume    │                 │
│         │  (50GB)     │                 │
│         └─────────────┘                 │
└─────────────────────────────────────────┘
```

### First-Time Setup

1. Deploy: `kubectl apply -f openhands.yaml`
2. Access: https://openhands.homelab.local
3. Configure LLM backend (defaults to local Ollama)
4. Start a task: "Clone the homelab repo and add a README"

### Security Notes

⚠️ **OpenHands runs privileged DinD containers**

- Network policy restricts egress
- Isolated namespace
- No access to cluster secrets by default

## 🔄 Spegel - P2P Image Distribution

### How It Works

```
Traditional:
  Node A ──────► Docker Hub ◄────── Node B
                    ↑
                    │ (Slow WAN)
                    │
                Node C

With Spegel:
  Node A ◄────────────────► Node B
    ▲                          ▲
    │         (Fast LAN)       │
    └──────────► Node C ◄──────┘
```

### Node Configuration (REQUIRED)

Before installing Spegel, configure containerd on **each node**:

```bash
# For standard Kubernetes
cat >> /etc/containerd/config.toml << EOF
[plugins."io.containerd.grpc.v1.cri".containerd]
  discard_unpacked_layers = false
EOF
systemctl restart containerd

# For K3s
cat >> /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl << EOF
[plugins."io.containerd.grpc.v1.cri".containerd]
  discard_unpacked_layers = false
EOF
systemctl restart k3s
```

### Installation

```bash
kubectl apply -f spegel.yaml
```

## 🤖 K8sGPT - AI SRE

### What It Does

Scans your cluster for issues and uses Ollama to explain fixes in plain English.

### Example Output

```
Problem: Pod "nginx-broken" in namespace "default" is in CrashLoopBackOff
Analysis: The container is failing to start because the image "nginx:broken" 
          cannot be pulled (ImagePullBackOff).
Solution: 
  1. Check if the image tag exists: `docker pull nginx:broken`
  2. If using a private registry, verify imagePullSecrets
  3. Correct the image tag to a valid version: `nginx:latest`
```

### Manual Analysis

```bash
# Port-forward to k8sgpt pod
kubectl -n k8sgpt exec -it deploy/k8sgpt-cli -- k8sgpt analyze --explain
```

## 🔍 Coroot - eBPF Observability

### Zero-Config Service Maps

Coroot automatically discovers:
- All services and their dependencies
- Latency between services
- Error rates
- Resource usage

No sidecars, no instrumentation, no code changes.

### Access

https://coroot.homelab.local

### Integration with Prometheus

Coroot can use your existing Prometheus as a data source:

```yaml
env:
  - name: BOOTSTRAP_PROMETHEUS_URL
    value: "http://prometheus.monitoring.svc.cluster.local:9090"
```

## 🛡️ Tetragon - eBPF Security

### Defense-in-Depth

Unlike traditional security tools that **alert** after an attack, Tetragon can **block** malicious syscalls at the kernel level.

### Pre-configured Policies

| Policy | What It Detects/Blocks |
|--------|------------------------|
| `reverse-shell.yaml` | Outbound connections from shells |
| `sensitive-files.yaml` | Access to /etc/shadow, SSH keys |
| `container-escape.yaml` | Attempts to access host namespaces |

### View Security Events

```bash
# Stream tetragon events
kubectl -n tetragon logs -l app=tetragon -c export-stdout -f

# Or use tetra CLI
kubectl -n tetragon exec -it ds/tetragon -- tetra getevents
```

### Add Custom Policy

```yaml
apiVersion: cilium.io/v1alpha1
kind: TracingPolicy
metadata:
  name: "block-bitcoin-mining"
spec:
  kprobes:
  - call: "tcp_connect"
    syscall: false
    selectors:
    - matchArgs:
      - index: 1
        operator: "In"
        values:
        - "stratum+tcp://*"
    matchActions:
    - action: Sigkill
```

## 📊 Resource Requirements

| Service | Min RAM | Recommended | Storage |
|---------|---------|-------------|---------|
| SpinKube | 256MB | 512MB | - |
| OpenHands | 4GB | 8GB | 50GB |
| Spegel | 128MB | 256MB | - |
| K8sGPT | 256MB | 512MB | - |
| Coroot | 512MB | 2GB | 50GB |
| Tetragon | 256MB | 1GB | - |
| **Total** | **~6GB** | **~12GB** | **100GB** |

## 🔗 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    2025 AI-Native Kubernetes                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    COMPUTE LAYER                                │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │ │
│  │  │   Standard   │  │   SpinKube   │  │   OpenHands  │         │ │
│  │  │  Containers  │  │    (WASM)    │  │  (AI Agent)  │         │ │
│  │  │   (OCI)      │  │  <10ms start │  │   (DinD)     │         │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘         │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    AI OPERATIONS                                │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │ │
│  │  │    Ollama    │──│   K8sGPT     │  │   Continue   │         │ │
│  │  │   (LLM)      │  │  (AI SRE)    │  │ (Code Assist)│         │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘         │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    OBSERVABILITY (eBPF)                        │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │ │
│  │  │    Coroot    │  │   Tetragon   │  │  Prometheus  │         │ │
│  │  │ (Service Map)│  │  (Security)  │  │  (Metrics)   │         │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘         │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    DISTRIBUTION                                 │ │
│  │  ┌──────────────────────────────────────────────────────────┐  │ │
│  │  │                     Spegel (P2P)                         │  │ │
│  │  │   Node A ◄────────────► Node B ◄────────────► Node C    │  │ │
│  │  └──────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## 📚 Related Docs

- [Infrastructure README](../infrastructure/README.md) - Core K8s components
- [DevEx README](../devex/README.md) - Developer tools
- [BASE_ECOSYSTEM.md](../../docs/BASE_ECOSYSTEM.md) - Base network reference
