import asyncio
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy import select
from app.models.course import Course
from app.models.progress import Enrollment

engine = create_async_engine("sqlite+aiosqlite:///./sql_app.db")
async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async def main():
    async with async_session() as session:
        result = await session.execute(select(Course).join(Enrollment, Enrollment.course_id == Course.id))
        courses = result.scalars().all()
        for course in courses:
            print(f"Course: {course.id}, {course.title}, {course.difficulty}")
            
asyncio.run(main())
