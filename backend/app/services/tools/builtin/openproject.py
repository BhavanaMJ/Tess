from pydantic import BaseModel, Field, field_validator
from typing import Any, Dict
from app.services.tools.base import BaseTool
from app.services.productivity.openproject import OpenProjectProvider
import re

class WorklogInput(BaseModel):
    task_id: str = Field(..., description="OpenProject work package identifier")
    hours: float = Field(..., description="Worklog duration in hours (positive, <= 24)")
    comment: str = Field(..., description="Description/notes for the worklog")

    @field_validator("task_id")
    @classmethod
    def validate_task_id(cls, v: str) -> str:
        s = str(v).strip()
        if not s:
            raise ValueError("task_id cannot be empty")
        if not re.match(r"^[0-9a-zA-Z_-]+$", s):
            raise ValueError(f"task_id contains invalid characters: '{v}'")
        return s

    @field_validator("hours")
    @classmethod
    def validate_hours(cls, v: float) -> float:
        try:
            val = float(v)
        except (ValueError, TypeError):
            raise ValueError(f"Invalid hours: '{v}'")
        if val <= 0:
            raise ValueError("hours must be greater than 0")
        if val > 24.0:
            raise ValueError("hours cannot exceed 24 per entry")
        return round(val, 2)

    @field_validator("comment")
    @classmethod
    def validate_comment(cls, v: str) -> str:
        s = str(v).strip()
        if not s:
            raise ValueError("comment cannot be empty")
        return s

class OpenProjectUpdateWorklog(BaseTool):
    name = "openproject_update_worklog"
    description = "Update the OpenProject worklog for a specific task"
    risk_level = "MEDIUM"
    action_type = "UPDATE_WORKLOG"
    input_schema = WorklogInput

    def execute(self, user_id: str, context: Any, parameters: Dict[str, Any]) -> Any:
        # Context must contain supabase client
        supabase = context
        if not supabase:
            raise ValueError("Database context required for tool execution")
        
        # 1. Retrieve credentials internally without exposing to LLM/client
        res = supabase.table("productivity_connections")\
            .select("base_url, credential_reference")\
            .eq("user_id", user_id)\
            .eq("provider", "openproject")\
            .execute()
            
        if not res.data:
            raise ValueError("OpenProject connection not configured for this user")
            
        conn = res.data[0]
        base_url = conn.get("base_url")
        api_token = conn.get("credential_reference")
        
        if not base_url or not api_token:
            raise ValueError("OpenProject credentials incomplete or missing")

        # 2. Reuse OpenProjectProvider (no second integration)
        provider = OpenProjectProvider(base_url=base_url, api_token=api_token)

        # 3. Real external execution via OpenProject API v3 (no simulation)
        result = provider.create_time_entry(
            task_id=str(parameters["task_id"]),
            hours=float(parameters["hours"]),
            comment=str(parameters["comment"])
        )

        return result
