import re

with open('lib/features/creator/presentation/providers/creator_courses_provider.dart', 'r') as f:
    content = f.read()

# Replace Notifier<AsyncValue<void>> with Notifier<AsyncValue<List<Course>>>
content = content.replace("Notifier<AsyncValue<void>>", "Notifier<AsyncValue<List<Course>>>")
content = content.replace("AsyncValue<void>", "AsyncValue<List<Course>>")
content = content.replace("return const AsyncValue.data(null);", "fetchCourses();\n    return const AsyncValue.loading();")

# Add import
if "import '../../course/domain/entities/course.dart';" not in content:
    content = "import '../../course/domain/entities/course.dart';\n" + content

# Add fetchCourses method
fetch_method = """
  Future<void> fetchCourses() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/creator/courses');
      if (response.statusCode == 200) {
        final List data = response.data;
        final courses = data.map((e) => Course.fromJson(e)).toList();
        state = AsyncValue.data(courses);
      } else {
        state = AsyncValue.error('Failed to load courses', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
    }
  }
"""

content = content.replace("Future<int?> createCourse", fetch_method + "\n  Future<int?> createCourse")

# Fix createCourse to refresh list
content = content.replace("state = const AsyncValue.data(null);", "fetchCourses();")
content = content.replace("state = const AsyncValue.data([]);", "fetchCourses();")

with open('lib/features/creator/presentation/providers/creator_courses_provider.dart', 'w') as f:
    f.write(content)

print("Patched creator_courses_provider.dart")
