# 🧪 Experimental Stack - Cybernetic Infrastructure

> **Bleeding-Edge Technologies** - Transform your homelab from passive hosting to active governance

This documentation covers the **Five Pillars** of experimental infrastructure that push your homelab to the cutting edge of self-hosted technology.

---

## 🏛️ The Five Pillars

The experimental stack implements concepts from the **Architectural Evolution of the Modern Homelab** - transforming static infrastructure into a dynamic, self-regulating cybernetic system.

| Pillar | Component | Purpose | Integration |
|--------|-----------|---------|-------------|
| 🧠 **Cognitive** | LangFlow | Agentic AI Orchestration | Visual LLM chain builder |
| 💥 **Resilience** | Chaos Mesh | Fault Injection as a Service | Controlled chaos testing |
| ⚡ **Observability** | Kepler | eBPF Energy Monitoring | Joules-per-token metrics |
| 🏗️ **Platform** | Kratix | Everything-as-a-Service | XaaS via Promises |
| 💰 **Finance** | Rotki | Sovereign Financial Analytics | Local-first DeFi tracking |

---

## 🧠 Pillar 1: LangFlow (Cognitive Layer)

LangFlow is a visual IDE for building LLM applications. Unlike basic chat interfaces, it enables **agentic workflows** where AI systems can reason, decide, and execute complex tasks autonomously.

### Key Features

- **Visual Chain Construction**: Drag-and-drop LLM logic components
- **Custom Python Nodes**: Inject arbitrary code into AI pipelines
- **Ollama Integration**: 100% air-gapped AI operations
- **Agent Tools**: Connect AI to infrastructure APIs

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      LangFlow                               │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐ │
│  │  Prompt  │──▶│  Ollama  │──▶│  Tools   │──▶│  Output  │ │
│  │ Template │   │  Model   │   │ (Python) │   │ Response │ │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘ │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
              ┌───────────────────┐
              │     Ollama API    │
              │  (Local AI Models)│
              └───────────────────┘
```

### Use Case: HomeOS Command Center

Build a natural language interface to control your infrastructure:

1. **User**: "The media server is acting up, please restart it"
2. **LangFlow Agent**:
   - Parses intent: `restart_service`
   - Identifies entity: `jellyfin`
   - Calls Portainer API to restart container
3. **Response**: "I've restarted the Jellyfin container successfully"

### Installation

**Kubernetes:**
```bash
kubectl apply -f k8s/experimental/langflow.yaml
```

**Docker:**
```bash
docker compose -f docker/docker-compose.experimental.yml up -d langflow
```

### Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `OLLAMA_HOST` | Ollama API endpoint | `http://ollama:11434` |
| `LANGFLOW_SUPERUSER` | Admin username | `admin` |
| `LANGFLOW_SUPERUSER_PASSWORD` | Admin password | Required |
| `LANGFLOW_DATABASE_URL` | PostgreSQL connection | Required |

---

## 💥 Pillar 2: Chaos Mesh (Resilience Layer)

Chaos Mesh is a CNCF project for **chaos engineering** in Kubernetes. It answers: "What happens when things break?" by proactively injecting faults.

### Key Features

- **Pod Chaos**: Kill, restart, or stress pods
- **Network Chaos**: Latency, packet loss, partitions
- **IO Chaos**: Disk delays and failures
- **Workflow Engine**: Orchestrate complex chaos scenarios

### Fault Types

| Type | Action | Use Case |
|------|--------|----------|
| PodChaos | pod-kill, pod-failure | Test HA and recovery |
| NetworkChaos | delay, loss, partition | Test distributed systems |
| IOChaos | latency, fault | Test database resilience |
| StressChaos | cpu, memory | Test resource limits |

### Example: Matrix Synapse Stress Test

Test what happens when the database connection drops:

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: synapse-db-partition
spec:
  action: partition
  selector:
    labelSelectors:
      app: synapse
  target:
    selector:
      labelSelectors:
        app: postgresql
  duration: "60s"
```

**Observations to Record:**
- Does the Element client show "Reconnecting"?
- Are messages buffered and delivered after recovery?
- What error does Nginx Proxy return (502 vs 504)?

### The "Immunity System" Concept

Create scheduled chaos that exercises the system regularly:

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: Workflow
metadata:
  name: weekly-immunity-test
spec:
  schedule: "0 3 * * 0"  # Sunday 3 AM
  entry: immunity-sequence
  templates:
    - name: immunity-sequence
      templateType: Serial
      children:
        - kill-random-pod
        - network-stress
        - verify-metrics
```

### Installation

```bash
# Kubernetes only (requires privileged DaemonSet)
kubectl apply -f k8s/experimental/chaos-mesh.yaml

# Access dashboard
kubectl port-forward -n chaos-mesh svc/chaos-dashboard 2333:2333
```

---

## ⚡ Pillar 3: Kepler (Observability Layer)

Kepler (Kubernetes Efficient Power Level Exporter) uses **eBPF** to measure actual power consumption per pod. It connects software execution to physical energy expenditure.

### Key Features

- **Per-Pod Energy Metrics**: Joules consumed per container
- **Hardware Counter Integration**: RAPL, ACPI measurements
- **Carbon Emissions Estimation**: gCO2 based on grid intensity
- **Prometheus Integration**: Native metrics export

### The "Green AI" Experiment

With Ollama running locally, measure the **Cost of Intelligence**:

```promql
# Joules per Token
sum(rate(kepler_container_joules_total{container_name="ollama"}[5m])) 
/ 
sum(rate(ollama_tokens_generated[5m]))

# Hourly electricity cost (at $0.15/kWh)
sum(increase(kepler_container_joules_total{container_name="ollama"}[1h])) 
/ 3600000 * 0.15

# Carbon footprint (gCO2/hour at 400g/kWh)
sum(increase(kepler_container_joules_total[1h])) / 3600000 * 400
```

### Grafana Dashboard

Import Dashboard ID **17701** for comprehensive energy visualization:

- Total Cluster Power (Watts)
- Power by Namespace (Pie Chart)
- Top 10 Energy-Consuming Containers
- Carbon Emissions Over Time

### Installation

```bash
# Kubernetes
kubectl apply -f k8s/experimental/kepler.yaml

# Docker alternative: Scaphandre
docker compose -f docker/docker-compose.experimental.yml up -d scaphandre
```

---

## 🏗️ Pillar 4: Kratix (Platform Layer)

Kratix transforms your homelab from a collection of services into an **Internal Developer Platform (IDP)**. Using "Promises", you can offer **X-as-a-Service** (XaaS).

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Promise** | A contract defining what users can request |
| **API (CRD)** | The interface users interact with |
| **Pipeline** | How the platform fulfills requests |
| **Destination** | Where resources get deployed |

### Example: DevEnvironment-as-a-Service

**The Promise**: Platform team creates a Promise that provisions full development environments.

**The Request**: Developers create a simple YAML:

```yaml
apiVersion: platform.homelab.io/v1
kind: DevEnvironment
metadata:
  name: project-alpha
spec:
  language: python
  db: true
  size: medium
```

**The Result**: Kratix automatically provisions:
- code-server deployment
- PostgreSQL database
- Ingress at `project-alpha.dev.lab.local`
- Environment variables with DB credentials

### Multi-Cluster Emulation

Even with a single cluster, use **vCluster** to simulate multi-environment:

```
┌─────────────────────────────────────────────┐
│              Physical Cluster               │
├─────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Kratix    │  │      vCluster       │  │
│  │  Platform   │  ├──────────┬──────────┤  │
│  │  Cluster    │──│Production│ Staging  │  │
│  └─────────────┘  └──────────┴──────────┘  │
└─────────────────────────────────────────────┘
```

### Installation

```bash
kubectl apply -f k8s/experimental/kratix.yaml
```

---

## 💰 Pillar 5: Rotki (Finance Layer)

Rotki is a **local-first** crypto portfolio tracker. Unlike cloud-based alternatives, all data stays on your infrastructure in encrypted SQLCipher databases.

### Key Features

- **Multi-Chain Support**: Ethereum, L2s, Bitcoin, and more
- **DeFi Analytics**: Protocol-specific tracking
- **Tax Reporting**: CSV exports for tax preparation
- **100% Sovereign**: No cloud sync, no third-party servers

### Connect to Local Blockchain Nodes

Configure Rotki to use your local Base L2 node:

```
Settings → Networks → Base L2
RPC Endpoint: http://base-node:8545
```

This enables fully **air-gapped** balance queries without touching external APIs.

### Installation

**Kubernetes:**
```bash
kubectl apply -f k8s/experimental/rotki.yaml
```

**Docker:**
```bash
docker compose -f docker/docker-compose.experimental.yml up -d rotki
```

### Security Considerations

| Risk | Mitigation |
|------|------------|
| Web UI exposure | Deploy behind OAuth2 proxy |
| Data at rest | Encrypted with SQLCipher |
| External RPC leakage | Use local blockchain nodes |

---

## 🔄 The Cybernetic Loop

The true power emerges when all pillars integrate into a **self-regulating system**:

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

### Example Scenario

1. **Sense (Kepler)**: Detects Ollama consuming 280W (abnormal spike)
2. **Analyze (Prometheus)**: Alert: "High Energy Cost" triggered
3. **Decide (LangFlow)**: AI agent receives webhook, reasons:
   - "Non-critical workload causing spike"
   - "Should switch to efficient model to save power"
4. **Act**:
   - **Option A (Kratix)**: Trigger Promise to redeploy with smaller model
   - **Option B (Chaos Mesh)**: Force restart if stuck process detected

---

## 📋 Quick Reference

### Access Points

| Service | URL | Port |
|---------|-----|------|
| LangFlow | https://langflow.lab.local | 7860 |
| Chaos Dashboard | https://chaos.lab.local | 2333 |
| Rotki | https://rotki.lab.local | 4242 |
| Kepler Metrics | :9102/metrics | 9102 |

### Commands

```bash
# Start all experimental services (Docker)
docker compose -f docker/docker-compose.experimental.yml up -d

# Start experimental stack (Kubernetes)
kubectl apply -f k8s/experimental/

# Check Kepler metrics
curl http://localhost:9102/metrics | grep kepler_

# Run chaos experiment
kubectl apply -f k8s/experimental/chaos-mesh.yaml
```

---

## 📚 References

| Component | Documentation |
|-----------|---------------|
| LangFlow | [docs.langflow.org](https://docs.langflow.org/) |
| Chaos Mesh | [chaos-mesh.org](https://chaos-mesh.org/) |
| Kepler | [sustainable-computing.io](https://sustainable-computing.io/) |
| Kratix | [kratix.io](https://kratix.io/) |
| Rotki | [rotki.readthedocs.io](https://rotki.readthedocs.io/) |

---

*"The infrastructure that observes, reasons, and acts is no longer a tool—it is a partner."* 🔄
