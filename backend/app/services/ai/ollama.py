import httpx
from fastapi import HTTPException
from app.services.ai.base import BaseAIProvider

class OllamaProvider(BaseAIProvider):
    def __init__(self, base_url: str, model: str):
        self.base_url = base_url
        self.model = model
        self.api_url = f"{self.base_url.rstrip('/')}/api/generate"

    async def chat(self, message: str) -> str:
        payload = {
            "model": self.model,
            "prompt": message,
            "stream": False
        }
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(self.api_url, json=payload, timeout=180.0)
                response.raise_for_status()
                data = response.json()
                return data.get("response", "")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Ollama provider error: {str(e)}")
