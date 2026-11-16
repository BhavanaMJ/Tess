from supabase import Client
import uuid
from datetime import datetime, timedelta, timezone
from typing import Dict, Any, Optional
import hashlib
import json

def _get_param_fingerprint(params: Optional[Dict[str, Any]]) -> str:
    if not params:
        return ""
    sorted_str = json.dumps(params, sort_keys=True, default=str)
    return hashlib.sha256(sorted_str.encode()).hexdigest()[:16]

def _parse_iso_datetime(dt_str: str) -> datetime:
    try:
        # Standardize timezone handling
        cleaned = dt_str.replace("Z", "+00:00")
        dt = datetime.fromisoformat(cleaned)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except Exception:
        return datetime.now(timezone.utc)

class ConfirmationService:
    def __init__(self, supabase: Client, user_id: str):
        self.supabase = supabase
        self.user_id = user_id

    def request_confirmation(self, plan_id: str, step_id: str, summary: str, parameters: Optional[Dict[str, Any]] = None) -> str:
        conf_id = str(uuid.uuid4())
        param_fp = _get_param_fingerprint(parameters)
        summary_text = f"{summary} [fp:{param_fp}]" if param_fp else summary

        now_utc = datetime.now(timezone.utc)
        expires_at = (now_utc + timedelta(minutes=15)).isoformat()

        data = {
            "id": conf_id,
            "user_id": self.user_id,
            "plan_id": plan_id,
            "step_id": step_id,
            "summary": summary_text,
            "status": "PENDING",
            "expires_at": expires_at
        }
        self.supabase.table("action_confirmations").insert(data).execute()
        return conf_id

    def confirm(self, conf_id: str):
        # 1. Fetch confirmation and verify ownership
        res = self.supabase.table("action_confirmations")\
            .select("*")\
            .eq("id", conf_id)\
            .eq("user_id", self.user_id)\
            .execute()

        if not res.data:
            raise PermissionError("Confirmation not found or access denied")

        conf = res.data[0]
        current_status = conf.get("status")

        if current_status == "CANCELLED":
            raise ValueError("Cannot confirm an action that has been cancelled")
        if current_status == "EXPIRED":
            raise ValueError("Cannot confirm an action that has expired")

        # 2. Check if expired by time
        expires_at_str = conf.get("expires_at")
        if expires_at_str:
            expires_at = _parse_iso_datetime(expires_at_str)
            if datetime.now(timezone.utc) > expires_at:
                self.supabase.table("action_confirmations").update({
                    "status": "EXPIRED"
                }).eq("id", conf_id).eq("user_id", self.user_id).execute()
                raise ValueError("Confirmation has expired")

        # 3. Mark CONFIRMED
        self.supabase.table("action_confirmations").update({
            "status": "CONFIRMED",
            "confirmed_at": datetime.now(timezone.utc).isoformat()
        }).eq("id", conf_id).eq("user_id", self.user_id).execute()

    def cancel(self, conf_id: str):
        res = self.supabase.table("action_confirmations")\
            .select("id")\
            .eq("id", conf_id)\
            .eq("user_id", self.user_id)\
            .execute()
        if not res.data:
            raise PermissionError("Confirmation not found or access denied")

        self.supabase.table("action_confirmations").update({
            "status": "CANCELLED"
        }).eq("id", conf_id).eq("user_id", self.user_id).execute()

    def invalidate_confirmations_for_step(self, step_id: str):
        """Invalidates all confirmations for a given step (e.g. when parameters change)."""
        self.supabase.table("action_confirmations").update({
            "status": "CANCELLED"
        }).eq("step_id", step_id).eq("user_id", self.user_id).execute()

    def is_confirmed(self, step_id: str, current_parameters: Optional[Dict[str, Any]] = None) -> bool:
        res = self.supabase.table("action_confirmations")\
            .select("*")\
            .eq("step_id", step_id)\
            .eq("user_id", self.user_id)\
            .execute()

        if not res.data:
            return False

        # Get latest confirmation
        conf = res.data[-1]
        if conf.get("status") != "CONFIRMED":
            return False

        # Check expiration
        expires_at_str = conf.get("expires_at")
        if expires_at_str:
            expires_at = _parse_iso_datetime(expires_at_str)
            if datetime.now(timezone.utc) > expires_at:
                self.supabase.table("action_confirmations").update({
                    "status": "EXPIRED"
                }).eq("id", conf["id"]).eq("user_id", self.user_id).execute()
                return False

        # Check parameter fingerprint match
        if current_parameters is not None:
            summary = conf.get("summary", "")
            if "[fp:" in summary:
                conf_fp = summary.split("[fp:")[1].split("]")[0]
                curr_fp = _get_param_fingerprint(current_parameters)
                if conf_fp != curr_fp:
                    # Invalidate because parameters changed after confirmation
                    self.cancel(conf["id"])
                    return False

        return True
