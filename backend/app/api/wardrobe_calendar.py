from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Optional
import logging

from app.core.auth import get_current_user, get_supabase_client, get_user_id
from app.services.wardrobe.service import WardrobeService
from app.services.wardrobe.laundry_service import LaundryService
from app.services.wardrobe.outfit_service import OutfitService
from app.services.wardrobe.weather_service import WeatherService
from app.services.wardrobe.calendar_service import CalendarService
from app.schemas.calendar import (
    WeatherSummary,
    OutfitPlanCreate,
    OutfitPlanUpdate,
    OutfitPlanResponse,
    ActualWearCreate,
    ActualWearResponse,
    CalendarDayDetailResponse,
    CalendarWeekResponse,
    CalendarMonthResponse,
    RecentlyWornGarmentItem,
    UnusedGarmentItem,
    RepetitionCheckResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/wardrobe/calendar", tags=["wardrobe-calendar"])
weather_router = APIRouter(prefix="/api/v1/wardrobe/weather", tags=["wardrobe-weather"])

def get_calendar_service(
    user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client),
) -> CalendarService:
    uid = get_user_id(user)
    wardrobe_service = WardrobeService(supabase, uid)
    laundry_service = LaundryService(supabase, uid, wardrobe_service=wardrobe_service)
    outfit_service = OutfitService(supabase, uid, wardrobe_service=wardrobe_service, laundry_service=laundry_service)
    weather_service = WeatherService(supabase, uid)
    return CalendarService(supabase, uid, outfit_service=outfit_service, weather_service=weather_service)

def get_weather_service(
    user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client),
) -> WeatherService:
    uid = get_user_id(user)
    return WeatherService(supabase, uid)

# --- 1. OUTFIT PLANS ---
@router.post("/plans", response_model=OutfitPlanResponse, status_code=status.HTTP_201_CREATED)
async def create_plan(
    req: OutfitPlanCreate,
    service: CalendarService = Depends(get_calendar_service),
):
    """Creates a planned outfit for a specific date without modifying garment laundry status."""
    try:
        return service.create_plan(req)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"[CalendarRouter] Error creating plan: {e}")
        raise HTTPException(status_code=500, detail="Failed to create outfit plan.")

@router.get("/plans/upcoming", response_model=List[OutfitPlanResponse])
async def get_upcoming_plans(
    limit: int = Query(10, ge=1, le=50),
    service: CalendarService = Depends(get_calendar_service),
):
    """Retrieves upcoming planned outfits."""
    return service.get_upcoming_plans(limit=limit)

@router.get("/plans/{plan_id}", response_model=OutfitPlanResponse)
async def get_plan(
    plan_id: str,
    service: CalendarService = Depends(get_calendar_service),
):
    """Retrieves an outfit plan by ID."""
    plan = service.get_plan(plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found.")
    return plan

@router.put("/plans/{plan_id}", response_model=OutfitPlanResponse)
async def update_plan(
    plan_id: str,
    req: OutfitPlanUpdate,
    service: CalendarService = Depends(get_calendar_service),
):
    """Updates an outfit plan date, occasion, or notes."""
    try:
        return service.update_plan(plan_id, req)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"[CalendarRouter] Error updating plan: {e}")
        raise HTTPException(status_code=500, detail="Failed to update outfit plan.")

@router.delete("/plans/{plan_id}")
async def delete_plan(
    plan_id: str,
    service: CalendarService = Depends(get_calendar_service),
):
    """Deletes an outfit plan."""
    try:
        service.delete_plan(plan_id)
        return {"status": "success", "message": "Plan deleted successfully."}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"[CalendarRouter] Error deleting plan: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete outfit plan.")

# --- 2. ACTUAL WEAR CONFIRMATION ---
@router.post("/wear", response_model=ActualWearResponse, status_code=status.HTTP_201_CREATED)
async def record_actual_wear(
    req: ActualWearCreate,
    service: CalendarService = Depends(get_calendar_service),
):
    """
    Confirms actual wear of an outfit on a specific calendar date.
    Transitions constituent garments to WORN, increments wear counts,
    and updates the associated plan if plan_id is provided.
    """
    try:
        return service.record_actual_wear(req)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"[CalendarRouter] Error recording actual wear: {e}")
        raise HTTPException(status_code=500, detail="Failed to record actual wear.")

@router.get("/history", response_model=List[ActualWearResponse])
async def get_outfit_history(
    limit: int = Query(50, ge=1, le=100),
    service: CalendarService = Depends(get_calendar_service),
):
    """Retrieves chronological wear history."""
    return service.get_outfit_history(limit=limit)

# --- 3. CALENDAR VIEWS ---
@router.get("/day/{date_str}", response_model=CalendarDayDetailResponse)
async def get_day_detail(
    date_str: str,
    service: CalendarService = Depends(get_calendar_service),
):
    """Returns day detail including planned outfits, actual wear records, and weather forecast."""
    try:
        return service.get_day_detail(date_str)
    except Exception as e:
        logger.error(f"[CalendarRouter] Error fetching day detail for {date_str}: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve calendar day detail.")

@router.get("/week", response_model=CalendarWeekResponse)
async def get_week_view(
    start_date: str = Query(..., description="YYYY-MM-DD"),
    service: CalendarService = Depends(get_calendar_service),
):
    """Returns 7-day week view starting from start_date."""
    try:
        return service.get_week_view(start_date)
    except Exception as e:
        logger.error(f"[CalendarRouter] Error fetching week view: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve week view.")

@router.get("/month", response_model=CalendarMonthResponse)
async def get_month_view(
    year: int = Query(..., ge=2020, le=2050),
    month: int = Query(..., ge=1, le=12),
    service: CalendarService = Depends(get_calendar_service),
):
    """Returns monthly view containing every day in the month."""
    try:
        return service.get_month_view(year, month)
    except Exception as e:
        logger.error(f"[CalendarRouter] Error fetching month view: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve month view.")

# --- 4. CALENDAR INTELLIGENCE ---
@router.get("/intelligence/repetition", response_model=RepetitionCheckResponse)
async def check_repetition(
    outfit_id: str = Query(...),
    date: str = Query(..., description="YYYY-MM-DD"),
    window_days: int = Query(14, ge=1, le=60),
    service: CalendarService = Depends(get_calendar_service),
):
    """Checks whether an outfit was recently worn within the specified window."""
    return service.check_repetition(outfit_id, date, window_days=window_days)

@router.get("/intelligence/recently-worn", response_model=List[RecentlyWornGarmentItem])
async def get_recently_worn(
    limit: int = Query(10, ge=1, le=50),
    service: CalendarService = Depends(get_calendar_service),
):
    """Returns garments recently worn with dates and wear counts."""
    return service.get_recently_worn_garments(limit=limit)

@router.get("/intelligence/unused", response_model=List[UnusedGarmentItem])
async def get_unused_garments(
    days_threshold: int = Query(30, ge=7, le=365),
    service: CalendarService = Depends(get_calendar_service),
):
    """Returns garments that haven't been worn in over days_threshold days."""
    return service.get_unused_garments(days_threshold=days_threshold)

# --- 5. WEATHER PROXY ENDPOINT ---
@weather_router.get("/{date_str}", response_model=WeatherSummary)
async def get_weather(
    date_str: str,
    location: str = Query("Current Location"),
    lat: float = Query(37.7749),
    lon: float = Query(-122.4194),
    service: WeatherService = Depends(get_weather_service),
):
    """Returns weather summary and outfit styling suggestion for a date."""
    return service.get_weather_for_date(date_str, location=location, latitude=lat, longitude=lon)

