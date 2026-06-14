import asyncio
import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text

load_dotenv()
async def check():
    engine = create_async_engine(os.getenv("DATABASE_URL"))
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as session:
        await session.execute(text("UPDATE users SET role='student' WHERE email='student@example.com'"))
        
        # also assign all courses to cs3052hig@gmail.com and admin@example.com just in case
        res = await session.execute(text("SELECT id FROM users WHERE email='cs3052hig@gmail.com' LIMIT 1"))
        user = res.fetchone()
        if user:
            await session.execute(text(f"UPDATE courses SET instructor_id='{user[0]}'"))
        
        await session.commit()
        print("Updated student role and course instructor.")

asyncio.run(check())
