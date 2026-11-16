import pytest
from datetime import datetime, timezone, timedelta
from unittest.mock import MagicMock
from fastapi.testclient import TestClient

from app.main import app
from app.core.auth import get_current_user, get_supabase_client
from app.services.companion.service import CompanionService
from app.services.companion.personality import PersonalityEngine, PERSONALITY_PRESETS, PROGRESSION_STAGES
from app.services.companion.routine_engine import RoutineEngine
from app.services.companion.memory_continuity import MemoryContinuityEngine
from app.schemas.companion import CompanionRoutineCreate, CompanionRoutineUpdate, CompanionPreferencesUpdate

# ==============================================================================
# In-Memory Mock Supabase Client for Phase 10 Testing
# ==============================================================================
class MockTableQuery:
    def __init__(self, data_list):
        self._target_list = data_list
        self._filters = []
        self._pending_update = None
        self._is_delete = False

    def select(self, *args, **kwargs):
        return self

    def insert(self, payload):
        if isinstance(payload, list):
            self._target_list.extend(payload)
        else:
            self._target_list.append(dict(payload))
        return self

    def update(self, payload):
        self._pending_update = payload
        return self

    def delete(self):
        self._is_delete = True
        return self

    def eq(self, col, val):
        self._filters.append((col, val))
        return self

    def order(self, col, desc=False):
        return self

    def limit(self, count):
        return self

    def execute(self):
        matched = []
        for item in self._target_list:
            match = True
            for col, val in self._filters:
                if item.get(col) != val:
                    match = False
                    break
            if match:
                matched.append(item)

        if self._pending_update is not None:
            for item in matched:
                item.update(self._pending_update)

        if self._is_delete:
            for item in matched:
                if item in self._target_list:
                    self._target_list.remove(item)

        res = MagicMock()
        res.data = matched
        return res
        return res

class MockSupabaseClient:
    def __init__(self, initial_data=None):
        self.tables = initial_data or {}

    def table(self, name):
        if name not in self.tables:
            self.tables[name] = []
        return MockTableQuery(self.tables[name])

# ==============================================================================
# 1. Personality & Progression Engine Tests
# ==============================================================================
def test_personality_presets_and_system_prompt():
    prefs = {
        "personality": "CALM",
        "communication_style": "CONCISE",
        "encouragement_style": "GENTLE",
        "formality": "NEUTRAL",
        "quiet_mode": False,
        "current_stage": 1
    }
    prompt = PersonalityEngine.build_system_prompt(prefs)
    assert "CALM" in prompt
    assert "CONCISE" in prompt
    # Strict safety boundaries
    assert "Never claim to be human" in prompt
    assert "Never express emotional distress" in prompt
    assert "Do not manipulate user emotions" in prompt

def test_quiet_mode_system_prompt():
    prefs = {
        "personality": "FOCUSED",
        "quiet_mode": True,
        "current_stage": 2
    }
    prompt = PersonalityEngine.build_system_prompt(prefs)
    assert "QUIET MODE ACTIVE" in prompt

def test_companion_progression_evaluation():
    # Stage 1: initial
    stage = PersonalityEngine.evaluate_progression(interaction_count=5, milestone_count=1)
    assert stage == 1

    # Stage 2: 10+ interactions, 2+ milestones
    stage = PersonalityEngine.evaluate_progression(interaction_count=12, milestone_count=2)
    assert stage == 2

    # Stage 3: 30+ interactions, 5+ milestones
    stage = PersonalityEngine.evaluate_progression(interaction_count=35, milestone_count=6)
    assert stage == 3

    # If progression is disabled by user, unlocks all stages unconditionally
    stage = PersonalityEngine.evaluate_progression(interaction_count=0, milestone_count=0, progression_enabled=False)
    assert stage == 3

# ==============================================================================
# 2. Routine Engine & Timezone / Quiet Hours Tests
# ==============================================================================
def test_quiet_hours_evaluation():
    # Overnight window: 22:00 to 08:00
    assert RoutineEngine.is_in_quiet_hours("23:30", "22:00", "08:00") is True
    assert RoutineEngine.is_in_quiet_hours("04:15", "22:00", "08:00") is True
    assert RoutineEngine.is_in_quiet_hours("07:59", "22:00", "08:00") is True
    assert RoutineEngine.is_in_quiet_hours("08:01", "22:00", "08:00") is False
    assert RoutineEngine.is_in_quiet_hours("14:00", "22:00", "08:00") is False

    # Daytime window: 13:00 to 15:00
    assert RoutineEngine.is_in_quiet_hours("14:00", "13:00", "15:00") is True
    assert RoutineEngine.is_in_quiet_hours("16:00", "13:00", "15:00") is False

def test_routine_due_check_with_deduplication():
    # Fixed time: Monday 09:00 UTC
    dt_monday_9am = datetime(2026, 11, 16, 9, 0, tzinfo=timezone.utc)

    routine = {
        "id": "r-1",
        "routine_name": "Morning Planning",
        "routine_type": "DAILY_PLANNING",
        "preferred_time": "09:00",
        "days_of_week": ["MON", "TUE", "WED", "THU", "FRI"],
        "timezone": "UTC",
        "enabled": True,
        "last_run_at": None
    }

    # Should be due
    assert RoutineEngine.is_routine_due(routine, quiet_mode=False, now_dt=dt_monday_9am) is True

    # If quiet mode is enabled, should not be due
    assert RoutineEngine.is_routine_due(routine, quiet_mode=True, now_dt=dt_monday_9am) is False

    # If disabled, should not be due
    disabled_routine = dict(routine, enabled=False)
    assert RoutineEngine.is_routine_due(disabled_routine, quiet_mode=False, now_dt=dt_monday_9am) is False

    # If run recently (2 hours ago), should be suppressed by deduplication cooldown
    recent_run_routine = dict(routine, last_run_at=(dt_monday_9am - timedelta(hours=2)).isoformat())
    assert RoutineEngine.is_routine_due(recent_run_routine, quiet_mode=False, now_dt=dt_monday_9am) is False

# ==============================================================================
# 3. Memory Continuity Engine Tests
# ==============================================================================
def test_memory_relevance_selection():
    memories = [
        {"id": "m1", "category": "GOAL", "content": "Deliver Phase 10 Living AI companion", "importance": 5, "is_confirmed": True},
        {"id": "m2", "category": "PREFERENCE", "content": "Prefers dark mode and concise summaries", "importance": 3, "is_confirmed": True},
        {"id": "m3", "category": "PROJECT", "content": "Working on OpenProject docker deployment", "importance": 4, "is_confirmed": True},
        {"id": "m4", "category": "ROUTINE", "content": "Takes morning coffee break at 10am", "importance": 1, "is_confirmed": False}
    ]

    selected = MemoryContinuityEngine.select_relevant_memories(memories, "How is Phase 10 companion progressing?", limit=2)
    assert len(selected) == 2
    assert selected[0]["id"] == "m1"  # Highest keyword and importance match

def test_memory_outdated_check():
    old_unconfirmed = {
        "id": "m-old",
        "content": "Temporary sprint deadline for last month",
        "created_at": (datetime.now(timezone.utc) - timedelta(days=75)).isoformat(),
        "is_confirmed": False
    }
    status = MemoryContinuityEngine.check_outdated_status(old_unconfirmed)
    assert status["is_outdated"] is True

    confirmed = {
        "id": "m-confirmed",
        "content": "Core architectural principle",
        "created_at": (datetime.now(timezone.utc) - timedelta(days=90)).isoformat(),
        "is_confirmed": True
    }
    status_c = MemoryContinuityEngine.check_outdated_status(confirmed)
    assert status_c["is_outdated"] is False

# ==============================================================================
# 4. Companion Service End-to-End Tests
# ==============================================================================
def test_companion_service_profile_and_crud():
    mock_db = MockSupabaseClient()
    service = CompanionService(supabase=mock_db, user_id="user-p10")

    # 1. Get default preferences
    prefs = service.get_preferences()
    assert prefs.personality == "FRIENDLY"
    assert prefs.current_stage == 1

    # 2. Update preferences to PROFESSIONAL
    updated = service.update_preferences(CompanionPreferencesUpdate(
        personality="PROFESSIONAL",
        mascot_theme="CYAN",
        quiet_mode=False
    ))
    assert updated.personality == "PROFESSIONAL"
    assert updated.mascot_theme == "CYAN"
    assert updated.formality == "FORMAL"

    # 3. Create Routine
    routine = service.create_routine(CompanionRoutineCreate(
        routine_name="Morning Briefing",
        routine_type="MORNING_BRIEFING",
        preferred_time="08:30",
        days_of_week=["MON", "TUE", "WED", "THU", "FRI"],
        timezone="UTC",
        enabled=True
    ))
    assert routine.routine_name == "Morning Briefing"
    assert routine.preferred_time == "08:30"

    # 4. Routine should create FIRST_ROUTINE milestone
    milestones = service.get_milestones()
    assert len(milestones) == 1
    assert milestones[0].milestone_type == "FIRST_ROUTINE"

    # 5. Profile Response
    profile = service.get_profile()
    assert profile.current_stage == 1
    assert profile.stage_name == "TESS Seed"
    assert profile.active_routines_count == 1
    assert profile.total_milestones == 1

# ==============================================================================
# 5. Companion Fast-API Endpoints Tests
# ==============================================================================
def test_phase10_companion_api_endpoints():
    client = TestClient(app)
    mock_db = MockSupabaseClient()
    app.dependency_overrides[get_current_user] = lambda: {"id": "user-p10", "email": "companion@tess.ai"}
    app.dependency_overrides[get_supabase_client] = lambda: mock_db
    headers = {"Authorization": "Bearer test-jwt"}

    try:
        # GET /api/v1/companion/preferences
        res_p = client.get("/api/v1/companion/preferences", headers=headers)
        assert res_p.status_code == 200
        assert res_p.json()["personality"] == "FRIENDLY"

        # PUT /api/v1/companion/preferences
        res_pu = client.put("/api/v1/companion/preferences", json={
            "personality": "CALM",
            "mascot_theme": "EMERALD",
            "quiet_mode": True
        }, headers=headers)
        assert res_pu.status_code == 200
        assert res_pu.json()["personality"] == "CALM"
        assert res_pu.json()["mascot_theme"] == "EMERALD"
        assert res_pu.json()["quiet_mode"] is True

        # POST /api/v1/companion/routines
        res_r = client.post("/api/v1/companion/routines", json={
            "routine_name": "Evening Review",
            "routine_type": "EVENING_REVIEW",
            "preferred_time": "19:00",
            "days_of_week": ["MON", "TUE", "WED", "THU", "FRI"],
            "timezone": "UTC"
        }, headers=headers)
        assert res_r.status_code == 200
        r_id = res_r.json()["id"]

        # GET /api/v1/companion/routines
        res_rg = client.get("/api/v1/companion/routines", headers=headers)
        assert res_rg.status_code == 200
        assert len(res_rg.json()) >= 1

        # PUT /api/v1/companion/routines/{id}
        res_ru = client.put(f"/api/v1/companion/routines/{r_id}", json={
            "preferred_time": "20:00"
        }, headers=headers)
        assert res_ru.status_code == 200
        assert res_ru.json()["preferred_time"] == "20:00"

        # GET /api/v1/companion/profile
        res_prof = client.get("/api/v1/companion/profile", headers=headers)
        assert res_prof.status_code == 200
        assert "stage_name" in res_prof.json()

        # GET /api/v1/companion/milestones
        res_m = client.get("/api/v1/companion/milestones", headers=headers)
        assert res_m.status_code == 200

        # GET /api/v1/companion/activity
        res_act = client.get("/api/v1/companion/activity", headers=headers)
        assert res_act.status_code == 200

        # DELETE /api/v1/companion/routines/{id}
        res_rd = client.delete(f"/api/v1/companion/routines/{r_id}", headers=headers)
        assert res_rd.status_code == 204
    finally:
        app.dependency_overrides.clear()
