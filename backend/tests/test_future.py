import pytest
from app.schemas.productivity import ProductivitySummary, ProductivityTask
from app.schemas.future import FuturePrediction, FutureScenario
from app.services.future.signals import SignalExtractor
from app.services.future.pattern_engine import PatternEngine
from app.services.future.confidence import ConfidenceEngine
from app.services.future.scenario_engine import ScenarioEngine
from app.services.future.scenario_simulator import ScenarioSimulator
from app.services.future.counterfactual_engine import CounterfactualEngine
from datetime import datetime, timedelta

def test_signal_extraction():
    summary = ProductivitySummary(total_active=10, overdue=2, due_today=1, due_this_week=2, completed_recently=5)
    active_tasks = [
        ProductivityTask(id="1", user_id="u1", source="test", external_id="t1", title="Stalled Task", created_at=datetime.now() - timedelta(days=10), updated_at=datetime.now() - timedelta(days=10))
    ]
    
    signals = SignalExtractor.extract_signals(summary, active_tasks)
    
    names = [s.name for s in signals]
    assert "overdue_tasks_count" in names
    assert "due_soon_count" in names
    assert "recent_completions" in names
    assert "stalled_tasks_count" in names

def test_pattern_engine():
    summary = ProductivitySummary(total_active=10, overdue=2, due_today=1, due_this_week=3, completed_recently=5)
    signals = SignalExtractor.extract_signals(summary, [])
    patterns = PatternEngine.evaluate(signals)
    
    names = [p.name for p in patterns]
    assert "OVERDUE_ACCUMULATION" in names
    assert "DEADLINE_CLUSTER" in names
    assert "COMPLETION_MOMENTUM" in names
    
def test_confidence_engine():
    prob, conf = ConfidenceEngine.calculate("OVERDUE_ACCUMULATION", 1)
    assert prob == 0.75
    assert conf == "MEDIUM"
    
    prob, conf = ConfidenceEngine.calculate("COMPLETION_MOMENTUM", 2)
    assert prob == 0.8
    assert conf == "HIGH"

def test_scenario_engine():
    summary = ProductivitySummary(total_active=10, overdue=1, due_today=0, due_this_week=0, completed_recently=0)
    signals = SignalExtractor.extract_signals(summary, [])
    patterns = PatternEngine.evaluate(signals)
    
    scenarios = ScenarioEngine.generate(patterns)
    assert len(scenarios) == 1
    assert scenarios[0].prediction_type == "RISK"
    assert scenarios[0].time_horizon == "24h"

def test_scenario_simulator():
    pred1 = FuturePrediction(
        id="p1", user_id="u1", prediction_type="RISK", title="Overdue Increase", 
        description="...", probability=0.8, confidence="HIGH", time_horizon="24h", 
        evidence=["Overdue tasks"], reasoning="...", status="ACTIVE", created_at=datetime.now()
    )
    
    scenario = ScenarioSimulator.simulate_current_trajectory([pred1], "24h")
    assert scenario.trajectory_type == "CURRENT_TRAJECTORY"
    assert "Pressure" in scenario.title
    assert len(scenario.events) == 3

def test_counterfactual_engine():
    scenario = FutureScenario(
        id="s1", trajectory_type="CURRENT_TRAJECTORY", title="Increasing Pressure",
        summary="...", horizon="24h", probability=0.8, confidence="HIGH",
        evidence=["overdue tasks exist"], events=[]
    )
    
    cf = CounterfactualEngine.generate_alternative(scenario)
    assert cf is not None
    assert "Complete the highest-priority overdue task" in cf.action
