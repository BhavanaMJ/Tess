from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class InterventionBase(BaseModel):
    type: str
    priority: str
    title: str
    message: str
    reason: Optional[str]
    value_score: float

class InterventionCreate(InterventionBase):
    prediction_id: Optional[str] = None
    scenario_id: Optional[str] = None

class InterventionResponse(InterventionBase):
    id: str
    user_id: str
    status: str
    created_at: datetime
    sent_at: Optional[datetime] = None
    deferred_until: Optional[datetime] = None

class DecisionResult(BaseModel):
    should_intervene: bool
    value_score: float
    priority: str
    reason: str
    intervention_type: str
    title: str
    message: str

class RespondRequest(BaseModel):
    action: str  # 'ACTED', 'LATER', 'DISMISS'
