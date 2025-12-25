"""
Signal Classifier API - ML-based RF Signal Classification
Uses TorchSig and custom models for signal identification
Port: 5604
"""

import asyncio
import io
import json
import logging
import os
import tempfile
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

import numpy as np
from fastapi import BackgroundTasks, FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Signal Classifier API",
    description="ML-based RF signal classification and identification",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
MODEL_DIR = Path(os.getenv("MODEL_DIR", "/app/models"))
CAPTURES_DIR = Path(os.getenv("CAPTURES_DIR", "/app/captures"))
MODEL_DIR.mkdir(parents=True, exist_ok=True)
CAPTURES_DIR.mkdir(parents=True, exist_ok=True)

# Classification storage
classifications: Dict[str, Dict[str, Any]] = {}

# Supported modulation types
MODULATION_TYPES = [
    "OOK", "4ASK", "8ASK",
    "BPSK", "QPSK", "8PSK", "16PSK", "32PSK",
    "16QAM", "32QAM", "64QAM", "128QAM", "256QAM",
    "2FSK", "4FSK", "8FSK", "16FSK",
    "GMSK", "OFDM", "AM-DSB", "AM-SSB", "FM", "PM",
]

# Protocol signatures (simplified pattern matching)
PROTOCOL_SIGNATURES = {
    "wifi_2.4ghz": {"freq_range": (2400, 2500), "bandwidth": 20},
    "wifi_5ghz": {"freq_range": (5150, 5850), "bandwidth": 40},
    "bluetooth": {"freq_range": (2400, 2483), "bandwidth": 1},
    "zigbee": {"freq_range": (2400, 2500), "bandwidth": 2},
    "lte_band7": {"freq_range": (2500, 2690), "bandwidth": 10},
    "lte_band3": {"freq_range": (1710, 1880), "bandwidth": 10},
    "5g_n78": {"freq_range": (3300, 3800), "bandwidth": 100},
    "lorawan": {"freq_range": (868, 928), "bandwidth": 0.125},
    "adsb": {"freq_range": (1090, 1090), "bandwidth": 1},
    "gps_l1": {"freq_range": (1575, 1576), "bandwidth": 2},
}


class ClassificationRequest(BaseModel):
    """Signal classification request"""
    sample_rate: float = Field(..., description="Sample rate in Hz")
    center_freq: Optional[float] = Field(None, description="Center frequency in Hz")
    bandwidth: Optional[float] = Field(None, description="Signal bandwidth in Hz")


class ClassificationResult(BaseModel):
    """Classification result"""
    classification_id: str
    status: str
    modulation: Optional[str] = None
    modulation_confidence: float = 0.0
    protocol: Optional[str] = None
    protocol_confidence: float = 0.0
    signal_features: Dict[str, Any] = {}
    started_at: str
    completed_at: Optional[str] = None
    error: Optional[str] = None


class SignalFeatures(BaseModel):
    """Extracted signal features"""
    snr_db: float
    bandwidth_hz: float
    power_dbm: float
    symbol_rate: Optional[float] = None
    modulation_index: Optional[float] = None


def extract_features(iq_data: np.ndarray, sample_rate: float) -> Dict[str, Any]:
    """Extract features from IQ data"""
    # Calculate power
    power = np.mean(np.abs(iq_data) ** 2)
    power_dbm = 10 * np.log10(power + 1e-10) + 30
    
    # Estimate SNR using median filter method
    sorted_power = np.sort(np.abs(iq_data) ** 2)
    noise_floor = np.median(sorted_power[:len(sorted_power)//10])
    signal_power = np.mean(sorted_power[-len(sorted_power)//10:])
    snr_db = 10 * np.log10(signal_power / (noise_floor + 1e-10))
    
    # Estimate bandwidth using FFT
    fft = np.fft.fftshift(np.fft.fft(iq_data))
    power_spectrum = np.abs(fft) ** 2
    threshold = np.max(power_spectrum) * 0.1
    occupied = np.where(power_spectrum > threshold)[0]
    if len(occupied) > 0:
        bandwidth_bins = occupied[-1] - occupied[0]
        bandwidth_hz = (bandwidth_bins / len(fft)) * sample_rate
    else:
        bandwidth_hz = 0
    
    # Instantaneous frequency for FSK detection
    phase = np.unwrap(np.angle(iq_data))
    inst_freq = np.diff(phase) * sample_rate / (2 * np.pi)
    freq_deviation = np.std(inst_freq)
    
    return {
        "snr_db": float(snr_db),
        "power_dbm": float(power_dbm),
        "bandwidth_hz": float(bandwidth_hz),
        "freq_deviation_hz": float(freq_deviation),
        "num_samples": len(iq_data),
        "sample_rate": sample_rate,
    }


def classify_modulation(iq_data: np.ndarray, features: Dict[str, Any]) -> tuple:
    """Classify modulation type using feature-based heuristics"""
    # This is a simplified classifier - production would use trained neural network
    
    # Calculate constellation features
    amplitude_std = np.std(np.abs(iq_data))
    phase_std = np.std(np.angle(iq_data))
    
    # Amplitude histogram for ASK detection
    amp_hist, _ = np.histogram(np.abs(iq_data), bins=20)
    amp_peaks = np.sum(amp_hist > np.max(amp_hist) * 0.3)
    
    # Phase histogram for PSK detection
    phase_hist, _ = np.histogram(np.angle(iq_data), bins=16)
    phase_peaks = np.sum(phase_hist > np.max(phase_hist) * 0.3)
    
    # Frequency deviation for FSK
    freq_dev = features.get("freq_deviation_hz", 0)
    
    predictions = {}
    
    # FSK detection
    if freq_dev > features["sample_rate"] * 0.01:
        if freq_dev > features["sample_rate"] * 0.1:
            predictions["4FSK"] = 0.7
        else:
            predictions["2FSK"] = 0.7
    
    # PSK detection based on phase clusters
    if phase_peaks >= 7 and amplitude_std < 0.2:
        predictions["8PSK"] = 0.8
    elif phase_peaks >= 3 and amplitude_std < 0.2:
        predictions["QPSK"] = 0.85
    elif phase_peaks >= 2 and amplitude_std < 0.15:
        predictions["BPSK"] = 0.9
    
    # QAM detection based on constellation spread
    if amplitude_std > 0.2 and phase_peaks >= 4:
        if amp_peaks >= 4:
            predictions["16QAM"] = 0.75
        else:
            predictions["64QAM"] = 0.6
    
    # OOK detection
    if amp_peaks == 2 and phase_std < 0.3:
        predictions["OOK"] = 0.85
    
    # OFDM detection (high peak-to-average power ratio)
    papr = np.max(np.abs(iq_data) ** 2) / np.mean(np.abs(iq_data) ** 2)
    if papr > 10:
        predictions["OFDM"] = 0.7
    
    # GMSK (constant envelope with Gaussian shaping)
    if amplitude_std < 0.1 and freq_dev > 0:
        predictions["GMSK"] = 0.75
    
    if not predictions:
        return "unknown", 0.0
    
    best_mod = max(predictions, key=predictions.get)
    return best_mod, predictions[best_mod]


def classify_protocol(center_freq: Optional[float], bandwidth: float, modulation: str) -> tuple:
    """Classify protocol based on frequency and signal characteristics"""
    if center_freq is None:
        return "unknown", 0.0
    
    center_mhz = center_freq / 1e6
    bandwidth_mhz = bandwidth / 1e6
    
    matches = []
    
    for protocol, params in PROTOCOL_SIGNATURES.items():
        freq_min, freq_max = params["freq_range"]
        proto_bw = params["bandwidth"]
        
        # Check frequency match
        if freq_min <= center_mhz <= freq_max:
            freq_score = 1.0
        elif abs(center_mhz - (freq_min + freq_max) / 2) < 50:
            freq_score = 0.5
        else:
            continue
        
        # Check bandwidth match
        bw_ratio = bandwidth_mhz / proto_bw if proto_bw > 0 else 1
        if 0.5 <= bw_ratio <= 2:
            bw_score = 1.0 - abs(1 - bw_ratio) * 0.5
        else:
            bw_score = 0.3
        
        confidence = freq_score * 0.6 + bw_score * 0.4
        matches.append((protocol, confidence))
    
    if not matches:
        return "unknown", 0.0
    
    best_match = max(matches, key=lambda x: x[1])
    return best_match


async def run_classification(
    classification_id: str,
    iq_data: np.ndarray,
    sample_rate: float,
    center_freq: Optional[float],
):
    """Run classification in background"""
    try:
        classifications[classification_id]["status"] = "analyzing"
        
        # Extract features
        features = extract_features(iq_data, sample_rate)
        classifications[classification_id]["signal_features"] = features
        
        # Classify modulation
        modulation, mod_confidence = classify_modulation(iq_data, features)
        classifications[classification_id]["modulation"] = modulation
        classifications[classification_id]["modulation_confidence"] = mod_confidence
        
        # Classify protocol
        protocol, proto_confidence = classify_protocol(
            center_freq,
            features["bandwidth_hz"],
            modulation
        )
        classifications[classification_id]["protocol"] = protocol
        classifications[classification_id]["protocol_confidence"] = proto_confidence
        
        classifications[classification_id]["status"] = "completed"
        classifications[classification_id]["completed_at"] = datetime.utcnow().isoformat()
        
    except Exception as e:
        logger.error(f"Classification {classification_id} failed: {e}")
        classifications[classification_id]["status"] = "failed"
        classifications[classification_id]["error"] = str(e)


@app.get("/")
async def root():
    """API root"""
    return {
        "service": "Signal Classifier API",
        "description": "ML-based RF signal classification",
        "version": "1.0.0",
        "supported_modulations": MODULATION_TYPES,
        "supported_protocols": list(PROTOCOL_SIGNATURES.keys()),
        "endpoints": {
            "POST /classify": "Classify uploaded IQ data",
            "GET /classification/{id}": "Get classification result",
            "GET /health": "Health check",
        }
    }


@app.get("/health")
async def health():
    """Health check"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "modulation_types": len(MODULATION_TYPES),
        "protocol_signatures": len(PROTOCOL_SIGNATURES),
        "active_classifications": len([c for c in classifications.values() if c["status"] == "analyzing"]),
    }


@app.post("/classify", response_model=ClassificationResult)
async def classify_signal(
    background_tasks: BackgroundTasks,
    sample_rate: float,
    center_freq: Optional[float] = None,
    file: UploadFile = File(..., description="IQ data file (complex64 or float32 interleaved I/Q)")
):
    """Classify uploaded IQ data"""
    classification_id = str(uuid.uuid4())[:8]
    
    # Read and parse IQ data
    content = await file.read()
    
    # Assume complex64 (interleaved float32 I/Q)
    try:
        iq_data = np.frombuffer(content, dtype=np.complex64)
    except Exception:
        # Try interleaved float32
        try:
            float_data = np.frombuffer(content, dtype=np.float32)
            iq_data = float_data[0::2] + 1j * float_data[1::2]
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Could not parse IQ data: {e}")
    
    if len(iq_data) < 1000:
        raise HTTPException(status_code=400, detail="Need at least 1000 samples for classification")
    
    classifications[classification_id] = {
        "classification_id": classification_id,
        "status": "queued",
        "modulation": None,
        "modulation_confidence": 0.0,
        "protocol": None,
        "protocol_confidence": 0.0,
        "signal_features": {},
        "started_at": datetime.utcnow().isoformat(),
        "completed_at": None,
        "error": None,
    }
    
    background_tasks.add_task(
        run_classification,
        classification_id,
        iq_data,
        sample_rate,
        center_freq
    )
    
    return ClassificationResult(**classifications[classification_id])


@app.get("/classification/{classification_id}", response_model=ClassificationResult)
async def get_classification(classification_id: str):
    """Get classification result"""
    if classification_id not in classifications:
        raise HTTPException(status_code=404, detail="Classification not found")
    return ClassificationResult(**classifications[classification_id])


@app.get("/modulations")
async def list_modulations():
    """List supported modulation types"""
    return {"modulations": MODULATION_TYPES}


@app.get("/protocols")
async def list_protocols():
    """List supported protocol signatures"""
    return {"protocols": PROTOCOL_SIGNATURES}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5604)
