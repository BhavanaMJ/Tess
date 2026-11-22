from datetime import datetime, date
from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict
from enum import Enum

class LaundryStatusEnum(str, Enum):
    CLEAN = "CLEAN"
    WORN = "WORN"
    WASHING = "WASHING"
    DRYING = "DRYING"
    STORED = "STORED"

class GarmentBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=150)
    main_category: str = Field(..., min_length=1, max_length=100)
    subcategory: Optional[str] = None
    original_image_ref: Optional[str] = None
    processed_image_ref: Optional[str] = None
    thumbnail_ref: Optional[str] = None
    primary_color: str = Field("Unknown", max_length=50)
    secondary_colors: List[str] = Field(default_factory=list)
    pattern: Optional[str] = None
    fabric_material: Optional[str] = None
    neckline: Optional[str] = None
    sleeve_length: Optional[str] = None
    fit: Optional[str] = None
    silhouette: Optional[str] = None
    garment_length: Optional[str] = None
    size: Optional[str] = None
    brand: Optional[str] = None
    purchase_date: Optional[date] = None
    purchase_price: Optional[float] = None
    occasions: List[str] = Field(default_factory=list)
    seasons: List[str] = Field(default_factory=list)
    laundry_status: Optional[str] = None
    is_favorite: bool = False
    notes: Optional[str] = None

class GarmentCreate(GarmentBase):
    id: Optional[str] = None

class GarmentUpdate(BaseModel):
    name: Optional[str] = None
    main_category: Optional[str] = None
    subcategory: Optional[str] = None
    original_image_ref: Optional[str] = None
    processed_image_ref: Optional[str] = None
    thumbnail_ref: Optional[str] = None
    primary_color: Optional[str] = None
    secondary_colors: Optional[List[str]] = None
    pattern: Optional[str] = None
    fabric_material: Optional[str] = None
    neckline: Optional[str] = None
    sleeve_length: Optional[str] = None
    fit: Optional[str] = None
    silhouette: Optional[str] = None
    garment_length: Optional[str] = None
    size: Optional[str] = None
    brand: Optional[str] = None
    purchase_date: Optional[date] = None
    purchase_price: Optional[float] = None
    occasions: Optional[List[str]] = None
    seasons: Optional[List[str]] = None
    laundry_status: Optional[str] = None
    is_favorite: Optional[bool] = None
    notes: Optional[str] = None

class GarmentResponse(GarmentBase):
    id: str
    user_id: str
    is_archived: bool = False
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class CategoryResponse(BaseModel):
    id: str
    name: str
    icon_name: Optional[str] = None
    parent_category_id: Optional[str] = None
    subcategories: List[str] = Field(default_factory=list)
    order_index: int = 0

class GarmentListResponse(BaseModel):
    items: List[GarmentResponse]
    total: int
    page: int
    limit: int

class WardrobeStatsResponse(BaseModel):
    total_garments: int
    clean_count: int
    worn_count: int
    in_laundry_count: int
    stored_count: int
    unassigned_count: int

class InitialImportRequest(BaseModel):
    garments: List[GarmentCreate]

class InitialImportResponse(BaseModel):
    imported_count: int
    skipped_count: int
    total_garments: int

