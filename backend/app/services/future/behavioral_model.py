from datetime import datetime, timedelta, timezone
from typing import Dict, Any, List, Optional
from supabase import Client
from app.schemas.future import BehavioralInsight, BehavioralAnalysisResponse

class PersonalBehavioralModel:
    def __init__(self, supabase: Client, user_id: str):
        self.supabase = supabase
        self.user_id = user_id

    def extract_behavioral_profile(self, window_days: int = 30) -> BehavioralAnalysisResponse:
        now = datetime.now(timezone.utc)
        period_start = now - timedelta(days=window_days)

        # 1. Fetch tasks
        tasks_resp = self.supabase.table("productivity_tasks")\
            .select("*")\
            .eq("user_id", self.user_id)\
            .execute()
        tasks = tasks_resp.data or []

        # 2. Fetch productivity events
        events_resp = self.supabase.table("productivity_events")\
            .select("*")\
            .eq("user_id", self.user_id)\
            .gte("created_at", period_start.isoformat())\
            .execute()
        events = events_resp.data or []

        # 3. Fetch interventions
        interventions_resp = self.supabase.table("interventions")\
            .select("*")\
            .eq("user_id", self.user_id)\
            .gte("created_at", period_start.isoformat())\
            .execute()
        interventions = interventions_resp.data or []

        # 4. Fetch agent plans
        plans_resp = self.supabase.table("agent_plans")\
            .select("*")\
            .eq("user_id", self.user_id)\
            .gte("created_at", period_start.isoformat())\
            .execute()
        plans = plans_resp.data or []

        # Determine data quality
        total_signals = len(tasks) + len(events) + len(interventions)
        if total_signals < 3:
            data_quality = "INSUFFICIENT"
        elif total_signals < 10:
            data_quality = "PRELIMINARY"
        else:
            data_quality = "GOOD"

        # Calculate Task Completion Metrics
        total_tasks = len(tasks)
        completed_tasks = [t for t in tasks if str(t.get("status", "")).upper() in ("CLOSED", "DONE", "COMPLETED")]
        active_tasks = [t for t in tasks if str(t.get("status", "")).upper() not in ("CLOSED", "DONE", "COMPLETED")]
        completion_rate = round(len(completed_tasks) / max(total_tasks, 1), 2)

        # Overdue analysis
        overdue_tasks = []
        for t in active_tasks:
            due_str = t.get("due_date")
            if due_str:
                try:
                    due_date = datetime.fromisoformat(due_str.replace("Z", "+00:00"))
                    if due_date < now:
                        overdue_tasks.append(t)
                except Exception:
                    pass
        overdue_rate = round(len(overdue_tasks) / max(len(active_tasks), 1), 2)

        # Intervention acceptance
        accepted_interventions = [i for i in interventions if i.get("user_response") in ("FIX_IT", "CONFIRMED", "ACCEPTED")]
        dismissed_interventions = [i for i in interventions if i.get("user_response") in ("DISMISSED", "REJECTED")]
        int_acceptance_rate = round(len(accepted_interventions) / max(len(interventions), 1), 2)

        # Agent execution conversion
        executed_plans = [p for p in plans if p.get("status") in ("SUCCESS", "EXECUTED", "CONFIRMED")]
        plan_execution_rate = round(len(executed_plans) / max(len(plans), 1), 2)

        # Synthesize Evidence-Backed Insights
        insights: List[BehavioralInsight] = []

        # Task completion insight
        if total_tasks > 0:
            insights.append(BehavioralInsight(
                category="TASK_COMPLETION",
                headline=f"{len(completed_tasks)} of {total_tasks} tasks completed ({int(completion_rate * 100)}%)",
                observation=(
                    f"Over the last {window_days} days, you closed {len(completed_tasks)} tasks out of {total_tasks} tracked commitments."
                    if data_quality != "INSUFFICIENT"
                    else "Limited task completion history is currently recorded."
                ),
                evidence=[
                    f"Completed tasks: {len(completed_tasks)}",
                    f"Active backlog: {len(active_tasks)}",
                    f"Observed window: {window_days} days"
                ],
                data_quality=data_quality,
                window_days=window_days
            ))

        # Overdue insight
        if len(overdue_tasks) > 0:
            insights.append(BehavioralInsight(
                category="DEADLINE_ADHERENCE",
                headline=f"{len(overdue_tasks)} active tasks past scheduled due date",
                observation="Several pending tasks have exceeded their target deadlines, indicating workload concentration or optimistic scheduling.",
                evidence=[
                    f"Overdue count: {len(overdue_tasks)}",
                    f"Overdue ratio of active tasks: {int(overdue_rate * 100)}%"
                ],
                data_quality=data_quality,
                window_days=window_days
            ))
        else:
            insights.append(BehavioralInsight(
                category="DEADLINE_ADHERENCE",
                headline="No overdue commitments detected",
                observation="All active tasks are currently scheduled for future deadlines or have no deadline constraints.",
                evidence=["Overdue tasks: 0"],
                data_quality=data_quality,
                window_days=window_days
            ))

        # Intervention response insight
        if len(interventions) > 0:
            insights.append(BehavioralInsight(
                category="INTERVENTION_RESPONSIVENESS",
                headline=f"{int(int_acceptance_rate * 100)}% intervention response rate",
                observation=f"You accepted or acted upon {len(accepted_interventions)} of {len(interventions)} proactive suggestions in this period.",
                evidence=[
                    f"Accepted: {len(accepted_interventions)}",
                    f"Dismissed: {len(dismissed_interventions)}"
                ],
                data_quality=data_quality,
                window_days=window_days
            ))

        # Productivity momentum insight
        momentum_headline = "Steady workflow momentum" if len(events) >= 5 else "Baseline activity level"
        insights.append(BehavioralInsight(
            category="PRODUCTIVITY_MOMENTUM",
            headline=momentum_headline,
            observation=f"Recorded {len(events)} productivity activity events and {len(plans)} autonomous agent plans in this window.",
            evidence=[
                f"Total events: {len(events)}",
                f"Agent plans created: {len(plans)}",
                f"Plans successfully executed: {len(executed_plans)}"
            ],
            data_quality=data_quality,
            window_days=window_days
        ))

        metrics = {
            "total_tasks": total_tasks,
            "completed_tasks": len(completed_tasks),
            "active_backlog": len(active_tasks),
            "overdue_tasks": len(overdue_tasks),
            "completion_rate": completion_rate,
            "overdue_rate": overdue_rate,
            "interventions_count": len(interventions),
            "intervention_acceptance_rate": int_acceptance_rate,
            "agent_plans_count": len(plans),
            "agent_execution_rate": plan_execution_rate,
            "total_events": len(events)
        }

        # Snapshot persistence
        try:
            self.supabase.table("behavioral_snapshots").insert({
                "user_id": self.user_id,
                "period_start": period_start.isoformat(),
                "period_end": now.isoformat(),
                "features": metrics,
                "data_quality": data_quality
            }).execute()
        except Exception:
            pass

        return BehavioralAnalysisResponse(
            insights=insights,
            metrics=metrics,
            data_quality=data_quality,
            period_start=period_start,
            period_end=now
        )

