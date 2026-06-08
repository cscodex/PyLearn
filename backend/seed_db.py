import asyncio
import os
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
import bcrypt
import uuid
from datetime import datetime, timezone

load_dotenv()

def get_hash(password: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')

async def seed():
    engine = create_async_engine(os.getenv("DATABASE_URL"))
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        # Check if admin exists
        result = await session.execute(text("SELECT id FROM users WHERE email = 'admin@cscodex.com'"))
        admin_row = result.fetchone()
        
        if not admin_row:
            admin_id = str(uuid.uuid4())
            await session.execute(text(f"""
                INSERT INTO users (id, email, password_hash, full_name, role, is_active, email_verified, created_at, updated_at)
                VALUES ('{admin_id}', 'admin@cscodex.com', '{get_hash("Admin@123")}', 'System Admin', 'admin', true, true, '{datetime.now(timezone.utc).isoformat()}', '{datetime.now(timezone.utc).isoformat()}')
            """))
            await session.execute(text(f"""
                INSERT INTO user_profiles (user_id, bio) VALUES ('{admin_id}', 'System Administrator')
            """))
            print("Created Admin user: admin@cscodex.com / Admin@123")
        else:
            admin_id = admin_row[0]
            print("Admin user already exists.")
            
        # Seed test courses
        course_result = await session.execute(text("SELECT count(*) FROM courses"))
        if course_result.scalar() == 0:
            await session.execute(text(f"""
                INSERT INTO courses (title, slug, description, instructor_id, difficulty, is_published)
                VALUES ('Python for Beginners', 'python-for-beginners', 'Learn the basics of Python programming.', '{admin_id}', 'beginner', true)
            """))
            await session.execute(text(f"""
                INSERT INTO courses (title, slug, description, instructor_id, difficulty, is_published)
                VALUES ('Data Structures in Python', 'data-structures-in-python', 'Master lists, dictionaries, and sets.', '{admin_id}', 'intermediate', true)
            """))
            print("Created sample courses.")
            
        # Seed dummy users for leaderboard
        users_result = await session.execute(text("SELECT count(*) FROM users"))
        if users_result.scalar() < 5:
            names = ["Alice Smith", "Bob Jones", "Charlie Brown", "Diana Prince"]
            for i, name in enumerate(names):
                uid = str(uuid.uuid4())
                await session.execute(text(f"""
                    INSERT INTO users (id, email, password_hash, full_name, role, is_active)
                    VALUES ('{uid}', 'user{i}@example.com', '{get_hash("password")}', '{name}', 'student', true)
                """))
                await session.execute(text(f"""
                    INSERT INTO user_profiles (user_id) VALUES ('{uid}')
                """))
                # Add score
                score = (4 - i) * 150 + 50 # random scores
                await session.execute(text(f"""
                    INSERT INTO user_scores (user_id, total_xp, level) VALUES ('{uid}', {score}, {score // 100 + 1})
                """))
            print("Created dummy users and leaderboard scores.")
            
        await session.commit()
        print("Database seeding completed successfully.")

asyncio.run(seed())
