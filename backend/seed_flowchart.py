import asyncio
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.future import select
from app.db.session import AsyncSessionLocal
from app.models.course import Course, Chapter, Lesson

async def seed_flowchart():
    async with AsyncSessionLocal() as db:
        print("Fetching Course 1, Chapter 1...")
        result = await db.execute(select(Chapter).where(Chapter.title == "1.1 Introduction and Setup").limit(1))
        chapter = result.scalar_one_or_none()
        
        if not chapter:
            print("Chapter not found.")
            return

        print("Checking if flowchart practical exists...")
        result = await db.execute(select(Lesson).where(Lesson.title == "Practical: Build a Flowchart").limit(1))
        existing = result.scalar_one_or_none()
        
        content_body = {
            "problem_statement": "Draw a flowchart to calculate the Area of a Rectangle.",
            "expected_nodes": [
                {"id": "n1", "type": "oval", "text": "START"},
                {"id": "n2", "type": "parallelogram", "text": "INPUT Length, Width"},
                {"id": "n3", "type": "rectangle", "text": "Area = Length * Width"},
                {"id": "n4", "type": "parallelogram", "text": "PRINT Area"},
                {"id": "n5", "type": "oval", "text": "STOP"}
            ],
            "expected_edges": [
                {"from": "n1", "to": "n2"},
                {"from": "n2", "to": "n3"},
                {"from": "n3", "to": "n4"},
                {"from": "n4", "to": "n5"}
            ]
        }
        
        if existing:
            print("Updating existing lesson...")
            existing.content_type = "flowchart_practical"
            existing.content_body = content_body
            # Flag modified or use explicit update not needed if we are just testing, but let's be safe
            from sqlalchemy.orm.attributes import flag_modified
            flag_modified(existing, "content_body")
        else:
            print("Creating new lesson...")
            new_lesson = Lesson(
                chapter_id=chapter.id,
                title="Practical: Build a Flowchart",
                order_index=3, 
                content_type="flowchart_practical",
                xp_reward=100,
                content_body=content_body
            )
            db.add(new_lesson)
            
        await db.commit()
        print("Done!")

if __name__ == "__main__":
    asyncio.run(seed_flowchart())
