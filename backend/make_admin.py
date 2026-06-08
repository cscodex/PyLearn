import asyncio
import uuid
from app.db.session import engine
from sqlalchemy import text
from app.core.security import get_password_hash

async def run():
    async with engine.begin() as conn:
        res = await conn.execute(text("SELECT email FROM users WHERE email='admin@example.com';"))
        if not res.fetchone():
            pw_hash = get_password_hash("password123")
            admin_id = str(uuid.uuid4())
            await conn.execute(text(f"INSERT INTO users (id, email, full_name, password_hash, role, is_active, email_verified) VALUES ('{admin_id}', 'admin@example.com', 'Admin User', '{pw_hash}', 'admin', true, true);"))
        else:
            await conn.execute(text("UPDATE users SET role='admin' WHERE email='admin@example.com';"))
    print("Admin user guaranteed!")

if __name__ == '__main__':
    asyncio.run(run())
