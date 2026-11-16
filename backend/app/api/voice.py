from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Response, status
from pydantic import BaseModel
import base64
from typing import Optional, Any
from app.services.voice.service import VoiceService
from app.core.auth import get_current_user
from app.services.ai.factory import get_ai_provider

router = APIRouter(tags=["voice"])

def _extract_user_id(user: Any) -> str:
    if hasattr(user, "id"):
        return str(user.id)
    if isinstance(user, dict) and "id" in user:
        return str(user["id"])
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid user session")

class SynthesizeRequest(BaseModel):
    text: str

class VoiceInteractionResponse(BaseModel):
    transcript: str
    response_text: str
    audio_base64: str

@router.post("/transcribe")
async def transcribe_audio(
    file: UploadFile = File(...),
    user: Any = Depends(get_current_user)
):
    user_id = _extract_user_id(user)
    try:
        content = await file.read()
        if not content:
            raise HTTPException(status_code=400, detail="Empty audio file")
        transcript = VoiceService.transcribe_audio(content, file.filename or "audio.wav")
        return {"transcript": transcript}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/synthesize")
async def synthesize_speech(
    req: SynthesizeRequest,
    user: Any = Depends(get_current_user)
):
    user_id = _extract_user_id(user)
    try:
        audio_bytes = VoiceService.synthesize_speech(req.text)
        return Response(content=audio_bytes, media_type="audio/wav")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/interact", response_model=VoiceInteractionResponse)
async def voice_interact(
    file: UploadFile = File(...),
    user: Any = Depends(get_current_user)
):
    user_id = _extract_user_id(user)
    """
    Complete voice loop:
    1. Speech-to-text
    2. Process with TESS AI assistant
    3. Text-to-speech audio generation
    """
    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="Empty audio file")

    transcript = VoiceService.transcribe_audio(content, file.filename or "audio.wav")

    # Generate response from AI service
    ai_provider = get_ai_provider()
    try:
        ai_resp = await ai_provider.chat(
            f"You are TESS, a personal AI companion. Keep voice responses concise, conversational, and helpful. User voice command: {transcript}"
        )
        response_text = ai_resp.strip() if ai_resp else "I heard your voice command. How can I assist you further?"
    except Exception:
        response_text = f"I understood: '{transcript}'. How can I assist you further?"

    audio_bytes = VoiceService.synthesize_speech(response_text)
    audio_b64 = base64.b64encode(audio_bytes).decode("utf-8")

    return VoiceInteractionResponse(
        transcript=transcript,
        response_text=response_text,
        audio_base64=audio_b64
    )
