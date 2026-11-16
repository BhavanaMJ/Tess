from supabase import Client
from datetime import datetime, timedelta

class CooldownManager:
    @staticmethod
    def is_on_cooldown(supabase: Client, user_id: str, prediction_id: str, intervention_type: str) -> bool:
        # Check if an intervention for this specific prediction was sent in the last 6 hours
        six_hours_ago = datetime.now() - timedelta(hours=6)
        
        res = supabase.table("interventions").select("id").eq("user_id", user_id).eq("prediction_id", prediction_id).gte("created_at", six_hours_ago.isoformat()).execute()
        if len(res.data) > 0:
            return True
            
        # Check if the user deferred a similar intervention recently
        res_deferred = supabase.table("interventions").select("deferred_until").eq("user_id", user_id).eq("status", "DEFERRED").eq("type", intervention_type).gte("deferred_until", datetime.now().isoformat()).execute()
        if len(res_deferred.data) > 0:
            return True
            
        # Check if an intervention of this type was dismissed in the last 12 hours
        twelve_hours_ago = datetime.now() - timedelta(hours=12)
        res_dismissed = supabase.table("interventions").select("id").eq("user_id", user_id).eq("status", "DISMISSED").eq("type", intervention_type).gte("created_at", twelve_hours_ago.isoformat()).execute()
        if len(res_dismissed.data) > 0:
            return True
            
        return False
