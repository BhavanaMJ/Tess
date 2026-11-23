from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Optional
from datetime import date
import logging

from app.core.auth import get_current_user, get_supabase_client, get_user_id
from app.services.wardrobe.insights_service import InsightsService
from app.schemas.insights import (
    AnalyticsPeriodEnum,
    WardrobeOverviewAnalytics,
    CategoryDistributionResponse,
    GarmentUsageListResponse,
    WardrobeUtilisationResponse,
    ColourAnalysisResponse,
    CategoryUsageResponse,
    OutfitRepetitionResponse,
    CostPerWearSummary,
    WardrobeRecommendationsResponse,
    CapsuleWardrobeSummary,
    StylePreferencesUpdate,
    StyleMemoryResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/wardrobe/insights", tags=["wardrobe-insights"])


def get_insights_service(
    user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client),
) -> InsightsService:
    uid = get_user_id(user)
    return InsightsService(supabase, uid)


@router.get("/overview", response_model=WardrobeOverviewAnalytics)
async def get_overview(
    period: AnalyticsPeriodEnum = Query(AnalyticsPeriodEnum.DAYS_30),
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    service: InsightsService = Depends(get_insights_service),
):
    """Retrieve aggregate wardrobe telemetry, active/laundry counts, and utilization for a selected period."""
    try:
        return service.get_overview(period=period, start_date=start_date, end_date=end_date)
    except Exception as e:
        logger.error(f"Error fetching wardrobe overview: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/category-distribution", response_model=CategoryDistributionResponse)
async def get_category_distribution(
    service: InsightsService = Depends(get_insights_service),
):
    """Retrieve garment count and percentage distribution by wardrobe category."""
    try:
        return service.get_category_distribution()
    except Exception as e:
        logger.error(f"Error fetching category distribution: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/most-worn", response_model=GarmentUsageListResponse)
async def get_most_worn(
    period: AnalyticsPeriodEnum = Query(AnalyticsPeriodEnum.ALL_TIME),
    limit: int = Query(5, ge=1, le=50),
    service: InsightsService = Depends(get_insights_service),
):
    """Retrieve top-worn garments for the selected period with cost-per-wear metrics."""
    try:
        return service.get_most_worn(period=period, limit=limit)
    except Exception as e:
        logger.error(f"Error fetching most worn garments: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/least-worn", response_model=GarmentUsageListResponse)
async def get_least_worn(
    period: AnalyticsPeriodEnum = Query(AnalyticsPeriodEnum.ALL_TIME),
    limit: int = Query(5, ge=1, le=50),
    service: InsightsService = Depends(get_insights_service),
):
    """Retrieve least-worn garments classified with neglect reasons."""
    try:
        return service.get_least_worn(period=period, limit=limit)
    except Exception as e:
        logger.error(f"Error fetching least worn garments: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/neglected", response_model=GarmentUsageListResponse)
async def get_neglected(
    threshold_days: int = Query(60, ge=14, le=365),
    limit: int = Query(10, ge=1, le=50),
    service: InsightsService = Depends(get_insights_service),
):
    """Retrieve neglected garments that are unrecorded, rarely worn, or not worn recently."""
    try:
        return service.get_neglected(threshold_days=threshold_days, limit=limit)
    except Exception as e:
        logger.error(f"Error fetching neglected garments: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/utilisation", response_model=WardrobeUtilisationResponse)
async def get_utilisation(
    period: AnalyticsPeriodEnum = Query(AnalyticsPeriodEnum.DAYS_30),
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    service: InsightsService = Depends(get_insights_service),
):
    """Compute exact wardrobe utilization metric: (unique_garments_worn / active_wardrobe) * 100."""
    try:
        return service.get_utilisation(period=period, start_date=start_date, end_date=end_date)
    except Exception as e:
        logger.error(f"Error calculating wardrobe utilisation: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/colour-analysis", response_model=ColourAnalysisResponse)
async def get_colour_analysis(
    service: InsightsService = Depends(get_insights_service),
):
    """Analyze color dominance and normalized palette grouping across the active wardrobe."""
    try:
        return service.get_colour_analysis()
    except Exception as e:
        logger.error(f"Error fetching colour analysis: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/category-usage", response_model=CategoryUsageResponse)
async def get_category_usage(
    period: AnalyticsPeriodEnum = Query(AnalyticsPeriodEnum.DAYS_30),
    service: InsightsService = Depends(get_insights_service),
):
    """Retrieve category-specific wear frequency and utilization rates."""
    try:
        return service.get_category_usage(period=period)
    except Exception as e:
        logger.error(f"Error fetching category usage analytics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/outfit-repetition", response_model=OutfitRepetitionResponse)
async def get_outfit_repetition(
    limit: int = Query(10, ge=1, le=50),
    service: InsightsService = Depends(get_insights_service),
):
    """Detect frequently repeated outfit combinations and average repetition intervals."""
    try:
        return service.get_outfit_repetition(limit=limit)
    except Exception as e:
        logger.error(f"Error fetching outfit repetition analytics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/cost-per-wear", response_model=CostPerWearSummary)
async def get_cost_per_wear(
    service: InsightsService = Depends(get_insights_service),
):
    """Compute cost-per-wear for all priced garments, highlighting best value and high-cost items."""
    try:
        return service.get_cost_per_wear()
    except Exception as e:
        logger.error(f"Error computing cost-per-wear analytics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/recommendations", response_model=WardrobeRecommendationsResponse)
async def get_recommendations(
    service: InsightsService = Depends(get_insights_service),
):
    """Generate intelligent recommendations: revive neglected pieces, new pairings, and balance tips."""
    try:
        return service.get_recommendations()
    except Exception as e:
        logger.error(f"Error generating wardrobe recommendations: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/capsule-intelligence", response_model=CapsuleWardrobeSummary)
async def get_capsule_intelligence(
    service: InsightsService = Depends(get_insights_service),
):
    """Evaluate capsule wardrobe readiness, versatile anchor garments, and potential combinations."""
    try:
        return service.get_capsule_intelligence()
    except Exception as e:
        logger.error(f"Error calculating capsule intelligence: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/style-memory", response_model=StyleMemoryResponse)
async def get_style_memory(
    service: InsightsService = Depends(get_insights_service),
):
    """Retrieve user personal style memory, persona, and empirical wear preferences."""
    try:
        return service.get_style_memory()
    except Exception as e:
        logger.error(f"Error fetching style memory: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/style-memory", response_model=StyleMemoryResponse)
async def update_style_memory(
    req: StylePreferencesUpdate,
    service: InsightsService = Depends(get_insights_service),
):
    """Update personal style persona, preferred colors, categories, or avoided combinations."""
    try:
        return service.update_style_preferences(req)
    except Exception as e:
        logger.error(f"Error updating style preferences: {e}")
        raise HTTPException(status_code=500, detail=str(e))
