"""
Pre-built Quantum Circuits

Common quantum circuits ready to use with the Quantum Simulator API.
These can be imported and used directly or as templates.
"""

from typing import List, Dict
import math

# ============================================================================
# Basic Circuits
# ============================================================================

def bell_state() -> List[Dict]:
    """
    Bell State (EPR pair) - Maximally entangled 2-qubit state.
    Creates: |00⟩ + |11⟩ / √2
    """
    return [
        {"gate": "h", "qubit": 0},
        {"gate": "cx", "control": 0, "target": 1}
    ]


def ghz_state(n_qubits: int = 3) -> List[Dict]:
    """
    GHZ State - Generalized entanglement for n qubits.
    Creates: |00...0⟩ + |11...1⟩ / √2
    """
    circuit = [{"gate": "h", "qubit": 0}]
    for i in range(n_qubits - 1):
        circuit.append({"gate": "cx", "control": i, "target": i + 1})
    return circuit


def w_state() -> List[Dict]:
    """
    W State - 3-qubit entanglement with different properties than GHZ.
    Creates: |001⟩ + |010⟩ + |100⟩ / √3
    """
    # Approximate W state preparation
    theta1 = 2 * math.acos(1/math.sqrt(3))
    theta2 = math.pi / 4
    
    return [
        {"gate": "ry", "qubit": 0, "angle": theta1},
        {"gate": "cx", "control": 0, "target": 1},
        {"gate": "ry", "qubit": 1, "angle": theta2},
        {"gate": "cx", "control": 1, "target": 2},
        {"gate": "x", "qubit": 0},
    ]


# ============================================================================
# Quantum Algorithms
# ============================================================================

def quantum_fourier_transform(n_qubits: int = 3) -> List[Dict]:
    """
    Quantum Fourier Transform (QFT) on n qubits.
    Foundation for many quantum algorithms.
    """
    circuit = []
    
    for j in range(n_qubits):
        circuit.append({"gate": "h", "qubit": j})
        
        for k in range(j + 1, n_qubits):
            # Controlled rotation
            angle = math.pi / (2 ** (k - j))
            circuit.append({
                "gate": "rz", 
                "qubit": k, 
                "angle": angle
            })
            circuit.append({"gate": "cx", "control": j, "target": k})
    
    # Swap qubits to get correct ordering
    for i in range(n_qubits // 2):
        circuit.append({
            "gate": "swap",
            "qubit1": i,
            "qubit2": n_qubits - 1 - i
        })
    
    return circuit


def grover_iteration(n_qubits: int = 2) -> List[Dict]:
    """
    Single Grover iteration (oracle + diffusion).
    This is a template - the oracle should be customized.
    """
    circuit = []
    
    # Initialize superposition
    for i in range(n_qubits):
        circuit.append({"gate": "h", "qubit": i})
    
    # Oracle (marks |11⟩ state for 2 qubits)
    circuit.append({"gate": "cz", "control": 0, "target": 1})
    
    # Diffusion operator
    for i in range(n_qubits):
        circuit.append({"gate": "h", "qubit": i})
        circuit.append({"gate": "x", "qubit": i})
    
    circuit.append({"gate": "cz", "control": 0, "target": 1})
    
    for i in range(n_qubits):
        circuit.append({"gate": "x", "qubit": i})
        circuit.append({"gate": "h", "qubit": i})
    
    return circuit


def deutsch_jozsa(n_qubits: int = 2) -> List[Dict]:
    """
    Deutsch-Jozsa algorithm for constant vs balanced function.
    Uses n input qubits + 1 ancilla.
    """
    circuit = []
    total_qubits = n_qubits + 1
    
    # Initialize ancilla to |1⟩
    circuit.append({"gate": "x", "qubit": n_qubits})
    
    # Apply Hadamard to all qubits
    for i in range(total_qubits):
        circuit.append({"gate": "h", "qubit": i})
    
    # Oracle (balanced function: XOR of inputs)
    for i in range(n_qubits):
        circuit.append({"gate": "cx", "control": i, "target": n_qubits})
    
    # Apply Hadamard to input qubits
    for i in range(n_qubits):
        circuit.append({"gate": "h", "qubit": i})
    
    return circuit


# ============================================================================
# Variational Circuits (for VQE, QAOA)
# ============================================================================

def variational_ansatz(n_qubits: int = 2, depth: int = 1) -> List[Dict]:
    """
    Hardware-efficient variational ansatz.
    Uses rotation gates and entangling layers.
    """
    circuit = []
    
    for d in range(depth):
        # Rotation layer
        for i in range(n_qubits):
            # Parameterized rotations (using fixed values as placeholders)
            circuit.append({"gate": "ry", "qubit": i, "angle": 0.5 * (d + 1)})
            circuit.append({"gate": "rz", "qubit": i, "angle": 0.3 * (d + 1)})
        
        # Entangling layer (linear connectivity)
        for i in range(n_qubits - 1):
            circuit.append({"gate": "cx", "control": i, "target": i + 1})
    
    return circuit


def qaoa_layer(n_qubits: int = 3, gamma: float = 0.5, beta: float = 0.5) -> List[Dict]:
    """
    Single QAOA layer for MaxCut on a path graph.
    """
    circuit = []
    
    # Initialize superposition
    for i in range(n_qubits):
        circuit.append({"gate": "h", "qubit": i})
    
    # Problem unitary (ZZ interactions)
    for i in range(n_qubits - 1):
        circuit.append({"gate": "cx", "control": i, "target": i + 1})
        circuit.append({"gate": "rz", "qubit": i + 1, "angle": 2 * gamma})
        circuit.append({"gate": "cx", "control": i, "target": i + 1})
    
    # Mixer unitary (X rotations)
    for i in range(n_qubits):
        circuit.append({"gate": "rx", "qubit": i, "angle": 2 * beta})
    
    return circuit


# ============================================================================
# Quantum Error Correction
# ============================================================================

def bit_flip_code_encode() -> List[Dict]:
    """
    3-qubit bit-flip code encoder.
    Encodes |ψ⟩ into |ψψψ⟩.
    """
    return [
        {"gate": "cx", "control": 0, "target": 1},
        {"gate": "cx", "control": 0, "target": 2}
    ]


def phase_flip_code_encode() -> List[Dict]:
    """
    3-qubit phase-flip code encoder.
    """
    return [
        {"gate": "cx", "control": 0, "target": 1},
        {"gate": "cx", "control": 0, "target": 2},
        {"gate": "h", "qubit": 0},
        {"gate": "h", "qubit": 1},
        {"gate": "h", "qubit": 2}
    ]


# ============================================================================
# Utility Functions
# ============================================================================

def get_circuit_info(circuit: List[Dict]) -> Dict:
    """Get information about a circuit."""
    num_qubits = 0
    gate_counts = {}
    
    for op in circuit:
        gate = op.get("gate", "unknown")
        gate_counts[gate] = gate_counts.get(gate, 0) + 1
        
        for key in ["qubit", "control", "target", "qubit1", "qubit2"]:
            if key in op:
                num_qubits = max(num_qubits, op[key] + 1)
    
    return {
        "num_qubits": num_qubits,
        "num_gates": len(circuit),
        "gate_counts": gate_counts,
    }


# ============================================================================
# Circuit Catalog
# ============================================================================

CIRCUIT_CATALOG = {
    "bell_state": {
        "function": bell_state,
        "description": "Bell state (EPR pair)",
        "qubits": 2,
    },
    "ghz_3": {
        "function": lambda: ghz_state(3),
        "description": "3-qubit GHZ state",
        "qubits": 3,
    },
    "ghz_4": {
        "function": lambda: ghz_state(4),
        "description": "4-qubit GHZ state",
        "qubits": 4,
    },
    "w_state": {
        "function": w_state,
        "description": "3-qubit W state",
        "qubits": 3,
    },
    "qft_3": {
        "function": lambda: quantum_fourier_transform(3),
        "description": "3-qubit QFT",
        "qubits": 3,
    },
    "grover_2": {
        "function": lambda: grover_iteration(2),
        "description": "2-qubit Grover iteration",
        "qubits": 2,
    },
    "deutsch_jozsa_2": {
        "function": lambda: deutsch_jozsa(2),
        "description": "Deutsch-Jozsa with 2 input qubits",
        "qubits": 3,
    },
    "variational_2x2": {
        "function": lambda: variational_ansatz(2, 2),
        "description": "Variational ansatz (2 qubits, depth 2)",
        "qubits": 2,
    },
    "qaoa_3": {
        "function": lambda: qaoa_layer(3),
        "description": "QAOA layer for 3-node path graph",
        "qubits": 3,
    },
}
