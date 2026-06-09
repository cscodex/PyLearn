import asyncio
from httpx import AsyncClient

async def main():
    async with AsyncClient(base_url="http://localhost:8000/api/v1") as client:
        # Login as creator
        response = await client.post("/auth/login", data={"username": "creator@example.com", "password": "password123"})
        token = response.json().get("access_token")
        headers = {"Authorization": f"Bearer {token}"}
        
        # Get courses
        courses_res = await client.get("/creator/courses", headers=headers)
        courses = courses_res.json()
        if not courses:
            print("No courses found")
            return
            
        course_id = courses[0]['id']
        
        # Get groups
        groups_res = await client.get("/creator/groups/", headers=headers)
        groups = groups_res.json()
        if not groups:
            print("No groups found")
            return
        
        group_id = groups[0]['id']
        print(f"Assigning course {course_id} to group {group_id}")

        # Assign course bulk
        response = await client.post(f"/creator/groups/{group_id}/assign/bulk", json={"course_ids": [course_id], "assignment_type": "mandatory"}, headers=headers)
        print("Assign status:", response.status_code, response.text)

if __name__ == "__main__":
    asyncio.run(main())
