import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select

from app.db.session import engine, AsyncSessionLocal
from app.models.user import User

async def main():
    async with AsyncSessionLocal() as db:
        users_res = await db.execute(select(User.email))
        users = users_res.scalars().all()
        for u in users:
            print(u)

if __name__ == "__main__":
    asyncio.run(main())
