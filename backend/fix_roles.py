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
        # Revert 'userX@example.com' back to student
        await session.execute(text("UPDATE users SET role='student' WHERE email LIKE 'user%@example.com'"))
        
        # Make 'creator@example.com' a creator
        await session.execute(text("UPDATE users SET role='creator' WHERE email='creator@example.com'"))
        
        # Make sure the current instructor is also creator or admin
        await session.execute(text("UPDATE users SET role='admin' WHERE email='charanpreetsinghg@gmail.com'"))
        await session.execute(text("UPDATE users SET role='admin' WHERE email='singh'"))
        
        await session.commit()
        print("Updated user roles successfully.")

asyncio.run(check())
