import asyncio
from httpx import AsyncClient

async def main():
    async with AsyncClient(base_url="http://localhost:8000/api/v1") as client:
        # Login
        response = await client.post("/auth/login", data={"username": "student@example.com", "password": "password123"})
        token = response.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        # Edit Profile
        response = await client.put("/auth/profile", json={"fullName": "Student Demo", "email": "student@example.com"}, headers=headers)
        print("Edit Profile:", response.status_code, response.text)

        # Change Password
        response = await client.put("/auth/password", json={"currentPassword": "password123", "newPassword": "password123"}, headers=headers)
        print("Change Password:", response.status_code, response.text)

if __name__ == "__main__":
    asyncio.run(main())
