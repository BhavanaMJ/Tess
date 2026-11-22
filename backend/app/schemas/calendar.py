from datetime import date, datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

from app.schemas.outfit import OutfitResponse

class WeatherSummary(BaseModel):
    location: str
    date: str
    temperature_c: float
    feels_like_c: Optional[float] = None
    condition_code: str
    condition_text: str
    rain_probability: int = 0
    wind_kph: Optional[float] = None
    humidity: Optional[int] = None
    styling_suggestion: str
    is_forecast_available: bool = True
    message: Optional[str] = None

class OutfitPlanCreate(BaseModel):
    outfit_id: str
    planned_date: str = Field(..., description="YYYY-MM-DD")
    occasion: str = Field("Casual", max_length=60)
    notes: Optional[str] = None

class OutfitPlanUpdate(BaseModel):
    planned_date: Optional[str] = Field(None, description="YYYY-MM-DD")
    occasion: Optional[str] = Field(None, max_length=60)
    notes: Optional[str] = None

class OutfitPlanResponse(BaseModel):
    id: str
    user_id: str
    outfit_id: str
    outfit_name: str
    outfit: OutfitResponse
    planned_date: str
    occasion: str
    notes: Optional[str] = None
    is_worn: bool = False
    is_available: bool = True
    repetition_warning: Optional[str] = None
    created_at: datetime
    updated_at: datetime

class ActualWearCreate(BaseModel):
    outfit_id: str
    actual_worn_date: str = Field(..., description="YYYY-MM-DD")
    plan_id: Optional[str] = None
    idempotency_key: Optional[str] = None
    notes: Optional[str] = None

class ActualWearResponse(BaseModel):
    id: str
    user_id: str
    outfit_id: str
    outfit_name: str
    outfit: OutfitResponse
    plan_id: Optional[str] = None
    actual_worn_date: str
    worn_at: datetime
    garments_updated: List[str] = []
    wear_count: int = 1
    notes: Optional[str] = None
    created_at: datetime

class CalendarDayDetailResponse(BaseModel):
    date: str
    plans: List[OutfitPlanResponse] = []
    actual_wears: List[ActualWearResponse] = []
    has_plan: bool = False
    has_actual_wear: bool = False
    weather: Optional[WeatherSummary] = None

class CalendarWeekResponse(BaseModel):
    start_date: str
    end_date: str
    days: List[CalendarDayDetailResponse]

class CalendarMonthResponse(BaseModel):
    year: int
    month: int
    days: List[CalendarDayDetailResponse]

class RecentlyWornGarmentItem(BaseModel):
    garment_id: str
    garment_name: str
    main_category: str
    primary_color: str
    thumbnail_ref: Optional[str] = None
    last_worn_date: Optional[datetime] = None
    wear_count: int = 0

class UnusedGarmentItem(BaseModel):
    garment_id: str
    garment_name: str
    main_category: str
    primary_color: str
    thumbnail_ref: Optional[str] = None
    last_worn_date: Optional[datetime] = None
    wear_count: int = 0
    status_category: str = Field(..., description="NEVER_WORN | INACTIVE_LONG_TERM | MISSING_DATA")

class RepetitionCheckResponse(BaseModel):
    is_repeated: bool
    message: Optional[str] = None
    last_worn_date: Optional[str] = None
    last_planned_or_worn_date: Optional[str] = None
    days_since: Optional[int] = None
    repetition_count: int = 0
