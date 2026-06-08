from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
import uuid

from app.api import deps
from app.models.user import User
from app.models.group import Group, GroupMember, GroupAssignment
from app.models.progress import Enrollment
from app.schemas.group import GroupCreate, GroupResponse, GroupStudentCreate, GroupAssignmentCreate, GroupAssignmentResponse
from app.schemas.user import UserAdminResponse
from app.core.security import get_password_hash

router = APIRouter()

@router.get("/users/search", response_model=List[UserAdminResponse])
async def search_students(
    query: str,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Search for students by email or full name."""
    check_creator_permission(current_user)
    
    result = await db.execute(
        select(User)
        .filter(User.role == "student")
        .filter((User.email.ilike(f"%{query}%")) | (User.full_name.ilike(f"%{query}%")))
        .limit(20)
    )
    users = result.scalars().all()
    
    return [
        UserAdminResponse(
            id=u.id,
            email=u.email,
            full_name=u.full_name,
            role=u.role,
            is_active=u.is_active,
            created_at=u.created_at.isoformat() if u.created_at else ""
        ) for u in users
    ]
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
    if current_user.role == "admin":
        result = await db.execute(select(Group))
    else:
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


@router.get("/{group_id}/users", response_model=List[UserAdminResponse])
async def get_group_users(
    group_id: int,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Get all users currently in the group."""
    check_creator_permission(current_user)
    
    group_res = await db.execute(select(Group).filter(Group.id == group_id, Group.creator_id == current_user.id))
    if not group_res.scalars().first():
        raise HTTPException(status_code=404, detail="Group not found")
        
    result = await db.execute(
        select(User)
        .join(GroupMember, GroupMember.user_id == User.id)
        .filter(GroupMember.group_id == group_id)
    )
    users = result.scalars().all()
    
    return [
        UserAdminResponse(
            id=u.id,
            email=u.email,
            full_name=u.full_name,
            role=u.role,
            is_active=u.is_active,
            created_at=u.created_at.isoformat() if u.created_at else ""
        ) for u in users
    ]

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

from app.schemas.group import GroupUpdate, GroupAddStudentsBulk, GroupAssignCoursesBulk

@router.put("/{group_id}", response_model=GroupResponse)
async def update_group(
    group_id: int,
    group_in: GroupUpdate,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Update a group."""
    check_creator_permission(current_user)
    
    result = await db.execute(select(Group).filter(Group.id == group_id, Group.creator_id == current_user.id))
    group = result.scalars().first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
        
    if group_in.name is not None:
        group.name = group_in.name
        
    await db.commit()
    await db.refresh(group)
    
    # get count
    count_res = await db.execute(select(func.count(GroupMember.user_id)).filter(GroupMember.group_id == group.id))
    m_count = count_res.scalar() or 0
    
    return GroupResponse(
        id=group.id,
        name=group.name,
        creator_id=group.creator_id,
        created_at=group.created_at,
        member_count=m_count
    )

@router.delete("/{group_id}", response_model=dict)
async def delete_group(
    group_id: int,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Delete a group."""
    check_creator_permission(current_user)
    
    result = await db.execute(select(Group).filter(Group.id == group_id, Group.creator_id == current_user.id))
    group = result.scalars().first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
        
    await db.delete(group)
    await db.commit()
    
    return {"status": "success", "message": "Group deleted"}

@router.post("/{group_id}/users/bulk", response_model=dict)
async def add_students_bulk(
    group_id: int,
    bulk_in: GroupAddStudentsBulk,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Add multiple existing students to a group."""
    check_creator_permission(current_user)
    
    # Verify group ownership
    group_res = await db.execute(select(Group).filter(Group.id == group_id, Group.creator_id == current_user.id))
    if not group_res.scalars().first():
        raise HTTPException(status_code=404, detail="Group not found")
        
    added = 0
    for uid in bulk_in.user_ids:
        # Check if already a member
        member_res = await db.execute(select(GroupMember).filter(GroupMember.group_id == group_id, GroupMember.user_id == uid))
        if not member_res.scalars().first():
            member = GroupMember(group_id=group_id, user_id=uid)
            db.add(member)
            added += 1
            
    if added > 0:
        await db.commit()
        
    return {"status": "success", "added_count": added}

@router.post("/{group_id}/assign/bulk", response_model=dict)
async def assign_courses_bulk(
    group_id: int,
    bulk_in: GroupAssignCoursesBulk,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Assign multiple courses to a group."""
    check_creator_permission(current_user)
    
    group_res = await db.execute(select(Group).filter(Group.id == group_id, Group.creator_id == current_user.id))
    if not group_res.scalars().first():
        raise HTTPException(status_code=404, detail="Group not found")
        
    assigned = 0
    for cid in bulk_in.course_ids:
        # Check if already assigned
        assign_res = await db.execute(select(GroupAssignment).filter(GroupAssignment.group_id == group_id, GroupAssignment.course_id == cid))
        if not assign_res.scalars().first():
            assignment = GroupAssignment(
                group_id=group_id,
                course_id=cid,
                assigned_by=current_user.id,
                assignment_type=bulk_in.assignment_type
            )
            db.add(assignment)
            assigned += 1
            
            # If mandatory, enroll
            if bulk_in.assignment_type == "mandatory":
                members_res = await db.execute(select(GroupMember).filter(GroupMember.group_id == group_id))
                for m in members_res.scalars().all():
                    enroll_res = await db.execute(select(Enrollment).filter(Enrollment.user_id == m.user_id, Enrollment.course_id == cid))
                    if not enroll_res.scalars().first():
                        db.add(Enrollment(user_id=m.user_id, course_id=cid))
                        
    if assigned > 0:
        await db.commit()
        
    return {"status": "success", "assigned_count": assigned}

@router.delete("/{group_id}/members/{user_id}", response_model=dict)
async def remove_student_from_group(
    group_id: int,
    user_id: uuid.UUID,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Remove a student from a group."""
    check_creator_permission(current_user)
    
    group_res = await db.execute(select(Group).filter(Group.id == group_id, Group.creator_id == current_user.id))
    if not group_res.scalars().first():
        raise HTTPException(status_code=404, detail="Group not found")
        
    member_res = await db.execute(select(GroupMember).filter(GroupMember.group_id == group_id, GroupMember.user_id == user_id))
    member = member_res.scalars().first()
    
    if not member:
        raise HTTPException(status_code=404, detail="Student not found in group")
        
    await db.delete(member)
    await db.commit()
    
    return {"status": "success", "message": "Student removed from group"}

@router.get("/{group_id}/assignments", response_model=List[GroupAssignmentResponse])
async def get_group_assignments(
    group_id: int,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    """Get all courses assigned to a group."""
    check_creator_permission(current_user)
    
    group_res = await db.execute(select(Group).filter(Group.id == group_id, Group.creator_id == current_user.id))
    if not group_res.scalars().first():
        raise HTTPException(status_code=404, detail="Group not found")
        
    result = await db.execute(select(GroupAssignment).filter(GroupAssignment.group_id == group_id))
    assignments = result.scalars().all()
    
    return [
        GroupAssignmentResponse(
            id=a.id,
            group_id=a.group_id,
            course_id=a.course_id,
            assigned_by=a.assigned_by,
            assignment_type=a.assignment_type,
            created_at=a.created_at
        ) for a in assignments
    ]
