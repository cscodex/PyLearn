import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select

from app.db.session import engine, AsyncSessionLocal
from app.models.user import User
from app.models.course import Course
from app.models.progress import Enrollment
from datetime import datetime

async def main():
    async with AsyncSessionLocal() as db:
        # Get creator and student
        creator_res = await db.execute(select(User).filter(User.email == 'creator@example.com'))
        creator = creator_res.scalar_one_or_none()
        
        student_res = await db.execute(select(User).filter(User.email == 'student@example.com'))
        student = student_res.scalar_one_or_none()
        
        if not creator or not student:
            print("Missing creator or student")
            return
            
        # Get courses created by creator
        courses_res = await db.execute(select(Course).filter(Course.instructor_id == creator.id))
        courses = courses_res.scalars().all()
        
        for course in courses:
            # Check if enrolled
            enrollment_res = await db.execute(select(Enrollment).filter(Enrollment.user_id == student.id, Enrollment.course_id == course.id))
            enrollment = enrollment_res.scalar_one_or_none()
            if not enrollment:
                print(f"Enrolling student in {course.title}")
                enrollment = Enrollment(
                    user_id=student.id,
                    course_id=course.id,
                    enrolled_at=datetime.utcnow(),
                    progress_percentage=25.0
                )
                db.add(enrollment)
        
        await db.commit()
        print("Done!")

if __name__ == "__main__":
    asyncio.run(main())
