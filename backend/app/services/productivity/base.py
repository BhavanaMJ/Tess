from abc import ABC, abstractmethod
from typing import List
from app.schemas.productivity import ProductivityTaskBase

class BaseProductivityProvider(ABC):
    @abstractmethod
    async def test_connection(self) -> dict:
        pass
        
    @abstractmethod
    async def get_tasks(self) -> List[ProductivityTaskBase]:
        pass
