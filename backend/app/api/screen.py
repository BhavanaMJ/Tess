from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from typing import Optional, Any
from app.services.screen.service import ScreenService
from app.core.auth import get_current_user

router = APIRouter(tags=["screen"])

def _extract_user_id(user: Any) -> str:
    if hasattr(user, "id"):
        return str(user.id)
    if isinstance(user, dict) and "id" in user:
        return str(user["id"])
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid user session")

@router.post("/analyze")
async def analyze_screen_capture(
    file: UploadFile = File(...),
    query: str = Form("Explain what is visible on the screen and any errors."),
    user: Any = Depends(get_current_user)
):
    user_id = _extract_user_id(user)
    """
    User-authorized screen understanding endpoint.
    Receives an explicitly user-submitted screenshot and query.
    """
    try:
        content = await file.read()
        if not content:
            raise HTTPException(status_code=400, detail="Empty screenshot file")
        result = await ScreenService.analyze_screen(content, query)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
