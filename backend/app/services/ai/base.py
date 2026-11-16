from abc import ABC, abstractmethod

class BaseAIProvider(ABC):
    @abstractmethod
    async def chat(self, message: str) -> str:
        """Send a message to the AI and return the response."""
        pass
