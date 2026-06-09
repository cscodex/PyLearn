import asyncio
from httpx import AsyncClient, ASGITransport
from app.main import app

async def main():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post("/api/v1/auth/login", data={"username": "creator@example.com", "password": "password123"})
        token = response.json().get("access_token")
        headers = {"Authorization": f"Bearer {token}"}
        
        groups_res = await client.get("/api/v1/creator/groups/", headers=headers)
        groups = groups_res.json()
        group_id = groups[0]['id']
        
        try:
            response = await client.post(f"/api/v1/creator/groups/{group_id}/assign", json={"course_id": 1, "assignment_type": "mandatory"}, headers=headers)
            print("Status:", response.status_code)
            print("Response:", response.text)
        except Exception as e:
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())
