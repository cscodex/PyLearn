import asyncio
from sqlalchemy import text
from app.db.session import engine

async def run():
    async with engine.begin() as conn:
        await conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS xp INTEGER DEFAULT 0;"))
        await conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS streak_days INTEGER DEFAULT 0;"))
        await conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;"))
    print("Columns added successfully!")

if __name__ == '__main__':
    asyncio.run(run())
