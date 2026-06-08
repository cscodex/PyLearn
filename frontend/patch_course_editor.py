import re

with open("lib/features/creator/presentation/pages/course_editor_screen.dart", "r") as f:
    content = f.read()

# Add _refreshCourse method
refresh_method = """  Future<void> _refreshCourse() async {
    ref.invalidate(courseDetailsProvider(widget.courseId));
  }
"""
if "_refreshCourse" not in content:
    content = content.replace("  // --- Dialogs & Actions ---", "  // --- Dialogs & Actions ---\n" + refresh_method)

# Fix non-awaited calls to use await and refresh
replacements = [
    (r"ref\.read\(creatorCoursesProvider\.notifier\)\.createModule\([^)]+\);",
     r"await \g<0>\n              await _refreshCourse();"),
    (r"ref\.read\(creatorCoursesProvider\.notifier\)\.updateModule\([^)]+\);",
     r"await \g<0>\n              await _refreshCourse();"),
    (r"ref\.read\(creatorCoursesProvider\.notifier\)\.createChapter\([^)]+\);",
     r"await \g<0>\n              await _refreshCourse();"),
    (r"ref\.read\(creatorCoursesProvider\.notifier\)\.updateChapter\([^)]+\);",
     r"await \g<0>\n              await _refreshCourse();"),
    (r"ref\.read\(creatorCoursesProvider\.notifier\)\.updateCourse\([^)]+\}\);",
     r"await \g<0>\n                await _refreshCourse();"),
]

for old, new in replacements:
    content = re.sub(old, new, content)

# Fix already awaited ones
content = re.sub(r"(if \(confirm\) await ref\.read\(creatorCoursesProvider\.notifier\)\.deleteModule\(id\);)",
                 r"\1\n    if (confirm) await _refreshCourse();", content)
content = re.sub(r"(if \(confirm\) await ref\.read\(creatorCoursesProvider\.notifier\)\.deleteChapter\(id\);)",
                 r"\1\n    if (confirm) await _refreshCourse();", content)
content = re.sub(r"(if \(confirm\) await ref\.read\(creatorCoursesProvider\.notifier\)\.deleteLesson\(id\);)",
                 r"\1\n    if (confirm) await _refreshCourse();", content)
content = re.sub(r"(final id = await ref\.read\(creatorCoursesProvider\.notifier\)\.createLesson[^\n]+;)",
                 r"\1\n                await _refreshCourse();", content)
content = re.sub(r"(await widget\.ref\.read\(creatorCoursesProvider\.notifier\)\.updateLesson[^\n]+;)",
                 r"\1\n              widget.ref.invalidate(courseDetailsProvider(widget.lesson.courseId ?? 0));", content) 
# wait lesson doesn't have courseId! Let's pass courseId to _LessonEditorDialog

with open("lib/features/creator/presentation/pages/course_editor_screen.dart", "w") as f:
    f.write(content)
