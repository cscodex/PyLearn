import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/course_provider.dart';

class CourseDetailScreen extends ConsumerWidget {
  final int courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final courseAsync = ref.watch(courseDetailsProvider(courseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
      ),
      body: courseAsync.when(
        data: (course) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 200,
                      color: theme.colorScheme.primaryContainer,
                      child: course.thumbnailUrl != null
                          ? Image.network(course.thumbnailUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.menu_book, size: 80, color: Colors.white54),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Chip(
                                label: Text(course.difficultyLevel.toUpperCase()),
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            course.title,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (course.description != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              course.description!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: Implement Enrollment logic and navigation to Ide
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Enrolling...')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Enroll Now', style: TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Course Content',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (course.modules.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('Content is being prepared for this course.'),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final module = course.modules[index];
                      return ExpansionTile(
                        title: Text(
                          'Module ${index + 1}: ${module.title}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: module.description != null
                            ? Text(module.description!)
                            : null,
                        children: module.chapters.map((chapter) {
                          return ListTile(
                            contentPadding: const EdgeInsets.only(left: 32, right: 16),
                            title: Text(chapter.title),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              if (chapter.id % 2 == 0) {
                                context.push('/quiz/${chapter.id}');
                              } else {
                                context.push('/ide/${chapter.id}');
                              }
                            },
                          );
                        }).toList(),
                      );
                    },
                    childCount: course.modules.length,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading course details: $error'),
              TextButton(
                onPressed: () => ref.refresh(courseDetailsProvider(courseId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
