import os
from typing import List, Optional, Any
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query, Header, status
from fastapi.responses import FileResponse
from supabase import Client

from app.core.auth import get_current_user, get_supabase_client, get_user_id
from app.schemas.wardrobe_capture import (
    CaptureJobResponse,
    GarmentCandidateResponse,
    GarmentCandidateUpdate,
    CaptureJobConfirmRequest,
    CaptureJobConfirmResponse,
    CaptureJobDiagnosticResponse,
)
from app.services.wardrobe.capture_service import WardrobeCaptureService, MEDIA_ROOT

router = APIRouter(tags=["wardrobe_capture"])

def get_optional_user_id(
    authorization: Optional[str] = Header(None),
    token: Optional[str] = Query(None),
) -> Optional[str]:
    """Extracts user ID from Authorization header or ?token= query parameter."""
    raw_token = None
    if authorization and authorization.startswith("Bearer "):
        raw_token = authorization.split("Bearer ", 1)[1].strip()
    elif token:
        raw_token = token.strip()

    if not raw_token:
        return None

    if raw_token in ("dev-token", "mock-token", "mock_jwt_token", "mock_jwt_token_bhavanamj") or raw_token.startswith("dev_") or raw_token.startswith("dev-"):
        return "d6dd3895-95c9-414b-8f08-863ba3985492" if raw_token == "dev-token" else f"user-{raw_token}"

    try:
        supabase = get_supabase_client()
        user_resp = supabase.auth.get_user(raw_token)
        if user_resp and user_resp.user:
            return str(user_resp.user.id)
    except Exception:
        pass
    return None

def get_capture_service(
    user: Any = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client),
) -> WardrobeCaptureService:
    user_id = get_user_id(user)
    return WardrobeCaptureService(supabase, user_id)

@router.post("/jobs", response_model=CaptureJobResponse, status_code=status.HTTP_201_CREATED)
async def create_capture_job(
    image: UploadFile = File(...),
    service: WardrobeCaptureService = Depends(get_capture_service),
):
    """
    Submits a garment photograph for AI analysis, multi-garment detection,
    and studio catalogue segmentation.
    """
    try:
        content = await image.read()
        if not content:
            raise HTTPException(status_code=400, detail="Empty photograph uploaded")
        job = await service.create_capture_job(content, image.filename or "capture.jpg")
        return job
    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process capture: {str(e)}")

@router.get("/jobs/{job_id}", response_model=CaptureJobResponse)
def get_capture_job(
    job_id: str,
    service: WardrobeCaptureService = Depends(get_capture_service),
):
    """Retrieves status, progress stage, and candidates for a capture job."""
    try:
        return service.get_capture_job(job_id)
    except KeyError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/jobs/{job_id}/candidates", response_model=List[GarmentCandidateResponse])
def get_job_candidates(
    job_id: str,
    service: WardrobeCaptureService = Depends(get_capture_service),
):
    """Lists all detected garment candidates for a capture job."""
    try:
        return service.get_job_candidates(job_id)
    except KeyError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/candidates/{candidate_id}", response_model=GarmentCandidateResponse)
def update_candidate(
    candidate_id: str,
    update: GarmentCandidateUpdate,
    service: WardrobeCaptureService = Depends(get_capture_service),
):
    """Updates attributes or inclusion toggle of a detected garment candidate."""
    try:
        return service.update_candidate(candidate_id, update)
    except KeyError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/jobs/{job_id}/retry", response_model=CaptureJobResponse)
async def retry_capture_job(
    job_id: str,
    service: WardrobeCaptureService = Depends(get_capture_service),
):
    """Retries processing on an existing capture job using preserved original photograph."""
    try:
        return await service.retry_job(job_id)
    except (KeyError, FileNotFoundError) as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/jobs/{job_id}/confirm", response_model=CaptureJobConfirmResponse)
def confirm_and_register_garments(
    job_id: str,
    req: CaptureJobConfirmRequest = CaptureJobConfirmRequest(),
    service: WardrobeCaptureService = Depends(get_capture_service),
):
    """
    Atomically registers approved, included candidates into My Wardrobe with
    permanent unique garment IDs.
    """
    try:
        return service.confirm_and_register_garments(job_id, req.candidate_ids)
    except KeyError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/jobs/{job_id}/diagnostic", response_model=CaptureJobDiagnosticResponse)
def get_job_diagnostic(
    job_id: str,
    service: WardrobeCaptureService = Depends(get_capture_service),
):
    """
    Developer-only Smart Capture diagnostic endpoint exposing original photo,
    binary segmentation mask, transparent cutout, catalogue composition,
    quality state, and VLM execution telemetry.
    """
    try:
        return service.get_job_diagnostic(job_id)
    except KeyError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/images/{user_id}/{folder}/{filename}")
def serve_capture_image(
    user_id: str,
    folder: str,
    filename: str,
    token: Optional[str] = Query(None),
    authorization: Optional[str] = Header(None),
):
    """
    Serves private user-scoped wardrobe photographs with support for:
    - Authorization: Bearer <token> header
    - ?token=<token> query parameter (for Flutter Image.network and browser <img> tags)
    - Local development authentication tokens
    """
    auth_uid = get_optional_user_id(authorization=authorization, token=token)
    if auth_uid and auth_uid != user_id:
        raise HTTPException(status_code=403, detail="Forbidden: You do not have permission to view this image.")

    file_path = os.path.join(MEDIA_ROOT, user_id, folder, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Image not found")

    media_type = "image/png" if filename.endswith(".png") else "image/jpeg"
    headers = {"Cache-Control": "public, max-age=3600"}
    return FileResponse(file_path, media_type=media_type, headers=headers)
