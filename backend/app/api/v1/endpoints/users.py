from fastapi import APIRouter, Depends
from typing import Any, List

from app.api import deps
from app.models.user import User
from app.models.course import Course
from app.models.progress import Enrollment
from app.schemas.user import UserStatsResponse, UserAchievementResponse, UserHistoryResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException
from app.models.group import Group, GroupMember, GroupAssignment
from app.schemas.group import GroupJoinRequest

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

@router.post("/me/join-group", response_model=dict)
async def join_group(
    req: GroupJoinRequest,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Join a group using a 6-digit join code."""
    # Find group by join code
    code = req.join_code.strip().upper()
    group_res = await db.execute(select(Group).filter(Group.join_code == code))
    group = group_res.scalars().first()
    
    if not group:
        raise HTTPException(status_code=404, detail="Invalid join code.")
        
    # Check if already a member
    member_res = await db.execute(select(GroupMember).filter(GroupMember.group_id == group.id, GroupMember.user_id == current_user.id))
    if member_res.scalars().first():
        return {"status": "success", "message": "Already a member of this group.", "group_name": group.name}
        
    # Join the group
    member = GroupMember(group_id=group.id, user_id=current_user.id)
    db.add(member)
    
    # Auto-enroll in mandatory courses assigned to this group
    assignments_res = await db.execute(select(GroupAssignment).filter(GroupAssignment.group_id == group.id, GroupAssignment.assignment_type == "mandatory"))
    for a in assignments_res.scalars().all():
        enroll_res = await db.execute(select(Enrollment).filter(Enrollment.user_id == current_user.id, Enrollment.course_id == a.course_id))
        if not enroll_res.scalars().first():
            db.add(Enrollment(user_id=current_user.id, course_id=a.course_id))
            
    await db.commit()
    return {"status": "success", "message": f"Successfully joined {group.name}", "group_name": group.name}

@router.get("/me/achievements", response_model=List[UserAchievementResponse])
async def get_my_achievements(
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Get the current user's achievements and badges."""
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
    """Get the current user's learning history."""
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
