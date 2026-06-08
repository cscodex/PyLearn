from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select
import json
import asyncio
from app.models.course import Course
from app.models.progress import Enrollment

# using sqlite3 directly to bypass async issues in simple script
import sqlite3
conn = sqlite3.connect("./sql_app.db")
conn.row_factory = sqlite3.Row
cursor = conn.cursor()

cursor.execute("""
SELECT courses.* FROM courses 
JOIN enrollments ON enrollments.course_id = courses.id
""")
rows = cursor.fetchall()
print(f"Total enrolled courses: {len(rows)}")
for row in rows:
    print(dict(row))

