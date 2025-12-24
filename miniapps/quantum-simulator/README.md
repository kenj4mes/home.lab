# Quantum Simulator Service

Quantum circuit simulator providing a REST API for executing circuits using multiple backends.

## Supported Backends

| Backend | Provider | Features |
|---------|----------|----------|
| **Qiskit** | IBM | Full gate set, noise models, statevector |
| **Cirq** | Google | Efficient simulation, device models |
| **PennyLane** | Xanadu | Differentiable circuits, ML integration |

## Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/run` | POST | Execute a quantum circuit |
| `/backends` | GET | List available backends |
| `/examples` | GET | Get example circuits |
| `/health` | GET | Health check |
| `/info` | GET | Service information |

## Usage

### Docker

```bash
# Build
docker build -t homelab/quantum-simulator .

# Run
docker run -p 5002:5000 homelab/quantum-simulator

# Test
curl http://localhost:5002/health
```

### API Examples

#### Execute Bell State

```bash
curl -X POST http://localhost:5002/run \
  -H "Content-Type: application/json" \
  -d '{
    "shots": 1024,
    "backend": "qiskit",
    "circuit": [
      {"gate": "h", "qubit": 0},
      {"gate": "cx", "control": 0, "target": 1}
    ]
  }'
```

Response:
```json
{
  "counts": {"00": 512, "11": 512},
  "shots": 1024,
  "num_qubits": 2,
  "backend": "qiskit_aer",
  "execution_time": 0.023
}
```

#### Rotation Gates

```bash
curl -X POST http://localhost:5002/run \
  -H "Content-Type: application/json" \
  -d '{
    "shots": 1000,
    "circuit": [
      {"gate": "rx", "qubit": 0, "angle": 1.5708},
      {"gate": "ry", "qubit": 1, "angle": 0.7854}
    ]
  }'
```

## Supported Gates

| Gate | Parameters | Description |
|------|------------|-------------|
| `h` | qubit | Hadamard |
| `x` | qubit | Pauli-X (NOT) |
| `y` | qubit | Pauli-Y |
| `z` | qubit | Pauli-Z |
| `t` | qubit | T gate (π/8) |
| `s` | qubit | S gate (π/4) |
| `cx`/`cnot` | control, target | Controlled-NOT |
| `cz` | control, target | Controlled-Z |
| `swap` | qubit1, qubit2 | SWAP |
| `rx` | qubit, angle | X rotation |
| `ry` | qubit, angle | Y rotation |
| `rz` | qubit, angle | Z rotation |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `QUANTUM_MAX_QUBITS` | 20 | Maximum qubits per circuit |
| `QUANTUM_MAX_SHOTS` | 10000 | Maximum shots per execution |

## Integration with Open-WebUI

Create a custom tool in Open-WebUI:

```python
import requests

def run_quantum_circuit(circuit: list, shots: int = 1024) -> dict:
    """Execute a quantum circuit on the local simulator."""
    resp = requests.post(
        "http://quantum-simulator:5000/run",
        json={"circuit": circuit, "shots": shots}
    )
    return resp.json()
```

## Pre-built Circuits

See `circuits.py` for ready-to-use quantum circuits:
- Bell State
- GHZ State
- W State
- Quantum Fourier Transform
- Grover's Algorithm
- QAOA
- Variational Ansatz
