from datetime import datetime, date
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, ConfigDict
from enum import Enum

class AnalyticsPeriodEnum(str, Enum):
    DAYS_7 = "7d"
    DAYS_30 = "30d"
    DAYS_90 = "90d"
    MONTHS_6 = "6m"
    MONTHS_12 = "12m"
    ALL_TIME = "all"
    CUSTOM = "custom"

class NeglectReasonEnum(str, Enum):
    NEVER_RECORDED = "NEVER_RECORDED"
    NOT_WORN_RECENTLY = "NOT_WORN_RECENTLY"
    RARELY_WORN = "RARELY_WORN"
    RECENTLY_ADDED = "RECENTLY_ADDED"
    INSUFFICIENT_DATA = "INSUFFICIENT_DATA"

class ValueTierEnum(str, Enum):
    EXCELLENT_VALUE = "EXCELLENT_VALUE"       # CPW <= 100
    GOOD_VALUE = "GOOD_VALUE"                 # CPW <= 300
    FAIR_VALUE = "FAIR_VALUE"                 # CPW <= 600
    HIGH_COST_PER_WEAR = "HIGH_COST_PER_WEAR" # CPW > 600
    UNRECORDED_WEARS = "UNRECORDED_WEARS"     # Price > 0, wears = 0
    MISSING_PRICE = "MISSING_PRICE"           # Price is None

class RecommendationTypeEnum(str, Enum):
    REVIVE_NEGLECTED = "REVIVE_NEGLECTED"
    NEW_COMBINATION = "NEW_COMBINATION"
    HIGH_WEAR_FAVORITE = "HIGH_WEAR_FAVORITE"
    CATEGORY_BALANCE = "CATEGORY_BALANCE"

# 1. Wardrobe Overview & Telemetry
class WardrobeOverviewAnalytics(BaseModel):
    period: AnalyticsPeriodEnum = AnalyticsPeriodEnum.DAYS_30
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    total_active_garments: int = 0
    total_archived_garments: int = 0
    total_worn_garments_in_period: int = 0
    unique_garments_worn_in_period: int = 0
    utilisation_percentage: float = 0.0
    clean_garments_count: int = 0
    in_laundry_count: int = 0
    never_worn_count: int = 0
    total_outfits_worn_in_period: int = 0
    total_investment: float = 0.0
    average_cost_per_wear: Optional[float] = None
    currency: str = "INR"

# 2. Category Distribution
class CategoryDistributionItem(BaseModel):
    category: str
    count: int
    percentage_of_wardrobe: float
    active_count: int
    worn_in_period_count: int = 0

class CategoryDistributionResponse(BaseModel):
    total_garments: int
    categories: List[CategoryDistributionItem]

# 3. Garment Usage Items (Most / Least / Neglected)
class GarmentUsageItem(BaseModel):
    garment_id: str
    garment_name: str
    main_category: str
    primary_color: str
    thumbnail_ref: Optional[str] = None
    wear_count: int
    last_worn_date: Optional[datetime] = None
    purchase_price: Optional[float] = None
    purchase_currency: str = "INR"
    cost_per_wear: Optional[float] = None
    neglect_reason: Optional[NeglectReasonEnum] = None
    laundry_status: Optional[str] = None

class GarmentUsageListResponse(BaseModel):
    period: AnalyticsPeriodEnum
    items: List[GarmentUsageItem]
    total: int

# 4. Wardrobe Utilisation
class WardrobeUtilisationResponse(BaseModel):
    period: AnalyticsPeriodEnum
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    active_garments_count: int
    unique_garments_worn_count: int
    utilisation_percentage: float
    wear_events_count: int
    summary_text: str

# 5. Colour Analysis
class ColourDistributionItem(BaseModel):
    color_group: str
    original_colors: List[str]
    count: int
    percentage: float

class ColourAnalysisResponse(BaseModel):
    total_garments: int
    dominant_color: Optional[str] = None
    distribution: List[ColourDistributionItem]

# 6. Category Usage Analytics
class CategoryUsageAnalytics(BaseModel):
    category: str
    total_garments: int
    wear_count: int
    unique_garments_worn: int
    utilisation_percentage: float

class CategoryUsageResponse(BaseModel):
    period: AnalyticsPeriodEnum
    categories: List[CategoryUsageAnalytics]

# 7. Outfit Repetition Analysis
class OutfitRepetitionItem(BaseModel):
    outfit_id: str
    outfit_name: str
    wear_count: int
    garment_names: List[str]
    garment_ids: List[str]
    last_worn_date: Optional[date] = None
    average_interval_days: Optional[float] = None
    occasion: str = "Casual"

class OutfitRepetitionResponse(BaseModel):
    total_repeated_outfits: int
    outfits: List[OutfitRepetitionItem]

# 8. Cost-Per-Wear Analytics
class CostPerWearItem(BaseModel):
    garment_id: str
    garment_name: str
    main_category: str
    primary_color: str
    thumbnail_ref: Optional[str] = None
    purchase_price: Optional[float] = None
    purchase_currency: str = "INR"
    purchase_date: Optional[date] = None
    wear_count: int
    cost_per_wear: Optional[float] = None
    value_tier: ValueTierEnum

class CostPerWearSummary(BaseModel):
    total_garments_count: int
    garments_with_price_count: int
    garments_without_price_count: int
    total_investment: float
    currency: str = "INR"
    average_cost_per_wear: Optional[float] = None
    items: List[CostPerWearItem]
    best_value_garments: List[CostPerWearItem]
    highest_cost_per_wear_garments: List[CostPerWearItem]

# 9. Intelligent Recommendations
class WardrobeRecommendationItem(BaseModel):
    id: str
    type: RecommendationTypeEnum
    title: str
    description: str
    garment_ids: List[str]
    garment_names: List[str]
    suggested_action: str
    confidence_score: float

class WardrobeRecommendationsResponse(BaseModel):
    recommendations: List[WardrobeRecommendationItem]

# 10. Capsule Wardrobe Intelligence
class CapsuleGarmentInsight(BaseModel):
    garment_id: str
    garment_name: str
    main_category: str
    primary_color: str
    thumbnail_ref: Optional[str] = None
    compatible_pairings_count: int
    versatility_score: float  # 0 to 100
    is_capsule_anchor: bool

class CapsuleWardrobeSummary(BaseModel):
    total_active_garments: int
    capsule_ready_garments_count: int
    average_versatility_score: float
    anchor_garments: List[CapsuleGarmentInsight]
    potential_outfit_combinations: int

# 11. Personal Style Memory
class StylePreferencesUpdate(BaseModel):
    preferred_colors: Optional[List[str]] = None
    preferred_categories: Optional[List[str]] = None
    preferred_occasions: Optional[List[str]] = None
    avoided_combinations: Optional[List[Dict[str, Any]]] = None
    style_persona: Optional[str] = None
    favorite_pairing_rules: Optional[List[Dict[str, Any]]] = None
    notes: Optional[str] = None

class StyleMemoryResponse(BaseModel):
    user_id: str
    style_persona: str
    preferred_colors: List[str]
    preferred_categories: List[str]
    preferred_occasions: List[str]
    avoided_combinations: List[Dict[str, Any]]
    favorite_pairing_rules: List[Dict[str, Any]]
    notes: Optional[str] = None
    top_worn_colors: List[str]
    top_worn_categories: List[str]
    dominant_occasions: List[str]
    interaction_summary: str
    updated_at: datetime
