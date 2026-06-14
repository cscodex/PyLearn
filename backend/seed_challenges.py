import asyncio
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.future import select
from app.db.session import AsyncSessionLocal
from app.models.course import Lesson
from app.models.assessment import CodingChallenge, TestCase

async def seed_challenges():
    async with AsyncSessionLocal() as db:
        print("Fetching code challenge lessons...")
        
        # 1. print() and input()
        res = await db.execute(select(Lesson).where(Lesson.title == "print() and input()").limit(1))
        l_io = res.scalar_one_or_none()
        
        if l_io:
            cc1 = CodingChallenge(
                lesson_id=l_io.id,
                title="Simple Interest Calculator",
                description="Write a program that takes three inputs: Principal, Rate, and Time (in that order, each on a new line). Calculate and print the Simple Interest.\n\nFormula: SI = (Principal * Rate * Time) / 100",
                difficulty="easy",
                starter_code="p = float(input())\nr = float(input())\nt = float(input())\n\n# Calculate SI and print it\n",
                solution_code="p = float(input())\nr = float(input())\nt = float(input())\nsi = (p * r * t) / 100\nprint(si)",
                xp_reward=20,
                order_index=1
            )
            db.add(cc1)
            await db.flush()
            
            tc1 = TestCase(challenge_id=cc1.id, input_data="1000\n5\n2", expected_output="100.0\n", is_hidden=False, order_index=1)
            tc2 = TestCase(challenge_id=cc1.id, input_data="5000\n4.5\n3", expected_output="675.0\n", is_hidden=True, order_index=2)
            db.add_all([tc1, tc2])
        
        # 2. Math Operators
        res = await db.execute(select(Lesson).where(Lesson.title == "Math Operators").limit(1))
        l_math = res.scalar_one_or_none()
        if l_math:
            cc2 = CodingChallenge(
                lesson_id=l_math.id,
                title="Celsius to Fahrenheit Conversion",
                description="Write a program to read a temperature in Celsius from standard input, and print the equivalent temperature in Fahrenheit.\n\nFormula: F = C * (9/5) + 32",
                difficulty="easy",
                starter_code="c = float(input())\n\n# Your code here\n",
                solution_code="c = float(input())\nf = c * (9/5) + 32\nprint(f)",
                xp_reward=20,
                order_index=1
            )
            db.add(cc2)
            await db.flush()
            
            tc1 = TestCase(challenge_id=cc2.id, input_data="0", expected_output="32.0\n", is_hidden=False, order_index=1)
            tc2 = TestCase(challenge_id=cc2.id, input_data="100", expected_output="212.0\n", is_hidden=False, order_index=2)
            db.add_all([tc1, tc2])
            
        # 3. Iterative Statements
        res = await db.execute(select(Lesson).where(Lesson.title == "Iterative Statements").limit(1))
        l_iter = res.scalar_one_or_none()
        if l_iter:
            cc3 = CodingChallenge(
                lesson_id=l_iter.id,
                title="Multiplication Table",
                description="Write a program to print the multiplication table of a given number N up to 10.\nExample for N=5:\n5 x 1 = 5\n5 x 2 = 10\n...",
                difficulty="medium",
                starter_code="n = int(input())\n\n# Use a loop to print the table\n",
                solution_code="n = int(input())\nfor i in range(1, 11):\n    print(f'{n} x {i} = {n * i}')",
                xp_reward=30,
                order_index=1
            )
            db.add(cc3)
            await db.flush()
            
            out5 = "5 x 1 = 5\n5 x 2 = 10\n5 x 3 = 15\n5 x 4 = 20\n5 x 5 = 25\n5 x 6 = 30\n5 x 7 = 35\n5 x 8 = 40\n5 x 9 = 45\n5 x 10 = 50\n"
            tc1 = TestCase(challenge_id=cc3.id, input_data="5", expected_output=out5, is_hidden=False, order_index=1)
            db.add(tc1)

        # 4. String Methods
        res = await db.execute(select(Lesson).where(Lesson.title == "String Methods").limit(1))
        l_str = res.scalar_one_or_none()
        if l_str:
            cc4 = CodingChallenge(
                lesson_id=l_str.id,
                title="Palindrome Checker",
                description="Write a program that takes a string as input and prints 'True' if it is a palindrome, and 'False' otherwise.",
                difficulty="medium",
                starter_code="s = input()\n\n# Your code here\n",
                solution_code="s = input()\nprint(s == s[::-1])",
                xp_reward=30,
                order_index=1
            )
            db.add(cc4)
            await db.flush()
            
            tc1 = TestCase(challenge_id=cc4.id, input_data="radar", expected_output="True\n", is_hidden=False, order_index=1)
            tc2 = TestCase(challenge_id=cc4.id, input_data="python", expected_output="False\n", is_hidden=False, order_index=2)
            db.add_all([tc1, tc2])

        # 5. List Methods
        res = await db.execute(select(Lesson).where(Lesson.title == "List Methods").limit(1))
        l_list = res.scalar_one_or_none()
        if l_list:
            cc5 = CodingChallenge(
                lesson_id=l_list.id,
                title="Find Maximum in List",
                description="Write a program to input 5 numbers (one per line), store them in a list, and print the maximum value using the max() method.",
                difficulty="medium",
                starter_code="lst = []\nfor i in range(5):\n    lst.append(int(input()))\n\n# Print the maximum element\n",
                solution_code="lst = []\nfor i in range(5):\n    lst.append(int(input()))\nprint(max(lst))",
                xp_reward=30,
                order_index=1
            )
            db.add(cc5)
            await db.flush()
            
            tc1 = TestCase(challenge_id=cc5.id, input_data="10\n20\n50\n5\n30", expected_output="50\n", is_hidden=False, order_index=1)
            db.add(tc1)

        # 6. Dictionary Methods
        res = await db.execute(select(Lesson).where(Lesson.title == "Dictionary Methods").limit(1))
        l_dict = res.scalar_one_or_none()
        if l_dict:
            cc6 = CodingChallenge(
                lesson_id=l_dict.id,
                title="Character Frequency",
                description="Write a program to count the frequency of characters in a string. The input is a string, and you should print a dictionary of the counts.",
                difficulty="hard",
                starter_code="s = input()\nfreq = {}\n\n# Your code here\n\nprint(freq)\n",
                solution_code="s = input()\nfreq = {}\nfor char in s:\n    freq[char] = freq.get(char, 0) + 1\nprint(freq)",
                xp_reward=40,
                order_index=1
            )
            db.add(cc6)
            await db.flush()
            
            tc1 = TestCase(challenge_id=cc6.id, input_data="hello", expected_output="{'h': 1, 'e': 1, 'l': 2, 'o': 1}\n", is_hidden=False, order_index=1)
            db.add(tc1)

        await db.commit()
        print("Successfully seeded coding challenges based on NCERT textbook programs!")

if __name__ == "__main__":
    asyncio.run(seed_challenges())
