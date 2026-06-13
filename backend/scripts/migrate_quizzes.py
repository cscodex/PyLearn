import asyncio
import json
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload

from app.db.session import AsyncSessionLocal
from app.models.course import Lesson
from app.models.assessment import Question, QuestionOption

async def migrate_quizzes():
    async with AsyncSessionLocal() as session:
        result = await session.execute(
            select(Lesson).where(Lesson.content_type == 'quiz')
        )
        lessons = result.scalars().all()

        for lesson in lessons:
            if lesson.content_body and "questions" in lesson.content_body:
                print(f"Processing lesson {lesson.id}: {lesson.title}")
                # check if it already has questions
                q_result = await session.execute(
                    select(Question).where(Question.lesson_id == lesson.id)
                )
                existing = q_result.scalars().all()
                if existing:
                    print("Already has questions in DB, skipping.")
                    continue

                for q_idx, q_data in enumerate(lesson.content_body["questions"]):
                    # create question
                    q = Question(
                        lesson_id=lesson.id,
                        question_text=q_data.get("question", ""),
                        question_type="multiple_choice",
                        question_data={},
                        points=10,
                        order_index=q_idx
                    )
                    session.add(q)
                    await session.flush() # to get q.id

                    options = q_data.get("options", [])
                    correct_idx = q_data.get("correctOptionIndex", -1)
                    
                    for o_idx, o_text in enumerate(options):
                        opt = QuestionOption(
                            question_id=q.id,
                            option_text=o_text,
                            is_correct=(o_idx == correct_idx),
                            order_index=o_idx
                        )
                        session.add(opt)
                
                print(f"Migrated questions for lesson {lesson.id}")
        
        await session.commit()

if __name__ == "__main__":
    asyncio.run(migrate_quizzes())
