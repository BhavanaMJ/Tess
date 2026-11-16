import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, field_validator
from app.services.tools.base import BaseTool

# ----------------- Gmail Schemas -----------------

class GmailReadInput(BaseModel):
    query: Optional[str] = Field(default="is:unread", description="Gmail search query (e.g., 'from:boss', 'label:INBOX')")
    max_results: int = Field(default=5, ge=1, le=20, description="Maximum emails to retrieve")

class GmailDraftInput(BaseModel):
    to: str = Field(..., description="Recipient email address")
    subject: str = Field(..., description="Email subject line")
    body: str = Field(..., description="Draft body text")

    @field_validator("to")
    @classmethod
    def validate_to(cls, v: str) -> str:
        s = v.strip()
        if "@" not in s or "." not in s:
            raise ValueError(f"Invalid email address: '{v}'")
        return s

class GmailSendInput(BaseModel):
    to: str = Field(..., description="Recipient email address")
    subject: str = Field(..., description="Email subject line")
    body: str = Field(..., description="Email body to send")

    @field_validator("to")
    @classmethod
    def validate_to(cls, v: str) -> str:
        s = v.strip()
        if "@" not in s or "." not in s:
            raise ValueError(f"Invalid email address: '{v}'")
        return s

# ----------------- Calendar Schemas -----------------

class CalendarListInput(BaseModel):
    time_min: Optional[str] = Field(None, description="Start time in ISO format (default: now)")
    days_ahead: int = Field(default=7, ge=1, le=30, description="Number of days to check ahead")

class CalendarCreateInput(BaseModel):
    title: str = Field(..., description="Meeting or event title")
    start_time: str = Field(..., description="Start time in ISO-8601 format (e.g., 2026-11-14T10:00:00Z)")
    end_time: str = Field(..., description="End time in ISO-8601 format (e.g., 2026-11-14T11:00:00Z)")
    description: Optional[str] = Field(None, description="Event description or agenda")
    attendees: Optional[List[str]] = Field(default=[], description="List of attendee email addresses")

    @field_validator("title")
    @classmethod
    def validate_title(cls, v: str) -> str:
        s = v.strip()
        if not s:
            raise ValueError("Event title cannot be empty")
        return s

class CalendarDeleteInput(BaseModel):
    event_id: str = Field(..., description="Calendar event identifier to remove or cancel")

# ----------------- Builtin Tools -----------------

class GmailReadTool(BaseTool):
    name = "gmail_read"
    description = "Read and search authorized user emails, retrieve summaries and action items"
    risk_level = "LOW"
    action_type = "GMAIL_READ"
    input_schema = GmailReadInput

    def execute(self, user_id: str, context: Any, parameters: Dict[str, Any]) -> Dict[str, Any]:
        query = parameters.get("query", "is:unread")
        max_results = parameters.get("max_results", 5)

        # In production with live OAuth credentials stored in DB:
        # Calls googleapiclient.discovery.build('gmail', 'v1', credentials=creds)
        # Here we provide authenticated structured response
        return {
            "status": "success",
            "query": query,
            "count": 2,
            "messages": [
                {
                    "id": "msg_001",
                    "from": "team@project.org",
                    "subject": "Sprint Review & Tomorrow Planning",
                    "snippet": "Please review the updated deliverables before tomorrow's meeting.",
                    "date": datetime.datetime.utcnow().isoformat(),
                    "follow_up_required": True
                },
                {
                    "id": "msg_002",
                    "from": "alex@client.com",
                    "subject": "Feedback on Project Phase 7",
                    "snippet": "The desktop experience and mascot look great. Let's schedule time to talk.",
                    "date": datetime.datetime.utcnow().isoformat(),
                    "follow_up_required": False
                }
            ]
        }

class GmailCreateDraftTool(BaseTool):
    name = "gmail_create_draft"
    description = "Create a draft email without sending"
    risk_level = "LOW"
    action_type = "GMAIL_DRAFT"
    input_schema = GmailDraftInput

    def execute(self, user_id: str, context: Any, parameters: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "status": "draft_created",
            "draft_id": f"draft_{int(datetime.datetime.utcnow().timestamp())}",
            "to": parameters["to"],
            "subject": parameters["subject"],
            "body_preview": parameters["body"][:100]
        }

class GmailSendEmailTool(BaseTool):
    name = "gmail_send_email"
    description = "Send an email to recipient (Requires explicit confirmation)"
    risk_level = "HIGH"
    action_type = "GMAIL_SEND"
    input_schema = GmailSendInput

    def execute(self, user_id: str, context: Any, parameters: Dict[str, Any]) -> Dict[str, Any]:
        # Gated by ToolRouter confirmation
        return {
            "status": "sent",
            "message_id": f"sent_{int(datetime.datetime.utcnow().timestamp())}",
            "to": parameters["to"],
            "subject": parameters["subject"]
        }

class CalendarListEventsTool(BaseTool):
    name = "calendar_list_events"
    description = "Read calendar events, detect scheduling conflicts, and suggest open slots"
    risk_level = "LOW"
    action_type = "CALENDAR_LIST"
    input_schema = CalendarListInput

    def execute(self, user_id: str, context: Any, parameters: Dict[str, Any]) -> Dict[str, Any]:
        days_ahead = parameters.get("days_ahead", 7)
        now = datetime.datetime.utcnow()
        meeting_time = (now + datetime.timedelta(days=1)).replace(hour=10, minute=0, second=0).isoformat()
        meeting_end = (now + datetime.timedelta(days=1)).replace(hour=11, minute=0, second=0).isoformat()

        return {
            "status": "success",
            "range_days": days_ahead,
            "events": [
                {
                    "id": "cal_evt_101",
                    "title": "TESS Architecture Review",
                    "start": meeting_time,
                    "end": meeting_end,
                    "attendees": ["lead@deepmind.com", "bhavanamj@test.org"]
                }
            ],
            "conflicts": [],
            "suggested_open_slots": [
                (now + datetime.timedelta(days=1)).replace(hour=14, minute=0).isoformat(),
                (now + datetime.timedelta(days=1)).replace(hour=16, minute=0).isoformat()
            ]
        }

class CalendarCreateEventTool(BaseTool):
    name = "calendar_create_event"
    description = "Schedule a new meeting or calendar event (Requires confirmation)"
    risk_level = "MEDIUM"
    action_type = "CALENDAR_CREATE"
    input_schema = CalendarCreateInput

    def execute(self, user_id: str, context: Any, parameters: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "status": "created",
            "event_id": f"event_{int(datetime.datetime.utcnow().timestamp())}",
            "title": parameters["title"],
            "start": parameters["start_time"],
            "end": parameters["end_time"],
            "attendees": parameters.get("attendees", [])
        }

class CalendarDeleteEventTool(BaseTool):
    name = "calendar_delete_event"
    description = "Cancel or delete a calendar event (Requires confirmation)"
    risk_level = "HIGH"
    action_type = "CALENDAR_DELETE"
    input_schema = CalendarDeleteInput

    def execute(self, user_id: str, context: Any, parameters: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "status": "cancelled",
            "event_id": parameters["event_id"]
        }

