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
        # Check saved_programs without join
        res = await session.execute(text("SELECT COUNT(*) FROM saved_programs"))
        print("Raw saved_programs count:", res.scalar())
        
        # Check saved_programs WITH join
        res = await session.execute(text("SELECT COUNT(*) FROM saved_programs JOIN users ON saved_programs.user_id = users.id"))
        print("Joined saved_programs count:", res.scalar())

        # Check enrollments WITH join
        res = await session.execute(text("SELECT COUNT(*) FROM enrollments JOIN users ON enrollments.user_id = users.id JOIN courses ON enrollments.course_id = courses.id"))
        print("Joined enrollments count:", res.scalar())

asyncio.run(check())
