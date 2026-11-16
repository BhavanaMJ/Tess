from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
import uuid
from supabase import Client
from app.schemas.future import FutureScenario, ScenarioEvent, MultipleFuturesResponse
from app.services.future.forecaster import LongTermForecaster

class MultipleFuturesEngine:
    def __init__(self, supabase: Client, user_id: str):
        self.supabase = supabase
        self.user_id = user_id

    def generate_multiple_futures(self, horizon: str = "30d", user_goal: Optional[str] = None) -> MultipleFuturesResponse:
        forecaster = LongTermForecaster(self.supabase, self.user_id)
        base_forecast = forecaster.forecast(horizon)

        backlog = base_forecast.projected_backlog
        completions = base_forecast.completion_forecast
        risk = base_forecast.burnout_risk_score
        conf = base_forecast.confidence

        # ======================================================================
        # Trajectory A: Current Trajectory (Status Quo Continued)
        # ======================================================================
        current_id = str(uuid.uuid4())
        current_events = [
            ScenarioEvent(
                id=str(uuid.uuid4()),
                sequence=1,
                relative_time=f"Day {int(max(base_forecast.uncertainty_range['lower_bound'] * 10, 3))}",
                title="Status Quo Workload Carried Forward",
                description="Existing task inflow continues matching current execution rate.",
                confidence=conf
            ),
            ScenarioEvent(
                id=str(uuid.uuid4()),
                sequence=2,
                relative_time=f"Day {int(max(base_forecast.uncertainty_range['upper_bound'] * 20, 14))}",
                title="Projected Mid-Horizon Backlog State",
                description=f"Active backlog projected to reach approximately {backlog} open tasks.",
                confidence=conf
            ),
            ScenarioEvent(
                id=str(uuid.uuid4()),
                sequence=3,
                relative_time=f"End of {horizon}",
                title="Forecast Horizon Equilibrium",
                description=f"Estimated {completions} tasks delivered with {int(risk * 100)}% deadline tension risk.",
                confidence=conf
            )
        ]

        current_scenario = FutureScenario(
            id=current_id,
            trajectory_type="CURRENT",
            title=f"Current Trajectory ({horizon}) — What you are currently creating",
            summary=(
                f"If current execution pace and task additions persist, you will deliver ~{completions} tasks "
                f"while maintaining an active backlog of {backlog} items."
            ),
            horizon=horizon,
            probability=base_forecast.probability,
            confidence=conf,
            evidence=base_forecast.evidence,
            events=current_events
        )

        # ======================================================================
        # Trajectory B: Improved Trajectory (Sustainable Micro-Habits)
        # ======================================================================
        improved_id = str(uuid.uuid4())
        improved_completions = int(round(completions * 1.35))
        improved_backlog = max(0, int(round(backlog * 0.65)))
        improved_risk = round(max(risk * 0.5, 0.1), 2)
        improved_prob = round(min(base_forecast.probability + 0.15, 0.90), 2)

        improved_events = [
            ScenarioEvent(
                id=str(uuid.uuid4()),
                sequence=1,
                relative_time="Week 1",
                title="Focus on Top 2 Weekly Priorities",
                description="Clearing 2 high-priority overdue tasks removes bottleneck dependencies.",
                confidence="HIGH"
            ),
            ScenarioEvent(
                id=str(uuid.uuid4()),
                sequence=2,
                relative_time="Week 2-3",
                title="Consistent Morning Velocity",
                description="Daily focused execution momentum accelerates delivery pace.",
                confidence="HIGH"
            ),
            ScenarioEvent(
                id=str(uuid.uuid4()),
                sequence=3,
                relative_time=f"End of {horizon}",
                title="Backlog Contraction & High Delivery",
                description=f"Backlog drops to ~{improved_backlog} tasks. Overdue commitments minimized.",
                confidence="HIGH"
            )
        ]

        improved_scenario = FutureScenario(
            id=improved_id,
            trajectory_type="IMPROVED",
            title=f"Improved Trajectory ({horizon}) — Sustainable Focus & Routine",
            summary=(
                f"By systematically resolving 2 critical tasks per week, you project to deliver ~{improved_completions} tasks "
                f"and reduce pending backlog to {improved_backlog} tasks, cutting stress risk to {int(improved_risk * 100)}%."
            ),
            horizon=horizon,
            probability=improved_prob,
            confidence="HIGH",
            evidence=[
                "High leverage from early task prioritization",
                "Sustainable +35% completion efficiency without burnout",
                f"User goal alignment: {user_goal or 'Steady productivity'}"
            ],
            events=improved_events
        )

        # ======================================================================
        # Trajectory C: Alternative Trajectory (Strategic Scope Reduction)
        # ======================================================================
        alt_id = str(uuid.uuid4())
        alt_backlog = max(0, int(round(backlog * 0.45)))
        alt_completions = int(round(completions * 0.90))
        alt_risk = 0.08
        alt_prob = 0.75

        alt_events = [
            ScenarioEvent(
                id=str(uuid.uuid4()),
                sequence=1,
                relative_time="Immediate",
                title="Strategic Scope De-prioritization",
                description="Identify non-essential or stale backlog items and archive them.",
                confidence="HIGH"
            ),
            ScenarioEvent(
                id=str(uuid.uuid4()),
                sequence=2,
                relative_time="Mid-Horizon",
                title="Zero-Debt Focused Delivery",
                description="Attention focused exclusively on single highest-value objective.",
                confidence="HIGH"
            ),
            ScenarioEvent(
                id=str(uuid.uuid4()),
                sequence=3,
                relative_time=f"End of {horizon}",
                title="High Mastery with Minimal Overhead",
                description=f"Backlog trimmed to {alt_backlog} core tasks with near-zero deadline friction.",
                confidence="HIGH"
            )
        ]

        alt_scenario = FutureScenario(
            id=alt_id,
            trajectory_type="ALTERNATIVE",
            title=f"Alternative Trajectory ({horizon}) — Essentialist Focus",
            summary=(
                f"If you prune secondary commitments and focus exclusively on core deliverables, backlog drops to {alt_backlog} "
                f"with minimal deadline friction (8% risk) while still delivering {alt_completions} high-impact tasks."
            ),
            horizon=horizon,
            probability=alt_prob,
            confidence="HIGH",
            evidence=[
                "Scope reduction prevents cognitive fragmentation",
                "Quality of deliverables increases as task switching decreases"
            ],
            events=alt_events
        )

        # Persist scenarios to database
        for sc in (current_scenario, improved_scenario, alt_scenario):
            try:
                data = sc.model_dump(exclude={"events"})
                data["user_id"] = self.user_id
                self.supabase.table("future_scenarios").insert(data).execute()
                for ev in sc.events:
                    ev_dict = ev.model_dump()
                    ev_dict["scenario_id"] = sc.id
                    self.supabase.table("scenario_events").insert(ev_dict).execute()
            except Exception:
                pass

        return MultipleFuturesResponse(
            horizon=horizon,
            current_trajectory=current_scenario,
            improved_trajectory=improved_scenario,
            alternative_trajectory=alt_scenario
        )

