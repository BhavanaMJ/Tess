from app.core.config import settings
from app.services.ai.base import BaseAIProvider
from app.services.ai.ollama import OllamaProvider
from app.services.ai.openrouter import OpenRouterProvider

def get_ai_provider() -> BaseAIProvider:
    if settings.ai_provider.lower() == "ollama":
        return OllamaProvider(base_url=settings.ollama_base_url, model=settings.ollama_model)
    elif settings.ai_provider.lower() == "openrouter":
        return OpenRouterProvider(api_key=settings.openrouter_api_key, model=settings.openrouter_model)
    else:
        raise ValueError(f"Unknown AI provider: {settings.ai_provider}")
