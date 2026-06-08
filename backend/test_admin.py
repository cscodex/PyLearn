import asyncio
from app.api.deps import get_db
from sqlalchemy import select
from app.models.user import User

async def test():
    async for db in get_db():
        result = await db.execute(select(User).where(User.email == 'admin@cscodex.com'))
        user = result.scalars().first()
        if user:
            print(f'FOUND ADMIN: {user.email}, is_active={user.is_active}, password_hash={user.password_hash}')
        else:
            print('ADMIN NOT FOUND')

if __name__ == '__main__':
    asyncio.run(test())
