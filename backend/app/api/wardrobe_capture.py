import os
from typing import List, Optional, Any
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from fastapi.responses import FileResponse
from supabase import Client

from app.core.auth import get_current_user, get_supabase_client, get_user_id
from app.schemas.wardrobe_capture import (
    CaptureJobResponse,
    GarmentCandidateResponse,
    GarmentCandidateUpdate,
    CaptureJobConfirmRequest,
    CaptureJobConfirmResponse,
)
from app.services.wardrobe.capture_service import WardrobeCaptureService, MEDIA_ROOT

router = APIRouter(tags=["wardrobe_capture"])

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

@router.get("/images/{user_id}/{folder}/{filename}")
def serve_capture_image(
    user_id: str,
    folder: str,
    filename: str,
    user: Any = Depends(get_current_user),
):
    """Serves private user-scoped wardrobe photographs with ownership verification."""
    current_uid = get_user_id(user)
    if current_uid != user_id:
        raise HTTPException(status_code=403, detail="Forbidden: You do not have permission to view this image.")

    file_path = os.path.join(MEDIA_ROOT, user_id, folder, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Image not found")

    media_type = "image/png" if filename.endswith(".png") else "image/jpeg"
    return FileResponse(file_path, media_type=media_type)
