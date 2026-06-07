from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
import uuid

from app.api import deps
from app.models.user import User
from app.models.group import Group, GroupMember, GroupAssignment
from app.models.course import Enrollment
from app.schemas.group import GroupCreate, GroupResponse, GroupStudentCreate, GroupAssignmentCreate, GroupAssignmentResponse
from app.core.security import get_password_hash

router = APIRouter()

def check_creator_permission(user: User):
    if user.role not in ["creator", "admin"]:
        raise HTTPException(status_code=403, detail="Only creators and admins can perform this action")

@router.post("/", response_model=GroupResponse)
async def create_group(
    group_in: GroupCreate,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Create a new student group/classroom."""
    check_creator_permission(current_user)
    
    group = Group(
        name=group_in.name,
        creator_id=current_user.id
    )
    db.add(group)
    await db.commit()
    await db.refresh(group)
    
    return GroupResponse(
        id=group.id,
        name=group.name,
        creator_id=group.creator_id,
        created_at=group.created_at,
        member_count=0
    )

@router.get("/", response_model=List[GroupResponse])
async def get_my_groups(
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """List all groups managed by the current creator."""
    check_creator_permission(current_user)
    
    result = await db.execute(select(Group).filter(Group.creator_id == current_user.id))
    groups = result.scalars().all()
    
    response_groups = []
    for g in groups:
        count_res = await db.execute(select(func.count(GroupMember.user_id)).filter(GroupMember.group_id == g.id))
        m_count = count_res.scalar() or 0
        response_groups.append(GroupResponse(
            id=g.id,
            name=g.name,
            creator_id=g.creator_id,
            created_at=g.created_at,
            member_count=m_count
        ))
    return response_groups

@router.post("/{group_id}/users", response_model=dict)
async def add_student_to_group(
    group_id: int,
    student_in: GroupStudentCreate,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Create a new student account and add them to the group."""
    check_creator_permission(current_user)
    
    # Verify group ownership
    group_res = await db.execute(select(Group).filter(Group.id == group_id, Group.creator_id == current_user.id))
    if not group_res.scalars().first():
        raise HTTPException(status_code=404, detail="Group not found")
        
    # Check if user email already exists
    user_res = await db.execute(select(User).filter(User.email == student_in.email))
    if user_res.scalars().first():
        raise HTTPException(status_code=400, detail="User with this email already exists")
        
    # Create the user
    new_user = User(
        email=student_in.email,
        full_name=student_in.full_name,
        password_hash=get_password_hash(student_in.password),
        role="student",
        is_active=True,
        email_verified=True # Auto-verify creator-made accounts
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    
    # Add user to group
    member = GroupMember(
        group_id=group_id,
        user_id=new_user.id
    )
    db.add(member)
    await db.commit()
    
    return {"status": "success", "user_id": str(new_user.id)}

@router.post("/{group_id}/assign", response_model=GroupAssignmentResponse)
async def assign_course_to_group(
    group_id: int,
    assign_in: GroupAssignmentCreate,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Assign a course to the entire group. If mandatory, auto-enrolls everyone."""
    check_creator_permission(current_user)
    
    # Verify group ownership
    group_res = await db.execute(select(Group).filter(Group.id == group_id, Group.creator_id == current_user.id))
    if not group_res.scalars().first():
        raise HTTPException(status_code=404, detail="Group not found")
        
    # Create assignment
    assignment = GroupAssignment(
        group_id=group_id,
        course_id=assign_in.course_id,
        assigned_by=current_user.id,
        assignment_type=assign_in.assignment_type
    )
    db.add(assignment)
    await db.commit()
    await db.refresh(assignment)
    
    # If mandatory, we should auto-enroll existing students
    if assign_in.assignment_type == "mandatory":
        members_res = await db.execute(select(GroupMember).filter(GroupMember.group_id == group_id))
        members = members_res.scalars().all()
        for m in members:
            # Check if already enrolled
            enroll_res = await db.execute(select(Enrollment).filter(Enrollment.user_id == m.user_id, Enrollment.course_id == assign_in.course_id))
            if not enroll_res.scalars().first():
                new_enroll = Enrollment(
                    user_id=m.user_id,
                    course_id=assign_in.course_id
                )
                db.add(new_enroll)
        await db.commit()
        
    return GroupAssignmentResponse(
        id=assignment.id,
        group_id=assignment.group_id,
        course_id=assignment.course_id,
        assigned_by=assignment.assigned_by,
        assignment_type=assignment.assignment_type,
        created_at=assignment.created_at
    )
