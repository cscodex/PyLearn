import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/course.dart';
import '../providers/course_provider.dart';
import '../../data/repositories/course_repository.dart';
import 'ide_screen.dart';
import 'quiz_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CoursePlayerScreen extends ConsumerStatefulWidget {
  final int courseId;
  final int lessonId;

  const CoursePlayerScreen({super.key, required this.courseId, required this.lessonId});

  @override
  ConsumerState<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends ConsumerState<CoursePlayerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _markCompleteAndNext(Course course, Lesson currentLesson) async {
    try {
      final repo = ref.read(courseRepositoryProvider);
      await repo.markLessonAsComplete(widget.courseId, currentLesson.id);
      
      // Refresh progress
      ref.refresh(courseDetailsProvider(widget.courseId));
      
      // Find next lesson
      Lesson? nextLesson;
      bool foundCurrent = false;
      
      for (final module in course.modules) {
        for (final chapter in module.chapters) {
          for (final lesson in chapter.lessons) {
            if (foundCurrent) {
              nextLesson = lesson;
              break;
            }
            if (lesson.id == currentLesson.id) {
              foundCurrent = true;
            }
          }
          if (nextLesson != null) break;
        }
        if (nextLesson != null) break;
      }
      
      if (nextLesson != null && mounted) {
        context.go('/courses/${widget.courseId}/learn/${nextLesson.id}');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course Completed! 🎉')),
        );
        context.go('/courses/${widget.courseId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking complete: $e')),
        );
      }
    }
  }

  Widget _buildSidebar(Course course) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: course.progressPercentage / 100.0,
                    backgroundColor: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 4),
                  Text('${course.progressPercentage.toStringAsFixed(0)}% Complete', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: course.modules.length,
                itemBuilder: (context, mIndex) {
                  final module = course.modules[mIndex];
                  return ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    children: module.chapters.map((chapter) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              chapter.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          ...chapter.lessons.map((lesson) {
                            final isCompleted = course.completedLessonIds.contains(lesson.id);
                            final isCurrent = lesson.id == widget.lessonId;
                            
                            return ListTile(
                              leading: Icon(
                                isCompleted ? Icons.check_circle : Icons.circle_outlined,
                                color: isCompleted ? Colors.green : Colors.grey,
                                size: 20,
                              ),
                              title: Text(lesson.title, style: TextStyle(fontSize: 14, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                              selected: isCurrent,
                              selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                              onTap: () {
                                if (!isCurrent) {
                                  context.go('/courses/${course.id}/learn/${lesson.id}');
                                } else {
                                  if (Scaffold.of(context).hasDrawer) {
                                    Navigator.pop(context);
                                  }
                                }
                              },
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonContent(Course course, Lesson lesson) {
    if (lesson.contentType == 'video' || lesson.contentType == 'text') {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Expanded(
                  child: Markdown(
                    data: lesson.contentBody?['text'] ?? 'No content available.',
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      p: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _markCompleteAndNext(course, lesson),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Mark Complete & Continue', style: TextStyle(fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    } else if (lesson.contentType == 'code_challenge') {
      return IdeScreen(lessonId: lesson.id, inline: true, onComplete: () => _markCompleteAndNext(course, lesson));
    } else if (lesson.contentType == 'quiz') {
      return QuizScreen(lessonId: lesson.id, inline: true, onComplete: () => _markCompleteAndNext(course, lesson));
    }
    
    return const Center(child: Text('Unknown content type'));
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailsProvider(widget.courseId));

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Course Player'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/courses/${widget.courseId}'),
          )
        ],
      ),
      drawer: courseAsync.whenOrNull(
        data: (course) => _buildSidebar(course)
      ),
      body: courseAsync.when(
        data: (course) {
          Lesson? currentLesson;
          for (final m in course.modules) {
            for (final c in m.chapters) {
              for (final l in c.lessons) {
                if (l.id == widget.lessonId) currentLesson = l;
              }
            }
          }
          
          if (currentLesson == null) {
            return const Center(child: Text('Lesson not found.'));
          }

          return Row(
            children: [
              // Show permanent sidebar on desktop
              if (MediaQuery.of(context).size.width >= 800)
                SizedBox(
                  width: 300,
                  child: _buildSidebar(course),
                ),
              if (MediaQuery.of(context).size.width >= 800)
                const VerticalDivider(width: 1, thickness: 1),
              
              Expanded(
                child: _buildLessonContent(course, currentLesson),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
