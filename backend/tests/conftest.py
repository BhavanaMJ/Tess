import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.services.ai.base import BaseAIProvider
from app.api.endpoints import get_ai_provider, get_db_service
from app.core.auth import get_current_user
from datetime import datetime
from collections import namedtuple

class MockAIProvider(BaseAIProvider):
    async def chat(self, message: str) -> str:
        return f"Mock response to: {message}"

User = namedtuple('User', ['id'])

class MockDBService:
    def get_conversations(self):
        return []
        
    def create_conversation(self, title):
        return {"id": "conv-1", "user_id": "user-1", "title": title, "created_at": datetime.now(), "updated_at": datetime.now()}

    def get_conversation_messages(self, conversation_id):
        return []

    def add_message(self, conversation_id, role, content):
        return {"id": "msg-1", "conversation_id": conversation_id, "role": role, "content": content, "created_at": datetime.now()}

    def get_recent_memories(self, limit):
        return []

    def add_memory(self, category, content, importance):
        return {"id": "mem-1", "user_id": "user-1", "category": category, "content": content, "importance": importance, "created_at": datetime.now(), "updated_at": datetime.now()}

    def update_memory(self, memory_id, updates):
        return {
            "id": memory_id,
            "user_id": "user-1",
            "category": updates.get("category", "preference"),
            "content": updates.get("content", "Updated memory"),
            "importance": updates.get("importance", 1),
            "is_confirmed": updates.get("is_confirmed", True),
            "provenance": updates.get("provenance", "USER_STATED"),
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        }

from app.api.productivity import get_prod_service
from app.api.future import get_future_service
from app.api.companion import get_companion_service
from app.schemas.productivity import ProductivitySummary, ProductivityTask
from app.schemas.companion import CompanionPreferences, CompanionProfileResponse

class MockProductivityService:
    def get_summary(self):
        return ProductivitySummary(total_active=5, overdue=1, due_today=2, due_this_week=2, completed_recently=3)
    
    def get_active_tasks(self):
        return [
            ProductivityTask(id="1", user_id="user-1", source="openproject", external_id="WP-1", title="Test Task", created_at=datetime.now(), updated_at=datetime.now())
        ]
        
    def save_connection(self, provider, base_url, credential_reference):
        pass
        
    async def sync_provider(self, provider_name):
        return {"status": "success", "synced_tasks": 1}

class MockFutureService:
    def get_latest_predictions(self, limit):
        return []

class MockCompanionService:
    def get_preferences(self):
        return CompanionPreferences()
    def update_preferences(self, updates):
        return CompanionPreferences()
    def increment_interaction(self):
        return 1
    def get_milestones(self):
        return []
    def record_milestone(self, *args, **kwargs):
        pass
    def record_activity(self, *args, **kwargs):
        pass
    def get_routines(self):
        return []
    def evaluate_due_routines(self):
        return []
    def get_profile(self):
        return CompanionProfileResponse(
            preferences=CompanionPreferences(),
            current_stage=1,
            stage_name="TESS Seed",
            interaction_count=1,
            active_routines_count=0,
            total_milestones=0,
            quiet_mode_active=False,
            personality_description="Friendly",
            available_stages=[]
        )

@pytest.fixture
def client():
    app.dependency_overrides[get_ai_provider] = lambda: MockAIProvider()
    app.dependency_overrides[get_current_user] = lambda: User(id="user-1")
    app.dependency_overrides[get_db_service] = lambda: MockDBService()
    app.dependency_overrides[get_prod_service] = lambda: MockProductivityService()
    app.dependency_overrides[get_future_service] = lambda: MockFutureService()
    app.dependency_overrides[get_companion_service] = lambda: MockCompanionService()
    
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
