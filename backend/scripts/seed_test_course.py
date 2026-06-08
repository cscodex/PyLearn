import asyncio
import os
import sys

# Add the parent directory to the path so we can import the app
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import AsyncSessionLocal
from app.models.course import Course, Module, Chapter, Lesson

async def seed_course():
    async with AsyncSessionLocal() as db:
        # Create Course
        course = Course(
            title="Python Advanced Masterclass 2",
            slug="python-advanced-masterclass-2",
            description="Deep dive into Python decorators, generators, async programming, and more.",
            difficulty="advanced",
            thumbnail_url="https://images.unsplash.com/photo-1526379095098-d400fd0bfce8?q=80&w=600&auto=format&fit=crop",
            is_published=True,
        )
        
        # Let's get an admin user
        from app.models.user import User
        from sqlalchemy.future import select
        
        result = await db.execute(select(User).filter(User.role == "admin"))
        admin = result.scalars().first()
        if admin:
            course.instructor_id = admin.id
            
        db.add(course)
        await db.flush()
        
        print(f"Created Course: {course.title} (ID: {course.id})")
        
        # Module 1
        module1 = Module(
            course_id=course.id,
            title="Advanced Functions",
            description="Master decorators and generators.",
            order_index=1
        )
        db.add(module1)
        await db.flush()
        
        # Chapter 1.1
        chapter1 = Chapter(
            module_id=module1.id,
            title="Decorators Demystified",
            order_index=1
        )
        db.add(chapter1)
        await db.flush()
        
        # Lesson 1.1.1 (Video)
        lesson1 = Lesson(
            chapter_id=chapter1.id,
            title="What are Decorators?",
            content_type="video",
            content_body={"text": "A decorator is a function that takes another function and extends the behavior of the latter function without explicitly modifying it."},
            video_url="https://www.youtube.com/watch?v=FsAPt_9Bf3U",
            order_index=1
        )
        # Lesson 1.1.2 (Code Challenge)
        lesson2 = Lesson(
            chapter_id=chapter1.id,
            title="Implement a Timing Decorator",
            content_type="code_challenge",
            content_body={"text": "Write a decorator `timeit` that prints the execution time of a function."},
            order_index=2
        )
        # Lesson 1.1.3 (Quiz)
        lesson3 = Lesson(
            chapter_id=chapter1.id,
            title="Decorators Quiz",
            content_type="quiz",
            content_body={"text": "Test your knowledge on decorators."},
            order_index=3
        )
        
        db.add_all([lesson1, lesson2, lesson3])
        await db.flush()
        
        # Module 2
        module2 = Module(
            course_id=course.id,
            title="Asynchronous Programming",
            description="Learn async/await in Python.",
            order_index=2
        )
        db.add(module2)
        await db.flush()
        
        # Chapter 2.1
        chapter2 = Chapter(
            module_id=module2.id,
            title="AsyncIO Basics",
            order_index=1
        )
        db.add(chapter2)
        await db.flush()
        
        # Lesson 2.1.1
        lesson4 = Lesson(
            chapter_id=chapter2.id,
            title="Introduction to AsyncIO",
            content_type="video",
            content_body={"text": "AsyncIO is a library to write concurrent code using the async/await syntax."},
            order_index=1
        )
        db.add(lesson4)
        await db.commit()
        
        print("Course seeding completed successfully!")

if __name__ == "__main__":
    asyncio.run(seed_course())
