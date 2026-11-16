from supabase import Client
from typing import List, Dict, Any, Optional
from datetime import datetime, timezone
import uuid
import logging

from app.schemas.companion import (
    CompanionPreferences,
    CompanionPreferencesUpdate,
    CompanionRoutine,
    CompanionRoutineCreate,
    CompanionRoutineUpdate,
    CompanionMilestone,
    CompanionActivity,
    CompanionProfileResponse
)
from app.services.companion.personality import PersonalityEngine, PROGRESSION_STAGES, PERSONALITY_PRESETS
from app.services.companion.routine_engine import RoutineEngine
from app.services.companion.memory_continuity import MemoryContinuityEngine

logger = logging.getLogger(__name__)

class CompanionService:
    def __init__(self, supabase: Client, user_id: str):
        self.supabase = supabase
        self.user_id = user_id

    # -------------------------------------------------------------------------
    # 1. Preferences & Mascot Customization
    # -------------------------------------------------------------------------
    def get_preferences(self) -> CompanionPreferences:
        res = self.supabase.table("companion_preferences").select("*").eq("user_id", self.user_id).execute()
        if res.data and len(res.data) > 0:
            return CompanionPreferences(**res.data[0])

        # Create default preferences
        default_pref = {
            "id": str(uuid.uuid4()),
            "user_id": self.user_id,
            "personality": "FRIENDLY",
            "communication_style": "BALANCED",
            "proactivity_level": "BALANCED",
            "encouragement_style": "GENTLE",
            "formality": "NEUTRAL",
            "mascot_theme": "PURPLE",
            "expression_style": "EXPRESSIVE",
            "animation_level": "NORMAL",
            "sound_enabled": False,
            "quiet_mode": False,
            "quiet_hours_start": "22:00",
            "quiet_hours_end": "08:00",
            "progression_enabled": True,
            "current_stage": 1,
            "interaction_count": 0,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat()
        }
        self.supabase.table("companion_preferences").insert(default_pref).execute()
        return CompanionPreferences(**default_pref)

    def update_preferences(self, updates: CompanionPreferencesUpdate) -> CompanionPreferences:
        curr = self.get_preferences()
        update_dict = updates.model_dump(exclude_unset=True)
        update_dict["updated_at"] = datetime.now(timezone.utc).isoformat()

        # If preset changed, auto-apply matching traits unless overridden
        if "personality" in update_dict and update_dict["personality"] in PERSONALITY_PRESETS:
            preset = PERSONALITY_PRESETS[update_dict["personality"]]
            if "communication_style" not in update_dict:
                update_dict["communication_style"] = preset["communication_style"]
            if "encouragement_style" not in update_dict:
                update_dict["encouragement_style"] = preset["encouragement_style"]
            if "formality" not in update_dict:
                update_dict["formality"] = preset["formality"]

        self.supabase.table("companion_preferences").update(update_dict).eq("user_id", self.user_id).execute()
        return self.get_preferences()

    # -------------------------------------------------------------------------
    # 2. Progression & Milestones
    # -------------------------------------------------------------------------
    def increment_interaction(self) -> int:
        prefs = self.get_preferences()
        new_count = prefs.interaction_count + 1
        milestones = self.get_milestones()

        new_stage = PersonalityEngine.evaluate_progression(
            interaction_count=new_count,
            milestone_count=len(milestones),
            progression_enabled=prefs.progression_enabled
        )

        update_payload: Dict[str, Any] = {
            "interaction_count": new_count,
            "updated_at": datetime.now(timezone.utc).isoformat()
        }
        if new_stage != prefs.current_stage:
            update_payload["current_stage"] = new_stage
            stage_info = PersonalityEngine.get_stage_info(new_stage)
            self.record_milestone(
                milestone_type="STAGE_UPGRADE",
                title=f"Evolution to {stage_info['name']}",
                description=f"Unlocked {stage_info['name']} based on sustained companion interaction.",
                stage_unlocked=new_stage
            )

        self.supabase.table("companion_preferences").update(update_payload).eq("user_id", self.user_id).execute()
        return new_count

    def get_milestones(self) -> List[CompanionMilestone]:
        res = self.supabase.table("companion_milestones").select("*").eq("user_id", self.user_id).order("achieved_at", desc=True).execute()
        return [CompanionMilestone(**item) for item in (res.data or [])]

    def record_milestone(self, milestone_type: str, title: str, description: str, stage_unlocked: int = 1) -> CompanionMilestone:
        payload = {
            "id": str(uuid.uuid4()),
            "user_id": self.user_id,
            "milestone_type": milestone_type,
            "title": title,
            "description": description,
            "stage_unlocked": stage_unlocked,
            "achieved_at": datetime.now(timezone.utc).isoformat()
        }
        self.supabase.table("companion_milestones").insert(payload).execute()
        self.record_activity("MILESTONE", f"Achieved milestone: {title}", {"milestone_type": milestone_type})
        return CompanionMilestone(**payload)

    # -------------------------------------------------------------------------
    # 3. Companion Activity History
    # -------------------------------------------------------------------------
    def get_activity(self, limit: int = 20) -> List[CompanionActivity]:
        res = self.supabase.table("companion_activity").select("*").eq("user_id", self.user_id).order("created_at", desc=True).limit(limit).execute()
        return [CompanionActivity(**item) for item in (res.data or [])]

    def record_activity(self, activity_type: str, summary: str, metadata: Optional[Dict[str, Any]] = None):
        payload = {
            "id": str(uuid.uuid4()),
            "user_id": self.user_id,
            "activity_type": activity_type,
            "summary": summary,
            "metadata": metadata or {},
            "created_at": datetime.now(timezone.utc).isoformat()
        }
        self.supabase.table("companion_activity").insert(payload).execute()

    # -------------------------------------------------------------------------
    # 4. Adaptive Personal Routines
    # -------------------------------------------------------------------------
    def get_routines(self) -> List[CompanionRoutine]:
        res = self.supabase.table("companion_routines").select("*").eq("user_id", self.user_id).order("created_at", desc=False).execute()
        return [CompanionRoutine(**item) for item in (res.data or [])]

    def create_routine(self, req: CompanionRoutineCreate) -> CompanionRoutine:
        payload = {
            "id": str(uuid.uuid4()),
            "user_id": self.user_id,
            "routine_name": req.routine_name,
            "routine_type": req.routine_type,
            "preferred_time": req.preferred_time,
            "days_of_week": req.days_of_week,
            "timezone": req.timezone,
            "enabled": req.enabled,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat()
        }
        self.supabase.table("companion_routines").insert(payload).execute()
        self.record_activity("ROUTINE_CREATED", f"Created personal routine: {req.routine_name} ({req.preferred_time})")

        # Check if first routine created milestone
        routines = self.get_routines()
        if len(routines) == 1:
            self.record_milestone("FIRST_ROUTINE", "First Personal Routine Established", f"Configured {req.routine_name} routine.")

        return CompanionRoutine(**payload)

    def update_routine(self, routine_id: str, updates: CompanionRoutineUpdate) -> CompanionRoutine:
        update_dict = updates.model_dump(exclude_unset=True)
        update_dict["updated_at"] = datetime.now(timezone.utc).isoformat()
        self.supabase.table("companion_routines").update(update_dict).eq("id", routine_id).eq("user_id", self.user_id).execute()
        res = self.supabase.table("companion_routines").select("*").eq("id", routine_id).eq("user_id", self.user_id).execute()
        return CompanionRoutine(**res.data[0])

    def delete_routine(self, routine_id: str) -> None:
        self.supabase.table("companion_routines").delete().eq("id", routine_id).eq("user_id", self.user_id).execute()
        self.record_activity("ROUTINE_DELETED", f"Deleted routine {routine_id}")

    def evaluate_due_routines(self) -> List[Dict[str, Any]]:
        prefs = self.get_preferences()
        routines = self.get_routines()
        due_list = []

        for r in routines:
            r_dict = r.model_dump()
            if RoutineEngine.is_routine_due(
                routine=r_dict,
                quiet_mode=prefs.quiet_mode,
                quiet_start=prefs.quiet_hours_start,
                quiet_end=prefs.quiet_hours_end
            ):
                template = RoutineEngine.ROUTINE_TEMPLATES.get(
                    r.routine_type,
                    {"title": f"🐾 {r.routine_name}", "message": f"Time for your scheduled {r.routine_name}."}
                )
                due_list.append({
                    "routine": r_dict,
                    "title": template["title"],
                    "message": template["message"]
                })
                # Update last_run_at to prevent retriggering
                self.supabase.table("companion_routines").update({
                    "last_run_at": datetime.now(timezone.utc).isoformat()
                }).eq("id", r.id).execute()

        return due_list

    # -------------------------------------------------------------------------
    # 5. Memory Continuity & Evolution
    # -------------------------------------------------------------------------
    def update_memory(self, memory_id: str, category: Optional[str] = None, content: Optional[str] = None, importance: Optional[int] = None, is_confirmed: Optional[bool] = None, provenance: Optional[str] = None) -> Dict[str, Any]:
        update_payload: Dict[str, Any] = {"updated_at": datetime.now(timezone.utc).isoformat()}
        if category is not None:
            update_payload["category"] = category
        if content is not None:
            update_payload["content"] = content
        if importance is not None:
            update_payload["importance"] = importance
        if is_confirmed is not None:
            update_payload["is_confirmed"] = is_confirmed
        if provenance is not None:
            update_payload["provenance"] = provenance

        self.supabase.table("memories").update(update_payload).eq("id", memory_id).eq("user_id", self.user_id).execute()
        res = self.supabase.table("memories").select("*").eq("id", memory_id).eq("user_id", self.user_id).execute()
        if res.data and len(res.data) > 0:
            return res.data[0]
        return update_payload

    def get_relevant_memories(self, query: str, limit: int = 5) -> List[Dict[str, Any]]:
        res = self.supabase.table("memories").select("*").eq("user_id", self.user_id).order("importance", desc=True).limit(50).execute()
        memories = res.data or []
        return MemoryContinuityEngine.select_relevant_memories(memories, query, limit=limit)

    # -------------------------------------------------------------------------
    # 6. Companion Profile Overview
    # -------------------------------------------------------------------------
    def get_profile(self) -> CompanionProfileResponse:
        prefs = self.get_preferences()
        routines = self.get_routines()
        milestones = self.get_milestones()
        stage_info = PersonalityEngine.get_stage_info(prefs.current_stage)
        preset = PERSONALITY_PRESETS.get(prefs.personality, PERSONALITY_PRESETS["FRIENDLY"])

        # Check if quiet hours currently apply
        local_now = RoutineEngine.get_local_now("UTC")
        curr_time_str = local_now.strftime("%H:%M")
        is_quiet = prefs.quiet_mode or RoutineEngine.is_in_quiet_hours(curr_time_str, prefs.quiet_hours_start, prefs.quiet_hours_end)

        return CompanionProfileResponse(
            preferences=prefs,
            current_stage=prefs.current_stage,
            stage_name=stage_info["name"],
            interaction_count=prefs.interaction_count,
            active_routines_count=len([r for r in routines if r.enabled]),
            total_milestones=len(milestones),
            quiet_mode_active=is_quiet,
            personality_description=preset["description"],
            available_stages=PROGRESSION_STAGES
        )

