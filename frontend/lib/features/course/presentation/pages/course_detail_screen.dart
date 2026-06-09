import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_html/flutter_html.dart';
import '../providers/course_provider.dart';
import '../../data/repositories/course_repository.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
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
                          Consumer(
                            builder: (context, ref, child) {
                              final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);
                              return enrolledCoursesAsync.maybeWhen(
                                data: (courses) {
                                  final isEnrolled = courses.any((c) => c.id == courseId);
                                  if (!isEnrolled) return const SizedBox.shrink();
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        LinearProgressIndicator(
                                          value: course.progressPercentage / 100.0,
                                          backgroundColor: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${course.progressPercentage.toStringAsFixed(0)}% Complete',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                orElse: () => const SizedBox.shrink(),
                              );
                            },
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
                            child: Consumer(
                              builder: (context, ref, child) {
                                final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);
                                
                                return enrolledCoursesAsync.when(
                                  data: (courses) {
                                    final isEnrolled = courses.any((c) => c.id == courseId);
                                    return ElevatedButton(
                                      onPressed: () async {
                                        if (isEnrolled) {
                                          // Continue course
                                          if (course.modules.isNotEmpty && course.modules.first.chapters.isNotEmpty && course.modules.first.chapters.first.lessons.isNotEmpty) {
                                            context.push('/courses/$courseId/learn/${course.modules.first.chapters.first.lessons.first.id}');
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Course has no content yet.')),
                                            );
                                          }
                                          return;
                                        }

                                        final repo = ref.read(courseRepositoryProvider);
                                        final success = await repo.enrollInCourse(courseId);
                                        if (context.mounted) {
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Successfully enrolled!')),
                                            );
                                            ref.refresh(enrolledCoursesProvider);
                                            ref.refresh(courseDetailsProvider(courseId));
                                            if (course.modules.isNotEmpty && course.modules.first.chapters.isNotEmpty && course.modules.first.chapters.first.lessons.isNotEmpty) {
                                              context.push('/courses/$courseId/learn/${course.modules.first.chapters.first.lessons.first.id}');
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Failed to enroll. Please try again.')),
                                            );
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: Text(
                                        isEnrolled 
                                            ? (course.progressPercentage >= 100 ? 'Course Completed' : 'Continue Course') 
                                            : 'Enroll Now', 
                                        style: const TextStyle(fontSize: 18)
                                      ),
                                    );
                                  },
                                  loading: () => const ElevatedButton(
                                    onPressed: null,
                                    child: SizedBox(
                                      height: 20, 
                                      width: 20, 
                                      child: CircularProgressIndicator(strokeWidth: 2)
                                    )
                                  ),
                                  error: (_, __) => ElevatedButton(
                                    onPressed: () => ref.refresh(enrolledCoursesProvider),
                                    child: const Text('Retry Loading')
                                  ),
                                );
                              }
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
                          return ExpansionTile(
                            title: Text(chapter.title),
                            children: chapter.lessons.map((lesson) {
                              return ExpansionTile(
                                tilePadding: const EdgeInsets.only(left: 48, right: 16),
                                leading: const Icon(Icons.play_circle_outline, size: 20),
                                title: Text(lesson.title, style: const TextStyle(fontSize: 14)),
                                subtitle: Text(lesson.contentType.toUpperCase(), style: const TextStyle(fontSize: 12)),
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16.0),
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Html(data: lesson.contentBody?['text'] ?? '<i>No preview available.</i>'),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            context.push('/courses/$courseId/learn/${lesson.id}');
                                          },
                                          child: const Text('Start Lesson'),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              );
                            }).toList(),
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
