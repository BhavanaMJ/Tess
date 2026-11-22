from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import Optional, List, Union
from supabase import Client

from app.core.auth import get_current_user, get_supabase_client, get_user_id
from app.services.wardrobe.service import WardrobeService
from app.schemas.wardrobe import (
    GarmentCreate,
    GarmentUpdate,
    GarmentResponse,
    GarmentListResponse,
    CategoryResponse,
    WardrobeStatsResponse,
    InitialImportRequest,
    InitialImportResponse,
)

router = APIRouter()

def get_wardrobe_service(
    user: dict = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
) -> WardrobeService:
    return WardrobeService(supabase=supabase, user_id=get_user_id(user))

@router.get("/items", response_model=List[GarmentResponse])
def get_wardrobe_items(
    category: Optional[str] = Query(None, description="Filter by main category"),
    laundry_status: Optional[str] = Query(None, description="Filter by laundry operational status"),
    is_favorite: Optional[bool] = Query(None, description="Filter by favorites only"),
    search: Optional[str] = Query(None, description="Search term across name, color, brand, ID"),
    sort_by: str = Query("created_at", description="Sort by field: created_at, updated_at, name"),
    sort_order: str = Query("desc", description="Sort direction: asc, desc"),
    page: int = Query(1, ge=1),
    limit: int = Query(100, ge=1, le=500),
    service: WardrobeService = Depends(get_wardrobe_service)
):
    """Retrieve all user wardrobe items matching filters."""
    result = service.get_items(
        category=category,
        laundry_status=laundry_status,
        is_favorite=is_favorite,
        search=search,
        sort_by=sort_by,
        sort_order=sort_order,
        page=page,
        limit=limit,
    )
    return result.items

@router.get("/items/paged", response_model=GarmentListResponse)
def get_wardrobe_items_paged(
    category: Optional[str] = None,
    laundry_status: Optional[str] = None,
    is_favorite: Optional[bool] = None,
    search: Optional[str] = None,
    sort_by: str = "created_at",
    sort_order: str = "desc",
    page: int = 1,
    limit: int = 50,
    service: WardrobeService = Depends(get_wardrobe_service)
):
    """Retrieve paginated garments with total count."""
    return service.get_items(
        category=category,
        laundry_status=laundry_status,
        is_favorite=is_favorite,
        search=search,
        sort_by=sort_by,
        sort_order=sort_order,
        page=page,
        limit=limit,
    )

@router.post("/items", response_model=GarmentResponse, status_code=status.HTTP_201_CREATED)
def create_wardrobe_item(
    item: GarmentCreate,
    service: WardrobeService = Depends(get_wardrobe_service)
):
    """Create a new user garment with validation and server-side user scoping."""
    if not item.name or not item.name.strip():
        raise HTTPException(status_code=400, detail="Garment name is required")
    if not item.main_category or not item.main_category.strip():
        raise HTTPException(status_code=400, detail="Main category is required")

    return service.create_item(item)

@router.get("/items/{garment_id}", response_model=GarmentResponse)
def get_wardrobe_item(
    garment_id: str,
    service: WardrobeService = Depends(get_wardrobe_service)
):
    """Retrieve a single garment by unique ID."""
    item = service.get_item(garment_id)
    if not item:
        raise HTTPException(status_code=404, detail=f"Garment '{garment_id}' not found")
    return item

@router.patch("/items/{garment_id}", response_model=GarmentResponse)
def patch_wardrobe_item(
    garment_id: str,
    update_data: GarmentUpdate,
    service: WardrobeService = Depends(get_wardrobe_service)
):
    """Partial update of garment attributes."""
    updated = service.update_item(garment_id, update_data)
    if not updated:
        raise HTTPException(status_code=404, detail=f"Garment '{garment_id}' not found")
    return updated

@router.put("/items/{garment_id}", response_model=GarmentResponse)
def put_wardrobe_item(
    garment_id: str,
    update_data: GarmentUpdate,
    service: WardrobeService = Depends(get_wardrobe_service)
):
    """Full/Partial update of garment attributes."""
    updated = service.update_item(garment_id, update_data)
    if not updated:
        raise HTTPException(status_code=404, detail=f"Garment '{garment_id}' not found")
    return updated

@router.delete("/items/{garment_id}")
def delete_wardrobe_item(
    garment_id: str,
    hard_delete: bool = Query(False, description="Set true for permanent purge, false for safe archival"),
    service: WardrobeService = Depends(get_wardrobe_service)
):
    """Delete or safely archive a garment."""
    success = service.delete_item(garment_id, hard_delete=hard_delete)
    if not success:
        raise HTTPException(status_code=404, detail=f"Garment '{garment_id}' not found")
    return {"status": "success", "id": garment_id, "archived": not hard_delete}

@router.get("/categories", response_model=List[CategoryResponse])
def get_wardrobe_categories(
    service: WardrobeService = Depends(get_wardrobe_service)
):
    """Retrieve wardrobe categories with standard and custom options."""
    return service.get_categories()

@router.get("/stats", response_model=WardrobeStatsResponse)
def get_wardrobe_stats(
    service: WardrobeService = Depends(get_wardrobe_service)
):
    """Retrieve real-time wardrobe operational telemetry."""
    return service.get_stats()

@router.post("/import-initial", response_model=InitialImportResponse)
def import_initial_inventory(
    req: InitialImportRequest,
    service: WardrobeService = Depends(get_wardrobe_service)
):
    """Import initial garment inventory batch (e.g. initial 18 garments)."""
    return service.import_initial_inventory(req.garments)

