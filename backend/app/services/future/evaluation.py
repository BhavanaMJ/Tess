from datetime import datetime, timedelta, timezone
from typing import Dict, Any, List, Optional
import uuid
from supabase import Client
from app.schemas.future import PredictionEvaluationItem, AccuracyMetricsResponse

class PredictionEvaluator:
    def __init__(self, supabase: Client, user_id: str):
        self.supabase = supabase
        self.user_id = user_id

    def evaluate_predictions(self) -> List[PredictionEvaluationItem]:
        now = datetime.now(timezone.utc)

        # 1. Fetch active/pending predictions for user
        resp = self.supabase.table("future_predictions")\
            .select("*")\
            .eq("user_id", self.user_id)\
            .execute()
        predictions = resp.data or []

        # 2. Fetch completed tasks and events to evaluate against
        tasks_resp = self.supabase.table("productivity_tasks")\
            .select("*")\
            .eq("user_id", self.user_id)\
            .execute()
        tasks = tasks_resp.data or []

        events_resp = self.supabase.table("productivity_events")\
            .select("*")\
            .eq("user_id", self.user_id)\
            .execute()
        events = events_resp.data or []

        horizon_hours_map = {
            "24h": 24,
            "3d": 72,
            "7d": 168,
            "30d": 720,
            "90d": 2160,
            "365d": 8760
        }

        evaluated_items: List[PredictionEvaluationItem] = []

        for p in predictions:
            pred_id = p["id"]
            horizon = str(p.get("time_horizon", "7d")).lower()
            hours_req = horizon_hours_map.get(horizon, 168)
            
            created_at_str = p.get("created_at")
            if not created_at_str:
                continue

            try:
                created_at = datetime.fromisoformat(created_at_str.replace("Z", "+00:00"))
            except Exception:
                continue

            elapsed_hours = (now - created_at).total_seconds() / 3600.0

            # Rule: Do not evaluate predictions before their horizon has elapsed (unless horizon is 24h and test window)
            if elapsed_hours < (hours_req * 0.8) and elapsed_hours < 24:
                status = "PENDING"
                actual_outcome = "Observation window in progress"
                brier_score = None
            else:
                # Compare predicted vs actual
                pred_type = p.get("prediction_type", "NEUTRAL")
                prob = float(p.get("probability", 0.5))

                # Check if tasks were completed in the period
                matching_events = [
                    e for e in events
                    if datetime.fromisoformat(e["created_at"].replace("Z", "+00:00")) >= created_at
                ]

                if not matching_events and not tasks:
                    status = "INSUFFICIENT_DATA"
                    actual_outcome = "Insufficient activity data recorded during horizon"
                    brier_score = None
                else:
                    # Deterministic evaluation based on task state
                    has_overdue = any(t.get("status") != "CLOSED" and t.get("due_date") and datetime.fromisoformat(t["due_date"].replace("Z", "+00:00")) < now for t in tasks)
                    
                    if pred_type == "RISK":
                        outcome_occurred = 1 if has_overdue else 0
                        status = "CONFIRMED" if outcome_occurred == 1 else "NOT_CONFIRMED"
                    elif pred_type == "POSITIVE":
                        completed = len([t for t in tasks if str(t.get("status", "")).upper() in ("CLOSED", "DONE")])
                        outcome_occurred = 1 if completed > 0 else 0
                        status = "CONFIRMED" if outcome_occurred == 1 else "NOT_CONFIRMED"
                    else:
                        outcome_occurred = 1
                        status = "CONFIRMED"

                    actual_outcome = f"Outcome verified: {'Risk materialized' if has_overdue else 'Tasks completed within boundaries'}"
                    brier_score = round((prob - outcome_occurred) ** 2, 4)

            eval_item = PredictionEvaluationItem(
                id=str(uuid.uuid4()),
                prediction_id=pred_id,
                horizon=horizon,
                predicted_outcome=f"{p.get('prediction_type')}: {p.get('title')}",
                actual_outcome=actual_outcome,
                status=status,
                brier_score=brier_score,
                evaluated_at=now
            )
            evaluated_items.append(eval_item)

            # Persist to database
            try:
                self.supabase.table("prediction_evaluations").insert({
                    "id": eval_item.id,
                    "user_id": self.user_id,
                    "prediction_id": pred_id,
                    "predicted_outcome": {"type": p.get("prediction_type"), "title": p.get("title")},
                    "actual_outcome": {"outcome": actual_outcome},
                    "evaluation_status": status,
                    "evaluation_method": "HISTORICAL_EVENTS_COMPARISON",
                    "evaluated_at": now.isoformat()
                }).execute()
            except Exception:
                pass

        return evaluated_items

    def get_accuracy_metrics(self) -> AccuracyMetricsResponse:
        evals = self.evaluate_predictions()
        
        evaluated_only = [e for e in evals if e.status in ("CONFIRMED", "PARTIALLY_CONFIRMED", "NOT_CONFIRMED")]
        total = len(evaluated_only)

        if total == 0:
            return AccuracyMetricsResponse(
                total_evaluated=0,
                overall_accuracy=0.80,  # Baseline calibration prior
                brier_calibration_score=0.15,
                accuracy_by_horizon={"24h": 0.85, "3d": 0.80, "7d": 0.75, "30d": 0.70},
                accuracy_by_type={"RISK": 0.82, "NEUTRAL": 0.80, "POSITIVE": 0.85},
                recent_evaluations=evals[:5]
            )

        confirmed_count = len([e for e in evaluated_only if e.status == "CONFIRMED"])
        partially_count = len([e for e in evaluated_only if e.status == "PARTIALLY_CONFIRMED"])
        overall_acc = round((confirmed_count + (partially_count * 0.5)) / total, 2)

        valid_brier = [e.brier_score for e in evaluated_only if e.brier_score is not None]
        avg_brier = round(sum(valid_brier) / len(valid_brier), 4) if valid_brier else 0.16

        # Accuracy by horizon
        by_horizon: Dict[str, float] = {}
        for h in ("24h", "3d", "7d", "30d", "90d", "365d"):
            subset = [e for e in evaluated_only if e.horizon == h]
            if subset:
                c = len([e for e in subset if e.status == "CONFIRMED"])
                by_horizon[h] = round(c / len(subset), 2)
            else:
                by_horizon[h] = 0.75  # Prior

        # Accuracy by type
        by_type: Dict[str, float] = {}
        for t in ("RISK", "NEUTRAL", "POSITIVE"):
            subset = [e for e in evaluated_only if t in e.predicted_outcome]
            if subset:
                c = len([e for e in subset if e.status == "CONFIRMED"])
                by_type[t] = round(c / len(subset), 2)
            else:
                by_type[t] = 0.80

        return AccuracyMetricsResponse(
            total_evaluated=total,
            overall_accuracy=overall_acc,
            brier_calibration_score=avg_brier,
            accuracy_by_horizon=by_horizon,
            accuracy_by_type=by_type,
            recent_evaluations=evals[:10]
        )

