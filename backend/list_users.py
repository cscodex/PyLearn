import asyncio
from app.api.deps import get_db
from sqlalchemy import select
from app.models.user import User

async def test():
    async for db in get_db():
        result = await db.execute(select(User))
        users = result.scalars().all()
        for u in users:
            print(f'User: {u.email}, Role: {u.role}, Active: {u.is_active}')

if __name__ == '__main__':
    asyncio.run(test())
