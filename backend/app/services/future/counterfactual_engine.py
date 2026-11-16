import uuid
from typing import Optional
from app.schemas.future import FutureScenario, Counterfactual

class CounterfactualEngine:
    @staticmethod
    def generate_alternative(scenario: FutureScenario) -> Optional[Counterfactual]:
        # Generate an alternative trajectory if the current one has risks
        if "Pressure" in scenario.title or "overdue" in " ".join(scenario.evidence).lower():
            return Counterfactual(
                id=str(uuid.uuid4()),
                action="Complete the highest-priority overdue task today.",
                assumption="The task is completed, clearing immediate backlog.",
                expected_effect="Reduces deadline pressure and opens capacity for new work tomorrow."
            )
            
        if "stalled" in " ".join(scenario.evidence).lower():
            return Counterfactual(
                id=str(uuid.uuid4()),
                action="Spend 15 minutes reviewing your stalled tasks.",
                assumption="Stalled tasks are either updated or closed.",
                expected_effect="Clears mental overhead and stagnant items from your active queue."
            )
            
        # If things are already positive, offer a generic accelerator or no alternative
        return Counterfactual(
            id=str(uuid.uuid4()),
            action="Maintain your current completion pace.",
            assumption="Focus remains on high priority items.",
            expected_effect="Ensures a consistently light workload and lower stress."
        )
