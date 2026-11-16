import pytest
from datetime import datetime, timedelta, timezone
from unittest.mock import patch, MagicMock
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.main import app
from app.services.tools.registry import ToolRegistry
from app.services.tools.router import ToolRouter
from app.services.tools.permissions import ToolPermissions
from app.services.tools.builtin.openproject import OpenProjectUpdateWorklog, WorklogInput
from app.services.productivity.openproject import OpenProjectProvider
from app.services.agent.planner import AgentPlanner
from app.services.agent.confirmation import ConfirmationService
from app.services.agent.executor import AgentExecutor
from app.services.agent.service import AgentService
from app.core.auth import get_current_user

# ==============================================================================
# In-Memory Mock Supabase Database
# ==============================================================================
class MockSupabaseQuery:
    def __init__(self, data_store, table_name):
        self.data_store = data_store
        self.table_name = table_name
        self.filters = []
        self._action = "select"
        self._payload = None

    def select(self, columns="*"):
        self._action = "select"
        return self

    def insert(self, record):
        self._action = "insert"
        self._payload = record
        return self

    def update(self, record):
        self._action = "update"
        self._payload = record
        return self

    def eq(self, column, value):
        self.filters.append((column, value))
        return self

    def order(self, column, desc=False):
        return self

    def execute(self):
        rows = self.data_store.setdefault(self.table_name, [])
        if self._action == "insert":
            if isinstance(self._payload, list):
                for p in self._payload:
                    rows.append(dict(p))
                return type("Response", (), {"data": self._payload})()
            else:
                rows.append(dict(self._payload))
                return type("Response", (), {"data": [self._payload]})()
        elif self._action == "update":
            matched = []
            for r in rows:
                if all(r.get(col) == val for col, val in self.filters):
                    r.update(self._payload)
                    matched.append(r)
            return type("Response", (), {"data": matched})()
        elif self._action == "select":
            matched = []
            for r in rows:
                if all(r.get(col) == val for col, val in self.filters):
                    matched.append(dict(r))
            return type("Response", (), {"data": matched})()

class MockSupabaseClient:
    def __init__(self):
        self.store = {}

    def table(self, table_name):
        return MockSupabaseQuery(self.store, table_name)


# ==============================================================================
# 1. Base Tool & Registry Tests
# ==============================================================================
def test_tool_registry():
    tool = OpenProjectUpdateWorklog()
    ToolRegistry.register(tool)
    retrieved = ToolRegistry.get_tool("openproject_update_worklog")
    assert retrieved.name == "openproject_update_worklog"
    assert retrieved.risk_level == "MEDIUM"

def test_tool_validation():
    tool = ToolRegistry.get_tool("openproject_update_worklog")
    validated = tool.validate({"task_id": "1", "hours": 4.0, "comment": "test"})
    assert validated.hours == 4.0
    assert validated.task_id == "1"
    assert validated.comment == "test"

def test_permissions():
    assert ToolPermissions.requires_confirmation("openproject_update_worklog") is True

def test_unconfirmed_execution():
    with pytest.raises(PermissionError) as exc_info:
        ToolRouter.route_and_execute(
            user_id="u1", 
            tool_name="openproject_update_worklog", 
            parameters={"task_id": "1", "hours": 4.0, "comment": "test"}, 
            context=None, 
            is_confirmed=False
        )
    assert "requires explicit user confirmation" in str(exc_info.value)

def test_planner():
    plan = AgentPlanner.plan("Update OpenProject worklog with 2 hours")
    assert plan.objective == "Update OpenProject worklog with 2 hours"
    assert len(plan.steps) == 1
    assert plan.steps[0].tool_name == "openproject_update_worklog"
    assert plan.steps[0].parameters["hours"] == 2.0


# ==============================================================================
# 2. FastAPI Router Registration Tests
# ==============================================================================
def test_fastapi_agent_router_registration():
    routes = [r.path for r in app.routes]
    assert "/api/v1/agent/objectives" in routes
    assert "/api/v1/agent/plans/{plan_id}" in routes
    assert "/api/v1/agent/plans/{plan_id}/confirm" in routes
    assert "/api/v1/agent/plans/{plan_id}/cancel" in routes
    assert "/api/v1/agent/plans/{plan_id}/execute" in routes

def test_fastapi_agent_endpoints_in_openapi_docs():
    with TestClient(app) as client:
        res = client.get("/openapi.json")
        assert res.status_code == 200
        schema = res.json()
        paths = schema.get("paths", {})
        assert "/api/v1/agent/objectives" in paths
        assert "/api/v1/agent/plans/{plan_id}" in paths
        assert "/api/v1/agent/plans/{plan_id}/confirm" in paths
        assert "/api/v1/agent/plans/{plan_id}/execute" in paths

def test_agent_endpoints_require_authentication():
    with TestClient(app) as client:
        # Without authorization header, should be rejected (401 or 403)
        res = client.post("/api/v1/agent/objectives", json={"objective": "Log time"})
        assert res.status_code in [401, 403]


# ==============================================================================
# 3. OpenProject Worklog Payload Validation Tests
# ==============================================================================
def test_openproject_payload_validation():
    # Valid
    val = WorklogInput(task_id="101", hours=2.5, comment="Work done")
    assert val.task_id == "101"
    assert val.hours == 2.5
    assert val.comment == "Work done"

    # Invalid hours (<= 0)
    with pytest.raises(ValueError):
        WorklogInput(task_id="101", hours=0, comment="Work done")

    # Invalid hours (> 24)
    with pytest.raises(ValueError):
        WorklogInput(task_id="101", hours=25, comment="Work done")

    # Empty task_id
    with pytest.raises(ValueError):
        WorklogInput(task_id="   ", hours=1.0, comment="Work done")

    # Empty comment
    with pytest.raises(ValueError):
        WorklogInput(task_id="101", hours=1.0, comment="   ")

def test_openproject_iso_duration_formatting():
    assert OpenProjectProvider._format_iso_duration(2.0) == "PT2H"
    assert OpenProjectProvider._format_iso_duration(1.5) == "PT1H30M"
    assert OpenProjectProvider._format_iso_duration(0.25) == "PT15M"
    with pytest.raises(ValueError):
        OpenProjectProvider._format_iso_duration(0)


# ==============================================================================
# 4. OpenProject Mocked Execution Tests
# ==============================================================================
def test_openproject_successful_worklog_creation_mocked():
    provider = OpenProjectProvider(base_url="https://openproject.example.com", api_token="secret-token-123")
    
    mock_response = MagicMock()
    mock_response.status_code = 201
    mock_response.json.return_value = {
        "id": 999,
        "_type": "TimeEntry",
        "hours": "PT2H",
        "spentOn": "2026-11-13",
        "createdAt": "2026-11-13T10:00:00Z",
        "updatedAt": "2026-11-13T10:00:00Z"
    }

    with patch("httpx.Client.post", return_value=mock_response) as mock_post:
        result = provider.create_time_entry(task_id="42", hours=2.0, comment="Resolved bug in agent router")
        
        assert result["status"] == "success"
        assert result["time_entry_id"] == "999"
        assert result["task_id"] == "42"
        assert result["hours"] == 2.0
        assert result["iso_hours"] == "PT2H"
        # Ensure credentials are NOT leaked in output
        assert "secret-token-123" not in str(result)
        
        # Verify call payload
        call_kwargs = mock_post.call_args[1]
        assert call_kwargs["json"]["hours"] == "PT2H"
        assert call_kwargs["json"]["comment"]["raw"] == "Resolved bug in agent router"
        assert call_kwargs["json"]["_links"]["workPackage"]["href"] == "/api/v3/work_packages/42"

def test_openproject_authentication_failure_mocked():
    provider = OpenProjectProvider(base_url="https://openproject.example.com", api_token="bad-token")
    mock_response = MagicMock()
    mock_response.status_code = 401
    mock_response.text = "Unauthorized"

    with patch("httpx.Client.post", return_value=mock_response):
        with pytest.raises(HTTPException) as exc_info:
            provider.create_time_entry(task_id="42", hours=1.0, comment="Test")
        assert exc_info.value.status_code == 401
        assert "authentication failed" in exc_info.value.detail.lower()

def test_openproject_api_failure_and_timeout_mocked():
    provider = OpenProjectProvider(base_url="https://openproject.example.com", api_token="token")
    
    # 404 work package not found
    mock_404 = MagicMock()
    mock_404.status_code = 404
    mock_404.text = "Work package not found"
    with patch("httpx.Client.post", return_value=mock_404):
        with pytest.raises(HTTPException) as exc_info:
            provider.create_time_entry(task_id="99999", hours=1.0, comment="Test")
        assert exc_info.value.status_code == 404

    # Timeout
    import httpx
    with patch("httpx.Client.post", side_effect=httpx.TimeoutException("Timed out")):
        with pytest.raises(HTTPException) as exc_info:
            provider.create_time_entry(task_id="1", hours=1.0, comment="Test")
        assert exc_info.value.status_code == 504


# ==============================================================================
# 5. Confirmation & Safety Guardrails
# ==============================================================================
def test_unconfirmed_action_cannot_execute():
    supabase = MockSupabaseClient()
    user_id = "user-123"
    
    # Setup connection
    supabase.table("productivity_connections").insert({
        "user_id": user_id,
        "provider": "openproject",
        "base_url": "https://op.example.com",
        "credential_reference": "token"
    }).execute()

    service = AgentService(supabase, user_id)
    plan = service.create_objective("Update openproject worklog with 2 hours")
    
    # Verify confirmation is required and pending
    assert plan.status == "READY"
    assert len(plan.steps) == 1
    assert plan.steps[0]["risk_level"] == "MEDIUM"

    # Attempting to execute unconfirmed plan should fail with PermissionError
    with pytest.raises(PermissionError) as exc_info:
        service.execute_plan(plan.id)
    assert "requires explicit user confirmation" in str(exc_info.value)

def test_expired_confirmation_rejected():
    supabase = MockSupabaseClient()
    user_id = "user-123"
    conf_svc = ConfirmationService(supabase, user_id)

    # Insert an expired confirmation
    past_time = (datetime.now(timezone.utc) - timedelta(minutes=30)).isoformat()
    conf_id = "conf-expired-1"
    supabase.table("action_confirmations").insert({
        "id": conf_id,
        "user_id": user_id,
        "plan_id": "plan-1",
        "step_id": "step-1",
        "summary": "Update worklog",
        "status": "PENDING",
        "expires_at": past_time
    }).execute()

    # Confirming expired should raise ValueError
    with pytest.raises(ValueError) as exc_info:
        conf_svc.confirm(conf_id)
    assert "expired" in str(exc_info.value).lower()
    assert conf_svc.is_confirmed("step-1") is False

def test_cancelled_action_rejected():
    supabase = MockSupabaseClient()
    user_id = "user-123"
    conf_svc = ConfirmationService(supabase, user_id)

    conf_id = conf_svc.request_confirmation("plan-1", "step-1", "Update worklog")
    conf_svc.confirm(conf_id)
    assert conf_svc.is_confirmed("step-1") is True

    # Cancel action
    conf_svc.cancel(conf_id)
    assert conf_svc.is_confirmed("step-1") is False

    # Attempting to re-confirm cancelled action fails
    with pytest.raises(ValueError) as exc_info:
        conf_svc.confirm(conf_id)
    assert "cancelled" in str(exc_info.value).lower()

def test_parameter_change_invalidates_confirmation():
    supabase = MockSupabaseClient()
    user_id = "user-123"
    conf_svc = ConfirmationService(supabase, user_id)

    orig_params = {"task_id": "1", "hours": 2.0, "comment": "Orig"}
    conf_id = conf_svc.request_confirmation("plan-1", "step-1", "Update worklog", parameters=orig_params)
    conf_svc.confirm(conf_id)

    # With original parameters: confirmed
    assert conf_svc.is_confirmed("step-1", current_parameters=orig_params) is True

    # If parameters change: previous confirmation is invalidated!
    changed_params = {"task_id": "1", "hours": 8.0, "comment": "Changed drastically"}
    assert conf_svc.is_confirmed("step-1", current_parameters=changed_params) is False
    assert conf_svc.is_confirmed("step-1") is False  # Status was marked cancelled


# ==============================================================================
# 6. Event Persistence Tests
# ==============================================================================
def test_successful_action_event_persistence():
    supabase = MockSupabaseClient()
    user_id = "user-123"

    supabase.table("productivity_connections").insert({
        "user_id": user_id,
        "provider": "openproject",
        "base_url": "https://op.example.com",
        "credential_reference": "token"
    }).execute()

    service = AgentService(supabase, user_id)
    plan = service.create_objective("Update openproject worklog with 2 hours")
    step_id = plan.steps[0]["id"]

    # Confirm step
    conf_res = supabase.table("action_confirmations").select("id").eq("step_id", step_id).execute()
    conf_id = conf_res.data[0]["id"]
    service.conf_service.confirm(conf_id)

    mock_resp = MagicMock()
    mock_resp.status_code = 201
    mock_resp.json.return_value = {"id": 1234, "createdAt": "2026-11-13T10:00:00Z"}

    with patch("httpx.Client.post", return_value=mock_resp):
        res = service.execute_plan(plan.id)
        assert res["status"] == "success"

    # Verify plan status is SUCCESS
    plan_data = supabase.table("agent_plans").select("*").eq("id", plan.id).execute().data[0]
    assert plan_data["status"] == "SUCCESS"

    # Verify event was logged to productivity_events
    events = supabase.table("productivity_events").select("*").execute().data
    assert len(events) == 1
    assert events[0]["event_type"] == "ACTION_COMPLETED"
    assert events[0]["user_id"] == user_id
    assert events[0]["payload"]["plan_id"] == plan.id

def test_failed_action_event_persistence():
    supabase = MockSupabaseClient()
    user_id = "user-123"

    supabase.table("productivity_connections").insert({
        "user_id": user_id,
        "provider": "openproject",
        "base_url": "https://op.example.com",
        "credential_reference": "token"
    }).execute()

    service = AgentService(supabase, user_id)
    plan = service.create_objective("Update openproject worklog with 2 hours")
    step_id = plan.steps[0]["id"]

    # Confirm step
    conf_res = supabase.table("action_confirmations").select("id").eq("step_id", step_id).execute()
    conf_id = conf_res.data[0]["id"]
    service.conf_service.confirm(conf_id)

    # Mock HTTP failure (500)
    mock_resp = MagicMock()
    mock_resp.status_code = 500
    mock_resp.text = "Internal Server Error"

    with patch("httpx.Client.post", return_value=mock_resp):
        with pytest.raises(HTTPException):
            service.execute_plan(plan.id)

    # Verify plan status is FAILED
    plan_data = supabase.table("agent_plans").select("*").eq("id", plan.id).execute().data[0]
    assert plan_data["status"] == "FAILED"

    # Verify failure event was logged to productivity_events
    events = supabase.table("productivity_events").select("*").execute().data
    assert len(events) == 1
    assert events[0]["event_type"] == "ACTION_FAILED"
    assert events[0]["payload"]["plan_id"] == plan.id

def test_non_idempotent_plan_reexecution_prevented():
    supabase = MockSupabaseClient()
    user_id = "user-123"

    supabase.table("productivity_connections").insert({
        "user_id": user_id,
        "provider": "openproject",
        "base_url": "https://op.example.com",
        "credential_reference": "token"
    }).execute()

    service = AgentService(supabase, user_id)
    plan = service.create_objective("Update openproject worklog with 2 hours")
    step_id = plan.steps[0]["id"]

    conf_res = supabase.table("action_confirmations").select("id").eq("step_id", step_id).execute()
    service.conf_service.confirm(conf_res.data[0]["id"])

    mock_resp = MagicMock()
    mock_resp.status_code = 201
    mock_resp.json.return_value = {"id": 1234}

    with patch("httpx.Client.post", return_value=mock_resp):
        service.execute_plan(plan.id)

    # Second execution attempt must raise ValueError and not create duplicate worklogs
    with pytest.raises(ValueError) as exc_info:
        service.execute_plan(plan.id)
    assert "current status is SUCCESS" in str(exc_info.value)
