import uuid
from typing import List
from app.schemas.future import FuturePrediction, FutureScenario, ScenarioEvent

class ScenarioSimulator:
    @staticmethod
    def simulate_current_trajectory(predictions: List[FuturePrediction], horizon: str) -> FutureScenario:
        # Filter predictions by horizon if necessary, for now we assume they are already filtered
        active_preds = [p for p in predictions if p.time_horizon == horizon]
        
        if not active_preds:
            return FutureScenario(
                id=str(uuid.uuid4()),
                trajectory_type="CURRENT_TRAJECTORY",
                title="Stable Trajectory",
                summary="No significant risks or momentum detected. Workload is stable.",
                horizon=horizon,
                probability=0.8,
                confidence="HIGH",
                evidence=["No active predictive patterns."],
                events=[
                    ScenarioEvent(id=str(uuid.uuid4()), sequence=1, relative_time="Morning", title="Routine starts", description="You begin your day with a standard workload.", confidence="HIGH"),
                    ScenarioEvent(id=str(uuid.uuid4()), sequence=2, relative_time="End of day", title="Steady progress", description="Your active workload remains relatively unchanged.", confidence="HIGH")
                ]
            )
            
        # Compile evidence
        evidence = []
        for p in active_preds:
            evidence.extend(p.evidence)
            
        # Deduplicate evidence
        evidence = list(set(evidence))
        
        # Determine overall trajectory type
        has_risk = any(p.prediction_type == "RISK" for p in active_preds)
        trajectory_type = "CURRENT_TRAJECTORY"
        
        if has_risk:
            title = "Increasing Pressure"
            summary = "Based on your current trajectory, deadline pressure is likely to increase."
            prob = max((p.probability for p in active_preds if p.prediction_type == "RISK"), default=0.7)
            conf = "HIGH" if prob > 0.8 else "MEDIUM"
            
            events = [
                ScenarioEvent(id=str(uuid.uuid4()), sequence=1, relative_time="Morning", title="Existing workload carries over", description="You begin the day with unresolved tasks.", confidence="HIGH"),
                ScenarioEvent(id=str(uuid.uuid4()), sequence=2, relative_time="Later in the day", title="Pressure builds", description="The existing workload competes with incoming tasks.", confidence="MEDIUM"),
                ScenarioEvent(id=str(uuid.uuid4()), sequence=3, relative_time="End of day", title="Backlog grows", description="Without intervention, the total active tasks increase.", confidence="MEDIUM")
            ]
        else:
            title = "Positive Momentum"
            summary = "If you continue at this pace, your active workload will decrease."
            prob = max((p.probability for p in active_preds if p.prediction_type == "POSITIVE"), default=0.7)
            conf = "HIGH" if prob > 0.8 else "MEDIUM"
            
            events = [
                ScenarioEvent(id=str(uuid.uuid4()), sequence=1, relative_time="Morning", title="Productive start", description="You maintain your recent completion momentum.", confidence="HIGH"),
                ScenarioEvent(id=str(uuid.uuid4()), sequence=2, relative_time="Later in the day", title="Clearing the queue", description="Tasks are completed ahead of deadline pressure.", confidence="MEDIUM"),
                ScenarioEvent(id=str(uuid.uuid4()), sequence=3, relative_time="End of day", title="Lighter workload", description="You finish with fewer active tasks than you started.", confidence="MEDIUM")
            ]
            
        return FutureScenario(
            id=str(uuid.uuid4()),
            trajectory_type=trajectory_type,
            title=title,
            summary=summary,
            horizon=horizon,
            probability=prob,
            confidence=conf,
            evidence=evidence,
            events=events
        )
