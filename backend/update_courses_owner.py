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
        # Get the ID of the user with charanpreetsinghg
        res = await session.execute(text("SELECT id, email FROM users WHERE email LIKE '%charanpreet%' LIMIT 1"))
        user = res.fetchone()
        if user:
            print(f"Found user: {user}")
            user_id = user[0]
            await session.execute(text(f"UPDATE courses SET instructor_id = '{user_id}'"))
            await session.commit()
            print("Successfully updated all courses to belong to this user!")
        else:
            print("User charanpreet not found!")

asyncio.run(check())
