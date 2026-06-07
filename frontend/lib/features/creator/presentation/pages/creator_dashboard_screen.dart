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
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_document, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'Welcome to Creator Studio',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Here you can build and manage courses, modules, quizzes, and assignments.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      context.push('/creator/groups');
                    },
                    icon: const Icon(Icons.people),
                    label: const Text('Manage Groups'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.push('/creator/enrollments');
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text('Enrollments'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      context.push('/creator/course/new');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Course'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
