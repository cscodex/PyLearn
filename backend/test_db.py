import asyncio
import asyncpg
import os

async def main():
    conn = await asyncpg.connect("postgresql://neondb_owner:npg_Bt5FrJwpoP9c@ep-lucky-boat-apbt6u95-pooler.c-7.us-east-1.aws.neon.tech/neondb?sslmode=require")
    columns = await conn.fetch("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'saved_programs'")
    for col in columns:
        print(col['column_name'], col['data_type'])
    
    rows = await conn.fetch("SELECT id, length(terminal_output), terminal_output FROM saved_programs ORDER BY id DESC LIMIT 5")
    for row in rows:
        print(dict(row))
    await conn.close()

asyncio.run(main())
