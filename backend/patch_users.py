import re

with open("app/api/v1/endpoints/users.py", "r") as f:
    content = f.read()

new_imports = """from fastapi import APIRouter, Depends
from typing import Any, List

from app.api import deps
from app.models.user import User
from app.models.course import Course
from app.models.progress import Enrollment
from app.schemas.user import UserStatsResponse, UserAchievementResponse, UserHistoryResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession"""

content = content.replace("""from fastapi import APIRouter, Depends
from typing import Any

from app.api import deps
from app.models.user import User
from app.schemas.user import UserStatsResponse""", new_imports)

new_endpoints = """
@router.get("/me/achievements", response_model=List[UserAchievementResponse])
async def get_my_achievements(
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    \"\"\"Get the current user's achievements and badges.\"\"\"
    # Dummy data for now
    return [
        UserAchievementResponse(
            id="badge-1",
            title="First Step",
            description="Completed your first lesson.",
            icon_url="https://cdn-icons-png.flaticon.com/512/5486/5486203.png",
            unlocked_at="2026-01-01T10:00:00Z"
        ),
        UserAchievementResponse(
            id="badge-2",
            title="Python Pioneer",
            description="Finished 5 Python challenges.",
            icon_url="https://cdn-icons-png.flaticon.com/512/5486/5486208.png",
            unlocked_at="2026-01-05T14:30:00Z"
        )
    ]

@router.get("/me/history", response_model=List[UserHistoryResponse])
async def get_my_history(
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    \"\"\"Get the current user's learning history.\"\"\"
    enrollments_res = await db.execute(
        select(Enrollment, Course.title)
        .join(Course, Course.id == Enrollment.course_id)
        .filter(Enrollment.user_id == current_user.id)
        .order_by(Enrollment.enrolled_at.desc())
    )
    
    rows = enrollments_res.all()
    history = []
    for row in rows:
        enrollment, course_title = row
        history.append(UserHistoryResponse(
            course_id=enrollment.course_id,
            course_title=course_title,
            progress_percentage=float(enrollment.progress_percentage),
            last_accessed_at=enrollment.enrolled_at.isoformat() if enrollment.enrolled_at else None,
            completed_at=enrollment.completed_at.isoformat() if enrollment.completed_at else None
        ))
    return history
"""

content = content + new_endpoints

with open("app/api/v1/endpoints/users.py", "w") as f:
    f.write(content)

