# ==============================================================================
# 🛠️ Developer Experience (DevEx) Stack
# ==============================================================================

# Developer Experience (DevEx) Stack

Enterprise-grade developer tools for your private cloud homelab.

## 📦 Components

| Service | Purpose | Port | URL |
|---------|---------|------|-----|
| **Coder** | Cloud Development Environments | 7080 | coder.homelab.local |
| **Plane** | Project Management (Jira/Linear alt) | 3000 | plane.homelab.local |
| **Hoppscotch** | API Testing (Postman alt) | 3000 | hoppscotch.homelab.local |
| **Ollama** | AI Coding Assistant Backend | 11434 | ollama.homelab.local |
| **Forgejo** | Git Forge & CI/CD | 3000/22 | git.homelab.local |

## 🚀 Quick Start

### Prerequisites

1. Kubernetes cluster running
2. Cert-Manager installed (`kubectl apply -f ../infrastructure/cert-manager.yaml`)
3. Ingress-NGINX or Traefik installed
4. Longhorn or other StorageClass configured

### Deploy All Services

```bash
# Deploy entire DevEx stack
kubectl apply -f coder.yaml
kubectl apply -f plane.yaml
kubectl apply -f hoppscotch.yaml
kubectl apply -f ollama.yaml
kubectl apply -f forgejo.yaml
```

### Deploy Individual Services

```bash
# Just the Git forge
kubectl apply -f forgejo.yaml

# Just AI coding assistance
kubectl apply -f ollama.yaml
```

## 🔧 Configuration

### 1. Update Secrets

Before deploying, update the `CHANGEME_*` values in each manifest:

```bash
# Generate random secrets
openssl rand -base64 32  # For passwords
openssl rand -hex 32     # For tokens
```

### 2. DNS Configuration

Add to your Pi-hole/DNS:

```
coder.homelab.local      -> <ingress-ip>
plane.homelab.local      -> <ingress-ip>
hoppscotch.homelab.local -> <ingress-ip>
ollama.homelab.local     -> <ingress-ip>
git.homelab.local        -> <ingress-ip>
```

### 3. Keycloak SSO (Optional)

For Coder SSO integration:

1. Create a new client in Keycloak realm `homelab`
2. Client ID: `coder`
3. Client Protocol: `openid-connect`
4. Access Type: `confidential`
5. Valid Redirect URIs: `https://coder.homelab.local/*`
6. Copy Client Secret to `coder-secrets`

## 💻 Coder - Cloud Dev Environments

Coder lets you define development environments as code using Terraform.

### Create a Workspace Template

```hcl
# templates/kubernetes-dev/main.tf
terraform {
  required_providers {
    coder = { source = "coder/coder" }
    kubernetes = { source = "hashicorp/kubernetes" }
  }
}

resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"
}

resource "kubernetes_pod" "workspace" {
  metadata {
    name      = "coder-${data.coder_workspace.me.name}"
    namespace = "coder-workspaces"
  }
  spec {
    container {
      name  = "dev"
      image = "codercom/enterprise-base:ubuntu"
      command = ["sh", "-c", coder_agent.main.init_script]
    }
  }
}
```

### Connect from VS Code

```bash
# Install Coder CLI
curl -fsSL https://coder.com/install.sh | sh

# Login
coder login https://coder.homelab.local

# SSH into workspace from VS Code
coder config-ssh
# Then: code --remote ssh-remote+coder.my-workspace
```

## 📋 Plane - Project Management

### First-Time Setup

1. Access https://plane.homelab.local
2. Create admin account
3. Create your first workspace
4. Invite team members (or just yourself)

### Features

- **Issues**: Track bugs, features, tasks
- **Cycles**: Sprint-like time-boxed iterations
- **Modules**: Group related issues
- **Views**: Custom filtered views
- **Pages**: Documentation within projects

## 🔬 Hoppscotch - API Testing

### Access

- Main App: https://hoppscotch.homelab.local
- Admin: https://admin.hoppscotch.homelab.local

### First-Time Setup

1. Access admin panel
2. Create admin account
3. Configure email settings (optional)
4. Create team workspaces

## 🤖 Ollama - AI Coding

### Pull Coding Models

```bash
# From within cluster
kubectl exec -n ollama deploy/ollama -- ollama pull qwen2.5-coder:7b
kubectl exec -n ollama deploy/ollama -- ollama pull deepseek-coder-v2:16b

# Or trigger the job
kubectl apply -f ollama.yaml  # Includes model pull job
```

### VS Code Integration

1. Install **Continue** extension in VS Code
2. Configure `~/.continue/config.json`:

```json
{
  "models": [
    {
      "title": "HomeLab Coder",
      "provider": "ollama",
      "model": "qwen2.5-coder:7b",
      "apiBase": "http://ollama.homelab.local:11434"
    }
  ]
}
```

### API Usage

```bash
# Chat completion
curl http://ollama.homelab.local:11434/api/chat -d '{
  "model": "qwen2.5-coder:7b",
  "messages": [{"role": "user", "content": "Write a Python function to sort a list"}]
}'

# Code completion
curl http://ollama.homelab.local:11434/api/generate -d '{
  "model": "qwen2.5-coder:7b",
  "prompt": "def fibonacci(n):",
  "suffix": "\n    return result"
}'
```

## 🔧 Forgejo - Git Forge

### First-Time Setup

1. Access https://git.homelab.local
2. Complete installation wizard
3. Create admin account
4. Register Action Runners

### Register CI/CD Runner

```bash
# Get registration token from Forgejo admin panel
# Site Administration -> Actions -> Runners -> Create new Runner

# Update runner-token in forgejo-secrets
kubectl -n forgejo create secret generic forgejo-secrets \
  --from-literal=runner-token="YOUR_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart runners
kubectl -n forgejo rollout restart deployment/forgejo-runner
```

### Git Clone via SSH

```bash
# Add SSH key to Forgejo profile
# Then clone:
git clone git@git.homelab.local:username/repo.git
```

### Container Registry

Push images to Forgejo's built-in registry:

```bash
docker login git.homelab.local
docker tag myapp:latest git.homelab.local/username/myapp:latest
docker push git.homelab.local/username/myapp:latest
```

## 📊 Resource Requirements

| Service | Min RAM | Recommended RAM | Storage |
|---------|---------|-----------------|---------|
| Coder | 512MB | 2GB | 10GB |
| Plane | 1GB | 2GB | 10GB |
| Hoppscotch | 256MB | 512MB | 5GB |
| Ollama | 4GB | 16GB | 50GB+ |
| Forgejo | 256MB | 1GB | 50GB |

**Total DevEx Stack**: ~6GB RAM minimum, ~16GB recommended

## 🔗 Integration Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Workflow                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐                 │
│  │ VS Code │───▶│  Coder  │───▶│ K8s Pod │                 │
│  │ Desktop │    │   CDE   │    │Workspace│                 │
│  └────┬────┘    └─────────┘    └────┬────┘                 │
│       │                              │                       │
│       │ Continue                     │ git push              │
│       ▼                              ▼                       │
│  ┌─────────┐                   ┌─────────┐                  │
│  │ Ollama  │                   │ Forgejo │──┐               │
│  │   AI    │                   │   Git   │  │ Actions       │
│  └─────────┘                   └─────────┘  │               │
│                                      │      ▼               │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐                 │
│  │  Plane  │◀───│  Issue  │◀───│ Runner  │                 │
│  │ Tracker │    │  Close  │    │  CI/CD  │                 │
│  └─────────┘    └─────────┘    └─────────┘                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 🔐 Security Notes

1. **All services use HTTPS** via Cert-Manager
2. **Secrets in Kubernetes** - not hardcoded
3. **Network policies** - apply from `../policies/`
4. **SSO recommended** - integrate with Keycloak
5. **No external dependencies** - 100% self-hosted
