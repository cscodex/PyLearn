import asyncio
from httpx import AsyncClient
async def main():
    async with AsyncClient(base_url="http://localhost:8000/api/v1") as client:
        # get token first
        resp = await client.post("/auth/login", data={"username": "student@example.com", "password": "Password123!"})
        if resp.status_code != 200:
            print("Login failed", resp.text)
            return
        token = resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        resp2 = await client.post("/saved-programs", json={"title": "test", "code": "print(1)"}, headers=headers)
        print("Without slash:", resp2.status_code, resp2.text)
        resp3 = await client.post("/saved-programs/", json={"title": "test", "code": "print(1)"}, headers=headers)
        print("With slash:", resp3.status_code, resp3.text)

asyncio.run(main())
