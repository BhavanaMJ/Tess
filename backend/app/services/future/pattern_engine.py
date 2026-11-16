from typing import List
from app.schemas.future import FutureSignal, FuturePattern

class PatternEngine:
    @staticmethod
    def evaluate(signals: List[FutureSignal]) -> List[FuturePattern]:
        patterns = []
        
        signal_dict = {s.name: s for s in signals}
        
        # 1. OVERDUE_ACCUMULATION
        if "overdue_tasks_count" in signal_dict:
            val = signal_dict["overdue_tasks_count"].value
            if val > 0:
                patterns.append(FuturePattern(
                    name="OVERDUE_ACCUMULATION",
                    evidence=[signal_dict["overdue_tasks_count"].description]
                ))
                
        # 2. DEADLINE_CLUSTER
        if "due_soon_count" in signal_dict:
            val = signal_dict["due_soon_count"].value
            if val >= 3:
                patterns.append(FuturePattern(
                    name="DEADLINE_CLUSTER",
                    evidence=[signal_dict["due_soon_count"].description, "High concentration of upcoming deadlines."]
                ))

        # 3. COMPLETION_MOMENTUM
        if "recent_completions" in signal_dict:
            val = signal_dict["recent_completions"].value
            if val >= 2:
                patterns.append(FuturePattern(
                    name="COMPLETION_MOMENTUM",
                    evidence=[signal_dict["recent_completions"].description, "Consistent recent work output."]
                ))
                
        # 4. STALLED_WORK
        if "stalled_tasks_count" in signal_dict:
            val = signal_dict["stalled_tasks_count"].value
            if val >= 2:
                patterns.append(FuturePattern(
                    name="STALLED_WORK",
                    evidence=[signal_dict["stalled_tasks_count"].description, "Multiple tasks show no recent activity."]
                ))
                
        return patterns
