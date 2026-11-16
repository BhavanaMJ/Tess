from typing import List
from app.schemas.future import FuturePattern, FutureScenarioBase
from app.services.future.confidence import ConfidenceEngine

class ScenarioEngine:
    @staticmethod
    def generate(patterns: List[FuturePattern]) -> List[FutureScenarioBase]:
        scenarios = []
        
        for p in patterns:
            prob, conf = ConfidenceEngine.calculate(p.name, len(p.evidence))
            
            if p.name == "OVERDUE_ACCUMULATION":
                scenarios.append(FutureScenarioBase(
                    prediction_type="RISK",
                    title="Overdue Workload Increase",
                    description="Your overdue workload may increase if the current pattern continues.",
                    probability=prob,
                    confidence=conf,
                    time_horizon="24h",
                    evidence=p.evidence,
                    reasoning="Detected existing overdue tasks. Without intervention, they will carry over."
                ))
            elif p.name == "DEADLINE_CLUSTER":
                scenarios.append(FutureScenarioBase(
                    prediction_type="RISK",
                    title="Imminent Deadline Pressure",
                    description="You are likely to face high deadline pressure soon.",
                    probability=prob,
                    confidence=conf,
                    time_horizon="3d",
                    evidence=p.evidence,
                    reasoning="Multiple tasks are due within the next few days."
                ))
            elif p.name == "COMPLETION_MOMENTUM":
                scenarios.append(FutureScenarioBase(
                    prediction_type="POSITIVE",
                    title="Workload Decrease",
                    description="Your active workload may decrease if your recent completion pace continues.",
                    probability=prob,
                    confidence=conf,
                    time_horizon="7d",
                    evidence=p.evidence,
                    reasoning="Recent task completions indicate a strong positive trajectory."
                ))
            elif p.name == "STALLED_WORK":
                scenarios.append(FutureScenarioBase(
                    prediction_type="NEUTRAL",
                    title="Task Stagnation",
                    description="Some work packages are likely to remain stalled without active review.",
                    probability=prob,
                    confidence=conf,
                    time_horizon="7d",
                    evidence=p.evidence,
                    reasoning="Tasks have remained untouched for an extended period."
                ))
                
        return scenarios
