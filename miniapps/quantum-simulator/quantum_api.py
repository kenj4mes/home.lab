"""
Quantum Simulator API

REST API for executing quantum circuits using multiple backends:
- Qiskit Aer (IBM)
- Cirq (Google)
- PennyLane (Xanadu)

Endpoints:
    POST /run         - Execute a quantum circuit
    GET /health       - Health check
    GET /info         - Service information
    GET /backends     - List available backends
    POST /qiskit      - Execute Qiskit-specific circuit
    POST /cirq        - Execute Cirq-specific circuit
    POST /pennylane   - Execute PennyLane-specific circuit
"""

from flask import Flask, request, jsonify
import time
import traceback
from typing import Dict, List, Any, Optional

# Import quantum libraries
try:
    from qiskit import QuantumCircuit
    from qiskit_aer import AerSimulator
    QISKIT_AVAILABLE = True
except ImportError:
    QISKIT_AVAILABLE = False

try:
    import cirq
    CIRQ_AVAILABLE = True
except ImportError:
    CIRQ_AVAILABLE = False

try:
    import pennylane as qml
    import numpy as np
    PENNYLANE_AVAILABLE = True
except ImportError:
    PENNYLANE_AVAILABLE = False

app = Flask(__name__)

# ============================================================================
# Configuration
# ============================================================================

MAX_QUBITS = int(__import__('os').environ.get("QUANTUM_MAX_QUBITS", 20))
MAX_SHOTS = int(__import__('os').environ.get("QUANTUM_MAX_SHOTS", 10000))
DEFAULT_SHOTS = 1024

# ============================================================================
# Qiskit Backend
# ============================================================================

def run_qiskit_circuit(circuit_def: List[Dict], num_qubits: int, shots: int) -> Dict:
    """
    Execute a circuit using Qiskit Aer simulator.
    
    Args:
        circuit_def: List of gate operations
        num_qubits: Number of qubits
        shots: Number of measurement shots
    
    Returns:
        Dictionary with measurement counts
    """
    if not QISKIT_AVAILABLE:
        raise RuntimeError("Qiskit not available")
    
    # Create circuit
    qc = QuantumCircuit(num_qubits, num_qubits)
    
    # Apply gates
    for op in circuit_def:
        gate = op.get("gate", "").lower()
        
        if gate == "h":
            qc.h(op["qubit"])
        elif gate == "x":
            qc.x(op["qubit"])
        elif gate == "y":
            qc.y(op["qubit"])
        elif gate == "z":
            qc.z(op["qubit"])
        elif gate == "cx" or gate == "cnot":
            qc.cx(op["control"], op["target"])
        elif gate == "cz":
            qc.cz(op["control"], op["target"])
        elif gate == "swap":
            qc.swap(op["qubit1"], op["qubit2"])
        elif gate == "rx":
            qc.rx(op["angle"], op["qubit"])
        elif gate == "ry":
            qc.ry(op["angle"], op["qubit"])
        elif gate == "rz":
            qc.rz(op["angle"], op["qubit"])
        elif gate == "t":
            qc.t(op["qubit"])
        elif gate == "s":
            qc.s(op["qubit"])
        elif gate == "measure":
            qubit = op["qubit"]
            qc.measure(qubit, qubit)
    
    # Measure all if no explicit measurements
    if not any(op.get("gate") == "measure" for op in circuit_def):
        qc.measure_all()
    
    # Run simulation
    simulator = AerSimulator()
    job = simulator.run(qc, shots=shots)
    result = job.result()
    counts = result.get_counts()
    
    return {
        "counts": counts,
        "shots": shots,
        "num_qubits": num_qubits,
        "backend": "qiskit_aer",
    }


# ============================================================================
# Cirq Backend
# ============================================================================

def run_cirq_circuit(circuit_def: List[Dict], num_qubits: int, shots: int) -> Dict:
    """
    Execute a circuit using Cirq simulator.
    
    Args:
        circuit_def: List of gate operations
        num_qubits: Number of qubits
        shots: Number of measurement shots
    
    Returns:
        Dictionary with measurement counts
    """
    if not CIRQ_AVAILABLE:
        raise RuntimeError("Cirq not available")
    
    # Create qubits
    qubits = cirq.LineQubit.range(num_qubits)
    
    # Build circuit
    circuit = cirq.Circuit()
    
    for op in circuit_def:
        gate = op.get("gate", "").lower()
        
        if gate == "h":
            circuit.append(cirq.H(qubits[op["qubit"]]))
        elif gate == "x":
            circuit.append(cirq.X(qubits[op["qubit"]]))
        elif gate == "y":
            circuit.append(cirq.Y(qubits[op["qubit"]]))
        elif gate == "z":
            circuit.append(cirq.Z(qubits[op["qubit"]]))
        elif gate == "cx" or gate == "cnot":
            circuit.append(cirq.CNOT(qubits[op["control"]], qubits[op["target"]]))
        elif gate == "cz":
            circuit.append(cirq.CZ(qubits[op["control"]], qubits[op["target"]]))
        elif gate == "swap":
            circuit.append(cirq.SWAP(qubits[op["qubit1"]], qubits[op["qubit2"]]))
        elif gate == "rx":
            circuit.append(cirq.rx(op["angle"])(qubits[op["qubit"]]))
        elif gate == "ry":
            circuit.append(cirq.ry(op["angle"])(qubits[op["qubit"]]))
        elif gate == "rz":
            circuit.append(cirq.rz(op["angle"])(qubits[op["qubit"]]))
        elif gate == "t":
            circuit.append(cirq.T(qubits[op["qubit"]]))
        elif gate == "s":
            circuit.append(cirq.S(qubits[op["qubit"]]))
    
    # Add measurements
    circuit.append(cirq.measure(*qubits, key="result"))
    
    # Run simulation
    simulator = cirq.Simulator()
    result = simulator.run(circuit, repetitions=shots)
    
    # Convert results to counts
    measurements = result.measurements["result"]
    counts = {}
    for row in measurements:
        key = "".join(str(b) for b in row)
        counts[key] = counts.get(key, 0) + 1
    
    return {
        "counts": counts,
        "shots": shots,
        "num_qubits": num_qubits,
        "backend": "cirq",
    }


# ============================================================================
# PennyLane Backend
# ============================================================================

def run_pennylane_circuit(circuit_def: List[Dict], num_qubits: int, shots: int) -> Dict:
    """
    Execute a circuit using PennyLane.
    
    Args:
        circuit_def: List of gate operations
        num_qubits: Number of qubits
        shots: Number of measurement shots
    
    Returns:
        Dictionary with measurement counts
    """
    if not PENNYLANE_AVAILABLE:
        raise RuntimeError("PennyLane not available")
    
    # Create device
    dev = qml.device("default.qubit", wires=num_qubits, shots=shots)
    
    @qml.qnode(dev)
    def circuit():
        for op in circuit_def:
            gate = op.get("gate", "").lower()
            
            if gate == "h":
                qml.Hadamard(wires=op["qubit"])
            elif gate == "x":
                qml.PauliX(wires=op["qubit"])
            elif gate == "y":
                qml.PauliY(wires=op["qubit"])
            elif gate == "z":
                qml.PauliZ(wires=op["qubit"])
            elif gate == "cx" or gate == "cnot":
                qml.CNOT(wires=[op["control"], op["target"]])
            elif gate == "cz":
                qml.CZ(wires=[op["control"], op["target"]])
            elif gate == "swap":
                qml.SWAP(wires=[op["qubit1"], op["qubit2"]])
            elif gate == "rx":
                qml.RX(op["angle"], wires=op["qubit"])
            elif gate == "ry":
                qml.RY(op["angle"], wires=op["qubit"])
            elif gate == "rz":
                qml.RZ(op["angle"], wires=op["qubit"])
            elif gate == "t":
                qml.T(wires=op["qubit"])
            elif gate == "s":
                qml.S(wires=op["qubit"])
        
        return qml.sample(wires=range(num_qubits))
    
    # Run circuit
    samples = circuit()
    
    # Convert to counts
    counts = {}
    if samples.ndim == 1:
        samples = samples.reshape(1, -1)
    
    for row in samples:
        key = "".join(str(int(b)) for b in row)
        counts[key] = counts.get(key, 0) + 1
    
    return {
        "counts": counts,
        "shots": shots,
        "num_qubits": num_qubits,
        "backend": "pennylane",
    }


# ============================================================================
# API Endpoints
# ============================================================================

@app.route("/run", methods=["POST"])
def run_circuit():
    """
    Execute a quantum circuit.
    
    Expected JSON:
    {
        "shots": 1024,
        "backend": "qiskit",  // or "cirq", "pennylane", "auto"
        "circuit": [
            {"gate": "h", "qubit": 0},
            {"gate": "cx", "control": 0, "target": 1}
        ]
    }
    
    Returns:
        JSON with measurement counts
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "No JSON data provided"}), 400
        
        # Parse parameters
        shots = min(data.get("shots", DEFAULT_SHOTS), MAX_SHOTS)
        backend = data.get("backend", "auto").lower()
        circuit_def = data.get("circuit", [])
        
        if not circuit_def:
            return jsonify({"error": "Empty circuit"}), 400
        
        # Determine number of qubits
        num_qubits = 0
        for op in circuit_def:
            for key in ["qubit", "control", "target", "qubit1", "qubit2"]:
                if key in op:
                    num_qubits = max(num_qubits, op[key] + 1)
        
        if num_qubits > MAX_QUBITS:
            return jsonify({"error": f"Maximum {MAX_QUBITS} qubits allowed"}), 400
        
        # Execute on selected backend
        start_time = time.time()
        
        if backend == "qiskit":
            result = run_qiskit_circuit(circuit_def, num_qubits, shots)
        elif backend == "cirq":
            result = run_cirq_circuit(circuit_def, num_qubits, shots)
        elif backend == "pennylane":
            result = run_pennylane_circuit(circuit_def, num_qubits, shots)
        elif backend == "auto":
            # Try backends in order of preference
            if QISKIT_AVAILABLE:
                result = run_qiskit_circuit(circuit_def, num_qubits, shots)
            elif CIRQ_AVAILABLE:
                result = run_cirq_circuit(circuit_def, num_qubits, shots)
            elif PENNYLANE_AVAILABLE:
                result = run_pennylane_circuit(circuit_def, num_qubits, shots)
            else:
                return jsonify({"error": "No quantum backends available"}), 500
        else:
            return jsonify({"error": f"Unknown backend: {backend}"}), 400
        
        result["execution_time"] = time.time() - start_time
        result["timestamp"] = time.time()
        
        return jsonify(result)
    
    except Exception as e:
        return jsonify({
            "error": str(e),
            "traceback": traceback.format_exc(),
        }), 500


@app.route("/health")
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "healthy",
        "service": "quantum-simulator",
        "timestamp": time.time(),
    })


@app.route("/info")
def info():
    """Service information endpoint."""
    return jsonify({
        "service": "HomeLab Quantum Simulator",
        "version": "1.0.0",
        "description": "Quantum circuit simulator with multiple backends",
        "endpoints": {
            "POST /run": "Execute a quantum circuit",
            "GET /backends": "List available backends",
            "GET /health": "Health check",
            "GET /info": "Service information",
        },
        "config": {
            "max_qubits": MAX_QUBITS,
            "max_shots": MAX_SHOTS,
            "default_shots": DEFAULT_SHOTS,
        },
        "backends": {
            "qiskit": QISKIT_AVAILABLE,
            "cirq": CIRQ_AVAILABLE,
            "pennylane": PENNYLANE_AVAILABLE,
        },
    })


@app.route("/backends")
def backends():
    """List available quantum backends."""
    available = []
    
    if QISKIT_AVAILABLE:
        available.append({
            "name": "qiskit",
            "description": "IBM Qiskit Aer Simulator",
            "status": "available",
        })
    
    if CIRQ_AVAILABLE:
        available.append({
            "name": "cirq",
            "description": "Google Cirq Simulator",
            "status": "available",
        })
    
    if PENNYLANE_AVAILABLE:
        available.append({
            "name": "pennylane",
            "description": "Xanadu PennyLane Simulator",
            "status": "available",
        })
    
    return jsonify({
        "backends": available,
        "default": "auto",
    })


@app.route("/examples")
def examples():
    """Example circuits for testing."""
    return jsonify({
        "bell_state": {
            "description": "Create a Bell state (entangled pair)",
            "circuit": [
                {"gate": "h", "qubit": 0},
                {"gate": "cx", "control": 0, "target": 1}
            ],
            "shots": 1024,
        },
        "ghz_state": {
            "description": "Create a GHZ state (3-qubit entanglement)",
            "circuit": [
                {"gate": "h", "qubit": 0},
                {"gate": "cx", "control": 0, "target": 1},
                {"gate": "cx", "control": 1, "target": 2}
            ],
            "shots": 1024,
        },
        "superposition": {
            "description": "Simple superposition",
            "circuit": [
                {"gate": "h", "qubit": 0}
            ],
            "shots": 1000,
        },
        "rotation": {
            "description": "Rotation gates example",
            "circuit": [
                {"gate": "rx", "qubit": 0, "angle": 1.5708},
                {"gate": "ry", "qubit": 1, "angle": 0.7854},
                {"gate": "rz", "qubit": 2, "angle": 3.1416}
            ],
            "shots": 1024,
        },
    })


# ============================================================================
# Main
# ============================================================================

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
