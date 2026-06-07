from fastapi import APIRouter, Depends
from typing import Any

from app.api import deps
from app.models.user import User
from app.schemas.user import UserStatsResponse

router = APIRouter()

@router.get("/me/stats", response_model=UserStatsResponse)
async def get_my_stats(
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Get the current user's profile and progress stats."""
    return UserStatsResponse(
        id=current_user.id,
        full_name=current_user.full_name,
        email=current_user.email,
        xp=current_user.xp,
        streak_days=current_user.streak_days,
        profile_picture_url=current_user.profile_picture_url
    )
