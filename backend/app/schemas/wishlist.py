from datetime import datetime, date
from typing import List, Optional, Dict, Any
from enum import Enum
from pydantic import BaseModel, Field

class PurchasePriorityEnum(str, Enum):
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    LOW = "LOW"

class WishlistStatusEnum(str, Enum):
    CONSIDERING = "CONSIDERING"
    SHORTLISTED = "SHORTLISTED"
    PURCHASED = "PURCHASED"
    NOT_INTERESTED = "NOT_INTERESTED"

class AssessmentOutcomeEnum(str, Enum):
    STRONG_ADDITION = "STRONG_ADDITION"
    POTENTIALLY_USEFUL = "POTENTIALLY_USEFUL"
    CONSIDER_ALTERNATIVES = "CONSIDER_ALTERNATIVES"
    INSUFFICIENT_INFO = "INSUFFICIENT_INFO"

class GapSeverityEnum(str, Enum):
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    LOW = "LOW"

# -----------------------------------------------------------------------------
# Wishlist CRUD Schemas
# -----------------------------------------------------------------------------

class WishlistItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=150)
    category: str = Field(..., min_length=1, max_length=50)
    subcategory: Optional[str] = None
    reference_image_path: Optional[str] = None
    expected_price: Optional[float] = Field(None, ge=0.0)
    expected_currency: str = "INR"
    purchase_priority: PurchasePriorityEnum = PurchasePriorityEnum.MEDIUM
    occasion: Optional[str] = None
    desired_colour: Optional[str] = None
    desired_pattern: Optional[str] = None
    description: Optional[str] = None
    notes: Optional[str] = None

class WishlistItemUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=150)
    category: Optional[str] = None
    subcategory: Optional[str] = None
    reference_image_path: Optional[str] = None
    expected_price: Optional[float] = Field(None, ge=0.0)
    expected_currency: Optional[str] = None
    purchase_priority: Optional[PurchasePriorityEnum] = None
    occasion: Optional[str] = None
    desired_colour: Optional[str] = None
    desired_pattern: Optional[str] = None
    description: Optional[str] = None
    notes: Optional[str] = None
    status: Optional[WishlistStatusEnum] = None
    actual_purchase_price: Optional[float] = Field(None, ge=0.0)
    actual_purchase_currency: Optional[str] = None
    purchased_at: Optional[datetime] = None

class WishlistStatusUpdate(BaseModel):
    status: WishlistStatusEnum
    actual_purchase_price: Optional[float] = Field(None, ge=0.0)
    actual_purchase_currency: Optional[str] = "INR"
    purchased_at: Optional[datetime] = None

class WishlistConvertToWardrobeRequest(BaseModel):
    actual_purchase_price: Optional[float] = Field(None, ge=0.0)
    actual_purchase_currency: Optional[str] = "INR"
    purchase_date: Optional[date] = None
    laundry_status: Optional[str] = None  # None / unassigned by default
    garment_name_override: Optional[str] = None
    primary_color: Optional[str] = None
    original_image_ref: Optional[str] = None
    processed_image_ref: Optional[str] = None

class WishlistItemResponse(BaseModel):
    id: str
    user_id: str
    name: str
    category: str
    subcategory: Optional[str] = None
    reference_image_path: Optional[str] = None
    expected_price: Optional[float] = None
    expected_currency: str = "INR"
    purchase_priority: str
    occasion: Optional[str] = None
    desired_colour: Optional[str] = None
    desired_pattern: Optional[str] = None
    description: Optional[str] = None
    notes: Optional[str] = None
    status: str
    purchased_at: Optional[datetime] = None
    actual_purchase_price: Optional[float] = None
    actual_purchase_currency: Optional[str] = None
    converted_garment_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime

class WishlistSummaryResponse(BaseModel):
    total_items: int
    high_priority_count: int
    shortlisted_count: int
    purchased_count: int
    considering_count: int
    not_interested_count: int
    estimated_wishlist_value: Dict[str, float] = Field(default_factory=dict)
    purchased_total_value: Dict[str, float] = Field(default_factory=dict)
    unpriced_items_count: int

# -----------------------------------------------------------------------------
# Shopping Intelligence & Gap Analysis Schemas
# -----------------------------------------------------------------------------

class GarmentMatchItem(BaseModel):
    garment_id: str
    garment_name: str
    main_category: str
    subcategory: Optional[str] = None
    primary_color: str
    image_url: Optional[str] = None
    similarity_reason: str
    match_type: str  # EXACT_COLOR_AND_CATEGORY, SAME_CATEGORY, SIMILAR_FUNCTION

class WardrobeGapItem(BaseModel):
    id: str
    title: str
    category: str
    suggested_subcategory: Optional[str] = None
    suggested_color: Optional[str] = None
    supporting_evidence: str
    current_inventory_count: int
    compatible_existing_garment_ids: List[str] = Field(default_factory=list)
    compatible_existing_garment_names: List[str] = Field(default_factory=list)
    potential_outfit_combinations_gained: int
    explanation: str
    confidence_score: float
    severity: str

class PurchaseAssessmentResponse(BaseModel):
    wishlist_item_id: str
    wishlist_item_name: str
    outcome: AssessmentOutcomeEnum
    headline: str
    explanation: str
    existing_similar_garments: List[GarmentMatchItem] = Field(default_factory=list)
    has_similar_owned: bool
    fills_category_gap: bool
    fills_colour_gap: bool
    compatible_pieces_count: int
    potential_new_combinations: int
    assessment_score: Optional[float] = None
    contributing_factors: List[str] = Field(default_factory=list)
    recommendation_action: str

class GarmentMatchRequest(BaseModel):
    category: str
    subcategory: Optional[str] = None
    desired_colour: Optional[str] = None
    limit: int = 5

