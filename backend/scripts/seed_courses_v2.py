import asyncio
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import AsyncSessionLocal
from app.models.course import Course, Module, Chapter, Lesson
from app.models.progress import Enrollment, UserLessonProgress, Bookmark
from sqlalchemy.future import select
from sqlalchemy import delete

async def seed_courses():
    async with AsyncSessionLocal() as db:
        await db.execute(delete(UserLessonProgress))
        await db.execute(delete(Bookmark))
        await db.execute(delete(Enrollment))
        await db.execute(delete(Lesson))
        await db.execute(delete(Chapter))
        await db.execute(delete(Module))
        await db.execute(delete(Course))
        await db.commit()
        print("Cleared existing courses and related data.")

        from app.models.user import User
        result = await db.execute(select(User).filter(User.role == "admin"))
        admin = result.scalars().first()
        instructor_id = admin.id if admin else None

        # ==========================================
        # COURSE 1: Python for Beginners (Comprehensive)
        # ==========================================
        course1 = Course(
            title="Python for Beginners: From Zero to Hero",
            slug="python-for-beginners-full",
            description="The most comprehensive introduction to Python programming. Learn variables, data structures, control flow, functions, and object-oriented programming. Perfect for absolute beginners.",
            difficulty="beginner",
            thumbnail_url="https://images.unsplash.com/photo-1526379095098-d400fd0bfce8?q=80&w=600&auto=format&fit=crop",
            is_published=True,
            instructor_id=instructor_id
        )
        db.add(course1)
        await db.flush()

        # --- MODULE 1 ---
        c1m1 = Module(course_id=course1.id, title="1. Getting Started with Python", description="Introduction to Python, setting up, and understanding basic syntax.", order_index=1)
        db.add(c1m1)
        await db.flush()
        
        c1m1c1 = Chapter(module_id=c1m1.id, title="1.1 Introduction and Setup", order_index=1)
        db.add(c1m1c1)
        await db.flush()

        db.add_all([
            Lesson(chapter_id=c1m1c1.id, title="Welcome to Python!", content_type="text", content_body={"text": """
# Welcome to Python!

Python is one of the most popular programming languages in the world, renowned for its readability, simplicity, and immense power. Whether you want to build websites, analyze data, train machine learning models, or just automate boring tasks, Python is the tool for the job.

## Why Learn Python?
- **Beginner Friendly:** Python reads almost like plain English. You don't have to worry about complex syntax like semicolons or curly braces.
- **Versatile:** It is used in web development (Django, Flask), Data Science (Pandas, NumPy), AI (TensorFlow, PyTorch), and scripting.
- **High Demand:** Python developers are highly sought after in the job market.

## How this course works
In this course, you will learn by doing. We have integrated an interactive IDE directly into the platform so you can write and run code as you read. You will also encounter quizzes and coding challenges to test your knowledge.

Let's get started on your journey to becoming a Python programmer!
"""}, order_index=1),
            Lesson(chapter_id=c1m1c1.id, title="Your First Python Program", content_type="code_challenge", content_body={"text": "Write a program that prints `Hello, World!` to the console. This is the traditional first step for any programmer. Use the `print()` function."}, order_index=2),
            Lesson(chapter_id=c1m1c1.id, title="Quiz: Python Basics", content_type="quiz", content_body={"text": "Which of the following is true about Python?"}, order_index=3) # Assume frontend handles quiz format for now.
        ])
        
        c1m1c2 = Chapter(module_id=c1m1.id, title="1.2 Variables and Data Types", order_index=2)
        db.add(c1m1c2)
        await db.flush()
        
        db.add_all([
            Lesson(chapter_id=c1m1c2.id, title="Understanding Variables", content_type="text", content_body={"text": """
# Variables in Python

A variable is like a container that stores a piece of information. You can think of it as a label attached to a value.

```python
name = "Alice"
age = 25
height = 5.7
is_student = True
```

In the example above:
- `name` holds a **String** (text)
- `age` holds an **Integer** (whole number)
- `height` holds a **Float** (decimal number)
- `is_student` holds a **Boolean** (True or False)

## Rules for naming variables
1. Must start with a letter or underscore (`_`).
2. Cannot start with a number.
3. Can only contain alphanumeric characters and underscores.
4. Variable names are case-sensitive (`age`, `Age`, and `AGE` are different).
"""}, order_index=1),
            Lesson(chapter_id=c1m1c2.id, title="Basic Math Operations", content_type="text", content_body={"text": """
# Math in Python

Python can act as a powerful calculator.

```python
# Addition
print(5 + 3) # 8

# Subtraction
print(10 - 2) # 8

# Multiplication
print(4 * 2) # 8

# Division
print(16 / 2) # 8.0 (Division always returns a float)

# Exponentiation (Power)
print(2 ** 3) # 8

# Modulo (Remainder)
print(17 % 9) # 8
```
"""}, order_index=2),
        ])

        # --- MODULE 2 ---
        c1m2 = Module(course_id=course1.id, title="2. Control Flow", description="Making decisions and repeating actions in code.", order_index=2)
        db.add(c1m2)
        await db.flush()
        
        c1m2c1 = Chapter(module_id=c1m2.id, title="2.1 If/Else Statements", order_index=1)
        db.add(c1m2c1)
        await db.flush()
        
        db.add_all([
            Lesson(chapter_id=c1m2c1.id, title="Conditional Logic", content_type="text", content_body={"text": """
# Conditional Statements

Often, you want your program to behave differently depending on the situation. This is where `if`, `elif`, and `else` statements come in.

```python
temperature = 25

if temperature > 30:
    print("It's a hot day")
elif temperature > 20:
    print("It's a nice day")
else:
    print("It's cold")
```

**Indentation matters!** Notice the spaces before the `print` statements. Python uses indentation to define blocks of code.
"""}, order_index=1),
            Lesson(chapter_id=c1m2c1.id, title="Logical Operators", content_type="text", content_body={"text": """
# Logical Operators

You can combine multiple conditions using `and`, `or`, and `not`.

```python
has_high_income = True
has_good_credit = True

if has_high_income and has_good_credit:
    print("Eligible for loan")
```
"""}, order_index=2),
        ])

        # ==========================================
        # COURSE 2: Data Science with Python
        # ==========================================
        course2 = Course(
            title="Data Science with Python: Pandas & Visualization",
            slug="data-science-python",
            description="Master data manipulation and visualization using the industry-standard libraries: Pandas, Matplotlib, and Seaborn.",
            difficulty="intermediate",
            thumbnail_url="https://images.unsplash.com/photo-1551288049-bebda4e38f71?q=80&w=600&auto=format&fit=crop",
            is_published=True,
            instructor_id=instructor_id
        )
        db.add(course2)
        await db.flush()
        
        c2m1 = Module(course_id=course2.id, title="1. Introduction to Pandas", description="Learn to manipulate tabular data with DataFrames.", order_index=1)
        db.add(c2m1)
        await db.flush()
        
        c2m1c1 = Chapter(module_id=c2m1.id, title="1.1 Series and DataFrames", order_index=1)
        db.add(c2m1c1)
        await db.flush()
        
        db.add_all([
            Lesson(chapter_id=c2m1c1.id, title="What is a DataFrame?", content_type="text", content_body={"text": """
# Introduction to DataFrames

A DataFrame is a 2-dimensional labeled data structure with columns of potentially different types. You can think of it like a spreadsheet or SQL table.

```python
import pandas as pd

data = {
    'Name': ['Alice', 'Bob', 'Charlie'],
    'Age': [25, 30, 35],
    'City': ['New York', 'Paris', 'London']
}

df = pd.DataFrame(data)
print(df)
```
"""}, order_index=1)
        ])

        await db.commit()
        print("Created comprehensive courses successfully!")

if __name__ == "__main__":
    asyncio.run(seed_courses())
