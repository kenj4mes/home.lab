"""
Bark TTS - Text-to-Speech API
Flask application providing REST API for Bark neural TTS.
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

# Lazy load Bark to avoid long startup
_bark_model = None

def get_bark():
    """Lazy load Bark model."""
    global _bark_model
    if _bark_model is None:
        logger.info("Loading Bark model...")
        from bark import SAMPLE_RATE, generate_audio, preload_models
        
        # Use small model if configured
        use_small = os.environ.get("BARK_SMALL_MODEL", "false").lower() == "true"
        preload_models(
            text_use_small=use_small,
            coarse_use_small=use_small,
            fine_use_small=use_small
        )
        
        _bark_model = {
            "generate_audio": generate_audio,
            "sample_rate": SAMPLE_RATE
        }
        logger.info("Bark model loaded successfully")
    return _bark_model

# Available voice presets
VOICE_PRESETS = {
    "en_speaker_0": "v2/en_speaker_0",
    "en_speaker_1": "v2/en_speaker_1",
    "en_speaker_2": "v2/en_speaker_2",
    "en_speaker_3": "v2/en_speaker_3",
    "en_speaker_4": "v2/en_speaker_4",
    "en_speaker_5": "v2/en_speaker_5",
    "en_speaker_6": "v2/en_speaker_6",
    "en_speaker_7": "v2/en_speaker_7",
    "en_speaker_8": "v2/en_speaker_8",
    "en_speaker_9": "v2/en_speaker_9",
    "zh_speaker_0": "v2/zh_speaker_0",
    "zh_speaker_1": "v2/zh_speaker_1",
    "zh_speaker_2": "v2/zh_speaker_2",
    "de_speaker_0": "v2/de_speaker_0",
    "de_speaker_1": "v2/de_speaker_1",
    "es_speaker_0": "v2/es_speaker_0",
    "es_speaker_1": "v2/es_speaker_1",
    "fr_speaker_0": "v2/fr_speaker_0",
    "fr_speaker_1": "v2/fr_speaker_1",
    "ja_speaker_0": "v2/ja_speaker_0",
    "ja_speaker_1": "v2/ja_speaker_1",
    "ko_speaker_0": "v2/ko_speaker_0",
    "ko_speaker_1": "v2/ko_speaker_1",
    "pt_speaker_0": "v2/pt_speaker_0",
    "pt_speaker_1": "v2/pt_speaker_1",
    "ru_speaker_0": "v2/ru_speaker_0",
    "ru_speaker_1": "v2/ru_speaker_1",
}

@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "healthy",
        "service": "bark-tts",
        "version": "1.0.0",
        "gpu_enabled": os.environ.get("BARK_USE_GPU", "true").lower() == "true"
    })

@app.route("/voices", methods=["GET"])
def list_voices():
    """List available voice presets."""
    return jsonify({
        "voices": VOICE_PRESETS,
        "default": "v2/en_speaker_6"
    })

@app.route("/synthesize", methods=["POST"])
def synthesize():
    """
    Synthesize speech from text.
    
    Request body:
        {
            "text": "Hello world! [laughs]",
            "voice": "v2/en_speaker_6",  # optional
            "output_format": "wav"        # optional: wav, mp3, base64
        }
    
    Returns:
        Audio file (wav/mp3) or base64-encoded audio
    """
    try:
        data = request.get_json()
        
        if not data or "text" not in data:
            return jsonify({"error": "Missing 'text' field"}), 400
        
        text = data["text"]
        voice = data.get("voice", "v2/en_speaker_6")
        output_format = data.get("output_format", "wav")
        
        # Validate voice
        if voice not in VOICE_PRESETS.values():
            # Check if short name was used
            voice = VOICE_PRESETS.get(voice, "v2/en_speaker_6")
        
        logger.info(f"Synthesizing: '{text[:50]}...' with voice {voice}")
        
        # Generate audio
        bark = get_bark()
        audio_array = bark["generate_audio"](text, history_prompt=voice)
        
        # Convert to bytes
        import scipy.io.wavfile as wav
        import numpy as np
        
        # Normalize audio
        audio_normalized = np.int16(audio_array * 32767)
        
        # Write to buffer
        buffer = io.BytesIO()
        wav.write(buffer, bark["sample_rate"], audio_normalized)
        buffer.seek(0)
        
        if output_format == "base64":
            audio_b64 = base64.b64encode(buffer.read()).decode("utf-8")
            return jsonify({
                "audio": audio_b64,
                "format": "wav",
                "sample_rate": bark["sample_rate"]
            })
        else:
            return send_file(
                buffer,
                mimetype="audio/wav",
                as_attachment=True,
                download_name="speech.wav"
            )
    
    except Exception as e:
        logger.error(f"Synthesis error: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route("/", methods=["GET"])
def index():
    """API documentation."""
    return jsonify({
        "service": "Bark TTS",
        "version": "1.0.0",
        "endpoints": {
            "/health": "GET - Health check",
            "/voices": "GET - List available voice presets",
            "/synthesize": "POST - Synthesize speech from text"
        },
        "example": {
            "text": "Hello! [laughs] How are you today?",
            "voice": "v2/en_speaker_6",
            "output_format": "wav"
        },
        "special_tokens": [
            "[laughs]", "[sighs]", "[music]", "[clears throat]",
            "[gasps]", "♪", "...", "—"
        ]
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
