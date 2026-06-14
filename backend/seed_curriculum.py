import asyncio
import sys
import os

# Add the backend directory to sys.path so we can import app modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.future import select
from app.db.session import AsyncSessionLocal
from app.models.user import User
from app.models.course import Course, Module, Chapter, Lesson
from app.models.assessment import Question, QuestionOption, CodingChallenge

async def seed_db():
    async with AsyncSessionLocal() as db:
        print("Fetching admin user...")
        result = await db.execute(select(User).limit(1))
        admin_user = result.scalar_one_or_none()
        
        if not admin_user:
            print("No users found. Please register an admin first.")
            return

        instructor_id = admin_user.id
        print(f"Using instructor ID: {instructor_id}")

        # COURSE 1
        course1 = Course(
            title="Python Basics & Computational Thinking",
            slug="python-basics",
            description="The foundation of computational thinking and programming using Python.",
            thumbnail_url="https://api.dicebear.com/8.x/shapes/png?seed=python-basics&backgroundColor=0a0a0a",
            difficulty="beginner",
            instructor_id=instructor_id,
            is_published=True,
            total_lessons=9
        )
        db.add(course1)
        await db.flush()

        module1 = Module(course_id=course1.id, title="Main Module", order_index=1)
        db.add(module1)
        await db.flush()

        # Chapter 1
        c1_ch1 = Chapter(module_id=module1.id, title="Introduction to Problem Solving", order_index=1)
        db.add(c1_ch1)
        await db.flush()

        l1_1 = Lesson(chapter_id=c1_ch1.id, title="Algorithms and Flowcharts", content_type="video", order_index=1)
        l1_2 = Lesson(chapter_id=c1_ch1.id, title="Interactive vs Script Mode", content_type="text", order_index=2, content_body={"text": "Python can run in interactive mode..."})
        l1_3 = Lesson(chapter_id=c1_ch1.id, title="print() and input()", content_type="code_challenge", order_index=3)
        db.add_all([l1_1, l1_2, l1_3])
        await db.flush()

        # Chapter 2
        c1_ch2 = Chapter(module_id=module1.id, title="Tokens, Variables, & Operators", order_index=2)
        db.add(c1_ch2)
        await db.flush()

        l2_1 = Lesson(chapter_id=c1_ch2.id, title="Keywords and Identifiers", content_type="video", order_index=1)
        l2_2 = Lesson(chapter_id=c1_ch2.id, title="Math Operators", content_type="code_challenge", order_index=2)
        l2_3 = Lesson(chapter_id=c1_ch2.id, title="Dynamic Typing", content_type="text", order_index=3)
        db.add_all([l2_1, l2_2, l2_3])
        await db.flush()

        # Chapter 3
        c1_ch3 = Chapter(module_id=module1.id, title="Control Flow", order_index=3)
        db.add(c1_ch3)
        await db.flush()

        l3_1 = Lesson(chapter_id=c1_ch3.id, title="Conditional Statements", content_type="video", order_index=1)
        l3_2 = Lesson(chapter_id=c1_ch3.id, title="Iterative Statements", content_type="code_challenge", order_index=2)
        l3_3 = Lesson(chapter_id=c1_ch3.id, title="Chapter 3 Quiz", content_type="quiz", order_index=3)
        db.add_all([l3_1, l3_2, l3_3])
        await db.flush()

        # Add a Question to the Quiz lesson!
        q1 = Question(lesson_id=l3_3.id, question_type="multiple_choice", question_text="What does the 'break' statement do?", question_data={}, order_index=1)
        db.add(q1)
        await db.flush()
        
        opt1 = QuestionOption(question_id=q1.id, option_text="Exits the loop entirely", is_correct=True, order_index=1)
        opt2 = QuestionOption(question_id=q1.id, option_text="Skips the current iteration", is_correct=False, order_index=2)
        opt3 = QuestionOption(question_id=q1.id, option_text="Stops the whole program", is_correct=False, order_index=3)
        db.add_all([opt1, opt2, opt3])
        await db.flush()


        # COURSE 2
        course2 = Course(
            title="Core Data Structures",
            slug="core-data-structures",
            description="Learn how to manage data efficiently using Python's core mutable and immutable structures.",
            thumbnail_url="https://api.dicebear.com/8.x/shapes/png?seed=data-structures&backgroundColor=0a0a0a",
            difficulty="intermediate",
            instructor_id=instructor_id,
            is_published=True,
            total_lessons=8
        )
        db.add(course2)
        await db.flush()

        module2 = Module(course_id=course2.id, title="Main Module", order_index=1)
        db.add(module2)
        await db.flush()

        # Chapter 1
        c2_ch1 = Chapter(module_id=module2.id, title="Strings", order_index=1)
        db.add(c2_ch1)
        await db.flush()

        l4_1 = Lesson(chapter_id=c2_ch1.id, title="String Traversal", content_type="video", order_index=1)
        l4_2 = Lesson(chapter_id=c2_ch1.id, title="String Methods", content_type="code_challenge", order_index=2)
        db.add_all([l4_1, l4_2])
        await db.flush()

        # Chapter 2
        c2_ch2 = Chapter(module_id=module2.id, title="Lists & Tuples", order_index=2)
        db.add(c2_ch2)
        await db.flush()

        l5_1 = Lesson(chapter_id=c2_ch2.id, title="Creating Lists", content_type="video", order_index=1)
        l5_2 = Lesson(chapter_id=c2_ch2.id, title="List Methods", content_type="code_challenge", order_index=2)
        l5_3 = Lesson(chapter_id=c2_ch2.id, title="Working with Tuples", content_type="text", order_index=3)
        db.add_all([l5_1, l5_2, l5_3])
        await db.flush()

        # Chapter 3
        c2_ch3 = Chapter(module_id=module2.id, title="Dictionaries", order_index=3)
        db.add(c2_ch3)
        await db.flush()

        l6_1 = Lesson(chapter_id=c2_ch3.id, title="Key-Value Mapping", content_type="video", order_index=1)
        l6_2 = Lesson(chapter_id=c2_ch3.id, title="Dictionary Methods", content_type="code_challenge", order_index=2)
        l6_3 = Lesson(chapter_id=c2_ch3.id, title="Final Class 11 Practical Quiz", content_type="quiz", order_index=3)
        db.add_all([l6_1, l6_2, l6_3])
        await db.flush()

        await db.commit()
        print("Successfully seeded Course 1 and Course 2!")

if __name__ == "__main__":
    asyncio.run(seed_db())
