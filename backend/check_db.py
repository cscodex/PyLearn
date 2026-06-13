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
        # Check saved_programs
        result = await session.execute(text("SELECT COUNT(*) FROM saved_programs"))
        print("Saved programs count:", result.scalar())
        
        # Check enrollments
        result = await session.execute(text("SELECT COUNT(*) FROM enrollments"))
        print("Enrollments count:", result.scalar())

asyncio.run(check())
