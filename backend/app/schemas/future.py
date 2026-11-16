from pydantic import BaseModel
from typing import List, Optional, Any, Dict
from datetime import datetime

class FutureSignal(BaseModel):
    name: str
    value: Any
    description: str

class FuturePattern(BaseModel):
    name: str
    evidence: List[str]

class FutureScenarioBase(BaseModel):
    prediction_type: str  # RISK, NEUTRAL, POSITIVE
    title: str
    description: str
    probability: float
    confidence: str
    time_horizon: str
    evidence: List[str]
    reasoning: str

class FuturePrediction(FutureScenarioBase):
    id: str
    user_id: str
    source_context: Optional[Dict[str, Any]] = None
    status: str
    created_at: datetime
    expires_at: Optional[datetime] = None

class ScenarioEvent(BaseModel):
    id: str
    sequence: int
    relative_time: str
    title: str
    description: str
    confidence: str

class FutureScenario(BaseModel):
    id: str
    trajectory_type: str
    title: str
    summary: str
    horizon: str
    probability: float
    confidence: str
    evidence: List[str]
    events: List[ScenarioEvent]

class Counterfactual(BaseModel):
    id: str
    action: str
    assumption: str
    expected_effect: str

class SimulationResponse(BaseModel):
    scenario: FutureScenario
    alternative: Optional[Counterfactual]

class FutureAnalysisResponse(BaseModel):
    signals: List[FutureSignal]
    patterns: List[FuturePattern]
    scenarios: List[FutureScenarioBase]

# ==============================================================================
# PHASE 9: ADVANCED FUTURE INTELLIGENCE SCHEMAS
# ==============================================================================

class BehavioralInsight(BaseModel):
    category: str
    headline: str
    observation: str
    evidence: List[str]
    data_quality: str  # GOOD, PRELIMINARY, INSUFFICIENT
    window_days: int

class BehavioralAnalysisResponse(BaseModel):
    insights: List[BehavioralInsight]
    metrics: Dict[str, Any]
    data_quality: str
    period_start: datetime
    period_end: datetime

class LongTermForecastRequest(BaseModel):
    horizon: str = "30d"  # 30d, 90d, 365d

class LongTermForecastResponse(BaseModel):
    id: str
    horizon: str
    projected_backlog: int
    completion_forecast: int
    burnout_risk_score: float
    probability: float
    confidence: str
    uncertainty_range: Dict[str, float]
    assumptions: List[str]
    evidence: List[str]
    explanation: str
    created_at: datetime

class MultipleFuturesRequest(BaseModel):
    horizon: str = "30d"  # 30d, 90d, 365d
    user_goal: Optional[str] = None

class MultipleFuturesResponse(BaseModel):
    horizon: str
    current_trajectory: FutureScenario
    improved_trajectory: FutureScenario
    alternative_trajectory: FutureScenario

class PredictionEvaluationItem(BaseModel):
    id: str
    prediction_id: str
    horizon: str
    predicted_outcome: str
    actual_outcome: str
    status: str  # PENDING, EVALUATED, CONFIRMED, PARTIALLY_CONFIRMED, NOT_CONFIRMED, INSUFFICIENT_DATA
    brier_score: Optional[float] = None
    evaluated_at: datetime

class AccuracyMetricsResponse(BaseModel):
    total_evaluated: int
    overall_accuracy: float
    brier_calibration_score: float
    accuracy_by_horizon: Dict[str, float]
    accuracy_by_type: Dict[str, float]
    recent_evaluations: List[PredictionEvaluationItem]

class InterventionEffectivenessResponse(BaseModel):
    total_interventions: int
    accepted_count: int
    dismissed_count: int
    actions_completed_count: int
    acceptance_rate: float
    action_conversion_rate: float
    insights: List[str]

