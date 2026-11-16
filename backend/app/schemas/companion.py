from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any, Literal
from datetime import datetime

# ==============================================================================
# PHASE 10: LIVING AI COMPANION SCHEMAS
# ==============================================================================

PersonalityType = Literal['CALM', 'FRIENDLY', 'PROFESSIONAL', 'PLAYFUL', 'FOCUSED', 'CUSTOM']
CommunicationStyle = Literal['CONCISE', 'BALANCED', 'DETAILED']
ProactivityLevel = Literal['LOW', 'BALANCED', 'PROACTIVE']
EncouragementStyle = Literal['GENTLE', 'ENERGETIC', 'PRAGMATIC']
FormalityLevel = Literal['CASUAL', 'NEUTRAL', 'FORMAL']
MascotTheme = Literal['PURPLE', 'CYAN', 'AMBER', 'EMERALD', 'ROSE', 'INDIGO']
ExpressionStyle = Literal['EXPRESSIVE', 'CLASSIC', 'MINIMAL']
AnimationLevel = Literal['MINIMAL', 'NORMAL', 'LIVELY']

class CompanionPreferencesBase(BaseModel):
    personality: str = "FRIENDLY"
    communication_style: str = "BALANCED"
    proactivity_level: str = "BALANCED"
    encouragement_style: str = "GENTLE"
    formality: str = "NEUTRAL"
    mascot_theme: str = "PURPLE"
    expression_style: str = "EXPRESSIVE"
    animation_level: str = "NORMAL"
    sound_enabled: bool = False
    quiet_mode: bool = False
    quiet_hours_start: str = "22:00"
    quiet_hours_end: str = "08:00"
    progression_enabled: bool = True
    current_stage: int = 1
    interaction_count: int = 0

class CompanionPreferences(CompanionPreferencesBase):
    id: Optional[str] = None
    user_id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class CompanionPreferencesUpdate(BaseModel):
    personality: Optional[str] = None
    communication_style: Optional[str] = None
    proactivity_level: Optional[str] = None
    encouragement_style: Optional[str] = None
    formality: Optional[str] = None
    mascot_theme: Optional[str] = None
    expression_style: Optional[str] = None
    animation_level: Optional[str] = None
    sound_enabled: Optional[bool] = None
    quiet_mode: Optional[bool] = None
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None
    progression_enabled: Optional[bool] = None
    current_stage: Optional[int] = None

class CompanionRoutineCreate(BaseModel):
    routine_name: str
    routine_type: str  # MORNING_BRIEFING, DAILY_PLANNING, WORKDAY_CHECK_IN, EVENING_REVIEW, WEEKLY_REVIEW, GOAL_CHECK_IN
    preferred_time: str  # HH:MM format e.g. "09:00"
    days_of_week: List[str] = ["MON", "TUE", "WED", "THU", "FRI"]
    timezone: str = "UTC"
    enabled: bool = True

class CompanionRoutineUpdate(BaseModel):
    routine_name: Optional[str] = None
    routine_type: Optional[str] = None
    preferred_time: Optional[str] = None
    days_of_week: Optional[List[str]] = None
    timezone: Optional[str] = None
    enabled: Optional[bool] = None

class CompanionRoutine(BaseModel):
    id: str
    user_id: str
    routine_name: str
    routine_type: str
    preferred_time: str
    days_of_week: List[str]
    timezone: str
    enabled: bool
    last_run_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class CompanionMilestone(BaseModel):
    id: str
    user_id: str
    milestone_type: str
    title: str
    description: str
    stage_unlocked: int = 1
    achieved_at: datetime

    class Config:
        from_attributes = True

class CompanionActivity(BaseModel):
    id: str
    user_id: str
    activity_type: str
    summary: str
    metadata: Dict[str, Any] = {}
    created_at: datetime

    class Config:
        from_attributes = True

class CompanionProfileResponse(BaseModel):
    preferences: CompanionPreferences
    current_stage: int
    stage_name: str
    interaction_count: int
    active_routines_count: int
    total_milestones: int
    quiet_mode_active: bool
    personality_description: str
    available_stages: List[Dict[str, Any]]

