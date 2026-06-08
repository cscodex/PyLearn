import '../providers/creator_courses_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/global_settings_menu.dart';

class CreatorDashboardScreen extends ConsumerWidget {
  const CreatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Studio'),
        centerTitle: false,
        actions: [
          const GlobalSettingsMenu(),
          const SizedBox(width: 8),
        ],
      ),
      
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_document, size: 48, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to Creator Studio',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Manage your courses, modules, and quizzes.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => context.push('/creator/course/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('New Course'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/creator/groups'),
                          icon: const Icon(Icons.people),
                          label: const Text('Manage Groups'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/creator/enrollments'),
                          icon: const Icon(Icons.analytics),
                          label: const Text('Enrollments'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'My Courses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final coursesAsync = ref.watch(creatorCoursesProvider);
              return coursesAsync.when(
                data: (courses) {
                  if (courses.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('You haven\'t created any courses yet.'),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final course = courses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.book, color: Theme.of(context).colorScheme.primary),
                              ),
                              title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                course.difficultyLevel.toUpperCase(),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // For now we can open the details screen or the builder
                                  _showEditCourseDialog(context, ref, course);
                              },
                            ),
                          );
                        },
                        childCount: courses.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),


    );
  }

  void _showEditCourseDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> course) {
    final titleCtrl = TextEditingController(text: course['title']);
    final descCtrl = TextEditingController(text: course['description']);
    String difficulty = course['difficulty_level'] ?? 'beginner';
    bool isPublished = course['is_published'] ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Course'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: difficulty,
                      decoration: const InputDecoration(labelText: 'Difficulty'),
                      items: const [
                        DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                        DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                        DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                      ],
                      onChanged: (val) => setDialogState(() => difficulty = val!),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Published'),
                      value: isPublished,
                      onChanged: (val) => setDialogState(() => isPublished = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await ref.read(creatorCoursesProvider.notifier).updateCourse(
                      course['id'],
                      {
                        "title": titleCtrl.text,
                        "slug": course['slug'] ?? titleCtrl.text.toLowerCase().replaceAll(' ', '-'),
                        "description": descCtrl.text,
                        "difficulty_level": difficulty,
                        "is_published": isPublished,
                        "thumbnail_url": course['thumbnail_url'] ?? "https://images.unsplash.com/photo-1515879218367-8466d910aaa4?q=80&w=600&auto=format&fit=crop",
                      },
                    );
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course updated successfully!')));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
