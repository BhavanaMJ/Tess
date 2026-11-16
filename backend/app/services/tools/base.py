from pydantic import BaseModel
from typing import Any, Dict, Type

class BaseTool:
    name: str = ""
    description: str = ""
    risk_level: str = "LOW"  # LOW, MEDIUM, HIGH
    action_type: str = ""
    input_schema: Type[BaseModel]

    def validate(self, parameters: Dict[str, Any]) -> BaseModel:
        return self.input_schema(**parameters)

    def execute(self, user_id: str, context: Any, parameters: Dict[str, Any]) -> Any:
        raise NotImplementedError("Tools must implement execute()")
