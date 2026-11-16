from app.schemas.agent import AgentPlanSchema, AgentStepSchema
import re
import datetime

class AgentPlanner:
    @staticmethod
    def plan(objective: str) -> AgentPlanSchema:
        obj_lower = objective.lower().strip()
        steps = []
        
        # 1. Worklog / OpenProject Workflow (Phase 6 legacy preservation)
        if any(kw in obj_lower for kw in ["worklog", "openproject", "fix", "log time"]):
            hours = 4.0
            hours_match = re.search(r'(\d+(?:\.\d+)?)\s*(?:hours|hour|hrs|hr|h\b)', obj_lower)
            if hours_match:
                try:
                    parsed_hours = float(hours_match.group(1))
                    if 0 < parsed_hours <= 24:
                        hours = parsed_hours
                except ValueError:
                    pass
            elif "2 hours" in obj_lower:
                hours = 2.0

            task_id = "1"
            task_match = re.search(r'(?:task|package|wp|#)\s*[-:]?\s*(\d+)', obj_lower)
            if task_match:
                task_id = task_match.group(1)

            steps = [
                AgentStepSchema(
                    tool_name="openproject_update_worklog",
                    action_type="UPDATE_WORKLOG",
                    parameters={
                        "task_id": task_id,
                        "hours": hours,
                        "comment": f"Worklog updated via TESS agent: {objective}"
                    },
                    risk_level="MEDIUM"
                )
            ]

        # 2. Meeting preparation / Calendar & Email Multi-Step Workflow (Milestone 8.6)
        elif any(kw in obj_lower for kw in ["meeting", "prepare me for", "briefing", "schedule"]):
            if "schedule" in obj_lower or "create event" in obj_lower:
                tomorrow_start = (datetime.datetime.utcnow() + datetime.timedelta(days=1)).replace(hour=10, minute=0).isoformat()
                tomorrow_end = (datetime.datetime.utcnow() + datetime.timedelta(days=1)).replace(hour=11, minute=0).isoformat()
                steps = [
                    AgentStepSchema(
                        tool_name="calendar_list_events",
                        action_type="CALENDAR_LIST",
                        parameters={"days_ahead": 3},
                        risk_level="LOW"
                    ),
                    AgentStepSchema(
                        tool_name="calendar_create_event",
                        action_type="CALENDAR_CREATE",
                        parameters={
                            "title": "Strategy Discussion",
                            "start_time": tomorrow_start,
                            "end_time": tomorrow_end,
                            "attendees": ["team@project.org"]
                        },
                        risk_level="MEDIUM"
                    )
                ]
            else:
                # Prepare for meeting workflow: Read calendar -> find emails -> prepare draft
                steps = [
                    AgentStepSchema(
                        tool_name="calendar_list_events",
                        action_type="CALENDAR_LIST",
                        parameters={"days_ahead": 2},
                        risk_level="LOW"
                    ),
                    AgentStepSchema(
                        tool_name="gmail_read",
                        action_type="GMAIL_READ",
                        parameters={"query": "meeting", "max_results": 3},
                        risk_level="LOW"
                    ),
                    AgentStepSchema(
                        tool_name="gmail_create_draft",
                        action_type="GMAIL_DRAFT",
                        parameters={
                            "to": "team@project.org",
                            "subject": "Meeting Prep Notes",
                            "body": f"Meeting briefing synthesized for objective: {objective}"
                        },
                        risk_level="LOW"
                    )
                ]

        # 3. Send Email Workflow
        elif any(kw in obj_lower for kw in ["send email", "email to", "send message"]):
            to_match = re.search(r'[\w\.-]+@[\w\.-]+\.\w+', objective)
            recipient = to_match.group(0) if to_match else "collaborator@test.org"
            steps = [
                AgentStepSchema(
                    tool_name="gmail_send_email",
                    action_type="GMAIL_SEND",
                    parameters={
                        "to": recipient,
                        "subject": "TESS Automated Notification",
                        "body": f"Notification generated per user request: {objective}"
                    },
                    risk_level="HIGH"
                )
            ]

        # 4. Browser Navigation / Web Research Workflow
        elif any(kw in obj_lower for kw in ["browse", "open url", "http", "website", "check github", "search web"]):
            url_match = re.search(r'https?://[^\s]+', objective)
            target_url = url_match.group(0) if url_match else "https://github.com"
            if "fill form" in obj_lower or "submit form" in obj_lower:
                steps = [
                    AgentStepSchema(
                        tool_name="browser_navigate",
                        action_type="BROWSER_NAVIGATE",
                        parameters={"url": target_url, "timeout_seconds": 15},
                        risk_level="LOW"
                    ),
                    AgentStepSchema(
                        tool_name="browser_fill_form",
                        action_type="BROWSER_FILL_FORM",
                        parameters={
                            "url": target_url,
                            "form_selector": "#contact-form",
                            "field_values": {"name": "User", "feedback": "Automated feedback submission"}
                        },
                        risk_level="HIGH"
                    )
                ]
            else:
                steps = [
                    AgentStepSchema(
                        tool_name="browser_navigate",
                        action_type="BROWSER_NAVIGATE",
                        parameters={"url": target_url, "timeout_seconds": 15},
                        risk_level="LOW"
                    ),
                    AgentStepSchema(
                        tool_name="browser_extract",
                        action_type="BROWSER_EXTRACT",
                        parameters={"url": target_url, "query": "updates"},
                        risk_level="LOW"
                    )
                ]

        # 5. File Intelligence Workflow
        elif any(kw in obj_lower for kw in ["file", "document", "pdf", "docx", "read report", "csv"]):
            path_match = re.search(r'(/[\w\.-]+)+', objective)
            path = path_match.group(0) if path_match else "document.txt"
            if "delete" in obj_lower or "remove" in obj_lower or "modify" in obj_lower:
                steps = [
                    AgentStepSchema(
                        tool_name="file_read",
                        action_type="FILE_READ",
                        parameters={"file_path": path},
                        risk_level="LOW"
                    ),
                    AgentStepSchema(
                        tool_name="file_modify",
                        action_type="FILE_MODIFY",
                        parameters={"action": "DELETE", "target_path": path},
                        risk_level="HIGH"
                    )
                ]
            else:
                steps = [
                    AgentStepSchema(
                        tool_name="file_read",
                        action_type="FILE_READ",
                        parameters={"file_path": path},
                        risk_level="LOW"
                    ),
                    AgentStepSchema(
                        tool_name="file_search",
                        action_type="FILE_SEARCH",
                        parameters={"file_path": path, "query": "summary"},
                        risk_level="LOW"
                    )
                ]

        else:
            raise ValueError(f"Unsupported agent objective: '{objective}'")
            
        return AgentPlanSchema(objective=objective, steps=steps)
