from typing import Any, Dict
from app.services.tools.registry import ToolRegistry
from app.services.tools.permissions import ToolPermissions

class ToolRouter:
    @staticmethod
    def route_and_execute(user_id: str, tool_name: str, parameters: Dict[str, Any], context: Any = None, is_confirmed: bool = False) -> Any:
        tool = ToolRegistry.get_tool(tool_name)
        
        # Risk evaluation
        if ToolPermissions.requires_confirmation(tool_name) and not is_confirmed:
            raise PermissionError(f"Execution of {tool_name} requires explicit user confirmation (Risk: {tool.risk_level}).")
            
        # Validation
        validated_params = tool.validate(parameters)
        
        # Execution
        return tool.execute(user_id, context, validated_params.model_dump())
