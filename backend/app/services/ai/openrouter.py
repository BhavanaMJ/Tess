import httpx
from fastapi import HTTPException
from app.services.ai.base import BaseAIProvider

class OpenRouterProvider(BaseAIProvider):
    def __init__(self, api_key: str, model: str):
        if not api_key or not model:
            raise ValueError("OpenRouter API key and model must be provided")
        self.api_key = api_key
        self.model = model
        self.api_url = "https://openrouter.ai/api/v1/chat/completions"

    async def chat(self, message: str) -> str:
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": self.model,
            "messages": [{"role": "user", "content": message}]
        }
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(self.api_url, json=payload, headers=headers, timeout=30.0)
                response.raise_for_status()
                data = response.json()
                choices = data.get("choices", [])
                if choices:
                    return choices[0].get("message", {}).get("content", "")
                return ""
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"OpenRouter provider error: {str(e)}")
