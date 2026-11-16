from fastapi import APIRouter, Depends, HTTPException
from typing import List, Any
from supabase import Client

from app.core.auth import get_current_user, get_supabase_client
from app.services.future.service import FutureService
from app.services.proactive.intervention_service import InterventionService
from app.schemas.proactive import InterventionResponse, RespondRequest
from app.api.future import get_future_service

router = APIRouter()

def get_intervention_service(
    user: Any = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
) -> InterventionService:
    user_id = str(user.id if hasattr(user, "id") else user["id"])
    return InterventionService(supabase, user_id)

@router.post("/evaluate", response_model=List[InterventionResponse])
def evaluate_proactive(
    db_future: FutureService = Depends(get_future_service),
    db_intervention: InterventionService = Depends(get_intervention_service)
):
    try:
        preds = db_future.get_latest_predictions(limit=5)
        return db_intervention.evaluate_and_intervene(preds)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Proactive evaluation failed: {str(e)}")

@router.get("/interventions", response_model=List[InterventionResponse])
def get_interventions(
    db_intervention: InterventionService = Depends(get_intervention_service)
):
    try:
        return db_intervention.get_interventions()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/interventions/{intervention_id}/respond")
def respond_intervention(
    intervention_id: str,
    req: RespondRequest,
    db_intervention: InterventionService = Depends(get_intervention_service)
):
    try:
        db_intervention.respond_to_intervention(intervention_id, req.action)
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
