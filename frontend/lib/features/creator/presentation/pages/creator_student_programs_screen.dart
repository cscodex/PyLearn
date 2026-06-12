import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../course/presentation/providers/saved_programs_provider.dart';
import '../../../course/presentation/pages/ide_screen.dart';

class CreatorStudentProgramsScreen extends ConsumerWidget {
  const CreatorStudentProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentProgramsAsync = ref.watch(studentProgramsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Programs & Outputs'),
      ),
      body: studentProgramsAsync.when(
        data: (programs) {
          if (programs.isEmpty) {
            return const Center(child: Text('No student programs found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: programs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final program = programs[index];
              return Card(
                elevation: 2,
                child: ExpansionTile(
                  leading: const Icon(Icons.code, color: Colors.blue),
                  title: Text('${program.studentName} - ${program.title}'),
                  subtitle: Text('Lesson ${program.lessonId ?? 'N/A'} • ${program.createdAt.split('T').first}'),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Code:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              program.code,
                              style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Terminal Output:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              program.terminalOutput ?? 'No output saved.',
                              style: TextStyle(fontFamily: 'monospace', color: Colors.green.shade400, fontSize: 13),
                            ),
                          ),
                          if (program.plots != null && program.plots!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text('Plots:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...program.plots!.map((plotData) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Image.memory(
                                  base64Decode(plotData.toString()),
                                  errorBuilder: (context, error, stackTrace) => const Text('Error loading plot', style: TextStyle(color: Colors.red)),
                                ),
                              );
                            }),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
