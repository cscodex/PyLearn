import asyncio
import httpx
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
        resp = await ac.get("/api/v1/auth/me", headers=headers)
        print("Auth Me:", resp.status_code, resp.json())

if __name__ == "__main__":
    asyncio.run(run_test())
