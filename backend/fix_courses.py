import asyncio
import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text

load_dotenv()

async def fix():
    engine = create_async_engine(os.getenv("DATABASE_URL"))
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        result = await session.execute(text("SELECT id, email, role FROM users"))
        users = result.fetchall()
        print("Users:", users)
        
        # let's just set instructor_id to the user who isn't test creator
        creator_id = None
        for u in users:
            if u[2] in ('creator', 'admin'):
                creator_id = u[0]
        
        if creator_id:
            await session.execute(text(f"UPDATE courses SET instructor_id = '{creator_id}'"))
            await session.commit()
            print(f"Updated all courses to instructor_id {creator_id}")
        else:
            print("No suitable creator found.")

asyncio.run(fix())
