import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/global_settings_menu.dart';
import '../../../course/presentation/providers/saved_programs_provider.dart';

class StudentProgramsScreen extends ConsumerWidget {
  const StudentProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPrograms = ref.watch(studentProgramsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Programs'),
        actions: const [GlobalSettingsMenu(), SizedBox(width: 8)],
      ),
      body: asyncPrograms.when(
        data: (programs) {
          if (programs.isEmpty) {
            return const Center(child: Text('No student programs found.'));
          }
          return ListView.builder(
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final program = programs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text(program.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('By: ${program.studentName ?? "Unknown"} (${program.studentEmail ?? ""})'),
                  trailing: FilledButton.tonalIcon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Evaluate'),
                    onPressed: () {
                      // We push to the IDE, passing the code via extra
                      context.push('/ide', extra: program);
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading programs: $e')),
      ),
    );
  }
}
