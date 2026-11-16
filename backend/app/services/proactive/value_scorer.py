from app.schemas.future import FuturePrediction

class ValueScorer:
    @staticmethod
    def calculate_score(prediction: FuturePrediction) -> float:
        # Heuristic value scoring: Impact * Probability * Urgency
        impact = 0.5
        urgency = 0.5
        
        ev_lower = " ".join(prediction.evidence).lower()
        
        # Impact
        if "high priority" in ev_lower or "missed deadline" in ev_lower:
            impact = 1.0
        elif "overdue" in ev_lower:
            impact = 0.8
            
        # Urgency based on horizon
        if prediction.time_horizon == "24h":
            urgency = 1.0
        elif prediction.time_horizon == "3d":
            urgency = 0.7
        else:
            urgency = 0.4
            
        # Actionability could also be factored in (e.g. if we have a specific task to act on)
        actionability = 1.0 if "task" in ev_lower else 0.8
            
        probability = prediction.probability or 0.5
        
        score = impact * probability * urgency * actionability
        return min(score, 1.0)
