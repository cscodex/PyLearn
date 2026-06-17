import re

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'r') as f:
    content = f.read()

loop_old = """    while (currentNodeId != null && isRunning) {
      if (isPaused) {"""

loop_new = """    while (currentNodeId != null && isRunning) {
      setState(() => runningNodeId = currentNodeId);
      
      if (isPaused) {"""

content = content.replace(loop_old, loop_new)

# Remove the trailing one
trailing_old = """      iterations++;
      if (iterations > 1000) {
        setState(() {
          consoleOutput.add("> Error: Maximum iterations (1000) reached. Infinite loop aborted.");
          isRunning = false;
          runningNodeId = null;
        });
        break;
      }
      
      setState(() => runningNodeId = currentNodeId);"""

trailing_new = """      iterations++;
      if (iterations > 1000) {
        setState(() {
          consoleOutput.add("> Error: Maximum iterations (1000) reached. Infinite loop aborted.");
          isRunning = false;
          runningNodeId = null;
        });
        break;
      }"""

content = content.replace(trailing_old, trailing_new)

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'w') as f:
    f.write(content)
