import pytest
from datetime import datetime, timezone, timedelta
from unittest.mock import MagicMock
from fastapi.testclient import TestClient

from app.main import app
from app.services.future.service import FutureService
from app.services.future.behavioral_model import PersonalBehavioralModel
from app.services.future.forecaster import LongTermForecaster
from app.services.future.multiple_futures import MultipleFuturesEngine
from app.services.future.evaluation import PredictionEvaluator
from app.services.future.intervention_effectiveness import InterventionEffectivenessService
from app.core.auth import get_current_user, get_supabase_client

# ==============================================================================
# In-Memory Mock Supabase Query for Phase 9 Testing
# ==============================================================================
class MockTableQuery:
    def __init__(self, data_list):
        self._data = list(data_list)

    def select(self, *args, **kwargs):
        return self

    def insert(self, payload):
        self._data.append(payload)
        return self

    def eq(self, col, val):
        self._data = [d for d in self._data if d.get(col) == val]
        return self

    def gte(self, col, val):
        self._data = [d for d in self._data if str(d.get(col, "")) >= str(val)]
        return self

    def order(self, col, desc=False):
        return self

    def limit(self, count):
        self._data = self._data[:count]
        return self

    def execute(self):
        res = MagicMock()
        res.data = self._data
        return res

class MockSupabaseClient:
    def __init__(self, initial_data=None):
        self.tables = initial_data or {}

    def table(self, name):
        if name not in self.tables:
            self.tables[name] = []
        return MockTableQuery(self.tables[name])

# ==============================================================================
# Fixtures
# ==============================================================================
@pytest.fixture
def mock_supabase():
    now = datetime.now(timezone.utc)
    return MockSupabaseClient({
        "productivity_tasks": [
            {"id": "t1", "user_id": "u1", "status": "CLOSED", "title": "Setup project", "due_date": (now - timedelta(days=2)).isoformat()},
            {"id": "t2", "user_id": "u1", "status": "OPEN", "title": "Write unit tests", "due_date": (now - timedelta(days=1)).isoformat()}, # Overdue
            {"id": "t3", "user_id": "u1", "status": "IN PROGRESS", "title": "Deploy staging", "due_date": (now + timedelta(days=4)).isoformat()}
        ],
        "productivity_events": [
            {"id": "e1", "user_id": "u1", "event_type": "TASK_CLOSED", "created_at": (now - timedelta(days=3)).isoformat()},
            {"id": "e2", "user_id": "u1", "event_type": "ACTION_COMPLETED", "created_at": (now - timedelta(days=1)).isoformat()}
        ],
        "interventions": [
            {"id": "i1", "user_id": "u1", "user_response": "FIX_IT", "created_at": (now - timedelta(days=2)).isoformat()},
            {"id": "i2", "user_id": "u1", "user_response": "DISMISSED", "created_at": (now - timedelta(days=1)).isoformat()}
        ],
        "agent_plans": [
            {"id": "p1", "user_id": "u1", "status": "SUCCESS", "created_at": (now - timedelta(days=2)).isoformat()}
        ],
        "future_predictions": [
            {
                "id": "pred_01",
                "user_id": "u1",
                "prediction_type": "RISK",
                "title": "Overdue backlog accumulation",
                "probability": 0.80,
                "time_horizon": "7d",
                "created_at": (now - timedelta(days=8)).isoformat()
            }
        ],
        "future_scenarios": [],
        "scenario_events": [],
        "behavioral_snapshots": [],
        "prediction_evaluations": [],
        "intervention_evaluations": []
    })

# ==============================================================================
# Milestone 9.1: Behavioral Intelligence Tests
# ==============================================================================
def test_behavioral_feature_extraction(mock_supabase):
    model = PersonalBehavioralModel(mock_supabase, "u1")
    profile = model.extract_behavioral_profile(window_days=30)

    assert profile.metrics["total_tasks"] == 3
    assert profile.metrics["completed_tasks"] == 1
    assert profile.metrics["overdue_tasks"] == 1
    assert profile.metrics["completion_rate"] == 0.33
    assert profile.metrics["overdue_rate"] == 0.50
    assert profile.metrics["intervention_acceptance_rate"] == 0.50
    assert len(profile.insights) >= 3

def test_behavioral_cold_start_handling():
    empty_supabase = MockSupabaseClient({})
    model = PersonalBehavioralModel(empty_supabase, "u_new")
    profile = model.extract_behavioral_profile(window_days=30)

    assert profile.data_quality == "INSUFFICIENT"
    assert profile.metrics["total_tasks"] == 0
    assert len(profile.insights) > 0

# ==============================================================================
# Milestone 9.2: Long-Term Forecasting Tests
# ==============================================================================
def test_long_term_forecasting_horizons(mock_supabase):
    forecaster = LongTermForecaster(mock_supabase, "u1")

    # 30-day forecast
    f30 = forecaster.forecast("30d")
    assert f30.horizon == "30d"
    assert f30.projected_backlog >= 0
    assert f30.completion_forecast >= 1
    assert 0.0 <= f30.probability <= 1.0
    assert "uncertainty_range" in f30.model_dump()
    assert len(f30.assumptions) >= 2
    assert len(f30.evidence) >= 2

    # 90-day quarterly forecast
    f90 = forecaster.forecast("90d")
    assert f90.horizon == "90d"
    assert f90.completion_forecast > f30.completion_forecast

    # 365-day annual forecast
    f365 = forecaster.forecast("365d")
    assert f365.horizon == "365d"
    assert f365.completion_forecast > f90.completion_forecast

    # Invalid horizon raises ValueError
    with pytest.raises(ValueError):
        forecaster.forecast("10years")

# ==============================================================================
# Milestone 9.3: Multiple Future Selves Tests
# ==============================================================================
def test_multiple_future_selves_generation(mock_supabase):
    engine = MultipleFuturesEngine(mock_supabase, "u1")
    futures = engine.generate_multiple_futures("30d", user_goal="Ship TESS Phase 9")

    # Verify Trajectory A (Current Status Quo)
    assert futures.current_trajectory.trajectory_type == "CURRENT"
    assert len(futures.current_trajectory.events) == 3

    # Verify Trajectory B (Improved Focus & Micro-habits)
    assert futures.improved_trajectory.trajectory_type == "IMPROVED"
    assert futures.improved_trajectory.probability >= futures.current_trajectory.probability
    assert len(futures.improved_trajectory.events) == 3

    # Verify Trajectory C (Alternative Scope Reduction)
    assert futures.alternative_trajectory.trajectory_type == "ALTERNATIVE"
    assert len(futures.alternative_trajectory.events) == 3

# ==============================================================================
# Milestone 9.4: Prediction Accuracy & Brier Calibration Tests
# ==============================================================================
def test_prediction_evaluation_and_brier_scoring(mock_supabase):
    evaluator = PredictionEvaluator(mock_supabase, "u1")
    evals = evaluator.evaluate_predictions()

    assert len(evals) == 1
    evaluated_item = evals[0]
    assert evaluated_item.prediction_id == "pred_01"
    # Overdue task exists so RISK prediction is CONFIRMED
    assert evaluated_item.status == "CONFIRMED"
    assert evaluated_item.brier_score is not None
    # Probability was 0.80, outcome was 1 -> Brier score = (0.80 - 1)^2 = 0.04
    assert evaluated_item.brier_score == pytest.approx(0.04, rel=1e-2)

    # Accuracy metrics calculation
    metrics = evaluator.get_accuracy_metrics()
    assert metrics.total_evaluated == 1
    assert metrics.overall_accuracy == 1.0
    assert metrics.brier_calibration_score == pytest.approx(0.04, rel=1e-2)

# ==============================================================================
# Milestone 9.5: Intervention Effectiveness Tests
# ==============================================================================
def test_intervention_effectiveness_analysis(mock_supabase):
    service = InterventionEffectivenessService(mock_supabase, "u1")
    report = service.evaluate_effectiveness()

    assert report.total_interventions == 2
    assert report.accepted_count == 1
    assert report.dismissed_count == 1
    assert report.acceptance_rate == 0.50
    assert len(report.insights) >= 3

# ==============================================================================
# Milestone 9.6: Future API Endpoints Tests
# ==============================================================================
def test_phase9_future_api_endpoints():
    client = TestClient(app)
    app.dependency_overrides[get_current_user] = lambda: {"id": "u1", "email": "user@tess.ai"}
    mock_supabase = MockSupabaseClient()
    app.dependency_overrides[get_supabase_client] = lambda: mock_supabase
    headers = {"Authorization": "Bearer test-jwt"}

    try:
        # GET /api/v1/future/behavior
        res_b = client.get("/api/v1/future/behavior?window_days=30", headers=headers)
        assert res_b.status_code == 200
        assert "insights" in res_b.json()

        # POST /api/v1/future/forecast
        res_f = client.post("/api/v1/future/forecast", json={"horizon": "30d"}, headers=headers)
        assert res_f.status_code == 200
        assert res_f.json()["horizon"] == "30d"

        # POST /api/v1/future/scenarios
        res_s = client.post("/api/v1/future/scenarios", json={"horizon": "30d", "user_goal": "Consistency"}, headers=headers)
        assert res_s.status_code == 200
        data_s = res_s.json()
        assert data_s["current_trajectory"]["trajectory_type"] == "CURRENT"
        assert data_s["improved_trajectory"]["trajectory_type"] == "IMPROVED"
        assert data_s["alternative_trajectory"]["trajectory_type"] == "ALTERNATIVE"

        # GET /api/v1/future/accuracy
        res_a = client.get("/api/v1/future/accuracy", headers=headers)
        assert res_a.status_code == 200
        assert "overall_accuracy" in res_a.json()

        # GET /api/v1/future/intervention-effectiveness
        res_e = client.get("/api/v1/future/intervention-effectiveness", headers=headers)
        assert res_e.status_code == 200
        assert "acceptance_rate" in res_e.json()
    finally:
        app.dependency_overrides.clear()
