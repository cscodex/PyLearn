import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select, text
import sys
import json

async def main():
    engine = create_async_engine("sqlite+aiosqlite:///app.db")
    async_session = sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    
    async with async_session() as session:
        result = await session.execute(text("SELECT id, lesson_id, title FROM saved_programs"))
        programs = result.all()
        for p in programs:
            print(f"ID: {p.id}, Lesson: {p.lesson_id}, Title: {p.title}")

        print("\nChecking lessons table:")
        result2 = await session.execute(text("SELECT id, title, content_body FROM lessons WHERE title LIKE '%Diction%'"))
        lessons = result2.all()
        for l in lessons:
            try:
                body = json.loads(l.content_body)
                starter = body.get('starter_code', '')[:30].replace('\n', ' ')
            except:
                starter = "Error parsing"
            print(f"Lesson ID: {l.id}, Title: {l.title}, Starter: {starter}...")

if __name__ == "__main__":
    asyncio.run(main())
