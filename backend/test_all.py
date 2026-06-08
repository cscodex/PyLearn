import asyncio
import httpx
import uuid
from app.db.session import AsyncSessionLocal
from app.core.security import create_access_token
from sqlalchemy.future import select
from app.models.user import User

async def run_tests():
    print("="*50)
    print("🚀 STARTING FULL INTEGRATION TEST")
    print("="*50)
    
    # 1. Setup DB Token
    async with AsyncSessionLocal() as db:
        admin_user = (await db.execute(select(User).filter(User.email=="admin@example.com"))).scalars().first()
        student_user = (await db.execute(select(User).filter(User.email=="student1@example.com"))).scalars().first()
        if not admin_user:
            print("❌ Admin user not found in DB!")
            return
        token = create_access_token(admin_user.id)
    
    headers = {"Authorization": f"Bearer {token}"}
    
    async with httpx.AsyncClient(base_url="http://127.0.0.1:8000", timeout=60.0) as ac:
        
        print("\n--- 1. Auth & Admin Tests ---")
        resp = await ac.get("/api/v1/auth/me", headers=headers)
        print(f"GET /api/v1/auth/me -> {resp.status_code}")
        assert resp.status_code == 200
        
        resp = await ac.get("/api/v1/admin/users", headers=headers)
        print(f"GET /api/v1/admin/users -> {resp.status_code}")
        assert resp.status_code == 200
        users = resp.json()
        print(f"  Found {len(users)} users.")
        
        # Test blocking/unblocking a dummy user (skip if no student found)
        if student_user:
            print(f"Testing block/unblock on {student_user.email}")
            resp = await ac.put(f"/api/v1/admin/users/{student_user.id}/block", headers=headers)
            print(f"PUT /api/v1/admin/users/{{id}}/block -> {resp.status_code}")
            resp = await ac.put(f"/api/v1/admin/users/{student_user.id}/unblock", headers=headers)
            print(f"PUT /api/v1/admin/users/{{id}}/unblock -> {resp.status_code}")
        
        
        print("\n--- 2. Creator Curriculum Tests ---")
        slug = f"integration-test-{uuid.uuid4().hex[:6]}"
        resp = await ac.post("/api/v1/creator/courses", json={
            "title": "Integration Test Course",
            "slug": slug,
            "description": "Integration testing course",
            "difficulty_level": "beginner",
            "is_published": False,
            "thumbnail_url": ""
        }, headers=headers)
        print(f"POST /api/v1/creator/courses -> {resp.status_code}")
        assert resp.status_code == 200
        course_id = resp.json().get("id")
        
        resp = await ac.post(f"/api/v1/creator/courses/{course_id}/modules", json={
            "title": "Module 1", "description": "Mod 1 desc", "order_index": 1
        }, headers=headers)
        print(f"POST /api/v1/creator/courses/{{id}}/modules -> {resp.status_code}")
        assert resp.status_code == 200
        module_id = resp.json().get("id")
        
        resp = await ac.post(f"/api/v1/creator/modules/{module_id}/chapters", json={
            "title": "Chapter 1", "description": "Chap 1 desc", "order_index": 1
        }, headers=headers)
        print(f"POST /api/v1/creator/modules/{{id}}/chapters -> {resp.status_code}")
        assert resp.status_code == 200
        chapter_id = resp.json().get("id")
        
        resp = await ac.post(f"/api/v1/creator/chapters/{chapter_id}/lessons", json={
            "title": "Quiz Lesson", "content_type": "quiz", "content_body": {}, "order_index": 1, "is_premium": False
        }, headers=headers)
        print(f"POST /api/v1/creator/chapters/{{id}}/lessons -> {resp.status_code}")
        assert resp.status_code == 200
        lesson_id = resp.json().get("id")
        
        resp = await ac.post(f"/api/v1/creator/lessons/{lesson_id}/questions", json={
            "question_type": "multiple_choice",
            "question_text": "What is the result of integration tests?",
            "points": 1,
            "order_index": 1,
            "options": [
                {"option_text": "Failure", "is_correct": False, "order_index": 1},
                {"option_text": "Success", "is_correct": True, "order_index": 2}
            ]
        }, headers=headers)
        print(f"POST /api/v1/creator/lessons/{{id}}/questions -> {resp.status_code}")
        assert resp.status_code == 200
        
        print("\n--- 3. Creator Groups Tests ---")
        resp = await ac.post("/api/v1/creator/groups", json={
            "name": f"Integration Group {uuid.uuid4().hex[:4]}",
            "description": "Group for integration testing"
        }, headers=headers)
        print(f"POST /api/v1/creator/groups -> {resp.status_code}")
        assert resp.status_code == 200
        group_id = resp.json().get("id")
        
        if student_user:
            resp = await ac.post(f"/api/v1/creator/groups/{group_id}/students", json={
                "student_id": str(student_user.id)
            }, headers=headers)
            print(f"POST /api/v1/creator/groups/{{id}}/students -> {resp.status_code}")
        
        resp = await ac.post(f"/api/v1/creator/groups/{group_id}/courses", json={
            "course_id": course_id,
            "assignment_type": "recommended"
        }, headers=headers)
        print(f"POST /api/v1/creator/groups/{{id}}/courses -> {resp.status_code}")
        assert resp.status_code == 200
        
        resp = await ac.get("/api/v1/creator/enrollments", headers=headers)
        print(f"GET /api/v1/creator/enrollments -> {resp.status_code}")
        assert resp.status_code == 200
        
        print("\n" + "="*50)
        print("✅ ALL TESTS COMPLETED SUCCESSFULLY!")
        print("="*50)

if __name__ == "__main__":
    asyncio.run(run_tests())
