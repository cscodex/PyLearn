import asyncio
from sqlalchemy.future import select
from app.db.session import AsyncSessionLocal
from app.models.user import User
from app.models.course import Course
from app.models.progress import Enrollment

async def main():
    async with AsyncSessionLocal() as db:
        # Get users
        student_res = await db.execute(select(User).filter(User.email == 'student@example.com'))
        student = student_res.scalars().first()
        
        creator_res = await db.execute(select(User).filter(User.email == 'creator@example.com'))
        creator = creator_res.scalars().first()
        
        admin_res = await db.execute(select(User).filter(User.email == 'admin@example.com'))
        admin = admin_res.scalars().first()
        
        if not student or not creator or not admin:
            print("Demo users not found.")
            return

        # Get the Python course (Course 22 based on logs, but we'll find by title pattern)
        course_res = await db.execute(select(Course).filter(Course.title.ilike('%Data Science with Python%')))
        course = course_res.scalars().first()
        
        if not course:
            print("Data Science with Python course not found.")
            return

        print(f"Transferring course '{course.title}' ownership to {creator.email}")
        course.instructor_id = creator.id
        
        # Add enrollments
        for user in [student, creator, admin]:
            # Check if enrolled
            enr_res = await db.execute(select(Enrollment).filter(Enrollment.user_id == user.id, Enrollment.course_id == course.id))
            enr = enr_res.scalars().first()
            if not enr:
                print(f"Enrolling {user.email} in course {course.id}")
                new_enr = Enrollment(user_id=user.id, course_id=course.id, progress_percentage=0)
                db.add(new_enr)
            else:
                print(f"{user.email} already enrolled.")
        
        await db.commit()
        print("Done!")

if __name__ == "__main__":
    asyncio.run(main())
