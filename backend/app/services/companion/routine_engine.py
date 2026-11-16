from typing import List, Dict, Any, Optional
from datetime import datetime, timezone, timedelta
import zoneinfo
import logging

logger = logging.getLogger(__name__)

class RoutineEngine:
    ROUTINE_TEMPLATES = {
        "MORNING_BRIEFING": {
            "title": "🌅 Morning Briefing",
            "message": "Good morning! Ready for today's high-leverage priorities and schedule check?",
            "default_time": "08:30"
        },
        "DAILY_PLANNING": {
            "title": "📋 Daily Planning Session",
            "message": "Let's review today's commitments and align on your top priority tasks.",
            "default_time": "09:30"
        },
        "WORKDAY_CHECK_IN": {
            "title": "⚡ Midday Workday Check-in",
            "message": "Midday pulse: How is your momentum holding up against today's target packages?",
            "default_time": "14:00"
        },
        "EVENING_REVIEW": {
            "title": "🌙 Evening Review & Wind-down",
            "message": "Wrapping up for the day? Would you like to review today's accomplishments?",
            "default_time": "18:30"
        },
        "WEEKLY_REVIEW": {
            "title": "📊 Weekly Strategic Review",
            "message": "Let's reflect on your weekly velocity, completed milestones, and next week's horizon.",
            "default_time": "17:00"
        },
        "GOAL_CHECK_IN": {
            "title": "🎯 Goal Alignment Check",
            "message": "Checking in: Are your active tasks effectively advancing your primary goals?",
            "default_time": "11:00"
        }
    }

    @staticmethod
    def is_in_quiet_hours(current_time_str: str, quiet_start: str = "22:00", quiet_end: str = "08:00") -> bool:
        """
        Determines whether the given HH:MM time falls inside the quiet hours window.
        Handles overnight spans (e.g. 22:00 to 08:00).
        """
        try:
            curr_h, curr_m = map(int, current_time_str.split(":"))
            start_h, start_m = map(int, quiet_start.split(":"))
            end_h, end_m = map(int, quiet_end.split(":"))

            curr_mins = curr_h * 60 + curr_m
            start_mins = start_h * 60 + start_m
            end_mins = end_h * 60 + end_m

            if start_mins <= end_mins:
                # Same day quiet period e.g. 13:00 to 15:00
                return start_mins <= curr_mins < end_mins
            else:
                # Overnight quiet period e.g. 22:00 to 08:00
                return curr_mins >= start_mins or curr_mins < end_mins
        except Exception:
            return False

    @staticmethod
    def get_local_now(tz_str: str = "UTC") -> datetime:
        try:
            tz = zoneinfo.ZoneInfo(tz_str)
            return datetime.now(tz)
        except Exception:
            return datetime.now(timezone.utc)

    @staticmethod
    def is_routine_due(
        routine: Dict[str, Any],
        quiet_mode: bool = False,
        quiet_start: str = "22:00",
        quiet_end: str = "08:00",
        now_dt: Optional[datetime] = None
    ) -> bool:
        if not routine.get("enabled", True):
            return False

        if quiet_mode:
            return False

        user_tz = routine.get("timezone", "UTC")
        local_now = now_dt or RoutineEngine.get_local_now(user_tz)
        curr_time_str = local_now.strftime("%H:%M")

        # Check quiet hours
        if RoutineEngine.is_in_quiet_hours(curr_time_str, quiet_start, quiet_end):
            return False

        # Check day of week
        weekday_map = {0: "MON", 1: "TUE", 2: "WED", 3: "THU", 4: "FRI", 5: "SAT", 6: "SUN"}
        curr_day = weekday_map.get(local_now.weekday(), "MON")
        days = routine.get("days_of_week") or ["MON", "TUE", "WED", "THU", "FRI"]
        if curr_day not in days:
            return False

        # Check time match (within +/- 30 min window)
        pref_time = routine.get("preferred_time", "09:00")
        try:
            curr_h, curr_m = map(int, curr_time_str.split(":"))
            pref_h, pref_m = map(int, pref_time.split(":"))
            diff_mins = abs((curr_h * 60 + curr_m) - (pref_h * 60 + pref_m))
            if diff_mins > 30 and diff_mins < (1440 - 30):
                return False
        except Exception:
            return False

        # Check last run deduplication (at least 8 hours cooldown)
        last_run = routine.get("last_run_at")
        if last_run:
            if isinstance(last_run, str):
                try:
                    last_run_dt = datetime.fromisoformat(last_run.replace("Z", "+00:00"))
                except Exception:
                    last_run_dt = None
            else:
                last_run_dt = last_run

            if last_run_dt:
                if last_run_dt.tzinfo is None:
                    last_run_dt = last_run_dt.replace(tzinfo=timezone.utc)
                if local_now.tzinfo is None:
                    local_now = local_now.replace(tzinfo=timezone.utc)
                if (local_now - last_run_dt).total_seconds() < 8 * 3600:
                    return False

        return True

