import re

with open('../backend/app/api/v1/endpoints/admin.py', 'r') as f:
    content = f.read()

import_statement = "from app.schemas.user import UserAdminResponse, AdminUserCreate\nfrom app.core.security import get_password_hash\n"

# replace the UserAdminResponse import
content = content.replace("from app.schemas.user import UserAdminResponse", import_statement)

new_endpoint = """
@router.post("/users", response_model=UserAdminResponse)
async def create_user(
    user_in: AdminUserCreate,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user)
) -> Any:
    \"\"\"
    Create a new user. Only accessible to admins.
    \"\"\"
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not enough permissions")
        
    result = await db.execute(select(User).filter(User.email == user_in.email))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="User with this email already exists")
        
    user = User(
        email=user_in.email,
        full_name=user_in.full_name,
        role=user_in.role,
        password_hash=get_password_hash(user_in.password),
        is_active=True
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    
    return UserAdminResponse(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role,
        is_active=user.is_active,
        created_at=user.created_at.isoformat() if user.created_at else ""
    )
"""

# Insert new endpoint before list_users
content = content.replace("@router.get(\"/users\",", new_endpoint + "\n@router.get(\"/users\",")

with open('../backend/app/api/v1/endpoints/admin.py', 'w') as f:
    f.write(content)

print("Patched admin.py")
