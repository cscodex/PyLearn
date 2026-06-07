import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/course_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coursesAsync = ref.watch(allCoursesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PythonTutor', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _buildGamificationBadge(Icons.local_fire_department, '5', Colors.orange),
          const SizedBox(width: 8),
          _buildGamificationBadge(Icons.star, '240 XP', Colors.amber),
          const SizedBox(width: 16),
        ],
      ),
      body: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return const Center(child: Text('No courses available yet.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(allCoursesProvider.future),
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1;
                if (constraints.maxWidth >= 900) {
                  crossAxisCount = 3;
                } else if (constraints.maxWidth >= 600) {
                  crossAxisCount = 2;
                }

                if (crossAxisCount == 1) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCourseCard(context, theme, courses[index]),
                      );
                    },
                  );
                } else {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      return _buildCourseCard(context, theme, courses[index]);
                    },
                  );
                }
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading courses: $error'),
              TextButton(
                onPressed: () => ref.refresh(allCoursesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamificationBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, ThemeData theme, dynamic course) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/courses/${course.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 140,
              color: theme.colorScheme.primaryContainer,
              child: course.thumbnailUrl != null
                  ? Image.network(course.thumbnailUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.code, size: 64, color: Colors.white54),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        course.difficultyLevel.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (course.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      course.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
