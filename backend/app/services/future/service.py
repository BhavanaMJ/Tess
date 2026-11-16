from supabase import Client
from typing import List, Optional
import uuid

from app.schemas.productivity import ProductivitySummary, ProductivityTask
from app.schemas.future import (
    FutureAnalysisResponse,
    FuturePrediction,
    SimulationResponse,
    BehavioralAnalysisResponse,
    LongTermForecastResponse,
    MultipleFuturesResponse,
    AccuracyMetricsResponse,
    InterventionEffectivenessResponse,
    PredictionEvaluationItem
)
from app.services.future.signals import SignalExtractor
from app.services.future.pattern_engine import PatternEngine
from app.services.future.scenario_engine import ScenarioEngine
from app.services.future.scenario_simulator import ScenarioSimulator
from app.services.future.counterfactual_engine import CounterfactualEngine
from app.services.future.behavioral_model import PersonalBehavioralModel
from app.services.future.forecaster import LongTermForecaster
from app.services.future.multiple_futures import MultipleFuturesEngine
from app.services.future.evaluation import PredictionEvaluator
from app.services.future.intervention_effectiveness import InterventionEffectivenessService

class FutureService:
    def __init__(self, supabase: Client, user_id: str):
        self.supabase = supabase
        self.user_id = user_id

    def analyze_and_predict(self, summary: ProductivitySummary, active_tasks: List[ProductivityTask]) -> FutureAnalysisResponse:
        signals = SignalExtractor.extract_signals(summary, active_tasks)
        patterns = PatternEngine.evaluate(signals)
        scenarios = ScenarioEngine.generate(patterns)
        
        for s in scenarios:
            pred_id = str(uuid.uuid4())
            data = s.model_dump()
            data["id"] = pred_id
            data["user_id"] = self.user_id
            
            self.supabase.table("future_predictions").insert(data).execute()
            self.supabase.table("future_events").insert({
                "user_id": self.user_id,
                "event_type": "PREDICTION_CREATED",
                "prediction_id": pred_id
            }).execute()

        return FutureAnalysisResponse(signals=signals, patterns=patterns, scenarios=scenarios)

    def get_latest_predictions(self, limit: int = 5) -> List[FuturePrediction]:
        resp = self.supabase.table("future_predictions").select("*").eq("user_id", self.user_id).eq("status", "ACTIVE").order("created_at", desc=True).limit(limit).execute()
        return [FuturePrediction(**item) for item in resp.data]

    def simulate(self, horizon: str) -> SimulationResponse:
        predictions = self.get_latest_predictions(limit=10)
        
        scenario = ScenarioSimulator.simulate_current_trajectory(predictions, horizon)
        alternative = CounterfactualEngine.generate_alternative(scenario)
        
        # Save scenario
        scenario_data = scenario.model_dump(exclude={"events"})
        scenario_data["user_id"] = self.user_id
        self.supabase.table("future_scenarios").insert(scenario_data).execute()
        
        for ev in scenario.events:
            ev_data = ev.model_dump()
            ev_data["scenario_id"] = scenario.id
            self.supabase.table("scenario_events").insert(ev_data).execute()
            
        if alternative:
            alt_data = alternative.model_dump()
            alt_data["user_id"] = self.user_id
            alt_data["scenario_id"] = scenario.id
            self.supabase.table("counterfactuals").insert(alt_data).execute()
            
        return SimulationResponse(scenario=scenario, alternative=alternative)

    # ==========================================================================
    # PHASE 9: ADVANCED FUTURE INTELLIGENCE METHODS
    # ==========================================================================
    def get_behavioral_profile(self, window_days: int = 30) -> BehavioralAnalysisResponse:
        return PersonalBehavioralModel(self.supabase, self.user_id).extract_behavioral_profile(window_days)

    def generate_long_term_forecast(self, horizon: str = "30d") -> LongTermForecastResponse:
        return LongTermForecaster(self.supabase, self.user_id).forecast(horizon)

    def generate_multiple_futures(self, horizon: str = "30d", user_goal: Optional[str] = None) -> MultipleFuturesResponse:
        return MultipleFuturesEngine(self.supabase, self.user_id).generate_multiple_futures(horizon, user_goal)

    def evaluate_predictions(self) -> List[PredictionEvaluationItem]:
        return PredictionEvaluator(self.supabase, self.user_id).evaluate_predictions()

    def get_accuracy_metrics(self) -> AccuracyMetricsResponse:
        return PredictionEvaluator(self.supabase, self.user_id).get_accuracy_metrics()

    def get_intervention_effectiveness(self) -> InterventionEffectivenessResponse:
        return InterventionEffectivenessService(self.supabase, self.user_id).evaluate_effectiveness()

