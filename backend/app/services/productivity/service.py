from supabase import Client
from typing import List
from datetime import datetime, date, timedelta
from app.schemas.productivity import ProductivityConnection, ProductivityTask, ProductivitySummary
from app.services.productivity.openproject import OpenProjectProvider

class ProductivityService:
    def __init__(self, supabase: Client, user_id: str):
        self.supabase = supabase
        self.user_id = user_id

    def get_connection(self, provider: str = "openproject") -> ProductivityConnection:
        resp = self.supabase.table("productivity_connections").select("*").eq("user_id", self.user_id).eq("provider", provider).execute()
        if not resp.data:
            return None
        return ProductivityConnection(**resp.data[0])

    def save_connection(self, provider: str, base_url: str, credential_reference: str):
        data = {
            "user_id": self.user_id,
            "provider": provider,
            "base_url": base_url,
            "credential_reference": credential_reference
        }
        self.supabase.table("productivity_connections").upsert(data, on_conflict="user_id,provider").execute()

    async def sync_provider(self, provider_name: str = "openproject"):
        conn = self.get_connection(provider_name)
        if not conn:
            raise ValueError("Integration not configured")
        
        if provider_name == "openproject":
            provider = OpenProjectProvider(base_url=conn.base_url, api_token=conn.credential_reference)
            tasks = await provider.get_tasks()
            
            # Simple full sync for Phase 2
            for task in tasks:
                data = task.model_dump()
                data["user_id"] = self.user_id
                
                # Check for existing
                existing_resp = self.supabase.table("productivity_tasks").select("id").eq("user_id", self.user_id).eq("source", task.source).eq("external_id", task.external_id).execute()
                
                if existing_resp.data:
                    # Update
                    self.supabase.table("productivity_tasks").update(data).eq("id", existing_resp.data[0]["id"]).execute()
                else:
                    # Insert
                    self.supabase.table("productivity_tasks").insert(data).execute()
                    
            return {"status": "success", "synced_tasks": len(tasks)}
        
        raise ValueError("Unknown provider")

    def get_summary(self) -> ProductivitySummary:
        resp = self.supabase.table("productivity_tasks").select("*").eq("user_id", self.user_id).execute()
        tasks = resp.data
        
        summary = ProductivitySummary()
        today = date.today()
        end_of_week = today + timedelta(days=(6 - today.weekday()))
        
        for task in tasks:
            status = str(task.get("status") or "").lower()
            if status not in ["closed", "rejected", "done"]:
                summary.total_active += 1
                
                due_date_str = task.get("due_date")
                if due_date_str:
                    due_date = datetime.fromisoformat(due_date_str.replace('Z', '+00:00')).date()
                    if due_date < today:
                        summary.overdue += 1
                    elif due_date == today:
                        summary.due_today += 1
                    elif today <= due_date <= end_of_week:
                        summary.due_this_week += 1
            else:
                updated_str = task.get("updated_at")
                if updated_str:
                    updated = datetime.fromisoformat(updated_str.replace('Z', '+00:00')).date()
                    if today - timedelta(days=7) <= updated <= today:
                        summary.completed_recently += 1
                        
        return summary
    
    def get_active_tasks(self) -> List[ProductivityTask]:
        resp = self.supabase.table("productivity_tasks").select("*").eq("user_id", self.user_id).execute()
        tasks = []
        for item in resp.data:
            status = str(item.get("status") or "").lower()
            if status not in ["closed", "rejected", "done"]:
                tasks.append(ProductivityTask(**item))
        return tasks
