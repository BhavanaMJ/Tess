from fastapi import APIRouter, Depends, HTTPException, Query, status
from supabase import Client
from typing import List, Optional, Any
from pydantic import BaseModel

from app.core.auth import get_current_user, get_supabase_client
from app.services.future.service import FutureService
from app.services.productivity.service import ProductivityService
from app.schemas.future import (
    FutureAnalysisResponse,
    FuturePrediction,
    SimulationResponse,
    FutureScenario,
    BehavioralAnalysisResponse,
    LongTermForecastRequest,
    LongTermForecastResponse,
    MultipleFuturesRequest,
    MultipleFuturesResponse,
    AccuracyMetricsResponse,
    InterventionEffectivenessResponse,
    PredictionEvaluationItem
)

router = APIRouter()

def _extract_user_id(user: Any) -> str:
    if hasattr(user, "id"):
        return str(user.id)
    if isinstance(user, dict) and "id" in user:
        return str(user["id"])
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid user session")

def get_future_service(user: Any = Depends(get_current_user), supabase: Client = Depends(get_supabase_client)) -> FutureService:
    user_id = _extract_user_id(user)
    return FutureService(supabase=supabase, user_id=user_id)
    
def get_prod_service_dep(user: Any = Depends(get_current_user), supabase: Client = Depends(get_supabase_client)) -> ProductivityService:
    user_id = _extract_user_id(user)
    return ProductivityService(supabase=supabase, user_id=user_id)

@router.post("/analyze", response_model=FutureAnalysisResponse)
def analyze_future(
    db_future: FutureService = Depends(get_future_service),
    db_prod: ProductivityService = Depends(get_prod_service_dep)
):
    try:
        summary = db_prod.get_summary()
        active_tasks = db_prod.get_active_tasks()
        return db_future.analyze_and_predict(summary, active_tasks)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Future analysis failed: {str(e)}")

class SimulateRequest(BaseModel):
    horizon: str

@router.post("/simulate", response_model=SimulationResponse)
def simulate_future(
    req: SimulateRequest,
    db_future: FutureService = Depends(get_future_service)
):
    try:
        return db_future.simulate(req.horizon)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Simulation failed: {str(e)}")

@router.get("/predictions", response_model=List[FuturePrediction])
def get_predictions(
    db_future: FutureService = Depends(get_future_service)
):
    return db_future.get_latest_predictions()

# ==============================================================================
# PHASE 9: ADVANCED FUTURE INTELLIGENCE ENDPOINTS
# ==============================================================================

@router.get("/behavior", response_model=BehavioralAnalysisResponse)
def get_behavioral_profile(
    window_days: int = Query(default=30, ge=7, le=180),
    db_future: FutureService = Depends(get_future_service)
):
    """Retrieve historical behavioral intelligence dimensions and evidence-backed insights."""
    try:
        return db_future.get_behavioral_profile(window_days)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Behavioral profiling failed: {str(e)}")

@router.post("/forecast", response_model=LongTermForecastResponse)
def generate_long_term_forecast(
    req: LongTermForecastRequest,
    db_future: FutureService = Depends(get_future_service)
):
    """Generate explainable long-term forecast (30d, 90d, 365d) based on historical patterns."""
    try:
        return db_future.generate_long_term_forecast(req.horizon)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Forecasting failed: {str(e)}")

@router.get("/forecast", response_model=List[FuturePrediction])
def get_forecasts(
    limit: int = Query(default=10, ge=1, le=50),
    db_future: FutureService = Depends(get_future_service)
):
    """Retrieve existing forecasts and predictions."""
    return db_future.get_latest_predictions(limit=limit)

@router.post("/scenarios", response_model=MultipleFuturesResponse)
def generate_multiple_scenarios(
    req: MultipleFuturesRequest,
    db_future: FutureService = Depends(get_future_service)
):
    """Generate Multiple Future Selves: Current Trajectory, Improved Trajectory, and Alternative Trajectory."""
    try:
        return db_future.generate_multiple_futures(req.horizon, req.user_goal)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Scenario generation failed: {str(e)}")

@router.get("/scenarios", response_model=List[FutureScenario])
def get_scenarios(
    limit: int = Query(default=10, ge=1, le=50),
    db_future: FutureService = Depends(get_future_service)
):
    """Retrieve scenario history."""
    try:
        resp = db_future.supabase.table("future_scenarios")\
            .select("*")\
            .eq("user_id", db_future.user_id)\
            .order("created_at", desc=True)\
            .limit(limit)\
            .execute()
        return [FutureScenario(**item, events=[]) for item in (resp.data or [])]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch scenarios: {str(e)}")

@router.post("/evaluate", response_model=List[PredictionEvaluationItem])
def evaluate_predictions(
    db_future: FutureService = Depends(get_future_service)
):
    """Evaluate eligible predictions against observed task and event outcomes."""
    try:
        return db_future.evaluate_predictions()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction evaluation failed: {str(e)}")

@router.get("/accuracy", response_model=AccuracyMetricsResponse)
def get_prediction_accuracy(
    db_future: FutureService = Depends(get_future_service)
):
    """Retrieve prediction accuracy, Brier calibration scores, and metrics by horizon/type."""
    try:
        return db_future.get_accuracy_metrics()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Accuracy calculation failed: {str(e)}")

@router.get("/intervention-effectiveness", response_model=InterventionEffectivenessResponse)
def get_intervention_effectiveness(
    db_future: FutureService = Depends(get_future_service)
):
    """Retrieve intervention effectiveness, acceptance rates, and action conversion metrics."""
    try:
        return db_future.get_intervention_effectiveness()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Intervention effectiveness calculation failed: {str(e)}")

