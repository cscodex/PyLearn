import re

with open('lib/features/creator/presentation/pages/creator_dashboard_screen.dart', 'r') as f:
    content = f.read()

# Add import for provider
if "creator_courses_provider.dart" not in content:
    content = "import '../providers/creator_courses_provider.dart';\n" + content

# Replace the body with a more dynamic UI that lists courses
replacement = """
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
                          child: Text('You haven\\'t created any courses yet.'),
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
                                '${course.difficultyLevel.toUpperCase()} • ${course.isPublished ? "Published" : "Draft"}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // For now we can open the details screen or the builder
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Course editing coming soon!')),
                                );
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
"""

content = re.sub(r'body: Center\(.*?\),', replacement, content, flags=re.DOTALL)

with open('lib/features/creator/presentation/pages/creator_dashboard_screen.dart', 'w') as f:
    f.write(content)

print("Patched creator_dashboard_screen.dart")
