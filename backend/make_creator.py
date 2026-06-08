import asyncio
from app.db.session import engine
from sqlalchemy import text

async def run():
    async with engine.begin() as conn:
        await conn.execute(text("UPDATE users SET role='creator' WHERE email='user1@example.com';"))
    print("Made user1 a creator!")

if __name__ == '__main__':
    asyncio.run(run())
