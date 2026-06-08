import asyncio
import httpx
import uuid
from app.db.session import AsyncSessionLocal
from app.core.security import create_access_token
from sqlalchemy.future import select
from app.models.user import User

async def run_test():
    async with AsyncSessionLocal() as db:
        user = (await db.execute(select(User).filter(User.email=="admin@example.com"))).scalars().first()
        token = create_access_token(user.id)
    
    headers = {"Authorization": f"Bearer {token}"}
    async with httpx.AsyncClient(base_url="http://127.0.0.1:8000") as ac:
        # Create course
        slug = f"test-course-{uuid.uuid4().hex[:6]}"
        resp = await ac.post("/api/v1/creator/courses", json={
            "title": "Test Course",
            "slug": slug,
            "description": "Test Description",
            "difficulty_level": "beginner",
            "is_published": False,
            "thumbnail_url": ""
        }, headers=headers)
        print("Create Course:", resp.status_code, resp.json())
        course_id = resp.json().get("id")
        if not course_id: return
        
        # Create module
        resp = await ac.post(f"/api/v1/creator/courses/{course_id}/modules", json={
            "title": "Module 1",
            "description": "Mod desc",
            "order_index": 1
        }, headers=headers)
        print("Create Module:", resp.status_code, resp.json())
        module_id = resp.json().get("id")
        if not module_id: return
        
        # Create chapter
        resp = await ac.post(f"/api/v1/creator/modules/{module_id}/chapters", json={
            "title": "Chapter 1",
            "description": "Chap desc",
            "order_index": 1
        }, headers=headers)
        print("Create Chapter:", resp.status_code, resp.json())
        chapter_id = resp.json().get("id")
        if not chapter_id: return
        
        # Create lesson
        resp = await ac.post(f"/api/v1/creator/chapters/{chapter_id}/lessons", json={
            "title": "Quiz Lesson",
            "content_type": "quiz",
            "content_body": {},
            "order_index": 1,
            "is_premium": False
        }, headers=headers)
        print("Create Lesson:", resp.status_code, resp.json())
        lesson_id = resp.json().get("id")
        if not lesson_id: return
        
        # Add quiz questions
        resp = await ac.post(f"/api/v1/creator/lessons/{lesson_id}/questions", json={
            "question_type": "multiple_choice",
            "question_text": "What is 2+2?",
            "points": 1,
            "order_index": 1,
            "options": [
                {"option_text": "3", "is_correct": False, "order_index": 1},
                {"option_text": "4", "is_correct": True, "order_index": 2}
            ]
        }, headers=headers)
        print("Create Question:", resp.status_code, resp.json())

if __name__ == "__main__":
    asyncio.run(run_test())
