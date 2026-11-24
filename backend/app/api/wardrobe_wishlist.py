import os
import logging
from typing import List, Optional, Any, Dict
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from fastapi.responses import FileResponse
from supabase import Client

from app.core.auth import get_current_user, get_supabase_client, get_user_id
from app.schemas.wishlist import (
    WishlistItemCreate,
    WishlistItemUpdate,
    WishlistStatusUpdate,
    WishlistConvertToWardrobeRequest,
    WishlistItemResponse,
    WishlistSummaryResponse,
    WardrobeGapItem,
    GarmentMatchItem,
    GarmentMatchRequest,
    PurchaseAssessmentResponse,
)
from app.services.wardrobe.wishlist_service import (
    WishlistService,
    WardrobeGapAnalysisService,
    PurchaseIntelligenceService,
    MEDIA_ROOT,
)

logger = logging.getLogger(__name__)

wishlist_router = APIRouter(prefix="/api/v1/wardrobe/wishlist", tags=["Wardrobe Wishlist"])
shopping_intel_router = APIRouter(prefix="/api/v1/wardrobe/shopping-intelligence", tags=["Wardrobe Shopping Intelligence"])


def get_wishlist_service(
    supabase: Client = Depends(get_supabase_client),
    user: Any = Depends(get_current_user),
) -> WishlistService:
    user_id = get_user_id(user)
    return WishlistService(supabase, user_id)


def get_gap_service(
    wishlist_service: WishlistService = Depends(get_wishlist_service),
) -> WardrobeGapAnalysisService:
    return WardrobeGapAnalysisService(wishlist_service)


def get_intelligence_service(
    wishlist_service: WishlistService = Depends(get_wishlist_service),
) -> PurchaseIntelligenceService:
    return PurchaseIntelligenceService(wishlist_service)


# -----------------------------------------------------------------------------
# Wishlist CRUD Endpoints
# -----------------------------------------------------------------------------

@wishlist_router.get("", response_model=List[WishlistItemResponse])
def get_wishlist_items(
    status: Optional[str] = Query(None, description="Filter by status (CONSIDERING, SHORTLISTED, PURCHASED, NOT_INTERESTED)"),
    priority: Optional[str] = Query(None, description="Filter by priority (HIGH, MEDIUM, LOW)"),
    category: Optional[str] = Query(None, description="Filter by category"),
    sort_by: str = Query("created_at", description="Sort by field: created_at, expected_price, priority"),
    sort_order: str = Query("desc", description="asc or desc"),
    service: WishlistService = Depends(get_wishlist_service),
):
    """Retrieves all wishlist items for the authenticated user with optional filtering and sorting."""
    return service.get_items(
        status=status,
        priority=priority,
        category=category,
        sort_by=sort_by,
        sort_order=sort_order,
    )


@wishlist_router.post("", response_model=WishlistItemResponse, status_code=201)
def create_wishlist_item(
    item: WishlistItemCreate,
    service: WishlistService = Depends(get_wishlist_service),
):
    """Creates a new wishlist item."""
    try:
        return service.create_item(item)
    except Exception as e:
        logger.error(f"[WishlistAPI] Create item error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@wishlist_router.get("/summary", response_model=WishlistSummaryResponse)
def get_wishlist_summary(
    service: WishlistService = Depends(get_wishlist_service),
):
    """Returns aggregated summary metrics across the user's wishlist."""
    return service.get_summary()


@wishlist_router.get("/{item_id}", response_model=WishlistItemResponse)
def get_wishlist_item(
    item_id: str,
    service: WishlistService = Depends(get_wishlist_service),
):
    """Retrieves a single wishlist item by ID."""
    item = service.get_item(item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Wishlist item not found")
    return item


@wishlist_router.put("/{item_id}", response_model=WishlistItemResponse)
def update_wishlist_item(
    item_id: str,
    update_data: WishlistItemUpdate,
    service: WishlistService = Depends(get_wishlist_service),
):
    """Updates fields of an existing wishlist item."""
    updated = service.update_item(item_id, update_data)
    if not updated:
        raise HTTPException(status_code=404, detail="Wishlist item not found")
    return updated


@wishlist_router.delete("/{item_id}", status_code=204)
def delete_wishlist_item(
    item_id: str,
    service: WishlistService = Depends(get_wishlist_service),
):
    """Deletes a wishlist item by ID."""
    success = service.delete_item(item_id)
    if not success:
        raise HTTPException(status_code=404, detail="Wishlist item not found")
    return None


@wishlist_router.patch("/{item_id}/status", response_model=WishlistItemResponse)
def update_wishlist_status(
    item_id: str,
    status_data: WishlistStatusUpdate,
    service: WishlistService = Depends(get_wishlist_service),
):
    """Updates the status of a wishlist item (e.g. marking as Purchased, Shortlisted, etc.)."""
    updated = service.update_status(item_id, status_data)
    if not updated:
        raise HTTPException(status_code=404, detail="Wishlist item not found")
    return updated


@wishlist_router.post("/{item_id}/convert-to-wardrobe", response_model=Dict[str, Any])
def convert_wishlist_item_to_wardrobe(
    item_id: str,
    conversion_data: WishlistConvertToWardrobeRequest = WishlistConvertToWardrobeRequest(),
    service: WishlistService = Depends(get_wishlist_service),
):
    """
    Idempotently converts a purchased wishlist item into an active wardrobe garment (CLO-xxx),
    preserving expected price vs actual purchase price, without forcing clean laundry state.
    """
    try:
        wishlist_item, garment = service.convert_to_wardrobe(item_id, conversion_data)
        return {
            "wishlist_item": wishlist_item.dict(),
            "garment": garment,
            "message": "Successfully converted wishlist item to wardrobe garment",
        }
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"[WishlistAPI] Conversion error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@wishlist_router.post("/upload-image")
async def upload_wishlist_reference_image(
    file: UploadFile = File(...),
    service: WishlistService = Depends(get_wishlist_service),
):
    """Uploads an inspiration or reference photograph for a wishlist item."""
    try:
        data = await file.read()
        if not data:
            raise HTTPException(status_code=400, detail="Empty file uploaded")
        image_url = service.save_reference_image(data, file.filename or "photo.jpg")
        return {"image_url": image_url}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"[WishlistAPI] Image upload error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@wishlist_router.get("/images/{user_id}/{filename}")
def serve_wishlist_image(
    user_id: str,
    filename: str,
    user: Any = Depends(get_current_user),
):
    """Serves private user-scoped wishlist reference photographs."""
    current_uid = get_user_id(user)
    if current_uid != user_id:
        raise HTTPException(status_code=403, detail="Forbidden: You do not have permission to view this image.")

    file_path = os.path.join(MEDIA_ROOT, user_id, "wishlist", filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Image not found")

    media_type = "image/png" if filename.endswith(".png") else "image/jpeg"
    return FileResponse(file_path, media_type=media_type)


# -----------------------------------------------------------------------------
# Shopping Intelligence & Gap Analysis Endpoints
# -----------------------------------------------------------------------------

@shopping_intel_router.get("/gaps", response_model=List[WardrobeGapItem])
def get_wardrobe_gaps(
    service: WardrobeGapAnalysisService = Depends(get_gap_service),
):
    """
    Analyzes current wardrobe inventory, category ratios, and color palettes
    to identify authentic wardrobe gaps and potential combination opportunities.
    """
    return service.analyze_wardrobe_gaps()


@shopping_intel_router.post("/match", response_model=List[GarmentMatchItem])
def match_existing_garments(
    match_req: GarmentMatchRequest,
    service: PurchaseIntelligenceService = Depends(get_intelligence_service),
):
    """
    Checks whether the user already owns similar items matching a prospective purchase's
    category, subcategory, or color palette to prevent redundant purchases.
    """
    return service.find_matching_garments(
        category=match_req.category,
        subcategory=match_req.subcategory,
        desired_colour=match_req.desired_colour,
        limit=match_req.limit,
    )


@shopping_intel_router.get("/assessment/{item_id}", response_model=PurchaseAssessmentResponse)
def get_purchase_assessment(
    item_id: str,
    service: PurchaseIntelligenceService = Depends(get_intelligence_service),
):
    """
    Computes an explainable purchase decision assessment for a specific wishlist item,
    evaluating existing similar garments, category gaps, color harmony, and styling versatility.
    """
    try:
        return service.assess_wishlist_item(item_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"[ShoppingIntelAPI] Assessment error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

