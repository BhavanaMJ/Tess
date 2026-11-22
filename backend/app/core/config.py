from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional

class Settings(BaseSettings):
    supabase_url: Optional[str] = None
    supabase_anon_key: Optional[str] = None
    
    ai_provider: str = "ollama"
    
    ollama_base_url: str = "http://localhost:11434"
    ollama_model: str = "llama3.2:1b"
    
    openrouter_api_key: Optional[str] = None
    openrouter_model: Optional[str] = None

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

settings = Settings()
