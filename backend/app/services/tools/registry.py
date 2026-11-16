from typing import Dict, Type
from app.services.tools.base import BaseTool

class ToolRegistry:
    _tools: Dict[str, BaseTool] = {}

    @classmethod
    def register(cls, tool: BaseTool):
        cls._tools[tool.name] = tool

    @classmethod
    def get_tool(cls, name: str) -> BaseTool:
        if name not in cls._tools:
            raise ValueError(f"Tool {name} is not registered.")
        return cls._tools[name]

    @classmethod
    def list_tools(cls) -> Dict[str, BaseTool]:
        return cls._tools
