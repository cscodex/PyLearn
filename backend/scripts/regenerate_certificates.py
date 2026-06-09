import asyncio
import os
import sys
from dotenv import load_dotenv

# MUST LOAD DOTENV BEFORE ANY APP IMPORTS
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"))

# Setup imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.session import AsyncSessionLocal
from sqlalchemy import select, func, cast, Integer
from app.models.misc import Certificate
from app.models.course import Course, Module, Chapter, Lesson
from app.models.user import User
from app.models.assessment import Question, QuizSubmission
from app.services.certificate_service import generate_and_upload_certificate
import app.services.cloudinary_service

async def main():
    print("Starting certificate regeneration...")
    async with AsyncSessionLocal() as db:
        certs = await db.execute(select(Certificate))
        certs = certs.scalars().all()
        
        print(f"Found {len(certs)} certificates.")
        
        for cert in certs:
            print(f"Regenerating {cert.certificate_number}...")
            
            # User
            user_res = await db.execute(select(User).filter_by(id=cert.user_id))
            user = user_res.scalars().first()
            if not user:
                continue
                
            # Course
            course_res = await db.execute(select(Course).filter_by(id=cert.course_id))
            course = course_res.scalars().first()
            if not course:
                continue
                
            # Instructor
            instructor_name = "Instructor"
            if course.instructor_id:
                inst_res = await db.execute(select(User).filter_by(id=course.instructor_id))
                inst = inst_res.scalars().first()
                if inst:
                    instructor_name = inst.full_name
                    
            # Admin
            admin_res = await db.execute(select(User).filter_by(role="admin").order_by(User.id).limit(1))
            admin = admin_res.scalars().first()
            director_name = admin.full_name if admin else "Director"
            
            # Duration
            duration_str = "40 Hours"
            if course.estimated_hours:
                duration_str = f"{int(course.estimated_hours)} Hours"
                
            # Concepts
            lessons_res = await db.execute(
                select(Lesson.title)
                .join(Chapter, Lesson.chapter_id == Chapter.id)
                .join(Module, Chapter.module_id == Module.id)
                .filter(Module.course_id == course.id)
                .order_by(Module.order_index, Chapter.order_index, Lesson.order_index)
                .limit(6)
            )
            concepts = [t for t in lessons_res.scalars().all()]
            
            # Score
            score_res = await db.execute(
                select(func.avg(cast(QuizSubmission.is_correct, Integer)))
                .join(Question, QuizSubmission.question_id == Question.id)
                .join(Lesson, Question.lesson_id == Lesson.id)
                .join(Chapter, Lesson.chapter_id == Chapter.id)
                .join(Module, Chapter.module_id == Module.id)
                .filter(Module.course_id == course.id)
                .filter(QuizSubmission.user_id == user.id)
            )
            avg_score = score_res.scalar()
            
            score_str = "Completed"
            grade_str = "-"
            
            if avg_score is not None:
                score_pct = float(avg_score) * 100.0
                score_str = f"{int(score_pct)}%"
                if score_pct >= 90:
                    grade_str = "A+"
                elif score_pct >= 80:
                    grade_str = "A"
                elif score_pct >= 70:
                    grade_str = "B"
                elif score_pct >= 60:
                    grade_str = "C"
                else:
                    grade_str = "D"
            
            secure_url = generate_and_upload_certificate(
                student_name=user.full_name,
                course_name=course.title,
                certificate_id=cert.certificate_number,
                instructor_name=instructor_name,
                director_name=director_name,
                duration_str=duration_str,
                score_str=score_str,
                grade_str=grade_str,
                concepts=concepts
            )
            
            if secure_url:
                cert.pdf_url = secure_url
                print(f"Successfully uploaded new cert for {user.full_name} at {secure_url}")
                
        await db.commit()
    print("Done")

if __name__ == "__main__":
    asyncio.run(main())
