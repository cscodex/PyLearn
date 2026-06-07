import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreatorDashboardScreen extends ConsumerWidget {
  const CreatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Studio'),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () {
              context.push('/creator/groups');
            },
            icon: const Icon(Icons.people),
            label: const Text('Manage Groups'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              // TODO: Navigate to Course Builder
            },
            icon: const Icon(Icons.add),
            label: const Text('New Course'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_document, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Welcome to Creator Studio',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Here you can build and manage courses, modules, quizzes, and assignments.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
