"""
MusicGen - AI Music Generation API
Flask application providing REST API for Meta's AudioCraft MusicGen.
"""

import os
import io
import base64
import logging
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Lazy load MusicGen to avoid long startup
_musicgen_model = None

def get_musicgen():
    """Lazy load MusicGen model."""
    global _musicgen_model
    if _musicgen_model is None:
        logger.info("Loading MusicGen model...")
        from audiocraft.models import MusicGen
        
        model_name = os.environ.get("MUSICGEN_MODEL", "small")
        _musicgen_model = MusicGen.get_pretrained(f"facebook/musicgen-{model_name}")
        _musicgen_model.set_generation_params(duration=10)
        
        logger.info(f"MusicGen model ({model_name}) loaded successfully")
    return _musicgen_model

@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "healthy",
        "service": "musicgen",
        "version": "1.0.0",
        "model": os.environ.get("MUSICGEN_MODEL", "small")
    })

@app.route("/generate", methods=["POST"])
def generate():
    """
    Generate music from text prompt.
    
    Request body:
        {
            "prompt": "epic orchestral theme with drums",
            "duration": 10,              # optional, max 30 seconds
            "output_format": "wav"       # optional: wav, mp3, base64
        }
    
    Returns:
        Audio file (wav/mp3) or base64-encoded audio
    """
    try:
        data = request.get_json()
        
        if not data or "prompt" not in data:
            return jsonify({"error": "Missing 'prompt' field"}), 400
        
        prompt = data["prompt"]
        duration = min(data.get("duration", 10), 30)  # Cap at 30 seconds
        output_format = data.get("output_format", "wav")
        
        logger.info(f"Generating music: '{prompt[:50]}...' ({duration}s)")
        
        # Generate music
        model = get_musicgen()
        model.set_generation_params(duration=duration)
        
        wav = model.generate([prompt])
        
        # Get sample rate and convert to numpy
        import torch
        import scipy.io.wavfile as wavfile
        import numpy as np
        
        audio_data = wav[0].cpu().numpy()
        sample_rate = model.sample_rate
        
        # Normalize to int16
        audio_normalized = np.int16(audio_data[0] * 32767)
        
        # Write to buffer
        buffer = io.BytesIO()
        wavfile.write(buffer, sample_rate, audio_normalized)
        buffer.seek(0)
        
        if output_format == "base64":
            audio_b64 = base64.b64encode(buffer.read()).decode("utf-8")
            return jsonify({
                "audio": audio_b64,
                "format": "wav",
                "sample_rate": sample_rate,
                "duration": duration
            })
        else:
            return send_file(
                buffer,
                mimetype="audio/wav",
                as_attachment=True,
                download_name="music.wav"
            )
    
    except Exception as e:
        logger.error(f"Generation error: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route("/generate_with_melody", methods=["POST"])
def generate_with_melody():
    """
    Generate music conditioned on a melody (audio file).
    
    Request:
        multipart/form-data with:
        - prompt: Text description
        - melody: Audio file (wav/mp3)
        - duration: Optional duration in seconds
    """
    try:
        if "prompt" not in request.form:
            return jsonify({"error": "Missing 'prompt' field"}), 400
        
        if "melody" not in request.files:
            return jsonify({"error": "Missing 'melody' file"}), 400
        
        import torch
        import torchaudio
        
        prompt = request.form["prompt"]
        duration = min(int(request.form.get("duration", 10)), 30)
        melody_file = request.files["melody"]
        
        # Load melody
        melody_buffer = io.BytesIO(melody_file.read())
        melody, sr = torchaudio.load(melody_buffer)
        
        logger.info(f"Generating with melody: '{prompt[:50]}...' ({duration}s)")
        
        # Generate music
        model = get_musicgen()
        model.set_generation_params(duration=duration)
        
        wav = model.generate_with_chroma([prompt], melody[None].expand(1, -1, -1), sr)
        
        # Convert to bytes
        import scipy.io.wavfile as wavfile
        import numpy as np
        
        audio_data = wav[0].cpu().numpy()
        audio_normalized = np.int16(audio_data[0] * 32767)
        
        buffer = io.BytesIO()
        wavfile.write(buffer, model.sample_rate, audio_normalized)
        buffer.seek(0)
        
        return send_file(
            buffer,
            mimetype="audio/wav",
            as_attachment=True,
            download_name="music_melody.wav"
        )
    
    except Exception as e:
        logger.error(f"Melody generation error: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route("/", methods=["GET"])
def index():
    """API documentation."""
    return jsonify({
        "service": "MusicGen",
        "version": "1.0.0",
        "model": os.environ.get("MUSICGEN_MODEL", "small"),
        "endpoints": {
            "/health": "GET - Health check",
            "/generate": "POST - Generate music from text prompt",
            "/generate_with_melody": "POST - Generate music with melody conditioning"
        },
        "example": {
            "prompt": "epic orchestral theme with powerful drums and soaring strings",
            "duration": 10,
            "output_format": "wav"
        },
        "models": {
            "small": "300M parameters, fastest",
            "medium": "1.5B parameters, balanced",
            "large": "3.3B parameters, highest quality"
        }
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
