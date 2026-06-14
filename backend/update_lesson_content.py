import asyncio
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from app.db.session import AsyncSessionLocal
from app.models.course import Lesson
from app.models.assessment import CodingChallenge, Question

async def fix_lessons():
    async with AsyncSessionLocal() as db:
        print("Fetching lessons...")
        result = await db.execute(select(Lesson))
        lessons = result.scalars().all()
        
        for lesson in lessons:
            if lesson.content_type == "video":
                lesson.content_body = {
                    "text": f"<h1>{lesson.title}</h1><p>Watch the video above to learn about {lesson.title}.</p>"
                }
            elif lesson.content_type == "text":
                if not lesson.content_body or "text" not in lesson.content_body:
                    lesson.content_body = {
                        "text": f"<h1>{lesson.title}</h1><p>This is a text lesson on {lesson.title}. Important concepts will be covered here.</p>"
                    }
            elif lesson.content_type == "code_challenge":
                # Fetch corresponding CodingChallenge
                cc_res = await db.execute(select(CodingChallenge).where(CodingChallenge.lesson_id == lesson.id))
                cc = cc_res.scalar_one_or_none()
                if cc:
                    lesson.content_body = {
                        "text": f"<h2>{cc.title}</h2><p>{cc.description.replace(chr(10), '<br>')}</p>",
                        "starter_code": cc.starter_code
                    }
                else:
                    lesson.content_body = {
                        "text": f"<h2>{lesson.title}</h2><p>Solve the challenge below.</p>",
                        "starter_code": "# Write your code here"
                    }
            elif lesson.content_type == "quiz":
                # Quizzes don't strictly need contentBody for QuizScreen, but we can add a fallback
                lesson.content_body = {
                    "text": f"<h2>{lesson.title}</h2><p>Test your knowledge with this quiz!</p>"
                }
                
        await db.commit()
        print("Successfully updated lesson content_body fields!")

if __name__ == "__main__":
    asyncio.run(fix_lessons())
