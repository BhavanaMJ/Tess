from typing import Tuple

class ConfidenceEngine:
    @staticmethod
    def calculate(pattern_name: str, evidence_count: int) -> Tuple[float, str]:
        # A heuristic mapping for Phase 3 to establish infrastructure without statistical ML
        
        base_probability = 0.5
        
        if pattern_name == "OVERDUE_ACCUMULATION":
            base_probability = 0.70 + (min(evidence_count, 3) * 0.05)
        elif pattern_name == "DEADLINE_CLUSTER":
            base_probability = 0.65 + (min(evidence_count, 3) * 0.05)
        elif pattern_name == "COMPLETION_MOMENTUM":
            base_probability = 0.80
        elif pattern_name == "STALLED_WORK":
            base_probability = 0.75
            
        prob = round(min(base_probability, 0.99), 2)
        
        if prob >= 0.8:
            confidence = "HIGH"
        elif prob >= 0.6:
            confidence = "MEDIUM"
        else:
            confidence = "LOW"
            
        return prob, confidence
