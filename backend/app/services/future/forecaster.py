from datetime import datetime, timedelta, timezone
from typing import Dict, Any, List, Optional
import uuid
import math
from supabase import Client
from app.schemas.future import LongTermForecastResponse
from app.services.future.behavioral_model import PersonalBehavioralModel

VALID_HORIZONS = {"24h", "3d", "7d", "30d", "90d", "365d"}

class LongTermForecaster:
    def __init__(self, supabase: Client, user_id: str):
        self.supabase = supabase
        self.user_id = user_id

    def forecast(self, horizon: str = "30d") -> LongTermForecastResponse:
        norm_horizon = horizon.lower().strip()
        if norm_horizon not in VALID_HORIZONS:
            raise ValueError(f"Invalid forecast horizon '{horizon}'. Must be one of: {', '.join(sorted(VALID_HORIZONS))}")

        # Map horizon to day count
        horizon_days_map = {
            "24h": 1,
            "3d": 3,
            "7d": 7,
            "30d": 30,
            "90d": 90,
            "365d": 365
        }
        days = horizon_days_map[norm_horizon]

        # 1. Fetch behavioral snapshot
        model = PersonalBehavioralModel(self.supabase, self.user_id)
        behavior = model.extract_behavioral_profile(window_days=min(max(days, 14), 90))
        metrics = behavior.metrics
        data_quality = behavior.data_quality

        active_backlog = metrics["active_backlog"]
        completed = metrics["completed_tasks"]
        overdue = metrics["overdue_tasks"]
        completion_rate = metrics["completion_rate"]

        # 2. Non-linear asymptotic forecasting model
        # Base weekly velocity: tasks completed per 7 days
        observed_window = max(behavior.period_end - behavior.period_start, timedelta(days=7)).days
        weekly_velocity = max(completed / max(observed_window / 7.0, 1.0), 0.5)

        # Decay factor: people don't add infinite tasks linearly
        # Backlog tends towards an equilibrium with task completion
        weeks = days / 7.0
        projected_completions = int(round(weekly_velocity * weeks * (0.85 if days > 30 else 1.0)))

        # New tasks inflow estimate (dampened for long horizons)
        inflow_rate = max(weekly_velocity * 0.9, 1.0)
        projected_new_tasks = int(round(inflow_rate * weeks * (0.75 if days >= 90 else 0.9)))

        projected_backlog = max(0, active_backlog + projected_new_tasks - projected_completions)

        # Burnout and deadline risk calculation
        # Risk factors: high overdue ratio, high backlog-to-velocity ratio
        backlog_pressure = active_backlog / max(weekly_velocity * 4.0, 1.0)
        overdue_ratio = metrics["overdue_rate"]
        raw_risk = (overdue_ratio * 0.5) + (min(backlog_pressure, 2.0) * 0.25)
        burnout_risk = round(min(max(raw_risk, 0.05), 0.95), 2)

        # Probability and Confidence
        if data_quality == "INSUFFICIENT":
            probability = 0.50
            confidence = "LOW"
            uncertainty = {"lower_bound": 0.30, "upper_bound": 0.70}
        elif data_quality == "PRELIMINARY":
            probability = round(min(max(0.40 + (burnout_risk * 0.3), 0.2), 0.8), 2)
            confidence = "MEDIUM"
            uncertainty = {"lower_bound": max(0.0, probability - 0.20), "upper_bound": min(1.0, probability + 0.20)}
        else:
            probability = round(min(max(0.35 + (burnout_risk * 0.4), 0.1), 0.9), 2)
            confidence = "HIGH"
            uncertainty = {"lower_bound": max(0.0, probability - 0.10), "upper_bound": min(1.0, probability + 0.10)}

        # Explainable Narrative & Assumptions
        assumptions = [
            f"Observed weekly task velocity remains steady at ~{round(weekly_velocity, 1)} tasks/week",
            f"No major external scheduling shocks occur over the {days}-day horizon",
            f"Overdue task resolution follows current historical pace"
        ]

        evidence = [
            f"Current active backlog: {active_backlog} tasks",
            f"Overdue tasks: {overdue}",
            f"Historical completion rate: {int(completion_rate * 100)}%",
            f"Historical observations quality: {data_quality}"
        ]

        if days <= 7:
            explanation = (
                f"Over the next {norm_horizon}, short-term commitments suggest an active workload of ~{projected_backlog} tasks. "
                f"Your completion momentum indicates ~{projected_completions} tasks will be cleared."
            )
        elif days <= 30:
            explanation = (
                f"Across the 30-day horizon, steady task inflows and historical execution predict an active backlog settling near {projected_backlog} tasks. "
                f"Maintaining consistent weekly completions will keep deadline pressure manageable."
            )
        elif days <= 90:
            explanation = (
                f"Quarterly forecast ({norm_horizon}): Based on sustainable productivity patterns, you are projected to complete ~{projected_completions} tasks. "
                f"Estimated backlog is projected at {projected_backlog} tasks with uncertainty range {int(uncertainty['lower_bound']*100)}%–{int(uncertainty['upper_bound']*100)}%."
            )
        else:
            explanation = (
                f"Annual horizon (365 days): Long-term projection reflects an equilibrium between task intake and delivery. "
                f"Estimated annual completions: ~{projected_completions} tasks. Projections at this horizon are probabilistic baselines subject to strategic goal shifts."
            )

        forecast_id = str(uuid.uuid4())
        created_at = datetime.now(timezone.utc)

        # Persist prediction in future_predictions table
        try:
            self.supabase.table("future_predictions").insert({
                "id": forecast_id,
                "user_id": self.user_id,
                "prediction_type": "RISK" if burnout_risk > 0.6 else "NEUTRAL",
                "title": f"{norm_horizon.upper()} Long-Term Forecast: {projected_backlog} Projected Backlog",
                "description": explanation,
                "probability": probability,
                "confidence": confidence,
                "time_horizon": norm_horizon,
                "evidence": evidence,
                "reasoning": f"Assumptions: {'; '.join(assumptions)}",
                "status": "ACTIVE",
                "created_at": created_at.isoformat()
            }).execute()
        except Exception:
            pass

        return LongTermForecastResponse(
            id=forecast_id,
            horizon=norm_horizon,
            projected_backlog=projected_backlog,
            completion_forecast=projected_completions,
            burnout_risk_score=burnout_risk,
            probability=probability,
            confidence=confidence,
            uncertainty_range=uncertainty,
            assumptions=assumptions,
            evidence=evidence,
            explanation=explanation,
            created_at=created_at
        )

