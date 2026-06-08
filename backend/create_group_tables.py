import asyncio
from app.db.session import engine
from app.db.base_class import Base
from app.models.user import User
from app.models.course import Course
from app.models.group import Group, GroupMember, GroupAssignment

async def run():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("Group tables created successfully!")

if __name__ == '__main__':
    asyncio.run(run())
