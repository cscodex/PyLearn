import asyncio
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.future import select
from app.db.session import AsyncSessionLocal
from app.models.course import Lesson

async def check():
    async with AsyncSessionLocal() as db:
        res = await db.execute(select(Lesson).where(Lesson.title == "Algorithms and Flowcharts").limit(1))
        lesson = res.scalar_one_or_none()
        if lesson:
            print("Content body:")
            print(lesson.content_body)

asyncio.run(check())
