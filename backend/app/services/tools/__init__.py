from app.services.tools.registry import ToolRegistry
from app.services.tools.builtin.openproject import OpenProjectUpdateWorklog
from app.services.tools.builtin.browser import (
    BrowserNavigateTool,
    BrowserExtractTool,
    BrowserFillFormTool
)
from app.services.tools.builtin.files import (
    FileReadTool,
    FileSearchTool,
    FileModifyTool
)
from app.services.tools.builtin.email_calendar import (
    GmailReadTool,
    GmailCreateDraftTool,
    GmailSendEmailTool,
    CalendarListEventsTool,
    CalendarCreateEventTool,
    CalendarDeleteEventTool
)

# Register all built-in tools
ToolRegistry.register(OpenProjectUpdateWorklog())
ToolRegistry.register(BrowserNavigateTool())
ToolRegistry.register(BrowserExtractTool())
ToolRegistry.register(BrowserFillFormTool())
ToolRegistry.register(FileReadTool())
ToolRegistry.register(FileSearchTool())
ToolRegistry.register(FileModifyTool())
ToolRegistry.register(GmailReadTool())
ToolRegistry.register(GmailCreateDraftTool())
ToolRegistry.register(GmailSendEmailTool())
ToolRegistry.register(CalendarListEventsTool())
ToolRegistry.register(CalendarCreateEventTool())
ToolRegistry.register(CalendarDeleteEventTool())
