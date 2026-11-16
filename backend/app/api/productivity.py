from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from supabase import Client
from typing import Dict, Any

from app.core.auth import get_current_user, get_supabase_client, get_user_id
from app.services.productivity.service import ProductivityService
from app.services.productivity.openproject import OpenProjectProvider
from app.schemas.productivity import ProductivitySummary

router = APIRouter()

def get_prod_service(user: dict = Depends(get_current_user), supabase: Client = Depends(get_supabase_client)) -> ProductivityService:
    return ProductivityService(supabase=supabase, user_id=get_user_id(user))

class ConnectionTestRequest(BaseModel):
    base_url: str
    api_token: str

@router.post("/integrations/openproject/test")
async def test_openproject(req: ConnectionTestRequest, db: ProductivityService = Depends(get_prod_service)):
    provider = OpenProjectProvider(base_url=req.base_url, api_token=req.api_token)
    res = await provider.test_connection()
    if res.get("connected"):
        db.save_connection(provider="openproject", base_url=req.base_url, credential_reference=req.api_token)
    return res

@router.post("/integrations/openproject/sync")
async def sync_openproject(db: ProductivityService = Depends(get_prod_service)):
    try:
        return await db.sync_provider("openproject")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Sync failed: {str(e)}")

@router.get("/summary", response_model=ProductivitySummary)
def get_productivity_summary(db: ProductivityService = Depends(get_prod_service)):
    return db.get_summary()

@router.get("/tasks")
def get_productivity_tasks(db: ProductivityService = Depends(get_prod_service)):
    return db.get_active_tasks()
