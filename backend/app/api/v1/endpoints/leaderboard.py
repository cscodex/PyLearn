from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import Any

from app.api import deps
from app.models.user import User
from app.schemas.user import LeaderboardResponse, LeaderboardUser

router = APIRouter()

@router.get("/", response_model=LeaderboardResponse)
async def get_global_leaderboard(
    limit: int = 50,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Get the global XP leaderboard."""
    
    stmt = select(User).where(User.xp > 0).order_by(desc(User.xp)).limit(limit)
    result = await db.execute(stmt)
    top_users = result.scalars().all()
    
    leaderboard_users = []
    current_user_rank = None
    
    for i, user in enumerate(top_users):
        rank = i + 1
        leaderboard_users.append(
            LeaderboardUser(
                id=user.id,
                full_name=user.full_name,
                xp=user.xp,
                profile_picture_url=user.profile_picture_url,
                rank=rank
            )
        )
        if user.id == current_user.id:
            current_user_rank = rank
            
    # If current user is not in top limit, we might need to query their rank separately
    # For now, if they aren't in the list, we just return None for their rank or query it
    if current_user_rank is None and current_user.xp > 0:
        # Count how many users have more XP than current_user
        count_stmt = select(User).where(User.xp > current_user.xp)
        count_res = await db.execute(count_stmt)
        better_users = len(count_res.scalars().all())
        current_user_rank = better_users + 1
        
    return LeaderboardResponse(
        users=leaderboard_users,
        current_user_rank=current_user_rank
    )
