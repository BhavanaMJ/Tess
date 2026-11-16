from supabase import Client
from typing import Optional
from app.schemas.future import FuturePrediction
from app.schemas.proactive import DecisionResult
from app.services.proactive.value_scorer import ValueScorer
from app.services.proactive.cooldown import CooldownManager

class DecisionEngine:
    THRESHOLD = 0.5  # Product threshold for intervention

    @staticmethod
    def should_intervene(supabase: Client, user_id: str, prediction: FuturePrediction, prefs: dict) -> DecisionResult:
        if not prefs.get("proactive_enabled", True):
            return DecisionResult(should_intervene=False, value_score=0, priority="LOW", reason="Proactive disabled", intervention_type="NONE", title="", message="")

        score = ValueScorer.calculate_score(prediction)
        if score < DecisionEngine.THRESHOLD:
            return DecisionResult(should_intervene=False, value_score=score, priority="LOW", reason="Below threshold", intervention_type="NONE", title="", message="")

        priority = "MEDIUM"
        if score > 0.8:
            priority = "HIGH"

        min_priority = prefs.get("minimum_intervention_priority", "MEDIUM")
        if min_priority == "HIGH" and priority != "HIGH":
            return DecisionResult(should_intervene=False, value_score=score, priority=priority, reason="Below user priority threshold", intervention_type="NONE", title="", message="")

        intervention_type = "FUTURE_RISK" if prediction.prediction_type == "RISK" else "POSITIVE_MOMENTUM"
        
        if CooldownManager.is_on_cooldown(supabase, user_id, prediction.id, intervention_type):
            return DecisionResult(should_intervene=False, value_score=score, priority=priority, reason="On cooldown", intervention_type="NONE", title="", message="")

        # Determine messaging
        if intervention_type == "FUTURE_RISK":
            title = "🐾 Tomorrow-you may have a problem"
            message = "I think this deserves your attention before tomorrow."
            if "deadline" in " ".join(prediction.evidence).lower():
                intervention_type = "DEADLINE_RISK"
                title = "🐾 This deadline is getting closer"
            elif "overdue" in " ".join(prediction.evidence).lower():
                intervention_type = "OVERDUE_RISK"
                title = "🐾 This task is becoming a bigger problem"
        else:
            title = "🐾 You're creating a better tomorrow"
            message = "You're creating a good trajectory. Keep going."
            
        return DecisionResult(
            should_intervene=True,
            value_score=score,
            priority=priority,
            reason="High-probability risk with actionable context",
            intervention_type=intervention_type,
            title=title,
            message=message
        )
