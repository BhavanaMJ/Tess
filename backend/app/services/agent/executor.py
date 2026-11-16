from supabase import Client
from typing import Any, Dict
from app.services.tools.router import ToolRouter
from app.services.agent.confirmation import ConfirmationService
from datetime import datetime, timezone

class AgentExecutor:
    def __init__(self, supabase: Client, user_id: str):
        self.supabase = supabase
        self.user_id = user_id
        self.conf_service = ConfirmationService(supabase, user_id)

    def execute_step(self, step_id: str) -> Dict[str, Any]:
        # 1. Load Step
        res = self.supabase.table("agent_steps").select("*").eq("id", step_id).execute()
        if not res.data:
            raise ValueError(f"Step {step_id} not found")
        step = res.data[0]
        
        # 2. Check Plan Ownership
        plan_res = self.supabase.table("agent_plans")\
            .select("user_id, status")\
            .eq("id", step["plan_id"])\
            .execute()

        if not plan_res.data or plan_res.data[0]["user_id"] != self.user_id:
            raise PermissionError("Access denied: You do not own this plan")

        if step["status"] != "PENDING":
            raise ValueError(f"Step cannot be executed: current status is '{step['status']}'")

        # 3. Check confirmation for Medium/High risk tools
        is_confirmed = False
        if step["risk_level"] in ["MEDIUM", "HIGH"]:
            is_confirmed = self.conf_service.is_confirmed(step_id, current_parameters=step.get("parameters"))
            if not is_confirmed:
                raise PermissionError(
                    f"Step {step_id} requires explicit user confirmation before execution "
                    f"(action is unconfirmed, expired, cancelled, or parameters changed)"
                )

        # 4. Execute
        now_iso = datetime.now(timezone.utc).isoformat()
        try:
            self.supabase.table("agent_steps").update({"status": "RUNNING"}).eq("id", step_id).execute()
            
            result = ToolRouter.route_and_execute(
                user_id=self.user_id,
                tool_name=step["tool_name"],
                parameters=step["parameters"],
                context=self.supabase,
                is_confirmed=is_confirmed
            )
            
            # Replay prevention: invalidate confirmation token immediately upon execution
            if is_confirmed:
                try:
                    self.conf_service.invalidate_confirmations_for_step(step_id)
                except Exception:
                    pass

            self.supabase.table("agent_steps").update({
                "status": "SUCCESS",
                "result": result,
                "completed_at": datetime.now(timezone.utc).isoformat()
            }).eq("id", step_id).execute()
            
            return result
        except Exception as e:
            self.supabase.table("agent_steps").update({
                "status": "FAILED",
                "result": {"error": str(e)},
                "completed_at": datetime.now(timezone.utc).isoformat()
            }).eq("id", step_id).execute()
            raise e
