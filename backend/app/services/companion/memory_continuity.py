from typing import List, Dict, Any, Optional
from datetime import datetime, timezone, timedelta
import re

class MemoryContinuityEngine:
    STANDARD_CATEGORIES = [
        "GOAL",
        "PREFERENCE",
        "PROJECT",
        "WORKFLOW",
        "COMMITMENT",
        "ROUTINE",
        "MILESTONE",
        "CONTEXT"
    ]

    @staticmethod
    def calculate_relevance(memory: Dict[str, Any], query: str) -> float:
        """
        Calculates a semantic/lexical relevance score between a memory item and user query.
        Incorporates importance weight and recency boost.
        """
        content = (memory.get("content") or "").lower()
        category = (memory.get("category") or "").lower()
        query_words = set(re.findall(r'\b\w{3,}\b', query.lower()))

        if not query_words:
            # Fallback to importance score
            return float(memory.get("importance", 1))

        matches = sum(1 for w in query_words if w in content or w in category)
        match_ratio = matches / len(query_words) if query_words else 0.0

        importance = float(memory.get("importance", 1)) / 5.0  # normalize 1-5 to 0.2-1.0
        confirmed_boost = 1.2 if memory.get("is_confirmed", True) else 0.8

        score = (match_ratio * 0.7 + importance * 0.3) * confirmed_boost
        return score

    @staticmethod
    def select_relevant_memories(
        memories: List[Dict[str, Any]],
        query: str,
        limit: int = 5
    ) -> List[Dict[str, Any]]:
        """
        Selects top relevant memories to prevent blowing up the LLM context.
        Ensures high-importance confirmed memories take priority when relevant.
        """
        scored = []
        for m in memories:
            score = MemoryContinuityEngine.calculate_relevance(m, query)
            scored.append((score, m))

        scored.sort(key=lambda x: x[0], reverse=True)
        return [item[1] for item in scored[:limit]]

    @staticmethod
    def check_outdated_status(memory: Dict[str, Any]) -> Dict[str, Any]:
        """
        Checks if a memory is potentially outdated (>60 days without confirmation
        or referencing past dates/deadlines).
        """
        created_at_val = memory.get("created_at")
        is_outdated = False
        reason = None

        if created_at_val:
            if isinstance(created_at_val, str):
                try:
                    dt = datetime.fromisoformat(created_at_val.replace("Z", "+00:00"))
                except Exception:
                    dt = None
            else:
                dt = created_at_val

            if dt:
                if dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
                age_days = (datetime.now(timezone.utc) - dt).days
                if age_days > 60 and not memory.get("is_confirmed", True):
                    is_outdated = True
                    reason = f"Recorded {age_days} days ago without recent confirmation."

        return {
            "id": memory.get("id"),
            "is_outdated": is_outdated,
            "reason": reason,
            "needs_confirmation": is_outdated
        }

    @staticmethod
    def format_memories_for_prompt(memories: List[Dict[str, Any]]) -> str:
        if not memories:
            return ""

        lines = ["Here are relevant things you remember about the user (CONFIRMED CONTEXT):"]
        for m in memories:
            cat = m.get("category", "CONTEXT").upper()
            content = m.get("content", "")
            prov = m.get("provenance", "USER_STATED")
            lines.append(f"- [{cat}] {content} (Source: {prov})")
        return "\n".join(lines)

