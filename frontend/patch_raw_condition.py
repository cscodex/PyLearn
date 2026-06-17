import re

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'r') as f:
    content = f.read()

old_add = """      staticPseudocode.add({
        'nodeId': node.id,
        'text': text,
        'type': node.type,
      });"""

new_add = """      staticPseudocode.add({
        'nodeId': node.id,
        'text': text,
        'type': node.type,
        'rawConditionText': node.text.trim(),
      });"""

content = content.replace(old_add, new_add)

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'w') as f:
    f.write(content)
