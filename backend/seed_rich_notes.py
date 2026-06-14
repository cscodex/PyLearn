import asyncio
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.future import select
from sqlalchemy import update
from app.db.session import AsyncSessionLocal
from app.models.course import Lesson

RICH_CONTENT = {
    # Course 1
    "Algorithms and Flowcharts": """
    <div style="border-left: 4px solid #9C27B0; padding-left: 16px; margin-bottom: 20px;">
        <h2>📝 Algorithms & Flowcharts</h2>
        <p><i>Before writing code, we must think computationally.</i></p>
    </div>
    
    <h3>1. What is an Algorithm?</h3>
    <p>An algorithm is a step-by-step set of instructions to solve a specific problem. Think of it like a recipe for baking a cake.</p>
    <ul>
        <li><b>Input:</b> Ingredients</li>
        <li><b>Process:</b> Mixing and Baking</li>
        <li><b>Output:</b> A delicious cake!</li>
    </ul>

    <h3>2. What is a Flowchart?</h3>
    <p>A flowchart is a visual or graphical representation of an algorithm. We use standard shapes to represent different types of actions:</p>
    <ul>
        <li><b>Oval:</b> Start / Stop</li>
        <li><b>Parallelogram:</b> Input / Output</li>
        <li><b>Rectangle:</b> Process (Calculations)</li>
        <li><b>Diamond:</b> Decision (Yes/No)</li>
        <li><b>Arrows:</b> Flow of control</li>
    </ul>
    
    <blockquote style="border-left: 4px solid #FF9800; padding: 10px; background-color: rgba(255,152,0,0.1);">
    <b>Tip:</b> Always draw a flowchart on paper before trying to write complex Python logic! It saves hours of debugging.
    </blockquote>
    """,

    "Interactive vs Script Mode": """
    <div style="border-left: 4px solid #2196F3; padding-left: 16px; margin-bottom: 20px;">
        <h2>🖥️ Python Execution Modes</h2>
    </div>

    <h3>1. Interactive Mode</h3>
    <p>In interactive mode, you type Python commands into the prompt (<code>>>></code>) and the interpreter executes them immediately.</p>
    <p><b>Pros:</b> Great for quick testing, debugging, and using Python as a calculator.<br>
    <b>Cons:</b> Your code isn't saved. Once you close the terminal, it's gone!</p>
    <pre><code>>>> print("Hello")
Hello
>>> 5 + 3
8</code></pre>

    <h3>2. Script Mode</h3>
    <p>In script mode, you write all your code in a file (like <code>program.py</code>) and then run the entire file at once.</p>
    <p><b>Pros:</b> Code is saved forever, easy to edit and share.<br>
    <b>Cons:</b> Takes slightly longer to set up than interactive mode.</p>
    
    <p><i>In this app, the IDE on your screen simulates Script Mode!</i></p>
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
    
    <pre><code># Valid Identifiers
my_var = 10
_score = 100
player1 = "John"

# Invalid Identifiers
1st_place = "Jane"  # Cannot start with a number
my-var = 50         # Hyphens are not allowed
for = 10            # 'for' is a keyword!</code></pre>
    """,

    "Dynamic Typing": """
    <div style="border-left: 4px solid #E91E63; padding-left: 16px; margin-bottom: 20px;">
        <h2>🔄 Dynamic Typing</h2>
        <p><i>Python is incredibly flexible with data.</i></p>
    </div>

    <p>Unlike languages like C++ or Java, where you must declare a variable's type (like <code>int x = 5;</code>), Python figures out the type automatically based on the value you assign!</p>
    
    <p>Furthermore, a variable can change its type dynamically throughout the program. This is called <b>Dynamic Typing</b>.</p>

    <pre><code># x is initially an integer
x = 10  
print(type(x))  # Output: &lt;class 'int'&gt;

# Now x becomes a string!
x = "Hello World"
print(type(x))  # Output: &lt;class 'str'&gt;

# Now x becomes a float!
x = 3.14
print(type(x))  # Output: &lt;class 'float'&gt;</code></pre>
    
    <blockquote style="border-left: 4px solid #FF9800; padding: 10px; background-color: rgba(255,152,0,0.1);">
    <b>Warning:</b> While dynamic typing is flexible, it can lead to bugs if you accidentally overwrite an integer with a string and then try to do math with it!
    </blockquote>
    """,

    "Conditional Statements": """
    <div style="border-left: 4px solid #00BCD4; padding-left: 16px; margin-bottom: 20px;">
        <h2>⚖️ Decision Making</h2>
    </div>

    <p>Conditional statements allow your program to make decisions and execute different blocks of code based on whether a condition is <code>True</code> or <code>False</code>.</p>

    <h3>The if-elif-else Structure</h3>
    <ul>
        <li><b>if:</b> Checks the first condition.</li>
        <li><b>elif:</b> (Else If) Checks another condition if the previous ones were False.</li>
        <li><b>else:</b> The fallback code that runs if EVERYTHING above was False.</li>
    </ul>

    <pre><code>temperature = 35

if temperature > 30:
    print("It's a hot day!")
elif temperature > 20:
    print("It's a nice day!")
else:
    print("It's a cold day!")</code></pre>

    <p><b>Indentation is Crucial!</b> Python uses spaces (usually 4) to determine which code belongs inside the <code>if</code> block. If you forget to indent, Python will throw an IndentationError.</p>
    """,

    # Course 2
    "String Traversal": """
    <div style="border-left: 4px solid #3F51B5; padding-left: 16px; margin-bottom: 20px;">
        <h2>🧵 String Traversal</h2>
    </div>

    <p>Traversal means accessing each character of a string one by one. This is typically done using loops.</p>

    <h3>Using a For Loop (Direct Traversal)</h3>
    <p>The cleanest way to traverse a string in Python is using a <code>for</code> loop directly on the string object.</p>
    <pre><code>word = "PYTHON"
for char in word:
    print(char)
# Output: P, Y, T, H, O, N (on separate lines)</code></pre>

    <h3>Using a For Loop (Index-based)</h3>
    <p>Sometimes you need to know the <b>index</b> (position) of the character. You can use <code>range()</code> and <code>len()</code> for this.</p>
    <pre><code>word = "PYTHON"
for i in range(len(word)):
    print(f"Index {i}: {word[i]}")</code></pre>

    <h3>Using a While Loop</h3>
    <pre><code>word = "PYTHON"
i = 0
while i < len(word):
    print(word[i])
    i += 1</code></pre>
    """,

    "Creating Lists": """
    <div style="border-left: 4px solid #8BC34A; padding-left: 16px; margin-bottom: 20px;">
        <h2>📦 Lists: The Ultimate Container</h2>
    </div>

    <p>A List is a collection which is ordered and <b>mutable</b> (changeable). In Python, lists are written with square brackets <code>[]</code>.</p>

    <h3>1. Creating Lists</h3>
    <pre><code># Empty list
my_list = []

# List of integers
numbers = [1, 2, 3, 4, 5]

# Heterogeneous List (Mixed types!)
mixed = [10, "Hello", 3.14, True]</code></pre>

    <h3>2. Accessing Elements</h3>
    <p>Lists are zero-indexed, meaning the first element is at index 0.</p>
    <pre><code>fruits = ["Apple", "Banana", "Cherry"]
print(fruits[0])  # Apple
print(fruits[-1]) # Cherry (Negative indexing starts from the end!)</code></pre>

    <h3>3. Mutability</h3>
    <p>Unlike strings, you can change individual elements inside a list.</p>
    <pre><code>fruits[1] = "Blueberry"
print(fruits) # ['Apple', 'Blueberry', 'Cherry']</code></pre>
    """,

    "Working with Tuples": """
    <div style="border-left: 4px solid #607D8B; padding-left: 16px; margin-bottom: 20px;">
        <h2>🔒 Tuples: Immutable Lists</h2>
    </div>

    <p>A Tuple is a collection which is ordered and <b>immutable</b> (unchangeable). Tuples are written with round brackets <code>()</code>.</p>

    <h3>1. Creating Tuples</h3>
    <pre><code># Empty tuple
my_tuple = ()

# Tuple with data
colors = ("red", "green", "blue")

# Tuple with a SINGLE element (Requires a trailing comma!)
single = ("apple",)  # If you omit the comma, Python treats it as a string in parenthesis.</code></pre>

    <h3>2. Why use Tuples?</h3>
    <ul>
        <li><b>Safety:</b> Use tuples for data that should never change (like days of the week, or constant configurations).</li>
        <li><b>Performance:</b> Tuples are slightly faster and use less memory than lists.</li>
    </ul>

    <h3>3. Packing and Unpacking</h3>
    <pre><code># Packing (Creating a tuple without parenthesis is valid!)
data = 1, 2, 3  

# Unpacking (Assigning tuple values to distinct variables)
a, b, c = data
print(a) # 1
print(b) # 2</code></pre>
    """,

    "Key-Value Mapping": """
    <div style="border-left: 4px solid #FF5722; padding-left: 16px; margin-bottom: 20px;">
        <h2>📖 Dictionaries: Key-Value Mapping</h2>
    </div>

    <p>A Dictionary is a collection which is unordered, changeable, and indexed by <b>Keys</b>. In Python, dictionaries are written with curly brackets <code>{}</code>.</p>

    <h3>1. What is a Key-Value pair?</h3>
    <p>Think of a real-world dictionary: you look up a word (the Key) to find its definition (the Value). In Python, Keys must be unique and immutable (like strings or numbers).</p>

    <pre><code>student = {
    "name": "John Doe",
    "age": 16,
    "grade": "11th"
}</code></pre>

    <h3>2. Accessing Data</h3>
    <p>You use the key inside square brackets to fetch the corresponding value.</p>
    <pre><code>print(student["name"])  # Output: John Doe

# Using .get() is safer because it returns None instead of an error if the key doesn't exist
print(student.get("GPA", "Not Found")) # Output: Not Found</code></pre>

    <h3>3. Modifying Dictionaries</h3>
    <pre><code># Adding a new key-value pair
student["school"] = "Delhi Public School"

# Updating an existing value
student["age"] = 17</code></pre>
    """
}

async def fix_lessons():
    async with AsyncSessionLocal() as db:
        print("Fetching lessons...")
        result = await db.execute(select(Lesson))
        lessons = result.scalars().all()
        
        for lesson in lessons:
            if lesson.title in RICH_CONTENT:
                new_body = lesson.content_body or {}
                new_body["text"] = RICH_CONTENT[lesson.title]
                
                # Perform an explicit update to guarantee JSON is modified
                stmt = (
                    update(Lesson)
                    .where(Lesson.id == lesson.id)
                    .values(content_body=new_body)
                )
                await db.execute(stmt)
                print(f"Updated: {lesson.title}")
                
        await db.commit()
        print("Done!")

if __name__ == "__main__":
    asyncio.run(fix_lessons())
