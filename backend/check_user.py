import asyncio
from sqlalchemy.future import select
from app.db.session import SessionLocal
from app.models.user import User

async def main():
    async with SessionLocal() as db:
        result = await db.execute(select(User).filter(User.email == "student@example.com"))
        user = result.scalars().first()
        if user:
            print(f"User found: {user.email}")
        else:
            print("User NOT found")

if __name__ == "__main__":
    asyncio.run(main())
