from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Optional
import logging

from app.core.auth import get_current_user, get_supabase_client, get_user_id
from app.services.wardrobe.service import WardrobeService
from app.services.wardrobe.laundry_service import LaundryService
from app.services.wardrobe.outfit_service import OutfitService
from app.schemas.outfit import (
    OutfitCreateRequest,
    OutfitUpdateRequest,
    OutfitResponse,
    OutfitListResponse,
    OutfitGenerateRequest,
    GuidedStylingRequest,
    OutfitValidateRequest,
    OutfitValidateResponse,
    OutfitWearRequest,
    OutfitWearResponse,
    OutfitRecommendationsResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/wardrobe/outfits", tags=["wardrobe-outfits"])

def get_outfit_service(
    user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client),
) -> OutfitService:
    uid = get_user_id(user)
    wardrobe_service = WardrobeService(supabase, uid)
    laundry_service = LaundryService(supabase, uid, wardrobe_service=wardrobe_service)
    return OutfitService(
        supabase=supabase,
        user_id=uid,
        wardrobe_service=wardrobe_service,
        laundry_service=laundry_service,
    )

# 1. GENERATE RECOMMENDATIONS (MODE A: AUTOMATIC)
@router.post("/generate", response_model=OutfitRecommendationsResponse)
async def generate_recommendations(
    req: OutfitGenerateRequest,
    service: OutfitService = Depends(get_outfit_service),
):
    """Automatically generates diverse outfit combinations based on eligible wardrobe items."""
    try:
        return service.generate_recommendations(req)
    except Exception as e:
        logger.error(f"[OutfitRouter] Error generating recommendations: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate outfit recommendations.")

# 2. GUIDED STYLING (MODE B)
@router.post("/guided", response_model=OutfitRecommendationsResponse)
async def generate_guided_styling(
    req: GuidedStylingRequest,
    service: OutfitService = Depends(get_outfit_service),
):
    """Styles around a chosen seed garment, suggesting complementary eligible items."""
    try:
        return service.generate_guided_styling(req)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"[OutfitRouter] Error in guided styling: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate guided outfits.")

# 3. VALIDATE MANUAL SELECTION (MODE C)
@router.post("/validate", response_model=OutfitValidateResponse)
async def validate_outfit_selection(
    req: OutfitValidateRequest,
    service: OutfitService = Depends(get_outfit_service),
):
    """Validates user-selected garments, confirming ownership, presence, and laundry availability."""
    try:
        return service.validate_outfit_selection(req)
    except Exception as e:
        logger.error(f"[OutfitRouter] Error validating outfit: {e}")
        raise HTTPException(status_code=500, detail="Failed to validate outfit selection.")

# 4. LIST SAVED OUTFITS
@router.get("", response_model=OutfitListResponse)
async def get_outfits(
    occasion: Optional[str] = Query(None),
    favourite_only: bool = Query(False),
    search: Optional[str] = Query(None),
    service: OutfitService = Depends(get_outfit_service),
):
    """List saved user outfits with optional occasion, favourite and keyword filters."""
    try:
        return service.get_outfits(
            occasion=occasion,
            favourite_only=favourite_only,
            search=search,
        )
    except Exception as e:
        logger.error(f"[OutfitRouter] Error listing outfits: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve outfits.")

# 5. CREATE / SAVE OUTFIT
@router.post("", response_model=OutfitResponse, status_code=status.HTTP_201_CREATED)
async def create_outfit(
    req: OutfitCreateRequest,
    service: OutfitService = Depends(get_outfit_service),
):
    """Save an outfit combination to the user's permanent digital wardrobe lookbook."""
    try:
        return service.create_outfit(req)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"[OutfitRouter] Error creating outfit: {e}")
        raise HTTPException(status_code=500, detail="Failed to save outfit.")

# 6. GET SINGLE OUTFIT
@router.get("/{outfit_id}", response_model=OutfitResponse)
async def get_outfit(
    outfit_id: str,
    service: OutfitService = Depends(get_outfit_service),
):
    """Retrieve details of a saved outfit, including current live garment laundry statuses."""
    outfit = service.get_outfit(outfit_id)
    if not outfit:
        raise HTTPException(status_code=404, detail="Outfit not found.")
    return outfit

# 7. UPDATE OUTFIT
@router.put("/{outfit_id}", response_model=OutfitResponse)
async def update_outfit(
    outfit_id: str,
    req: OutfitUpdateRequest,
    service: OutfitService = Depends(get_outfit_service),
):
    """Update outfit name, notes, occasion, favourite status, or constituent garments."""
    try:
        return service.update_outfit(outfit_id, req)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"[OutfitRouter] Error updating outfit: {e}")
        raise HTTPException(status_code=500, detail="Failed to update outfit.")

# 8. DELETE OUTFIT
@router.delete("/{outfit_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_outfit(
    outfit_id: str,
    service: OutfitService = Depends(get_outfit_service),
):
    """Delete or archive an outfit."""
    try:
        service.delete_outfit(outfit_id)
        return None
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    except Exception as e:
        logger.error(f"[OutfitRouter] Error deleting outfit: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete outfit.")

# 9. WEAR THIS OUTFIT (PHASE 4 LAUNDRY INTEGRATION)
@router.post("/{outfit_id}/wear", response_model=OutfitWearResponse)
async def wear_outfit(
    outfit_id: str,
    req: OutfitWearRequest = OutfitWearRequest(),
    service: OutfitService = Depends(get_outfit_service),
):
    """Record wearing of an outfit, updating garment statuses to WORN, incrementing wear_counts, and logging laundry history."""
    try:
        return service.wear_outfit(outfit_id, req)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"[OutfitRouter] Error recording wear: {e}")
        raise HTTPException(status_code=500, detail="Failed to record outfit wear.")

