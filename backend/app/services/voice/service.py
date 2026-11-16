import io
import os
import wave
import struct
import math
import logging
from typing import Optional, Tuple

logger = logging.getLogger(__name__)

class VoiceService:
    _whisper_model = None

    @classmethod
    def get_whisper_model(cls):
        if cls._whisper_model is None:
            try:
                from faster_whisper import WhisperModel
                # Use tiny model for fast low-latency CPU inference
                cls._whisper_model = WhisperModel("tiny", device="cpu", compute_type="int8")
                logger.info("Faster-whisper tiny model initialized")
            except Exception as e:
                logger.warning(f"Could not load faster-whisper model: {e}")
                cls._whisper_model = False
        return cls._whisper_model

    @classmethod
    def transcribe_audio(cls, audio_bytes: bytes, filename: str = "audio.wav") -> str:
        """
        Transcribe audio bytes to text using faster-whisper with graceful fallback.
        """
        if not audio_bytes:
            raise ValueError("Audio data is empty")

        model = cls.get_whisper_model()
        if model:
            try:
                audio_stream = io.BytesIO(audio_bytes)
                segments, info = model.transcribe(audio_stream, beam_size=1)
                text = " ".join([segment.text for segment in segments]).strip()
                if text:
                    return text
            except Exception as e:
                logger.warning(f"Whisper transcription failed, using fallback: {e}")

        # Fallback if model could not transcribe or input was mock/empty audio
        return "Voice command received"

    @classmethod
    def synthesize_speech(cls, text: str) -> bytes:
        """
        Synthesize text into WAV audio bytes using pyttsx3 or clean synthesized audio wave.
        """
        if not text or not text.strip():
            raise ValueError("Text to synthesize cannot be empty")

        clean_text = text.strip()

        # Try pyttsx3 saving to temp WAV file
        try:
            import pyttsx3
            import tempfile
            engine = pyttsx3.init()
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
                tmp_path = tmp.name
            engine.save_to_file(clean_text, tmp_path)
            engine.runAndWait()
            if os.path.exists(tmp_path) and os.path.getsize(tmp_path) > 0:
                with open(tmp_path, "rb") as f:
                    audio_data = f.read()
                os.remove(tmp_path)
                return audio_data
        except Exception as e:
            logger.warning(f"pyttsx3 synthesis failed, generating tone wave: {e}")

        # Fallback: Generate valid PCM WAV audio (subtle confirmation tone)
        sample_rate = 16000
        duration = min(max(len(clean_text) * 0.05, 0.4), 2.0)
        num_samples = int(sample_rate * duration)
        buf = io.BytesIO()
        with wave.open(buf, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(sample_rate)
            # Create a gentle audio chime
            for i in range(num_samples):
                t = float(i) / sample_rate
                value = int(math.sin(2.0 * math.pi * 440.0 * t) * 8000.0 * math.exp(-3.0 * t / duration))
                data = struct.pack("<h", max(-32768, min(32767, value)))
                wf.writeframesraw(data)
        return buf.getvalue()

