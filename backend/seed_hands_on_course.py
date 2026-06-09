import asyncio
import os
import json
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
from datetime import datetime, timezone

load_dotenv()

async def seed():
    engine = create_async_engine(os.getenv("DATABASE_URL"))
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        # Get creator
        result = await session.execute(text("SELECT id FROM users WHERE role = 'creator' LIMIT 1"))
        creator_row = result.fetchone()
        
        if not creator_row:
            print("No creator found.")
            return
            
        creator_id = creator_row[0]
        
        # Insert Course
        result = await session.execute(text(f"""
            INSERT INTO courses (title, slug, description, instructor_id, difficulty, is_published)
            VALUES ('Interactive Python Masterclass', 'interactive-python-masterclass', 'Learn Python by writing actual code. This course is completely hands-on.', '{creator_id}', 'beginner', true)
            RETURNING id
        """))
        course_id = result.fetchone()[0]

        # Insert Module
        result = await session.execute(text(f"""
            INSERT INTO modules (title, description, order_index, course_id)
            VALUES ('Module 1: The Basics', 'Start writing your first Python scripts.', 1, {course_id})
            RETURNING id
        """))
        module_id = result.fetchone()[0]

        # Insert Chapter
        result = await session.execute(text(f"""
            INSERT INTO chapters (title, description, order_index, module_id)
            VALUES ('Chapter 1: Print Statements', 'Learn how to output text.', 1, {module_id})
            RETURNING id
        """))
        chapter_id = result.fetchone()[0]

        # Insert Lesson
        content_body = json.dumps({
            "text": "Write a Python script that prints exactly 'Hello, PythonTutor!' to the console.",
            "starter_code": "def say_hello():\n    # Your code here\n    pass\n\nsay_hello()\n",
            "solution_code": "def say_hello():\n    print('Hello, PythonTutor!')\n\nsay_hello()\n"
        })
        
        # Use parameterized query to avoid quoting issues
        stmt = text("""
            INSERT INTO lessons (title, content_type, content_body, order_index, chapter_id)
            VALUES (:title, :type, :body, 1, :chap_id)
        """)
        await session.execute(stmt, {
            "title": 'Lesson 1: Hello World Challenge',
            "type": 'code_challenge',
            "body": content_body,
            "chap_id": chapter_id
        })

        await session.commit()
        print(f"Successfully seeded course with ID {course_id}")

asyncio.run(seed())
