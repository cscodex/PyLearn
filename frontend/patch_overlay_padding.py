import re

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'r') as f:
    content = f.read()

old_overlay = """          if (_showOverlays && isRunning)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              height: 250,"""

new_overlay = """          if (_showOverlays && isRunning)
            Positioned(
              left: 16,
              right: 16,
              bottom: 80, // Moved upwards
              height: 280, // Slightly taller for the new badges"""

content = content.replace(old_overlay, new_overlay)

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'w') as f:
    f.write(content)
