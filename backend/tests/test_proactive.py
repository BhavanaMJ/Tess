import pytest
from app.schemas.future import FuturePrediction
from app.services.proactive.value_scorer import ValueScorer
from app.services.proactive.decision_engine import DecisionEngine
from datetime import datetime

def test_value_scorer():
    pred = FuturePrediction(
        id="p1", user_id="u1", prediction_type="RISK", title="Overdue Increase", 
        description="...", probability=0.8, confidence="HIGH", time_horizon="24h", 
        evidence=["high priority overdue task"], reasoning="...", status="ACTIVE", created_at=datetime.now()
    )
    score = ValueScorer.calculate_score(pred)
    assert score == 0.8  # 1.0 (impact) * 0.8 (prob) * 1.0 (urgency) * 1.0 (actionability)

def test_decision_engine_disabled():
    pred = FuturePrediction(
        id="p1", user_id="u1", prediction_type="RISK", title="Overdue Increase", 
        description="...", probability=0.8, confidence="HIGH", time_horizon="24h", 
        evidence=["high priority task"], reasoning="...", status="ACTIVE", created_at=datetime.now()
    )
    # Mock supabase client
    class MockSupabase:
        pass
        
    decision = DecisionEngine.should_intervene(MockSupabase(), "u1", pred, {"proactive_enabled": False})
    assert decision.should_intervene == False
    assert decision.reason == "Proactive disabled"

def test_decision_engine_threshold():
    pred = FuturePrediction(
        id="p2", user_id="u1", prediction_type="RISK", title="Minor issue", 
        description="...", probability=0.3, confidence="LOW", time_horizon="7d", 
        evidence=["minor task"], reasoning="...", status="ACTIVE", created_at=datetime.now()
    )
    
    decision = DecisionEngine.should_intervene(None, "u1", pred, {"proactive_enabled": True})
    assert decision.should_intervene == False
    assert "threshold" in decision.reason.lower()
