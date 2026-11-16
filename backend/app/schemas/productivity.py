from pydantic import BaseModel
from typing import Optional, Any
from datetime import datetime

class ProductivityConnectionCreate(BaseModel):
    provider: str
    base_url: str
    credential_reference: str

class ProductivityConnection(ProductivityConnectionCreate):
    id: str
    user_id: str

class ProductivityTaskBase(BaseModel):
    source: str
    external_id: str
    title: str
    description: Optional[str] = None
    status: Optional[str] = None
    priority: Optional[str] = None
    assignee: Optional[str] = None
    project: Optional[str] = None
    start_date: Optional[datetime] = None
    due_date: Optional[datetime] = None
    completion_percent: int = 0

class ProductivityTask(ProductivityTaskBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

class ProductivityEvent(BaseModel):
    id: str
    user_id: str
    source: str
    event_type: str
    external_id: Optional[str] = None
    payload: Optional[Any] = None
    occurred_at: Optional[datetime] = None
    created_at: datetime

class ProductivitySummary(BaseModel):
    total_active: int = 0
    overdue: int = 0
    due_today: int = 0
    due_this_week: int = 0
    completed_recently: int = 0
