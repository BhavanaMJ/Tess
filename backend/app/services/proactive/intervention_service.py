from supabase import Client
from typing import List, Optional
import uuid
from datetime import datetime, timedelta
from app.schemas.proactive import InterventionResponse
from app.schemas.future import FuturePrediction
from app.services.proactive.decision_engine import DecisionEngine
from app.services.proactive.notification_service import NotificationService

class InterventionService:
    def __init__(self, supabase: Client, user_id: str):
        self.supabase = supabase
        self.user_id = user_id

    def _get_user_prefs(self):
        res = self.supabase.table("profiles").select("proactive_enabled, minimum_intervention_priority").eq("id", self.user_id).execute()
        if res.data:
            return res.data[0]
        return {"proactive_enabled": True, "minimum_intervention_priority": "MEDIUM"}

    def evaluate_and_intervene(self, predictions: List[FuturePrediction]) -> List[InterventionResponse]:
        prefs = self._get_user_prefs()
        interventions = []

        for p in predictions:
            decision = DecisionEngine.should_intervene(self.supabase, self.user_id, p, prefs)
            if decision.should_intervene:
                intervention_id = str(uuid.uuid4())
                
                data = {
                    "id": intervention_id,
                    "user_id": self.user_id,
                    "prediction_id": p.id,
                    "type": decision.intervention_type,
                    "priority": decision.priority,
                    "title": decision.title,
                    "message": decision.message,
                    "reason": decision.reason,
                    "value_score": decision.value_score,
                    "status": "SENT",
                    "sent_at": datetime.now().isoformat()
                }
                
                self.supabase.table("interventions").insert(data).execute()
                
                # Send Push Notification
                NotificationService.send_push_notification(self.user_id, decision.title, decision.message, {
                    "intervention_id": intervention_id,
                    "type": decision.intervention_type,
                    "screen": "future"
                })
                
                interventions.append(InterventionResponse(**data, created_at=datetime.now()))
                
        return interventions

    def get_interventions(self) -> List[InterventionResponse]:
        res = self.supabase.table("interventions").select("*").eq("user_id", self.user_id).order("created_at", desc=True).execute()
        return [InterventionResponse(**item) for item in res.data]
        
    def respond_to_intervention(self, intervention_id: str, action: str):
        update_data = {"status": action, "responded_at": datetime.now().isoformat()}
        
        if action == "LATER":
            update_data["status"] = "DEFERRED"
            update_data["deferred_until"] = (datetime.now() + timedelta(hours=4)).isoformat()
        elif action == "DISMISS":
            update_data["status"] = "DISMISSED"
            
        self.supabase.table("interventions").update(update_data).eq("id", intervention_id).eq("user_id", self.user_id).execute()
