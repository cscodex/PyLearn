import re

with open("frontend/lib/features/creator/presentation/pages/course_editor_screen.dart", "r") as f:
    content = f.read()

# 1. Add flutter_html import
if "import 'package:flutter_html/flutter_html.dart';" not in content:
    content = content.replace("import 'package:flutter_markdown/flutter_markdown.dart';", 
                              "import 'package:flutter_markdown/flutter_markdown.dart';\nimport 'package:flutter_html/flutter_html.dart';")

# 2. Replace ListTile with ExpansionTile for lesson
old_lesson_tile = """  Widget _buildLessonTile(Lesson lesson, bool isAdmin) {
    IconData icon;
    switch (lesson.contentType) {
      case 'video': icon = Icons.play_circle; break;
      case 'quiz': icon = Icons.quiz; break;
      case 'code_challenge': icon = Icons.code; break;
      default: icon = Icons.article; break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 64, right: 16),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(lesson.title),
      subtitle: Text(lesson.contentType.toUpperCase()),
      trailing: isAdmin ? null : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () {
              if (lesson.contentType == 'quiz') {
                context.push('/creator/quiz_builder/${lesson.id}');
              } else {
                _showEditLessonDialog(lesson);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            onPressed: () => _deleteLesson(lesson.id),
          ),
        ],
      ),
    );
  }"""

new_lesson_tile = """  Widget _buildLessonTile(Lesson lesson, bool isAdmin) {
    IconData icon;
    switch (lesson.contentType) {
      case 'video': icon = Icons.play_circle; break;
      case 'quiz': icon = Icons.quiz; break;
      case 'code_challenge': icon = Icons.code; break;
      default: icon = Icons.article; break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 48.0),
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(lesson.title),
        subtitle: Text(lesson.contentType.toUpperCase()),
        trailing: isAdmin ? null : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () {
                if (lesson.contentType == 'quiz') {
                  if (mounted) context.push('/creator/quiz_builder/${lesson.id}');
                } else {
                  _showEditLessonDialog(lesson);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => _deleteLesson(lesson.id),
            ),
            const Icon(Icons.expand_more), // Ensure expansion icon is still visible
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: lesson.contentType == 'code_challenge'
              ? Text('Starter Code:\\n${lesson.contentBody?['starter_code'] ?? 'No starter code'}\\n\\nSolution:\\n${lesson.contentBody?['solution_code'] ?? 'No solution'}')
              : Html(data: lesson.contentBody?['text'] ?? 'No content'),
          )
        ],
      ),
    );
  }"""
content = content.replace(old_lesson_tile, new_lesson_tile)

# 3. Rename "Code Challenge" dropdown option
content = content.replace("DropdownMenuItem(value: 'code_challenge', child: Text('Code Challenge'))", "DropdownMenuItem(value: 'code_challenge', child: Text('Practical Hands-on (Code Challenge)'))")

# 4. _LessonEditorDialogState changes for code_challenge
with open("frontend/lib/features/creator/presentation/pages/course_editor_screen.dart", "w") as f:
    f.write(content)
