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
        # Update everyone to admin just in case since this is local testing
        await session.execute(text("UPDATE users SET role = 'admin'"))
        
        # Or better, just get the first user who logged in via google
        result = await session.execute(text("SELECT id FROM users ORDER BY created_at DESC LIMIT 1"))
        latest_user = result.fetchone()
        if latest_user:
            user_id = latest_user[0]
            await session.execute(text(f"UPDATE courses SET instructor_id = '{user_id}'"))
            print(f"Updated all courses to be owned by latest user: {user_id}")
            
        await session.commit()
        print("Updated all users to admin role.")

asyncio.run(fix())
