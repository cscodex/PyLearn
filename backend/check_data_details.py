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
        res = await session.execute(text("SELECT * FROM enrollments LIMIT 10"))
        print("\nEnrollments:")
        for r in res.fetchall():
            print(r)
            
        res = await session.execute(text("SELECT * FROM saved_programs LIMIT 10"))
        print("\nSaved Programs:")
        for r in res.fetchall():
            print(r)

asyncio.run(check())
