import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../course/presentation/providers/saved_programs_provider.dart';
import '../../../course/presentation/pages/ide_screen.dart';

import '../../../../core/network/dio_client.dart';

final gradedSubmissionsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/admin/student-submissions');
    
    if (response.statusCode == 200) {
      return response.data as List<dynamic>;
    }
    return [];
  } catch (e) {
    // If user is a creator and not admin, this endpoint returns 403.
    // Gracefully return empty list instead of breaking the UI.
    return [];
  }
});

class CreatorStudentProgramsScreen extends ConsumerWidget {
  const CreatorStudentProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentProgramsAsync = ref.watch(studentProgramsProvider);
    final submissionsAsync = ref.watch(gradedSubmissionsProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Programs & Outputs'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Saved Programs'),
              Tab(text: 'Graded Assignments'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Saved Programs
            studentProgramsAsync.when(
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
      
      // Tab 2: Graded Assignments
      submissionsAsync.when(
        data: (submissions) {
          if (submissions.isEmpty) {
            return const Center(child: Text('No graded submissions yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final sub = submissions[index];
              final isPassed = sub['status'] == 'completed';
              return Card(
                elevation: 2,
                child: ExpansionTile(
                  leading: Icon(
                    isPassed ? Icons.check_circle : Icons.warning,
                    color: isPassed ? Colors.green : Colors.orange,
                  ),
                  title: Text('${sub['student_name']} - ${sub['challenge_title']}'),
                  subtitle: Text('Score: ${sub['score']}% (${sub['test_cases_passed']}/${sub['test_cases_total']} cases) • ${sub['submitted_at']?.split('T')?.first}'),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Submitted Code:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              sub['source_code'] ?? '',
                              style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Test Results:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...((sub['test_results'] as List<dynamic>?) ?? []).map((tr) {
                            final testPassed = tr['passed'] == true;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: testPassed ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                border: Border.all(color: testPassed ? Colors.green : Colors.red),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(testPassed ? Icons.check : Icons.close, size: 16, color: testPassed ? Colors.green : Colors.red),
                                      const SizedBox(width: 8),
                                      Text('Test Case ${tr['test_case_id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Expected: ${tr['expected_output']}'),
                                  Text('Actual: ${tr['actual_output']}'),
                                  if (tr['error'] != null) Text('Error: ${tr['error']}', style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                            );
                          }),
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
          ],
        ),
      ),
    );
  }
}
