import asyncio
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.future import select
from sqlalchemy import update
from app.db.session import AsyncSessionLocal
from app.models.course import Lesson

ENHANCED_CONTENT = {
    # Course 1
    "Algorithms and Flowcharts": """
    <div style="border-left: 4px solid #9C27B0; padding-left: 16px; margin-bottom: 20px;">
        <h2>📝 Algorithms & Flowcharts</h2>
        <p><i>Before writing code, we must think computationally.</i></p>
    </div>
    
    <h3>1. What is an Algorithm?</h3>
    <p>An algorithm is a step-by-step set of instructions to solve a specific problem. Think of it like a recipe for baking a cake.</p>
    
    <div style="background-color: rgba(156, 39, 176, 0.1); padding: 15px; border-radius: 8px; margin-bottom: 20px;">
        <b>Example: Algorithm to calculate the Area of a Rectangle</b>
        <ol>
            <li><b>Start</b> the program.</li>
            <li><b>Input:</b> Ask the user for the Length and Width.</li>
            <li><b>Process:</b> Multiply Length by Width and store it in 'Area'.</li>
            <li><b>Output:</b> Print the 'Area' to the screen.</li>
            <li><b>Stop</b> the program.</li>
        </ol>
    </div>

    <h3>2. What is a Flowchart?</h3>
    <p>A flowchart is a visual or graphical representation of an algorithm. We use standard shapes to represent different types of actions.</p>
    
    <h4>Example Flowchart (Area of Rectangle):</h4>
    <div style="text-align: center; font-family: monospace; background: rgba(0,0,0,0.05); padding: 20px; border-radius: 8px;">
        <div style="border: 2px solid #E91E63; border-radius: 20px; padding: 10px 20px; display: inline-block; font-weight: bold; color: #E91E63;">START (Oval)</div>
        <div style="font-size: 24px;">↓</div>
        <div style="border: 2px solid #2196F3; padding: 10px 20px; display: inline-block; font-weight: bold; color: #2196F3; border-style: dashed;">INPUT Length, Width (Parallelogram)</div>
        <div style="font-size: 24px;">↓</div>
        <div style="border: 2px solid #4CAF50; padding: 10px 20px; display: inline-block; font-weight: bold; color: #4CAF50;">Area = Length * Width (Rectangle)</div>
        <div style="font-size: 24px;">↓</div>
        <div style="border: 2px solid #2196F3; padding: 10px 20px; display: inline-block; font-weight: bold; color: #2196F3; border-style: dashed;">PRINT Area (Parallelogram)</div>
        <div style="font-size: 24px;">↓</div>
        <div style="border: 2px solid #E91E63; border-radius: 20px; padding: 10px 20px; display: inline-block; font-weight: bold; color: #E91E63;">STOP (Oval)</div>
    </div>
    
    <blockquote style="border-left: 4px solid #FF9800; padding: 10px; background-color: rgba(255,152,0,0.1); margin-top: 20px;">
    <b>Tip:</b> Always draw a flowchart on paper before trying to write complex Python logic! It saves hours of debugging.
    </blockquote>
    """,

    "Conditional Statements": """
    <div style="border-left: 4px solid #00BCD4; padding-left: 16px; margin-bottom: 20px;">
        <h2>⚖️ Decision Making (If-Else)</h2>
    </div>

    <p>Conditional statements allow your program to make decisions and execute different blocks of code based on whether a condition is <code>True</code> or <code>False</code>.</p>

    <h3>Flowchart of an If-Else Statement</h3>
    <div style="text-align: center; font-family: monospace; background: rgba(0,0,0,0.05); padding: 20px; border-radius: 8px;">
        <div style="border: 2px solid #E91E63; border-radius: 20px; padding: 10px 20px; display: inline-block; font-weight: bold; color: #E91E63;">START</div>
        <div style="font-size: 24px;">↓</div>
        <div style="border: 2px solid #FF9800; padding: 10px 20px; display: inline-block; font-weight: bold; color: #FF9800;">Is Temperature &gt; 30? (Diamond/Decision)</div>
        <div style="font-size: 24px;">↙ &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; ↘</div>
        <div style="display: flex; justify-content: space-around;">
            <div style="border: 2px solid #4CAF50; padding: 10px; color: #4CAF50;"><b>YES:</b> Print "Hot!"</div>
            <div style="border: 2px solid #F44336; padding: 10px; color: #F44336;"><b>NO:</b> Print "Cold!"</div>
        </div>
        <div style="font-size: 24px;">↘ &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; ↙</div>
        <div style="border: 2px solid #E91E63; border-radius: 20px; padding: 10px 20px; display: inline-block; font-weight: bold; color: #E91E63;">STOP</div>
    </div>

    <h3>The Code Example</h3>
    <pre><code>temperature = 35

if temperature > 30:
    print("It's a hot day!")
elif temperature > 20:
    print("It's a nice day!")
else:
    print("It's a cold day!")</code></pre>

    <p><b>Indentation is Crucial!</b> Python uses spaces (usually 4) to determine which code belongs inside the <code>if</code> block. If you forget to indent, Python will throw an IndentationError.</p>
    """,
    
    "Keywords and Identifiers": """
    <div style="border-left: 4px solid #4CAF50; padding-left: 16px; margin-bottom: 20px;">
        <h2>🔤 Vocabulary of Python</h2>
    </div>

    <h3>1. Keywords (Reserved Words)</h3>
    <p>Keywords are special words in Python that have built-in meaning. You <b>cannot</b> use them as variable names.</p>
    <p>Examples: <code>if, else, for, while, break, class, def, return, True, False</code></p>

    <h3>2. Identifiers</h3>
    <p>Identifiers are the names you create for variables, functions, and classes.</p>
    
    <h4>Rules for Naming Identifiers:</h4>
    <ol>
        <li>Must start with a letter (A-Z, a-z) or an underscore (_).</li>
        <li>Can contain numbers (0-9), but <b>not</b> at the beginning.</li>
        <li>No special characters allowed (e.g., @, #, $, %).</li>
        <li>Case-sensitive (<code>Age</code> and <code>age</code> are different).</li>
    </ol>
    
    <h3>Examples of Valid vs Invalid</h3>
    <div style="background-color: rgba(0,0,0,0.05); padding: 15px; border-radius: 8px;">
        <ul style="list-style-type: none; padding-left: 0;">
            <li style="color: #4CAF50; margin-bottom: 8px;">✅ <b>my_var = 10</b> (Valid: Letters and underscores)</li>
            <li style="color: #4CAF50; margin-bottom: 8px;">✅ <b>_score = 100</b> (Valid: Starts with underscore)</li>
            <li style="color: #4CAF50; margin-bottom: 16px;">✅ <b>player1 = "John"</b> (Valid: Number is at the end)</li>
            
            <li style="color: #F44336; margin-bottom: 8px;">❌ <b>1st_place = "Jane"</b> (Invalid: Cannot start with a number)</li>
            <li style="color: #F44336; margin-bottom: 8px;">❌ <b>my-var = 50</b> (Invalid: Hyphens are not allowed, only underscores)</li>
            <li style="color: #F44336; margin-bottom: 8px;">❌ <b>for = 10</b> (Invalid: 'for' is a reserved keyword!)</li>
        </ul>
    </div>
    """
}

async def fix_lessons():
    async with AsyncSessionLocal() as db:
        print("Fetching lessons...")
        result = await db.execute(select(Lesson))
        lessons = result.scalars().all()
        
        for lesson in lessons:
            if lesson.title in ENHANCED_CONTENT:
                new_body = lesson.content_body or {}
                new_body["text"] = ENHANCED_CONTENT[lesson.title]
                
                stmt = (
                    update(Lesson)
                    .where(Lesson.id == lesson.id)
                    .values(content_body=new_body)
                )
                await db.execute(stmt)
                print(f"Updated with diagrams: {lesson.title}")
                
        await db.commit()
        print("Done!")

if __name__ == "__main__":
    asyncio.run(fix_lessons())
