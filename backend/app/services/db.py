from supabase import Client
from typing import List, Optional
from app.schemas.domain import Conversation, Message, Memory

class DBService:
    def __init__(self, supabase: Client, user_id: str):
        self.supabase = supabase
        self.user_id = user_id

    # Conversations
    def create_conversation(self, title: str = "New Conversation") -> Conversation:
        data = {"user_id": self.user_id, "title": title}
        resp = self.supabase.table("conversations").insert(data).execute()
        return Conversation(**resp.data[0])

    def get_conversations(self) -> List[Conversation]:
        resp = self.supabase.table("conversations").select("*").eq("user_id", self.user_id).order("updated_at", desc=True).execute()
        return [Conversation(**item) for item in resp.data]
    
    def get_conversation_messages(self, conversation_id: str) -> List[Message]:
        # RLS ensures we only get our own messages
        resp = self.supabase.table("messages").select("*").eq("conversation_id", conversation_id).order("created_at", desc=False).execute()
        return [Message(**item) for item in resp.data]

    # Messages
    def add_message(self, conversation_id: str, role: str, content: str) -> Message:
        data = {"conversation_id": conversation_id, "role": role, "content": content}
        resp = self.supabase.table("messages").insert(data).execute()
        # Trigger an update on the conversation's updated_at via a small hack or rely on trigger
        # We have a trigger in SQL, but we need to update the table directly to fire it if we only update messages
        self.supabase.table("conversations").update({"updated_at": "now()"}).eq("id", conversation_id).execute()
        return Message(**resp.data[0])

    # Memories
    def get_recent_memories(self, limit: int = 5) -> List[Memory]:
        resp = self.supabase.table("memories").select("*").eq("user_id", self.user_id).order("importance", desc=True).limit(limit).execute()
        return [Memory(**item) for item in resp.data]
    
    def add_memory(self, category: str, content: str, importance: int = 1) -> Memory:
        data = {"user_id": self.user_id, "category": category, "content": content, "importance": importance}
        resp = self.supabase.table("memories").insert(data).execute()
        return Memory(**resp.data[0])

    def update_memory(self, memory_id: str, updates: dict) -> Memory:
        updates["updated_at"] = "now()"
        self.supabase.table("memories").update(updates).eq("id", memory_id).eq("user_id", self.user_id).execute()
        resp = self.supabase.table("memories").select("*").eq("id", memory_id).eq("user_id", self.user_id).execute()
        return Memory(**resp.data[0])

    def delete_memory(self, memory_id: str):
        self.supabase.table("memories").delete().eq("id", memory_id).eq("user_id", self.user_id).execute()
