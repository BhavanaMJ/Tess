from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime

class AgentStepSchema(BaseModel):
    tool_name: str
    action_type: str
    parameters: Dict[str, Any]
    risk_level: str

class AgentPlanSchema(BaseModel):
    objective: str
    steps: List[AgentStepSchema]

class AgentPlanResponse(BaseModel):
    id: str
    user_id: str
    objective: str
    status: str
    created_at: Optional[datetime] = None
    steps: List[Dict[str, Any]]

class ConfirmationRequest(BaseModel):
    plan_id: str
    step_id: str
    summary: str
