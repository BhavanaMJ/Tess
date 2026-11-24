import os
from typing import Any, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from supabase import Client

from app.core.auth import get_current_user, get_supabase_client, get_user_id
from app.schemas.wardrobe_import import (
    MetadataValidationRequest,
    MetadataValidationResponse,
    GarmentImportRegisterRequest,
    GarmentImportRegisterResponse,
)
from app.services.wardrobe.import_service import WardrobeImportService
from app.services.wardrobe.service import WardrobeService

router = APIRouter(prefix="/import", tags=["wardrobe_import"])

def get_import_service(
    user: Any = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client),
) -> WardrobeImportService:
    user_id = get_user_id(user)
    return WardrobeImportService(supabase, user_id)

def get_wardrobe_service(
    user: Any = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client),
) -> WardrobeService:
    user_id = get_user_id(user)
    return WardrobeService(supabase, user_id)

@router.post("/validate-metadata", response_model=MetadataValidationResponse)
def validate_garment_metadata(
    request: MetadataValidationRequest,
    service: WardrobeImportService = Depends(get_import_service),
):
    """
    Validates a raw JSON string or dictionary payload against TESS Garment
    Metadata Schema Version 1.1, returning field-level errors and normalized metadata.
    """
    return service.validate_metadata(
        raw_json=request.raw_json,
        metadata_dict=request.metadata,
    )

@router.post("/upload-image")
async def upload_import_image(
    image_type: str = Form("catalogue"),
    image: UploadFile = File(...),
    service: WardrobeImportService = Depends(get_import_service),
):
    """
    Uploads an original photograph or ChatGPT-generated catalogue image.
    Validates format (JPG, JPEG, PNG, WEBP) and size (<= 15MB) and stores
    in the user's private media folder.
    """
    try:
        content = await image.read()
        ref_url = service.save_import_image(
            image_type=image_type,
            file_bytes=content,
            filename=image.filename or "image.jpg",
        )
        return {
            "success": True,
            "image_type": image_type,
            "image_ref": ref_url,
            "filename": image.filename,
            "bytes_received": len(content),
        }
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Image upload failed: {str(e)}")

@router.post("/register", response_model=GarmentImportRegisterResponse)
def register_imported_garment(
    request: GarmentImportRegisterRequest,
    import_service: WardrobeImportService = Depends(get_import_service),
    wardrobe_service: WardrobeService = Depends(get_wardrobe_service),
):
    """
    Validates and registers an imported garment into the user's wardrobe:
    - Atomically assigns sequential unique CLO-xxx ID
    - Persists core visual attributes in relational columns
    - Persists full Schema 1.1 tree in metadata_payload
    - Enforces laundry_status = null initially
    """
    try:
        return import_service.register_garment(
            request=request,
            wardrobe_service=wardrobe_service,
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Registration failed: {str(e)}")
