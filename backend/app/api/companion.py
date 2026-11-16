from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import List, Any, Dict
from supabase import Client

from app.core.auth import get_current_user, get_supabase_client
from app.services.companion.service import CompanionService
from app.schemas.companion import (
    CompanionPreferences,
    CompanionPreferencesUpdate,
    CompanionRoutine,
    CompanionRoutineCreate,
    CompanionRoutineUpdate,
    CompanionMilestone,
    CompanionActivity,
    CompanionProfileResponse
)

router = APIRouter()

def _extract_user_id(user: Any) -> str:
    if hasattr(user, "id"):
        return str(user.id)
    if isinstance(user, dict) and "id" in user:
        return str(user["id"])
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid user session")

def get_companion_service(
    user: Any = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
) -> CompanionService:
    user_id = _extract_user_id(user)
    return CompanionService(supabase=supabase, user_id=user_id)

# -----------------------------------------------------------------------------
# Profile & Preferences
# -----------------------------------------------------------------------------
@router.get("/profile", response_model=CompanionProfileResponse)
def get_companion_profile(service: CompanionService = Depends(get_companion_service)):
    """Retrieve full companion profile, including stage, preferences, and active routines."""
    try:
        return service.get_profile()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch companion profile: {str(e)}")

@router.get("/preferences", response_model=CompanionPreferences)
def get_companion_preferences(service: CompanionService = Depends(get_companion_service)):
    """Retrieve companion personality, mascot theme, and notification preferences."""
    try:
        return service.get_preferences()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch preferences: {str(e)}")

@router.put("/preferences", response_model=CompanionPreferences)
def update_companion_preferences(
    req: CompanionPreferencesUpdate,
    service: CompanionService = Depends(get_companion_service)
):
    """Update companion personality traits, mascot theme, quiet mode, or progression settings."""
    try:
        return service.update_preferences(req)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update preferences: {str(e)}")

# -----------------------------------------------------------------------------
# Personal Routines
# -----------------------------------------------------------------------------
@router.get("/routines", response_model=List[CompanionRoutine])
def get_companion_routines(service: CompanionService = Depends(get_companion_service)):
    """Retrieve all user personal routines (morning briefing, evening review, etc.)."""
    try:
        return service.get_routines()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch routines: {str(e)}")

@router.post("/routines", response_model=CompanionRoutine)
def create_companion_routine(
    req: CompanionRoutineCreate,
    service: CompanionService = Depends(get_companion_service)
):
    """Create a new adaptive personal routine with preferred time, days, and timezone."""
    try:
        return service.create_routine(req)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create routine: {str(e)}")

@router.put("/routines/{routine_id}", response_model=CompanionRoutine)
def update_companion_routine(
    routine_id: str,
    req: CompanionRoutineUpdate,
    service: CompanionService = Depends(get_companion_service)
):
    """Update an existing personal routine's time, days, or enabled status."""
    try:
        return service.update_routine(routine_id, req)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update routine: {str(e)}")

@router.delete("/routines/{routine_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_companion_routine(
    routine_id: str,
    service: CompanionService = Depends(get_companion_service)
):
    """Delete a personal routine."""
    try:
        service.delete_routine(routine_id)
        return None
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete routine: {str(e)}")

@router.post("/routines/check")
def check_due_routines(service: CompanionService = Depends(get_companion_service)):
    """Evaluate and trigger due personal routines for the authenticated user."""
    try:
        due = service.evaluate_due_routines()
        return {"due_routines": due, "count": len(due)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to check routines: {str(e)}")

# -----------------------------------------------------------------------------
# Milestones & Activity History
# -----------------------------------------------------------------------------
@router.get("/milestones", response_model=List[CompanionMilestone])
def get_companion_milestones(service: CompanionService = Depends(get_companion_service)):
    """Retrieve meaningful companion evolution milestones."""
    try:
        return service.get_milestones()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch milestones: {str(e)}")

@router.get("/activity", response_model=List[CompanionActivity])
def get_companion_activity(
    limit: int = Query(default=20, ge=1, le=100),
    service: CompanionService = Depends(get_companion_service)
):
    """Retrieve companion interaction and routine activity logs."""
    try:
        return service.get_activity(limit=limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch activity: {str(e)}")

