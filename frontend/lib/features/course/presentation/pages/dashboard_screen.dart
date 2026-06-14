import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/course_provider.dart';

import '../../../../core/presentation/widgets/global_settings_menu.dart';

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
          const GlobalSettingsMenu(),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(allCoursesProvider.future);
          ref.refresh(enrolledCoursesProvider.future);
          ref.refresh(recommendedCoursesProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCourseSection(
              context,
              ref,
              'Continue Learning',
              ref.watch(enrolledCoursesProvider),
              emptyMessage: 'You are not enrolled in any courses yet.',
            ),
            const SizedBox(height: 24),
            _buildCourseSection(
              context,
              ref,
              'Recommended for You',
              ref.watch(recommendedCoursesProvider),
              emptyMessage: 'No recommended courses at this time.',
            ),
            const SizedBox(height: 24),
            _buildCourseSection(
              context,
              ref,
              'All Courses',
              ref.watch(allCoursesProvider),
              emptyMessage: 'No courses available.',
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'flowchart_fab',
            onPressed: () {
              if (context.mounted) context.push('/flowchart-designer');
            },
            icon: const Icon(Icons.account_tree),
            label: const Text('Flowchart'),
            backgroundColor: Colors.purpleAccent,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 16),
          const _BreathingFab(),
        ],
      ),
    );
  }

  Widget _buildCourseSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    AsyncValue<List<dynamic>> asyncCourses,
    {required String emptyMessage}
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        asyncCourses.when(
          data: (courses) {
            if (courses.isEmpty) return Text(emptyMessage, style: TextStyle(color: Colors.grey.shade600));
            return SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 280,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _buildCourseCard(context, theme, courses[index]),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (err, stack) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
      ],
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
                  ? Image.network(
                      course.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 64, color: Colors.white54),
                    )
                  : const Icon(Icons.code, size: 64, color: Colors.white54),
            ),
            Expanded(
              child: Padding(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (course.description != null) ...[
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          course.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingFab extends StatefulWidget {
  const _BreathingFab();

  @override
  State<_BreathingFab> createState() => _BreathingFabState();
}

class _BreathingFabState extends State<_BreathingFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: FloatingActionButton.extended(
            onPressed: () {
              if (context.mounted) context.push('/ide');
            },
            icon: const Icon(Icons.code),
            label: const Text('IDE'),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 4 * _animation.value,
          ),
        );
      },
    );
  }
}
