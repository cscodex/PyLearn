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
                'Python for Beginners: Variables & Data Types', 
                'python-for-beginners-variables', 
                'A gentle introduction to programming in Python, designed specifically for beginners, high schoolers, and college students. Learn how to store data and manipulate it!', 
                '{creator_id}', 
                'beginner', 
                true
            )
            RETURNING id
        """))
        course_id = result.fetchone()[0]

        # 2. Insert Module
        result = await session.execute(text(f"""
            INSERT INTO modules (title, description, order_index, course_id)
            VALUES ('Module 1: The Building Blocks', 'Learn the fundamental concepts of Python.', 1, {course_id})
            RETURNING id
        """))
        module_id = result.fetchone()[0]

        # 3. Insert Chapter
        result = await session.execute(text(f"""
            INSERT INTO chapters (title, description, order_index, module_id)
            VALUES ('Chapter 1: Storing Information', 'Learn how to use variables and understand data types.', 1, {module_id})
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

        # Lesson 1: Text & Graphics (Variables)
        await insert_lesson(
            title='Lesson 1: What is a Variable?',
            l_type='text',
            content_body={
                "text": '''
                <h1>What is a Variable?</h1>
                <p>Imagine you have a moving box. You write "Books" on the side of the box and put your favorite books inside. In programming, a <strong>variable</strong> is exactly like that box!</p>
                
                <div style="background-color: #f0f8ff; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
                    <h3>📦 Variable = Box</h3>
                    <p>It has a <strong>Name</strong> (like the label on the box) and a <strong>Value</strong> (what's inside the box).</p>
                </div>

                <p>Here is how you create a variable in Python:</p>
                <pre style="background-color: #282c34; color: white; padding: 10px; border-radius: 5px;">
age = 18
name = "Alice"</pre>

                <p>We just created two boxes! One is called <code>age</code> and holds the number 18. The other is called <code>name</code> and holds the word "Alice". Notice that words need to be surrounded by quotes (")!</p>
                '''
            },
            order_idx=1
        )

        # Lesson 2: Text (Data Types)
        await insert_lesson(
            title='Lesson 2: Data Types',
            l_type='text',
            content_body={
                "text": '''
                <h1>Common Data Types</h1>
                <p>Computers need to know what kind of data they are looking at. Just like you treat a book differently than a glass of water, Python treats numbers differently than text.</p>

                <ul>
                    <li><strong>String (str)</strong>: Used for text. Always wrapped in quotes. Example: <code>"Hello World"</code></li>
                    <li><strong>Integer (int)</strong>: Whole numbers. Example: <code>42</code> or <code>-5</code></li>
                    <li><strong>Float (float)</strong>: Numbers with a decimal point. Example: <code>3.14</code></li>
                    <li><strong>Boolean (bool)</strong>: Represents True or False. Example: <code>True</code></li>
                </ul>

                <p>You can check the type of a variable using the <code>type()</code> function.</p>
                <pre style="background-color: #282c34; color: white; padding: 10px; border-radius: 5px;">
print(type("Hello")) # This will print &lt;class 'str'&gt;</pre>
                '''
            },
            order_idx=2
        )

        # Lesson 3: Quiz
        await insert_lesson(
            title='Lesson 3: Check Your Understanding',
            l_type='quiz',
            content_body={
                "questions": [
                    {
                        "id": "q1",
                        "question": "Which of the following is a String (str) in Python?",
                        "options": ["42", "3.14", "\"Python\"", "True"],
                        "correctOptionIndex": 2,
                        "explanation": "Strings are used for text and must be wrapped in quotation marks."
                    },
                    {
                        "id": "q2",
                        "question": "What is the purpose of a variable?",
                        "options": [
                            "To make the code run slower",
                            "To store information so we can use it later",
                            "To draw graphics on the screen",
                            "To shut down the computer"
                        ],
                        "correctOptionIndex": 1,
                        "explanation": "Variables act like labeled boxes that store data (information) so we can easily retrieve and use it later in our program."
                    }
                ]
            },
            order_idx=3
        )

        # Lesson 4: Code Challenge 1
        await insert_lesson(
            title='Challenge 1: The Name Tag',
            l_type='code_challenge',
            content_body={
                "text": "Your task is to create a program that prints a virtual name tag. <br><br>1. Create a variable named <code>my_name</code> and assign it any string (like your own name).<br>2. Use the <code>print()</code> function to print the variable to the screen.",
                "starter_code": "# 1. Create a variable called my_name\nmy_name = \"\"\n\n# 2. Print the variable\n",
                "solution_code": "my_name = \"Alex\"\nprint(my_name)\n"
            },
            order_idx=4
        )

        # Lesson 5: Code Challenge 2
        await insert_lesson(
            title='Challenge 2: Basic Math',
            l_type='code_challenge',
            content_body={
                "text": "Let's do some math with variables! <br><br>1. Create a variable <code>apples</code> and set it to 5. <br>2. Create a variable <code>bananas</code> and set it to 3. <br>3. Create a variable <code>total_fruit</code> that adds apples and bananas together. <br>4. Print <code>total_fruit</code>.",
                "starter_code": "apples = 5\nbananas = 3\n\n# Your code here to calculate and print the total\n",
                "solution_code": "apples = 5\nbananas = 3\ntotal_fruit = apples + bananas\nprint(total_fruit)\n"
            },
            order_idx=5
        )

        await session.commit()
        print(f"Successfully seeded course with ID {course_id}")

asyncio.run(seed())
