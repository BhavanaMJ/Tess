from supabase import Client
import uuid
from typing import Dict, Any, List, Optional
from datetime import datetime, timezone

from app.schemas.agent import AgentPlanSchema, AgentPlanResponse
from app.services.agent.planner import AgentPlanner
from app.services.agent.executor import AgentExecutor
from app.services.agent.confirmation import ConfirmationService
from app.services.tools.permissions import ToolPermissions

class AgentService:
    def __init__(self, supabase: Client, user_id: str):
        self.supabase = supabase
        self.user_id = str(user_id)
        self.executor = AgentExecutor(supabase, self.user_id)
        self.conf_service = ConfirmationService(supabase, self.user_id)

    def create_objective(self, objective: str) -> AgentPlanResponse:
        plan = AgentPlanner.plan(objective)
        
        plan_id = str(uuid.uuid4())
        now_iso = datetime.now(timezone.utc).isoformat()
        self.supabase.table("agent_plans").insert({
            "id": plan_id,
            "user_id": self.user_id,
            "objective": plan.objective,
            "status": "PLANNING",
            "created_at": now_iso
        }).execute()
        
        steps_data = []
        for i, step in enumerate(plan.steps):
            step_id = str(uuid.uuid4())
            step_data = {
                "id": step_id,
                "plan_id": plan_id,
                "step_order": i + 1,
                "tool_name": step.tool_name,
                "action_type": step.action_type,
                "parameters": step.parameters,
                "risk_level": step.risk_level,
                "status": "PENDING",
                "created_at": now_iso
            }
            self.supabase.table("agent_steps").insert(step_data).execute()
            steps_data.append(step_data)
            
            # Request confirmation for Medium/High risk actions
            if ToolPermissions.requires_confirmation(step.tool_name):
                summary = f"Update OpenProject worklog with {step.parameters.get('hours')} hours on task {step.parameters.get('task_id')}."
                self.conf_service.request_confirmation(
                    plan_id=plan_id,
                    step_id=step_id,
                    summary=summary,
                    parameters=step.parameters
                )

        self.supabase.table("agent_plans").update({"status": "READY"}).eq("id", plan_id).execute()
        
        return self.get_plan(plan_id)

    def get_plan(self, plan_id: str) -> AgentPlanResponse:
        res = self.supabase.table("agent_plans")\
            .select("*")\
            .eq("id", plan_id)\
            .eq("user_id", self.user_id)\
            .execute()

        if not res.data:
            raise ValueError(f"Plan {plan_id} not found")
        plan = res.data[0]
        
        steps_res = self.supabase.table("agent_steps")\
            .select("*")\
            .eq("plan_id", plan_id)\
            .order("step_order")\
            .execute()
        
        # Merge confirmation states
        for s in steps_res.data:
            conf_res = self.supabase.table("action_confirmations")\
                .select("id, status, expires_at, summary")\
                .eq("step_id", s["id"])\
                .execute()
            if conf_res.data:
                s["confirmation"] = conf_res.data[-1]
                
        plan["steps"] = steps_res.data
        return AgentPlanResponse(**plan)

    def get_plans(self, limit: int = 20) -> List[AgentPlanResponse]:
        res = self.supabase.table("agent_plans")\
            .select("*")\
            .eq("user_id", self.user_id)\
            .order("created_at")\
            .execute()

        plans = []
        for p in res.data[:limit]:
            try:
                steps_res = self.supabase.table("agent_steps")\
                    .select("*")\
                    .eq("plan_id", p["id"])\
                    .order("step_order")\
                    .execute()
                for s in steps_res.data:
                    conf_res = self.supabase.table("action_confirmations")\
                        .select("id, status, expires_at, summary")\
                        .eq("step_id", s["id"])\
                        .execute()
                    if conf_res.data:
                        s["confirmation"] = conf_res.data[-1]
                p["steps"] = steps_res.data
                plans.append(AgentPlanResponse(**p))
            except Exception:
                pass
        return plans

    def cancel_plan(self, plan_id: str):
        plan = self.get_plan(plan_id)
        if plan.status in ["EXECUTING", "SUCCESS"]:
            raise ValueError(f"Cannot cancel a plan that is already {plan.status}")

        self.supabase.table("agent_plans").update({
            "status": "CANCELLED"
        }).eq("id", plan_id).eq("user_id", self.user_id).execute()

    def update_step_parameters(self, step_id: str, new_parameters: Dict[str, Any]):
        """Modifies step parameters and automatically invalidates existing confirmations."""
        step_res = self.supabase.table("agent_steps").select("*").eq("id", step_id).execute()
        if not step_res.data:
            raise ValueError(f"Step {step_id} not found")
        step = step_res.data[0]

        plan_res = self.supabase.table("agent_plans").select("user_id, status").eq("id", step["plan_id"]).execute()
        if not plan_res.data or plan_res.data[0]["user_id"] != self.user_id:
            raise PermissionError("Access denied")

        if plan_res.data[0]["status"] in ["EXECUTING", "SUCCESS"]:
            raise ValueError("Cannot modify step of an executed plan")

        # Invalidate previous confirmations
        self.conf_service.invalidate_confirmations_for_step(step_id)

        # Update parameters and reset status
        self.supabase.table("agent_steps").update({
            "parameters": new_parameters,
            "status": "PENDING"
        }).eq("id", step_id).execute()

    def execute_plan(self, plan_id: str) -> Dict[str, Any]:
        plan = self.get_plan(plan_id)
        
        # Non-idempotent guard: cannot re-execute a running or finished plan
        if plan.status in ["EXECUTING", "SUCCESS"]:
            raise ValueError(f"Plan cannot be executed: current status is {plan.status}")
            
        self.supabase.table("agent_plans").update({"status": "EXECUTING"}).eq("id", plan_id).execute()
        
        results = []
        try:
            for step in plan.steps:
                res = self.executor.execute_step(step["id"])
                results.append(res)
                
            now_iso = datetime.now(timezone.utc).isoformat()
            self.supabase.table("agent_plans").update({
                "status": "SUCCESS",
                "completed_at": now_iso
            }).eq("id", plan_id).execute()
            
            # Persist successful action event
            try:
                self.supabase.table("productivity_events").insert({
                    "user_id": self.user_id,
                    "source": "tess_agent",
                    "event_type": "ACTION_COMPLETED",
                    "payload": {"plan_id": plan_id, "results": results}
                }).execute()
            except Exception:
                pass
            
            return {"status": "success", "results": results}
        except Exception as e:
            # Mark plan as FAILED
            now_iso = datetime.now(timezone.utc).isoformat()
            self.supabase.table("agent_plans").update({
                "status": "FAILED",
                "completed_at": now_iso
            }).eq("id", plan_id).execute()

            # Persist failed action event
            try:
                self.supabase.table("productivity_events").insert({
                    "user_id": self.user_id,
                    "source": "tess_agent",
                    "event_type": "ACTION_FAILED",
                    "payload": {
                        "plan_id": plan_id,
                        "error": str(e),
                        "completed_steps": results
                    }
                }).execute()
            except Exception:
                pass

            raise e
