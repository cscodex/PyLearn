import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/profile_provider.dart';

class LearningHistoryScreen extends ConsumerWidget {
  const LearningHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning History'),
      ),
      body: profileAsync.when(
        data: (user) {
          final history = user.history;
          
          if (history.isEmpty) {
            return const Center(
              child: Text(
                'No learning history yet.\nStart a course to see your progress here!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final date = DateTime.tryParse(item.lastAccessedAt);
              final dateStr = date != null ? DateFormat.yMMMd().format(date) : 'Recently';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.book, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text(item.courseTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Last accessed: $dateStr'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: item.progressPercentage / 100.0,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        color: Colors.green,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 4),
                      Text('${item.progressPercentage.toInt()}% Completed', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading history: $err')),
      ),
    );
  }
}
