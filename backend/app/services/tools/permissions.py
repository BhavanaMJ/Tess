from app.services.tools.registry import ToolRegistry

class ToolPermissions:
    @staticmethod
    def requires_confirmation(tool_name: str) -> bool:
        tool = ToolRegistry.get_tool(tool_name)
        return tool.risk_level in ["MEDIUM", "HIGH"]
