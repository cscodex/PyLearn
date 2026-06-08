import asyncio
from app.db.session import AsyncSessionLocal
from app.models.user import User
from sqlalchemy.future import select
from app.core.security import get_password_hash

async def seed_users():
    async with AsyncSessionLocal() as db:
        users = [
            {"email": "admin@example.com", "role": "admin", "full_name": "Admin User"},
            {"email": "creator@example.com", "role": "creator", "full_name": "Creator User"},
            {"email": "student@example.com", "role": "student", "full_name": "Student User"},
        ]
        
        for u_data in users:
            result = await db.execute(select(User).filter(User.email == u_data["email"]))
            user = result.scalars().first()
            if not user:
                new_user = User(
                    email=u_data["email"],
                    password_hash=get_password_hash("password123"),
                    role=u_data["role"],
                    is_active=True,
                    full_name=u_data["full_name"]
                )
                db.add(new_user)
                print(f"Created {u_data['email']}")
            else:
                user.full_name = u_data["full_name"] # Ensure full_name is set
                print(f"{u_data['email']} already exists. Updated full_name.")
        
        await db.commit()

if __name__ == "__main__":
    asyncio.run(seed_users())
