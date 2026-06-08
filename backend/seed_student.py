import asyncio
from app.db.session import AsyncSessionLocal
from app.models.user import User, UserProfile
from app.core.security import get_password_hash
from sqlalchemy.future import select

async def seed_student():
    async with AsyncSessionLocal() as session:
        # Check if student exists
        student = await session.execute(select(User).filter(User.email == "student@example.com"))
        student = student.scalars().first()
        if not student:
            print("Creating test student...")
            student = User(
                email="student@example.com",
                full_name="Test Student",
                password_hash=get_password_hash("password123"),
                role="student",
                is_active=True,
                email_verified=True
            )
            session.add(student)
            await session.flush()
            
            profile = UserProfile(user_id=student.id)
            session.add(profile)
            await session.commit()
            print("Student created: student@example.com / password123")
        else:
            print("Student already exists.")

if __name__ == "__main__":
    asyncio.run(seed_student())
