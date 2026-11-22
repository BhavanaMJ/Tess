from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Optional
import logging

from app.core.auth import get_current_user, get_supabase_client, get_user_id
from app.services.wardrobe.service import WardrobeService
from app.services.wardrobe.laundry_service import LaundryService
from app.schemas.laundry import (
    LaundryStatsResponse,
    GarmentLaundryStatusUpdate,
    LaundryHistoryEntryResponse,
    LaundryBatchCreate,
    LaundryBatchResponse,
    LaundryBatchStatusUpdate,
    LaundryBatchItemAdd,
    BatchTransitionResponse,
)
from app.schemas.wardrobe import GarmentResponse, GarmentListResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/wardrobe", tags=["wardrobe-laundry"])

def get_laundry_service(
    user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client),
) -> LaundryService:
    uid = get_user_id(user)
    wardrobe_service = WardrobeService(supabase, uid)
    return LaundryService(supabase, uid, wardrobe_service=wardrobe_service)

# 1. LAUNDRY STATS
@router.get("/laundry/stats", response_model=LaundryStatsResponse)
async def get_laundry_stats(
    laundry_service: LaundryService = Depends(get_laundry_service),
):
    """Retrieve comprehensive laundry operational metrics across all 5 statuses + unassigned."""
    try:
        return laundry_service.get_laundry_stats()
    except Exception as e:
        logger.error(f"Error fetching laundry stats: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve laundry stats.")

# 2. ITEMS FILTERED BY LAUNDRY STATUS
@router.get("/laundry/items", response_model=GarmentListResponse)
async def get_laundry_items(
    laundry_status: Optional[str] = Query(None, description="CLEAN, WORN, WASHING, DRYING, STORED, or UNASSIGNED"),
    category: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    sort_by: str = Query("created_at"),
    sort_order: str = Query("desc"),
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=100),
    laundry_service: LaundryService = Depends(get_laundry_service),
):
    """Retrieve wardrobe garments filtered by specific laundry status (including explicit UNASSIGNED)."""
    try:
        ws = laundry_service.wardrobe_service
        # Retrieve all items and filter appropriately
        all_items = ws.get_items(category=category, search=search, sort_by=sort_by, sort_order=sort_order, limit=1000).items

        if laundry_status:
            status_norm = laundry_status.upper()
            if status_norm == "UNASSIGNED":
                filtered = [i for i in all_items if i.laundry_status is None]
            else:
                filtered = [i for i in all_items if i.laundry_status == status_norm]
        else:
            filtered = all_items

        start = (page - 1) * limit
        end = start + limit
        paginated = filtered[start:end]

        return GarmentListResponse(
            items=paginated,
            total=len(filtered),
            page=page,
            limit=limit,
        )
    except Exception as e:
        logger.error(f"Error fetching laundry items: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve laundry garments.")

# 3. INDIVIDUAL GARMENT LAUNDRY STATUS UPDATE
@router.patch("/items/{garment_id}/laundry-status", response_model=GarmentResponse)
async def update_garment_laundry_status(
    garment_id: str,
    update_data: GarmentLaundryStatusUpdate,
    laundry_service: LaundryService = Depends(get_laundry_service),
):
    """Update individual garment laundry status, increment wear/wash counts appropriately, and log history."""
    try:
        return laundry_service.update_garment_laundry_status(garment_id, update_data)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Error updating garment laundry status: {e}")
        raise HTTPException(status_code=500, detail="Failed to update garment laundry status.")

# 4. GARMENT LAUNDRY HISTORY
@router.get("/items/{garment_id}/laundry-history", response_model=List[LaundryHistoryEntryResponse])
async def get_garment_laundry_history(
    garment_id: str,
    laundry_service: LaundryService = Depends(get_laundry_service),
):
    """Retrieve chronologically ordered lifecycle history events for a specific garment."""
    try:
        # Verify garment exists and belongs to user
        garment = laundry_service.wardrobe_service.get_item(garment_id)
        if not garment:
            raise HTTPException(status_code=404, detail=f"Garment {garment_id} not found.")
        return laundry_service.get_garment_laundry_history(garment_id)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching garment laundry history: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve laundry history.")

# 5. LAUNDRY BATCH MANAGEMENT
@router.post("/laundry/batches", response_model=LaundryBatchResponse, status_code=status.HTTP_201_CREATED)
async def create_laundry_batch(
    batch_data: LaundryBatchCreate,
    laundry_service: LaundryService = Depends(get_laundry_service),
):
    """Create a new multi-garment laundry batch, associates garments, and transitions them into washing."""
    try:
        return laundry_service.create_batch(batch_data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error creating laundry batch: {e}")
        raise HTTPException(status_code=500, detail="Failed to create laundry batch.")

@router.get("/laundry/batches", response_model=List[LaundryBatchResponse])
async def list_laundry_batches(
    status: Optional[str] = Query(None, description="CREATED, WASHING, DRYING, COMPLETED, CANCELLED"),
    laundry_service: LaundryService = Depends(get_laundry_service),
):
    """Retrieve all laundry batches for authenticated user."""
    try:
        return laundry_service.get_batches(status=status)
    except Exception as e:
        logger.error(f"Error listing laundry batches: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve laundry batches.")

@router.get("/laundry/batches/{batch_id}", response_model=LaundryBatchResponse)
async def get_laundry_batch(
    batch_id: str,
    laundry_service: LaundryService = Depends(get_laundry_service),
):
    """Retrieve details of a specific laundry batch including member garments and individual statuses."""
    batch = laundry_service.get_batch(batch_id)
    if not batch:
        raise HTTPException(status_code=404, detail=f"Laundry batch {batch_id} not found.")
    return batch

@router.patch("/laundry/batches/{batch_id}/status", response_model=BatchTransitionResponse)
async def advance_laundry_batch_status(
    batch_id: str,
    update_data: LaundryBatchStatusUpdate,
    laundry_service: LaundryService = Depends(get_laundry_service),
):
    """Advance batch lifecycle (e.g. WASHING -> DRYING -> COMPLETED) preserving individual overrides."""
    try:
        return laundry_service.advance_batch_status(batch_id, update_data)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Error advancing batch status: {e}")
        raise HTTPException(status_code=500, detail="Failed to advance batch status.")

@router.post("/laundry/batches/{batch_id}/items", response_model=LaundryBatchResponse)
async def add_items_to_batch(
    batch_id: str,
    item_data: LaundryBatchItemAdd,
    laundry_service: LaundryService = Depends(get_laundry_service),
):
    """Add garments to an existing active laundry batch."""
    try:
        return laundry_service.add_items_to_batch(batch_id, item_data.garment_ids)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Error adding items to batch: {e}")
        raise HTTPException(status_code=500, detail="Failed to add items to batch.")

@router.delete("/laundry/batches/{batch_id}/items/{garment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_item_from_batch(
    batch_id: str,
    garment_id: str,
    laundry_service: LaundryService = Depends(get_laundry_service),
):
    """Remove a garment from an active batch while preserving all laundry history."""
    removed = laundry_service.remove_item_from_batch(batch_id, garment_id)
    if not removed:
        raise HTTPException(status_code=404, detail=f"Garment {garment_id} not active in batch {batch_id}.")
    return None
