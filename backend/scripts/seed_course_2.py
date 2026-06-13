import asyncio
import os
import json
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text

load_dotenv()

async def seed():
    engine = create_async_engine(os.getenv("DATABASE_URL"))
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        # Get creator
        result = await session.execute(text("SELECT id FROM users WHERE role = 'creator' LIMIT 1"))
        creator_row = result.fetchone()
        
        if not creator_row:
            print("No creator found.")
            return
            
        creator_id = creator_row[0]
        
        # 1. Insert Course
        result = await session.execute(text(f"""
            INSERT INTO courses (title, slug, description, instructor_id, difficulty, is_published)
            VALUES (
                'Advanced Python: Object-Oriented Programming & APIs', 
                'advanced-python-oop-apis', 
                'Take your Python skills to the next level. Learn about classes, objects, inheritance, and how to communicate with web APIs.', 
                '{creator_id}', 
                'advanced', 
                true
            )
            RETURNING id
        """))
        course_id = result.fetchone()[0]

        # 2. Insert Module
        result = await session.execute(text(f"""
            INSERT INTO modules (title, description, order_index, course_id)
            VALUES ('Module 1: Advanced Architecture', 'Master complex software design patterns.', 1, {course_id})
            RETURNING id
        """))
        module_id = result.fetchone()[0]

        # 3. Insert Chapter
        result = await session.execute(text(f"""
            INSERT INTO chapters (title, description, order_index, module_id)
            VALUES ('Chapter 1: Classes and Objects', 'Understand the blueprint of modern programming.', 1, {module_id})
            RETURNING id
        """))
        chapter_id = result.fetchone()[0]

        # Helper function to insert a lesson
        async def insert_lesson(title, l_type, content_body, order_idx):
            stmt = text("""
                INSERT INTO lessons (title, content_type, content_body, order_index, chapter_id)
                VALUES (:title, :type, :body, :order_idx, :chap_id)
            """)
            await session.execute(stmt, {
                "title": title,
                "type": l_type,
                "body": json.dumps(content_body),
                "order_idx": order_idx,
                "chap_id": chapter_id
            })

        # Lesson 1: Text
        await insert_lesson(
            title='Lesson 1: Introduction to OOP',
            l_type='text',
            content_body={
                "text": '''
                <h1>Object-Oriented Programming (OOP)</h1>
                <p>Imagine you are building a factory that creates cars. Instead of building each car from scratch every time, you create a <strong>Blueprint</strong>. In Python, this blueprint is called a <strong>Class</strong>.</p>
                
                <p>Once you have a Class, you can build as many actual cars (called <strong>Objects</strong>) as you want, and they will all follow the same blueprint!</p>

                <pre style="background-color: #282c34; color: white; padding: 10px; border-radius: 5px;">
class Car:
    def __init__(self, color):
        self.color = color

    def honk(self):
        print("Beep beep!")

my_car = Car("Red")
my_car.honk()</pre>
                '''
            },
            order_idx=1
        )

        # Lesson 2: Text
        await insert_lesson(
            title='Lesson 2: What is an API?',
            l_type='text',
            content_body={
                "text": '''
                <h1>Understanding APIs</h1>
                <p>An <strong>API (Application Programming Interface)</strong> is like a waiter in a restaurant. You (the customer) give the waiter your order. The waiter takes the order to the kitchen (the server), and then brings your food (the data) back to you.</p>

                <p>In Python, we use the <code>requests</code> library to talk to the waiter!</p>

                <pre style="background-color: #282c34; color: white; padding: 10px; border-radius: 5px;">
import requests
response = requests.get("https://api.github.com")
print(response.status_code)</pre>
                '''
            },
            order_idx=2
        )

        # Lesson 3: Extended Quiz (6 questions)
        await insert_lesson(
            title='Lesson 3: Advanced Concepts Mastery Quiz',
            l_type='quiz',
            content_body={
                "questions": [
                    {
                        "id": "q1",
                        "question": "What is a Class in Object-Oriented Programming?",
                        "options": ["An instance of an object", "A blueprint for creating objects", "A type of web server", "A Python library"],
                        "correctOptionIndex": 1,
                        "explanation": "A Class acts as a blueprint or template from which specific objects (instances) are created."
                    },
                    {
                        "id": "q2",
                        "question": "Which method is automatically called when a new object is created in Python?",
                        "options": ["__start__", "init()", "__init__", "create()"],
                        "correctOptionIndex": 2,
                        "explanation": "The __init__ method is the constructor in Python, called automatically upon object creation."
                    },
                    {
                        "id": "q3",
                        "question": "What does API stand for?",
                        "options": ["Automated Programming Interface", "Application Programming Interface", "Advanced Python Integration", "Application Process Integration"],
                        "correctOptionIndex": 1,
                        "explanation": "API stands for Application Programming Interface."
                    },
                    {
                        "id": "q4",
                        "question": "What is the role of 'self' in a Python class method?",
                        "options": ["It refers to the parent class", "It makes the method run faster", "It refers to the specific instance of the object calling the method", "It is a built-in Python module"],
                        "correctOptionIndex": 2,
                        "explanation": "'self' represents the instance of the class. By using the 'self' keyword we can access the attributes and methods of the class."
                    },
                    {
                        "id": "q5",
                        "question": "If you make a GET request to an API and it succeeds, what HTTP status code usually returns?",
                        "options": ["404", "500", "200", "403"],
                        "correctOptionIndex": 2,
                        "explanation": "A 200 OK status code means the request was successful."
                    },
                    {
                        "id": "q6",
                        "question": "What is 'Inheritance' in OOP?",
                        "options": ["When a class copies another class's properties and methods", "When a variable is passed between functions", "When Python upgrades to a newer version", "When an API returns JSON data"],
                        "correctOptionIndex": 0,
                        "explanation": "Inheritance allows a child class to inherit attributes and methods from a parent class."
                    }
                ]
            },
            order_idx=3
        )

        # Lesson 4: Code Challenge 1
        await insert_lesson(
            title='Challenge 1: Create a Class',
            l_type='code_challenge',
            content_body={
                "text": "Let's build a class! <br><br>1. Create a class named <code>Dog</code>.<br>2. Give it an <code>__init__</code> method that takes a <code>name</code> parameter and assigns it to <code>self.name</code>.<br>3. Give it a method called <code>bark</code> that prints 'Woof!'.<br>4. Create a Dog object named 'Buddy' and call its bark method.",
                "starter_code": "class Dog:\n    # Your code here\n    pass\n\n",
                "solution_code": "class Dog:\n    def __init__(self, name):\n        self.name = name\n    def bark(self):\n        print('Woof!')\n\nmy_dog = Dog('Buddy')\nmy_dog.bark()\n"
            },
            order_idx=4
        )

        # Lesson 5: Code Challenge 2
        await insert_lesson(
            title='Challenge 2: Inheritance',
            l_type='code_challenge',
            content_body={
                "text": "Now let's use inheritance. <br><br>1. We have a <code>Vehicle</code> class. Create a <code>Motorcycle</code> class that inherits from <code>Vehicle</code>.<br>2. Add a method <code>pop_wheelie</code> to the Motorcycle class that prints 'Popping a wheelie!'.<br>3. Create a Motorcycle object and call <code>pop_wheelie()</code>.",
                "starter_code": "class Vehicle:\n    def drive(self):\n        print('Driving...')\n\n# Create Motorcycle class here\n",
                "solution_code": "class Vehicle:\n    def drive(self):\n        print('Driving...')\n\nclass Motorcycle(Vehicle):\n    def pop_wheelie(self):\n        print('Popping a wheelie!')\n\nmoto = Motorcycle()\nmoto.pop_wheelie()\n"
            },
            order_idx=5
        )

        await session.commit()
        print(f"Successfully seeded Advanced Course with ID {course_id}")

        # Ensure the active creator owns it (Assign to the current user you might be logged in as)
        # We will assign ALL courses to ALL creators to make sure you see it in the Creator Dashboard!
        await session.execute(text("""
            UPDATE courses SET instructor_id = (SELECT id FROM users WHERE role = 'creator' ORDER BY id ASC LIMIT 1)
        """))
        await session.commit()

asyncio.run(seed())
