from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Dict, Any
from supabase import Client
from pydantic import BaseModel

from app.core.auth import get_current_user, get_supabase_client
from app.services.agent.service import AgentService
from app.schemas.agent import AgentPlanResponse
from app.services.agent.confirmation import ConfirmationService

router = APIRouter()

def _extract_user_id(user: Any) -> str:
    if hasattr(user, "id"):
        return str(user.id)
    if isinstance(user, dict) and "id" in user:
        return str(user["id"])
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid user object")

def get_agent_service(
    user: Any = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
) -> AgentService:
    user_id = _extract_user_id(user)
    return AgentService(supabase, user_id)

def get_confirmation_service(
    user: Any = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
) -> ConfirmationService:
    user_id = _extract_user_id(user)
    return ConfirmationService(supabase, user_id)

class ObjectiveRequest(BaseModel):
    objective: str

@router.post("/objectives", response_model=AgentPlanResponse)
def create_objective(
    req: ObjectiveRequest,
    db_agent: AgentService = Depends(get_agent_service)
):
    try:
        return db_agent.create_objective(req.objective)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.get("/plans", response_model=List[AgentPlanResponse])
def get_plans(
    db_agent: AgentService = Depends(get_agent_service)
):
    try:
        return db_agent.get_plans()
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.get("/plans/{plan_id}", response_model=AgentPlanResponse)
def get_plan(
    plan_id: str,
    db_agent: AgentService = Depends(get_agent_service)
):
    try:
        return db_agent.get_plan(plan_id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except PermissionError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.post("/plans/{plan_id}/confirm")
def confirm_plan(
    plan_id: str,
    db_agent: AgentService = Depends(get_agent_service),
    conf_svc: ConfirmationService = Depends(get_confirmation_service)
):
    try:
        plan = db_agent.get_plan(plan_id)
        confirmed_count = 0
        for step in plan.steps:
            conf = step.get("confirmation")
            if conf and conf.get("status") == "PENDING":
                conf_svc.confirm(conf.get("id"))
                confirmed_count += 1
        if confirmed_count == 0:
            raise ValueError("No pending confirmations found for this plan")
        return {"status": "success", "confirmed_count": confirmed_count}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except PermissionError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.post("/plans/{plan_id}/cancel")
def cancel_plan(
    plan_id: str,
    db_agent: AgentService = Depends(get_agent_service),
    conf_svc: ConfirmationService = Depends(get_confirmation_service)
):
    try:
        plan = db_agent.get_plan(plan_id)
        cancelled_count = 0
        for step in plan.steps:
            conf = step.get("confirmation")
            if conf:
                conf_svc.cancel(conf.get("id"))
                cancelled_count += 1
        db_agent.cancel_plan(plan_id)
        return {"status": "cancelled", "cancelled_count": cancelled_count}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except PermissionError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.post("/plans/{plan_id}/execute")
def execute_plan(
    plan_id: str,
    db_agent: AgentService = Depends(get_agent_service)
):
    try:
        return db_agent.execute_plan(plan_id)
    except PermissionError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))
