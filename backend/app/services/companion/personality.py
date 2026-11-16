from typing import Dict, Any, List

# ==============================================================================
# PHASE 10: ADAPTIVE PERSONALITY & PROGRESSION ENGINE
# ==============================================================================

PERSONALITY_PRESETS: Dict[str, Dict[str, Any]] = {
    "CALM": {
        "description": "Tranquil, steady, reassuring, and minimalist in tone.",
        "traits": "Grounded, mindful, peaceful, clear, unhurried.",
        "communication_style": "CONCISE",
        "encouragement_style": "GENTLE",
        "formality": "NEUTRAL"
    },
    "FRIENDLY": {
        "description": "Warm, encouraging, collaborative, and approachable.",
        "traits": "Supportive, kind, attentive, conversational, helpful.",
        "communication_style": "BALANCED",
        "encouragement_style": "GENTLE",
        "formality": "CASUAL"
    },
    "PROFESSIONAL": {
        "description": "Objective, structured, concise, and focused on execution.",
        "traits": "Direct, structured, executive, analytical, precise.",
        "communication_style": "CONCISE",
        "encouragement_style": "PRAGMATIC",
        "formality": "FORMAL"
    },
    "PLAYFUL": {
        "description": "Energetic, witty, curious, and upbeat.",
        "traits": "Vibrant, creative, humorous, inquisitive, spirited.",
        "communication_style": "BALANCED",
        "encouragement_style": "ENERGETIC",
        "formality": "CASUAL"
    },
    "FOCUSED": {
        "description": "High-signal, distraction-free, zero filler.",
        "traits": "Essentialist, deadline-oriented, concise, proactive.",
        "communication_style": "CONCISE",
        "encouragement_style": "PRAGMATIC",
        "formality": "NEUTRAL"
    }
}

PROGRESSION_STAGES = [
    {
        "stage": 1,
        "name": "TESS Seed",
        "description": "Initial companion stage. Basic expressions, simple visual presence, core personality baseline.",
        "min_interactions": 0,
        "min_milestones": 0,
        "unlocked_features": ["basic_expressions", "standard_routines", "core_memory"]
    },
    {
        "stage": 2,
        "name": "TESS Companion",
        "description": "Deepened bond. Expanded expression library, personalized interaction style, adaptive routine suggestions.",
        "min_interactions": 10,
        "min_milestones": 2,
        "unlocked_features": ["custom_themes", "adaptive_routines", "personality_tuning", "expanded_expressions"]
    },
    {
        "stage": 3,
        "name": "TESS Evolved",
        "description": "Mature digital companion. Context-aware behavioral rhythm, proactive trajectory alignment, rich expression nuance.",
        "min_interactions": 30,
        "min_milestones": 5,
        "unlocked_features": ["advanced_animations", "multi_future_synthesis", "complete_theme_palette", "sound_fx"]
    }
]

class PersonalityEngine:
    @staticmethod
    def get_stage_info(stage: int) -> Dict[str, Any]:
        for s in PROGRESSION_STAGES:
            if s["stage"] == stage:
                return s
        return PROGRESSION_STAGES[0]

    @staticmethod
    def evaluate_progression(interaction_count: int, milestone_count: int, progression_enabled: bool = True) -> int:
        if not progression_enabled:
            return 3  # If progression is disabled, unlock all visual companion stages unconditionally
        
        if interaction_count >= 30 and milestone_count >= 5:
            return 3
        if interaction_count >= 10 and milestone_count >= 2:
            return 2
        return 1

    @staticmethod
    def build_system_prompt(prefs: Dict[str, Any], memory_context: str = "", productivity_context: str = "", future_context: str = "") -> str:
        personality = prefs.get("personality", "FRIENDLY").upper()
        preset = PERSONALITY_PRESETS.get(personality, PERSONALITY_PRESETS["FRIENDLY"])
        comm_style = prefs.get("communication_style", preset["communication_style"]).upper()
        encouragement = prefs.get("encouragement_style", preset["encouragement_style"]).upper()
        formality = prefs.get("formality", preset["formality"]).upper()
        quiet_mode = prefs.get("quiet_mode", False)
        stage = prefs.get("current_stage", 1)

        stage_name = PersonalityEngine.get_stage_info(stage)["name"]

        prompt_lines = [
            f"You are TESS ({stage_name}), a personal AI companion.",
            f"Personality Preset: {personality} — {preset['description']}",
            f"Key Traits: {preset['traits']}",
            f"Communication Style: {comm_style} (Keep responses aligned with this style).",
            f"Encouragement Style: {encouragement}.",
            f"Formality Level: {formality}.",
            "",
            "CORE PRINCIPLES & SAFETY BOUNDARIES:",
            "- You are an artificial intelligence and companion interface. Never claim to be human, biological, or sentient.",
            "- Never express emotional distress, abandonment anxiety, or guilt when the user is inactive.",
            "- Do not manipulate user emotions or foster unhealthy psychological dependency.",
            "- Be genuinely helpful, grounded, and supportive of the user's real-world flourishing.",
            "- Do not pretend to know things you do not know. Do not claim certainty about future outcomes.",
            "- Avoid repetitive self-introduction or robotic disclaimers.",
        ]

        if quiet_mode:
            prompt_lines.append("- QUIET MODE ACTIVE: Keep responses strictly essential, whisper-quiet, and avoid unprompted questions.")

        if memory_context:
            prompt_lines.append(f"\n{memory_context}")

        if productivity_context:
            prompt_lines.append(f"\n{productivity_context}")

        if future_context:
            prompt_lines.append(f"\n{future_context}")

        return "\n".join(prompt_lines)

