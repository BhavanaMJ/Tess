from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Any
import logging
from supabase import Client
from pydantic import BaseModel

from app.schemas.chat import ChatRequest, ChatResponse
from app.schemas.domain import Conversation, ConversationCreate, Message, Memory, MemoryCreate, MemoryUpdate
from app.services.ai.factory import get_ai_provider
from app.services.ai.base import BaseAIProvider
from app.core.auth import get_current_user, get_supabase_client, get_user_id
from app.services.db import DBService
from app.api.companion import get_companion_service
from app.services.companion.service import CompanionService
from app.services.companion.personality import PersonalityEngine
from app.services.companion.memory_continuity import MemoryContinuityEngine

router = APIRouter()
logger = logging.getLogger(__name__)

TESS_PERSONALITY_PROMPT = """
You are TESS, a personal AI companion.
Personality traits: Warm, Intelligent, Calm, Concise, Helpful, Slightly proactive, Personal.
Rules:
- Be concise unless asked for details.
- Do not pretend to know things you do not know.
- Do not claim certainty about the future.
- Be a companion, not a generic robotic assistant.
- Do not constantly refer to yourself as TESS in every response.
"""

class ChatMessageRequest(BaseModel):
    message: str

def get_db_service(user: dict = Depends(get_current_user), supabase: Client = Depends(get_supabase_client)) -> DBService:
    return DBService(supabase=supabase, user_id=get_user_id(user))

@router.get("/conversations", response_model=List[Conversation])
def get_conversations(db: DBService = Depends(get_db_service)):
    return db.get_conversations()

@router.post("/conversations", response_model=Conversation)
def create_conversation(req: ConversationCreate, db: DBService = Depends(get_db_service)):
    return db.create_conversation(title=req.title)

@router.get("/conversations/{conversation_id}/messages", response_model=List[Message])
def get_messages(conversation_id: str, db: DBService = Depends(get_db_service)):
    return db.get_conversation_messages(conversation_id)

from app.api.productivity import get_prod_service
from app.services.productivity.service import ProductivityService
from app.api.future import get_future_service
from app.services.future.service import FutureService

@router.post("/conversations/{conversation_id}/messages", response_model=ChatResponse)
async def chat_in_conversation(
    conversation_id: str,
    req: ChatMessageRequest,
    db: DBService = Depends(get_db_service),
    provider: BaseAIProvider = Depends(get_ai_provider),
    prod_service: ProductivityService = Depends(get_prod_service),
    future_service: FutureService = Depends(get_future_service),
    companion_service: CompanionService = Depends(get_companion_service)
):
    try:
        # 1. Save user message & record interaction
        db.add_message(conversation_id=conversation_id, role="user", content=req.message)
        try:
            companion_service.increment_interaction()
        except Exception:
            pass
        
        # 2. Load recent messages
        history = db.get_conversation_messages(conversation_id)
        
        # 3. Load memories & Productivity Context with Memory Continuity
        all_memories = db.get_recent_memories(limit=30)
        memories_dict_list = [m.model_dump() for m in all_memories]
        relevant_memories = MemoryContinuityEngine.select_relevant_memories(memories_dict_list, req.message, limit=5)
        memory_context = MemoryContinuityEngine.format_memories_for_prompt(relevant_memories)

        active_tasks = prod_service.get_active_tasks()
        productivity_context = ""
        if active_tasks:
            summary = prod_service.get_summary()
            productivity_context = f"\nUser's Current Productivity State (FACTS):\n- Overdue: {summary.overdue}\n- Due Today: {summary.due_today}\n- Active tasks: {summary.total_active}\n"
            productivity_context += "Here is a list of the user's active work packages:\n"
            for t in active_tasks[:10]: # limit to avoid blowing up context
                productivity_context += f"- [{t.external_id}] {t.title} (Status: {t.status}, Priority: {t.priority})\n"

        # 4. Check Future Intent
        msg_lower = req.message.lower()
        future_keywords = ["what will happen", "what is likely to happen", "where am i heading", "am i on track", "what happens if", "risks do you see", "risks do i have", "tomorrow look like", "meet tomorrow me", "show me tomorrow"]
        
        future_context = ""
        is_future_intent = any(kw in msg_lower for kw in future_keywords)
        
        if is_future_intent:
            try:
                # Trigger a fresh simulation (e.g. 24h horizon for chat context)
                sim_result = future_service.simulate("24h")
                scenario = sim_result.scenario
                alt = sim_result.alternative
                
                future_context = f"\nUser's Probable Future Trajectory (SIMULATION - 24h horizon):\n"
                future_context += f"A possible future — not a prediction of certainty.\n"
                future_context += f"- Title: {scenario.title}\n"
                future_context += f"- Summary: {scenario.summary}\n"
                future_context += "Timeline:\n"
                for ev in scenario.events:
                    future_context += f"  > [{ev.relative_time}] {ev.title}: {ev.description}\n"
                    
                if alt:
                    future_context += f"\nAlternative Path (ONE CHANGE):\n"
                    future_context += f"- Action: {alt.action}\n"
                    future_context += f"- Expected Effect: {alt.expected_effect}\n"
            except Exception as e:
                future_context = "\nUser's Probable Future Trajectories:\nSimulation unavailable at the moment.\n"

        # 5. Construct AI context with Adaptive Personality
        try:
            prefs = companion_service.get_preferences().model_dump()
            system_prompt = PersonalityEngine.build_system_prompt(prefs)
        except Exception:
            system_prompt = TESS_PERSONALITY_PROMPT

        context_lines = [system_prompt, memory_context, productivity_context, future_context, "\nConversation History:"]
        for msg in history[-10:]: # include last 10 messages
            context_lines.append(f"{msg.role.capitalize()}: {msg.content}")
        
        # Add a prompt for the assistant to reply
        context_lines.append("Assistant:")
        
        full_prompt = "\n".join(context_lines)
        
        # 6. Get AI response
        response_text = await provider.chat(full_prompt)
        
        # 7. Save assistant message
        db.add_message(conversation_id=conversation_id, role="assistant", content=response_text)
        
        return ChatResponse(response=response_text)
    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/memories", response_model=List[Memory])
def get_memories(db: DBService = Depends(get_db_service)):
    return db.get_recent_memories(limit=50)

@router.post("/memories", response_model=Memory)
def create_memory(req: MemoryCreate, db: DBService = Depends(get_db_service)):
    return db.add_memory(category=req.category, content=req.content, importance=req.importance)

@router.put("/memories/{memory_id}", response_model=Memory)
def update_memory(memory_id: str, req: MemoryUpdate, db: DBService = Depends(get_db_service)):
    """Update or correct a personal memory item."""
    updates = req.model_dump(exclude_unset=True)
    return db.update_memory(memory_id, updates)

@router.delete("/memories/{memory_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_memory(memory_id: str, db: DBService = Depends(get_db_service)):
    db.delete_memory(memory_id)
    return None

class DeviceRegisterRequest(BaseModel):
    device_id: str
    device_name: str
    platform: str

@router.post("/devices/register")
def register_device(
    req: DeviceRegisterRequest,
    user: Any = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    try:
        user_id = str(user.id if hasattr(user, "id") else user["id"])
        data = {
            "user_id": user_id,
            "device_id": req.device_id,
            "device_name": req.device_name,
            "platform": req.platform,
            "last_seen_at": "now()"
        }
        res = supabase.table("user_devices").upsert(data, on_conflict="user_id,device_id").execute()
        return {"status": "success", "device_id": req.device_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to register device: {str(e)}")

@router.get("/devices")
def get_user_devices(
    user: Any = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    try:
        user_id = str(user.id if hasattr(user, "id") else user["id"])
        res = supabase.table("user_devices").select("*").eq("user_id", user_id).order("last_seen_at", desc=True).execute()
        return res.data or []
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

