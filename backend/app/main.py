from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.logging_config import setup_logging
from app.api.endpoints import router as api_router
from app.api.productivity import router as prod_router
from app.api.future import router as future_router
from app.api.proactive import router as proactive_router
from app.api.agent import router as agent_router
from app.api.voice import router as voice_router
from app.api.screen import router as screen_router
from app.api.companion import router as companion_router
from app.api.wardrobe import router as wardrobe_router
from app.api.wardrobe_capture import router as wardrobe_capture_router
from app.api.wardrobe_laundry import router as wardrobe_laundry_router
from app.api.wardrobe_outfit import router as wardrobe_outfit_router
from app.core.config import settings

# Initialize robust rotating logging with sensitive data masking
setup_logging()

app = FastAPI(title="TESS API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # For development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {"status": "ok"}

app.include_router(api_router, prefix="/api/v1")
app.include_router(prod_router, prefix="/api/v1/productivity")
app.include_router(future_router, prefix="/api/v1/future")
app.include_router(proactive_router, prefix="/api/v1/proactive")
app.include_router(agent_router, prefix="/api/v1/agent")
app.include_router(voice_router, prefix="/api/v1/voice")
app.include_router(screen_router, prefix="/api/v1/screen")
app.include_router(companion_router, prefix="/api/v1/companion")
app.include_router(wardrobe_router, prefix="/api/v1/wardrobe")
app.include_router(wardrobe_capture_router, prefix="/api/v1/wardrobe/capture")
app.include_router(wardrobe_laundry_router)
app.include_router(wardrobe_outfit_router)
