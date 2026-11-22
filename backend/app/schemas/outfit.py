from datetime import datetime
from enum import Enum
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class OutfitSourceEnum(str, Enum):
    AUTOMATIC = "AUTOMATIC"
    GUIDED = "GUIDED"
    MANUAL = "MANUAL"

class OutfitItemSummary(BaseModel):
    garment_id: str
    name: str
    main_category: str
    primary_color: str
    secondary_colors: List[str] = []
    pattern: Optional[str] = None
    original_image_ref: Optional[str] = None
    processed_image_ref: Optional[str] = None
    thumbnail_ref: Optional[str] = None
    laundry_status: Optional[str] = None
    is_eligible: bool = True
    unavailability_reason: Optional[str] = None

class OutfitCreateRequest(BaseModel):
    name: str = Field(..., max_length=140)
    description: Optional[str] = None
    occasion: str = Field("Casual", max_length=60)
    notes: Optional[str] = None
    is_favourite: bool = False
    creation_source: OutfitSourceEnum = OutfitSourceEnum.MANUAL
    styling_explanation: Optional[str] = None
    garment_ids: List[str] = Field(..., min_length=1)

class OutfitUpdateRequest(BaseModel):
    name: Optional[str] = Field(None, max_length=140)
    description: Optional[str] = None
    occasion: Optional[str] = Field(None, max_length=60)
    notes: Optional[str] = None
    is_favourite: Optional[bool] = None
    styling_explanation: Optional[str] = None
    garment_ids: Optional[List[str]] = None

class OutfitResponse(BaseModel):
    id: str
    user_id: str
    name: str
    description: Optional[str] = None
    occasion: str
    notes: Optional[str] = None
    is_favourite: bool = False
    creation_source: OutfitSourceEnum
    styling_explanation: Optional[str] = None
    wear_count: int = 0
    last_worn_date: Optional[datetime] = None
    items: List[OutfitItemSummary]
    garment_ids: List[str]
    is_available: bool = True
    unavailable_reasons: List[str] = []
    created_at: datetime
    updated_at: datetime

class OutfitListResponse(BaseModel):
    outfits: List[OutfitResponse]
    total: int

class OutfitGenerateRequest(BaseModel):
    occasion: Optional[str] = "Casual"
    exclude_worn: bool = True
    color_palette: Optional[str] = None
    comfort_preference: Optional[str] = None
    favorites_only: bool = False
    limit: int = 5

class GuidedStylingRequest(BaseModel):
    seed_garment_id: str
    occasion: Optional[str] = "Casual"
    exclude_worn: bool = True
    limit: int = 3

class OutfitValidateRequest(BaseModel):
    garment_ids: List[str]

class OutfitValidateResponse(BaseModel):
    is_valid: bool
    is_wearable: bool
    conflicts: List[str] = []
    items: List[OutfitItemSummary] = []

class OutfitWearRequest(BaseModel):
    idempotency_key: Optional[str] = None
    notes: Optional[str] = None

class OutfitWearResponse(BaseModel):
    outfit_id: str
    worn_at: datetime
    garments_updated: List[str]
    wear_count: int
    idempotency_key: Optional[str] = None

class OutfitRecommendationCard(BaseModel):
    id: str
    name: str
    occasion: str
    garments: List[OutfitItemSummary]
    garment_ids: List[str]
    explanation: str
    is_available: bool = True
    combination_fingerprint: str

class OutfitRecommendationsResponse(BaseModel):
    recommendations: List[OutfitRecommendationCard]
    total: int

