# 🧪 Experimental Stack (Cybernetic Pillars)

> **Bleeding-Edge Infrastructure** - 5 pillars transforming your homelab into a cognitive cybernetic ecosystem

This stack implements the **Architectural Evolution of the Modern Homelab** - moving from passive hosting to active governance with self-regulating, AI-driven infrastructure.

---

## 🏛️ The Five Pillars

| Pillar | Component | Purpose | Edge Factor |
|--------|-----------|---------|-------------|
| **Cognitive** | LangFlow | Agentic AI Orchestration | Visual Logic Construction |
| **Resilience** | Chaos Mesh | Fault Injection as a Service | Kernel-Level Chaos |
| **Observability** | Kepler | eBPF Energy Monitoring | Physics → Joules/Token |
| **Platform** | Kratix | Everything-as-a-Service | XaaS via Promises |
| **Finance** | Rotki | Sovereign Financial Analytics | Local-First DeFi |

---

## 📁 Directory Structure

```
experimental/
├── README.md              # This file
├── langflow.yaml          # Agentic AI orchestration
├── chaos-mesh.yaml        # Fault injection platform
├── kepler.yaml            # eBPF energy observability
├── kratix.yaml            # Platform engineering (Promises)
└── rotki.yaml             # Sovereign finance analytics
```

---

## 🚀 Installation Order

### Phase 1: Prerequisites
```bash
# Ensure cert-manager is installed (from k8s/infrastructure)
kubectl apply -f ../infrastructure/cert-manager.yaml

# Ensure Ollama is running (for LangFlow AI backend)
kubectl apply -f ../infrastructure/ollama.yaml
```

### Phase 2: Core Experimental Stack
```bash
# 1. Kepler (energy observability) - lightweight, runs everywhere
kubectl apply -f kepler.yaml

# 2. Chaos Mesh (fault injection) - needs privileged access
kubectl apply -f chaos-mesh.yaml

# 3. LangFlow (agentic AI) - connects to Ollama
kubectl apply -f langflow.yaml
```

### Phase 3: Advanced Platform (Optional)
```bash
# 4. Kratix (XaaS platform) - complex, needs dedicated setup
kubectl apply -f kratix.yaml

# 5. Rotki (finance) - optional, for crypto/DeFi analytics
kubectl apply -f rotki.yaml
```

---

## 🌐 Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| **LangFlow** | https://langflow.lab.local | Auto-generated |
| **Chaos Dashboard** | https://chaos.lab.local | RBAC-based |
| **Grafana (Kepler)** | https://grafana.lab.local | Dashboard #17701 |
| **Kratix** | kubectl only | RBAC-based |
| **Rotki** | https://rotki.lab.local | Local SQLCipher |

---

## 🔄 The Cybernetic Loop

The true power emerges when these pillars integrate:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CYBERNETIC FEEDBACK LOOP                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐         │
│   │ SENSE   │───▶│ ANALYZE │───▶│ DECIDE  │───▶│  ACT    │         │
│   │ Kepler  │    │ Rotki/  │    │LangFlow │    │ Kratix/ │         │
│   │ (eBPF)  │    │ Prom    │    │ (AI)    │    │ Chaos   │         │
│   └─────────┘    └─────────┘    └─────────┘    └─────────┘         │
│        │                                              │             │
│        └──────────────── FEEDBACK ───────────────────┘             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Example Scenario: Self-Healing Energy-Aware AI

1. **Sense (Kepler)**: Detects `ollama-llama3-70b` consuming 280W (spike)
2. **Analyze (Prometheus)**: Energy budget exceeded for non-critical load
3. **Decide (LangFlow)**: AI agent receives alert, reasons: "Switch to efficient model"
4. **Act (Kratix)**: Triggers Promise to redeploy with `llama3-8b` (saves 200W)

---

## ⚠️ Requirements

### Hardware
| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 16GB | 32GB+ |
| CPU | 4 cores | 8+ cores |
| Storage | 50GB | 100GB NVMe |
| Kernel | 5.8+ | 6.0+ (for eBPF) |

### Software
| Dependency | Version | Purpose |
|------------|---------|---------|
| Kubernetes | 1.28+ | Orchestration |
| cert-manager | 1.14+ | TLS certificates |
| Prometheus | 2.45+ | Metrics (for Kepler) |
| Ollama | latest | AI backend (for LangFlow) |

---

## 🔒 Security Considerations

| Pillar | Risk | Mitigation |
|--------|------|------------|
| **LangFlow** | RCE via Python nodes | NetworkPolicy isolation |
| **Chaos Mesh** | Privileged DaemonSet | RBAC + Namespace limits |
| **Kepler** | Kernel metrics exposure | Read-only eBPF |
| **Kratix** | Platform admin access | Scoped Promises |
| **Rotki** | Financial data | SQLCipher encryption |

### Air-Gapped Deployment
For offline operation:
1. Pre-pull all images to local registry
2. Download Helm charts and convert to manifests
3. Configure internal DNS for `*.lab.local`

---

## 📚 References

- [LangFlow Documentation](https://docs.langflow.org/)
- [Chaos Mesh CNCF Project](https://chaos-mesh.org/)
- [Kepler Project](https://sustainable-computing.io/)
- [Kratix Platform](https://kratix.io/)
- [Rotki Documentation](https://rotki.readthedocs.io/)

---

*"The infrastructure that observes, reasons, and acts is no longer a tool—it is a partner."*
