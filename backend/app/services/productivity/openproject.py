import httpx
from datetime import datetime
from typing import List, Optional
from fastapi import HTTPException
from app.services.productivity.base import BaseProductivityProvider
from app.schemas.productivity import ProductivityTaskBase
import base64
import re

class OpenProjectProvider(BaseProductivityProvider):
    def __init__(self, base_url: str, api_token: str):
        self.base_url = base_url.rstrip("/")
        self.api_token = api_token

    def _get_headers(self):
        auth_string = f"apikey:{self.api_token}"
        encoded_auth = base64.b64encode(auth_string.encode()).decode()
        return {
            "Authorization": f"Basic {encoded_auth}",
            "Content-Type": "application/json"
        }

    async def test_connection(self) -> dict:
        try:
            async with httpx.AsyncClient() as client:
                res = await client.get(f"{self.base_url}/api/v3/projects", headers=self._get_headers(), timeout=10)
                res.raise_for_status()
                data = res.json()
                return {"connected": True, "project_count": data.get("total", 0)}
        except Exception as e:
            # We don't expose sensitive info in error responses
            return {"connected": False, "error": "Unable to authenticate with OpenProject"}

    async def get_tasks(self) -> List[ProductivityTaskBase]:
        try:
            async with httpx.AsyncClient() as client:
                res = await client.get(f"{self.base_url}/api/v3/work_packages", headers=self._get_headers(), timeout=15)
                res.raise_for_status()
                data = res.json()
                tasks = []
                for wp in data.get("_embedded", {}).get("elements", []):
                    tasks.append(ProductivityTaskBase(
                        source="openproject",
                        external_id=str(wp.get("id")),
                        title=wp.get("subject", ""),
                        description=wp.get("description", {}).get("raw", ""),
                        status=wp.get("_links", {}).get("status", {}).get("title"),
                        priority=wp.get("_links", {}).get("priority", {}).get("title"),
                        assignee=wp.get("_links", {}).get("assignee", {}).get("title"),
                        project=wp.get("_links", {}).get("project", {}).get("title"),
                        start_date=wp.get("startDate"),
                        due_date=wp.get("dueDate"),
                        completion_percent=wp.get("percentageDone", 0)
                    ))
                return tasks
        except Exception as e:
            raise HTTPException(status_code=500, detail="Failed to sync OpenProject tasks")

    @staticmethod
    def _format_iso_duration(hours: float) -> str:
        """Converts decimal hours to ISO 8601 duration string (e.g. 2.0 -> 'PT2H', 1.5 -> 'PT1H30M')."""
        total_minutes = int(round(float(hours) * 60))
        if total_minutes <= 0:
            raise ValueError("Duration in hours must be greater than 0")
        h = total_minutes // 60
        m = total_minutes % 60
        if h > 0 and m > 0:
            return f"PT{h}H{m}M"
        elif h > 0:
            return f"PT{h}H"
        else:
            return f"PT{m}M"

    def create_time_entry(self, task_id: str, hours: float, comment: str, spent_on: Optional[str] = None) -> dict:
        """Creates a real time entry on OpenProject for a given work package.
        
        Uses synchronous httpx.Client so it executes cleanly in tool workflows.
        """
        # Validate inputs
        if not task_id or not str(task_id).strip():
            raise ValueError("Work package identifier (task_id) is required")
        clean_task_id = str(task_id).strip()
        if not re.match(r"^[0-9a-zA-Z_-]+$", clean_task_id):
            raise ValueError(f"Invalid work package identifier: '{task_id}'")

        try:
            val_hours = float(hours)
        except (TypeError, ValueError):
            raise ValueError(f"Invalid worklog hours: '{hours}'")

        if val_hours <= 0:
            raise ValueError("Worklog hours must be a positive number greater than 0")
        if val_hours > 24.0:
            raise ValueError("Worklog hours cannot exceed 24 hours per entry")

        if not comment or not str(comment).strip():
            raise ValueError("Worklog comment is required and cannot be empty")
        clean_comment = str(comment).strip()

        spent_on_date = spent_on or datetime.now().date().isoformat()
        iso_hours = self._format_iso_duration(val_hours)

        payload = {
            "hours": iso_hours,
            "comment": {
                "raw": clean_comment
            },
            "spentOn": spent_on_date,
            "_links": {
                "workPackage": {
                    "href": f"/api/v3/work_packages/{clean_task_id}"
                }
            }
        }

        url = f"{self.base_url}/api/v3/time_entries"

        try:
            with httpx.Client(timeout=15.0) as client:
                res = client.post(url, headers=self._get_headers(), json=payload)
                
                if res.status_code == 201:
                    data = res.json()
                    # Return sanitized external result without exposing credentials
                    return {
                        "status": "success",
                        "time_entry_id": str(data.get("id")),
                        "task_id": clean_task_id,
                        "hours": val_hours,
                        "iso_hours": iso_hours,
                        "comment": clean_comment,
                        "spent_on": spent_on_date,
                        "created_at": data.get("createdAt"),
                        "raw_response": {
                            "id": data.get("id"),
                            "_type": data.get("_type"),
                            "hours": data.get("hours"),
                            "spentOn": data.get("spentOn"),
                            "createdAt": data.get("createdAt"),
                            "updatedAt": data.get("updatedAt")
                        }
                    }
                elif res.status_code == 401:
                    raise HTTPException(
                        status_code=401,
                        detail="OpenProject authentication failed: Invalid API credentials"
                    )
                elif res.status_code == 403:
                    raise HTTPException(
                        status_code=403,
                        detail=f"OpenProject permission denied: Cannot log time on work package {clean_task_id}"
                    )
                elif res.status_code == 404:
                    raise HTTPException(
                        status_code=404,
                        detail=f"OpenProject work package '{clean_task_id}' not found"
                    )
                elif res.status_code in [400, 422]:
                    err_msg = "Validation failed"
                    try:
                        err_data = res.json()
                        err_msg = err_data.get("message") or err_data.get("errorIdentifier") or str(err_data)
                    except Exception:
                        err_msg = res.text
                    raise HTTPException(
                        status_code=400,
                        detail=f"OpenProject rejected time entry: {err_msg}"
                    )
                else:
                    raise HTTPException(
                        status_code=502,
                        detail=f"OpenProject API returned unexpected status {res.status_code}: {res.text}"
                    )
        except httpx.TimeoutException:
            raise HTTPException(
                status_code=504,
                detail="OpenProject request timed out. Please check your network and instance availability."
            )
        except httpx.ConnectError:
            raise HTTPException(
                status_code=502,
                detail=f"Could not connect to OpenProject at {self.base_url}. Connection refused."
            )
        except (HTTPException, ValueError):
            raise
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"OpenProject execution error: {str(e)}"
            )
