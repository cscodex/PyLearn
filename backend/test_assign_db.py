import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.models.group import GroupAssignment, GroupMember
from app.models.progress import Enrollment
from sqlalchemy.future import select

async def main():
    engine = create_async_engine("sqlite+aiosqlite:///./sql_app.db")
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        assign_in_course_id = 1
        group_id = 1
        members_res = await db.execute(select(GroupMember).filter(GroupMember.group_id == group_id))
        members = members_res.scalars().all()
        for m in members:
            enroll_res = await db.execute(select(Enrollment).filter(Enrollment.user_id == m.user_id, Enrollment.course_id == assign_in_course_id))
            if not enroll_res.scalars().first():
                new_enroll = Enrollment(
                    user_id=m.user_id,
                    course_id=assign_in_course_id,
                    progress_percentage=0.0
                )
                db.add(new_enroll)
        try:
            await db.commit()
            print("Commit successful")
        except Exception as e:
            print("DB ERROR:", e)

if __name__ == "__main__":
    asyncio.run(main())
