import re

with open('../backend/app/api/v1/endpoints/creator_groups.py', 'r') as f:
    content = f.read()

new_endpoint = """
@router.get("/{group_id}/users", response_model=List[UserAdminResponse])
async def get_group_users(
    group_id: int,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    \"\"\"Get all users currently in the group.\"\"\"
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
"""

content = content.replace("@router.post(\"/{group_id}/users\", response_model=dict)", new_endpoint + "\n@router.post(\"/{group_id}/users\", response_model=dict)")

with open('../backend/app/api/v1/endpoints/creator_groups.py', 'w') as f:
    f.write(content)

print("Patched creator_groups.py")
