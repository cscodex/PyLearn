import re

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'r') as f:
    content = f.read()

old_1 = """consoleOutput.add('> Initialized $left = $val');"""
new_1 = """consoleOutput.add('> Initialized $left = $val');
              _scrollToConsoleBottom();"""

old_2 = """consoleOutput.add('> Evaluated $right to $val');"""
new_2 = """consoleOutput.add('> Evaluated $right to $val');
              _scrollToConsoleBottom();"""

old_3 = """consoleOutput.add('> Output: $evaluatedStr');"""
new_3 = """consoleOutput.add('> Output: $evaluatedStr');
            _scrollToConsoleBottom();"""

content = content.replace(old_1, new_1)
content = content.replace(old_2, new_2)
content = content.replace(old_3, new_3)

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'w') as f:
    f.write(content)
